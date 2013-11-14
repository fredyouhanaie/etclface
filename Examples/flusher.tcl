#!/usr/bin/env tclsh

# flusher.tcl
#	Open a port, wait for messages, then print them.
#	We can only handle one remote connection at a time!

# Configurable parameters
# - these can be overridden on the command line
set ::mynode	"etfnode"
set ::mycookie	"secretcookie"
set ::myport	12345
set ::timeout	5000

package require etclface

proc usage {} {
	puts stderr "Usage: [file tail $::argv0] \[-c cookie\] \[-p port\] \[-n nodename\] \[-t timeout\]"
	exit 1
}

proc argv_shift {} {
	if {$::argc > 0} {
		set next [lindex $::argv 0]
		set ::argv [lrange $::argv 1 end]
		incr ::argc -1
	} else {
		set next {}
	}
	return $next
}

proc parse_opts {} {
	while {$::argc > 0} {
		set opt [argv_shift]
		switch -- $opt {
			"-c" {	if {$::argc == 0} usage
				set ::mycookie [argv_shift]
			}
			"-n" {	if {$::argc == 0} usage
				set ::mynode [argv_shift]
			}
			"-p" {	if {$::argc == 0} usage
				set ::myport [argv_shift]
			}
			"-t" {	if {$::argc == 0} usage
				set ::timeout [argv_shift]
			}
			default	usage
		}
	}
	return
}

# for verbose runs
proc diag {message} {
	puts stderr "$::argv0: [clock milliseconds] $message"
}

# uncomment, if needed
##etclface::tracelevel 44

parse_opts
diag "starting up as $::mynode, on port $::myport with cookie $::mycookie"

# initialize thyself
if [catch {	set ec [etclface::init $::mynode $::mycookie]
		set sockfd [etclface::socket - $::myport]
		etclface::listen $sockfd 5
		set fd [etclface::publish $ec $::myport]
		} result] {
	diag "startup failed: $result"
	exit 1
}
diag "startup OK."

while true {
	diag [string repeat "=" 50]
	diag "awaiting connections on $sockfd."
	if [catch {etclface::accept $ec $sockfd} result] {
		diag "accept failed: $result."
		diag [string repeat "-" 50]
		continue
	}
	array set econn $result
	diag "accepted a connection on $econn(fd) from $econn(nodename) at $econn(nodeaddr)."
	set connfd $econn(fd)

	# we need a buffer to receive the message
	if [catch {etclface::xb_new} result] {
		diag "xb_new failed: $result"
		exit 1
	}
	set xb $result

	# wait for a message on the new connection
	diag "awaiting a message on $connfd"
	while {![catch {etclface::receive $connfd $xb $::timeout} result]} {
		diag "received a message: $result"
		etclface::xb_reset $xb
		if {![catch {etclface::decode_version $xb} version]} {
			diag "version=$version"
		}
		if [catch {etclface::xb_print $xb} result] {
			diag "bad message: $result"
			continue
		}
		diag "message: $result"
		etclface::xb_reset $xb
	}
	# something went wrong, clean up and wait for another ping
	diag "receive failed: $result"
	etclface::disconnect $connfd
	etclface::xb_free $xb
	diag [string repeat "-" 50]
}

