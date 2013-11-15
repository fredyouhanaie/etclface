#!/usr/bin/env tclsh

# flusher-multi.tcl
#	Open a port, wait for connections from multiple nodes,
#	receive messages in any order, and print them out.
#	This is the event driven vesion of flusher.tcl

# Configurable parameters
# - these can be overridden on the command line
set ::mynode	"etfnode"
set ::mycookie	"secretcookie"
set ::myport	12345
set ::timeout	5000

package require etclface

proc usage {} {
	puts stderr "Usage: [file tail $::argv0] \[-c cookie\] \[-n nodename\] \[-p port\] \[-t timeout\]"
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
	set newtime [clock millisecond]
	set interval [expr $newtime - $::oldtime]
	set timestamp [format {%9d} $interval]
	puts stderr "$::argv0: $timestamp $message"
	set ::oldtime $newtime
}

# this is the handle for receiving connection requests
# once a connection is accepted, a new handle is set up for the new fd/chan
proc get_conn {ec chan fd} {
	if [catch {etclface::accept $ec $fd} result] {
		diag "($chan) accept failed: $result."
	} else {
		array set econn $result
		diag "($chan) accepted a new connection on $econn(fd) from $econn(nodename) at $econn(nodeaddr)."

		# set up handle for messages on this new connection
		set newchan [etclface::make_chan $econn(fd) R]
		chan event $newchan readable "get_message $newchan $econn(fd)"
	}
	return
}

# this is the handle for receiving messages on an established connection
proc get_message {chan fd} {
	# we need a buffer to receive the message
	if [catch {set xb [etclface::xb_new]} result] {
		diag "($chan) xb_new failed: $result"
	} elseif [catch {etclface::receive $fd $xb $::timeout} result] {
		diag "($chan) receive failed: $result"
		chan close $chan
	} elseif {$result == "TICK"} {
		diag "($chan) tick"
	} else {
		diag "($chan) received a new message: $result"
		if [catch {	etclface::xb_reset $xb
				set version [etclface::decode_version $xb]
				set message [etclface::xb_print $xb]
				diag "($chan) message: (vrsn=$version) $message"
				} result ] {
			diag "($chan) bad message: $result"
		}
	}
	if [info exists xb] {etclface::xb_free $xb}
	return
}

# this is for diag timestamps
set ::oldtime	[clock milliseconds]

parse_opts
diag "starting up as $::mynode, on port $::myport with cookie $::mycookie and timeout ${::timeout}ms"

# initialize thyself
if [catch {	set ec [etclface::init $::mynode $::mycookie]
		set sockfd [etclface::socket - $::myport]
		etclface::listen $sockfd 5
		set fd [etclface::publish $ec $::myport]
		} result] {
	diag "startup failed: $result"
	diag "$::errorInfo"
	exit 1
}
diag "startup OK."

# set up a handle for connection requests
set chan [etclface::make_chan $sockfd R]
chan event $chan readable "get_conn $ec $chan $sockfd"
diag "($chan) awaiting connections on $fd."

vwait forever

