#!/usr/bin/env tclsh

# pingserver.tcl
#	wait for ping messages, then respond.

# Configurable parameters
# TODO These should be configurable from the command line
#
set ::mynode	"etfnode"
set ::mycookie	"secretcookie"
set ::myport	12345

package require etclface

# for verbose runs
proc diag {message} {
	puts stderr "$::argv0: $message"
}

# reply to a ping message, e.g.
# {'$gen_call', {<erlnode@dell2d2.169.0>, #Ref<563.0.0>}, {is_auth, erlnode@dell2d2}}
# The format is
# a tuple of arity 3
# term 1 is an atom '$gen_call'
# term 2 is a tuple of arity 2
#	term 2.1 is the senders PID
#	term 2.2 is a REF
# term 3 is a tuple of arity 2
#	term 3.1 is the atom 'is_auth'
#	term 3.2 is the senders nodename
#
proc ping_reply {xb} {
	diag "ping_reply $xb."
	# rewind the index to the beginning
	etclface::xb_reset $xb
	catch {etclface::decode_version $xb}
	# for debugging, pretty-print the message
	set msg [etclface::xb_print $xb]
	diag "buff: >$msg<"
	# rewind the index to the beginning, again!
	etclface::xb_reset $xb
	catch {etclface::decode_version $xb}
	if [catch {	set arity [etclface::decode_tuple $xb]
			if {$arity != 3} {error "bad arity"}
			set tag [etclface::decode_atom $xb]
			if {$tag != {$gen_call}} {error "bad tag ($tag)"}
			set arity [etclface::decode_tuple $xb]
			if {$arity != 2} {error "bad arity"}
			set pid [etclface::decode_pid $xb]
			set ref [etclface::decode_term $xb]
			diag "ref=$ref."
			set arity [etclface::decode_tuple $xb]
			if {$arity != 2} {error "bad arity"}
			set tag [etclface::decode_atom $xb]
			if {$tag != {is_auth}} {error "bad tag"}
			set nodename [etclface::decode_atom $xb]
			} result] {
		diag "bad ping message ($result)."
		return
	}
	# message is ok, now send back the reply
	diag "ping message is OK."
}

# uncomment, if needed
##etclface::tracelevel 44

# initialize thyself
if [catch {	set ec [etclface::init $::mynode $::mycookie]
		set sockfd [etclface::socket - $::myport]
		etclface::listen $sockfd 5
		set fd [etclface::publish $ec $::myport] } result] {
	diag "startup failed: $result"
	exit 1
}
diag "startup OK."

while true {
	diag [string repeat "=" 50]
	# await pinggers
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
	diag "xb=$xb."

	# wait for a message on the new connection
	diag "awaiting a message on $connfd"
	if [catch {etclface::receive $connfd $xb} result] {
		# something went wrong, clean up and wait for another ping
		diag "receive failed: $result"
		etclface::disconnect $connfd
		etclface::xb_free $xb
		diag [string repeat "-" 50]
		continue
	}
	set msg $result
	diag "msg=$msg."

	# check and reply to the ping
	ping_reply $xb

	# clean up and move wait for another ping
	etclface::disconnect $connfd
	etclface::xb_free $xb
	diag [string repeat "-" 50]
}

