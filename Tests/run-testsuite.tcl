#!/usr/bin/env tclsh

# run-testsuite.tcl
#	run the tests
#
# Usage:
#	run-testsuite.tcl [-glob|-exact|-regexp] [pattern]
#
# - run all the tests, if no tests supplied on the command line
# - run the tests identified by command line pattern, e.g.
#	run-testsuite.tcl xinit_*
#	run-testsuite.tcl -glob xinit_*
#	run-testsuite.tcl -regexp *._1
#
# connect_[23] require an erlang node to be present on the local host
# - start it with "erl -sname erlnode -setcookie secretcookie"

package require tcltest

# full verbosity = {body start skip pass error line}
tcltest::configure -verbose {start skip pass error}

# we expect the test suite to be in the same directory as this one
source [file join [file dirname $argv0] etclface-testsuite.tcl]

# wrapper for all tests
proc runtest {tname tdesc} {
	tcltest::test $tname "$tdesc" {
		-body $tname
		-returnCodes ok
	}
}

# set up the erlang node
set pipedir /tmp/erlnode/
file mkdir "$pipedir"

# the erlang node parameters are defined in etclface-testsuite.tcl
set erlnodecmd "erl -sname $::remnode -setcookie $::cookie -s $::remserver"
exec run_erl -daemon "$pipedir" "$pipedir" "exec $erlnodecmd"
# give the node a chance to start up
after 1000

# run the tests
foreach tname [lsort [array names all_tests {*}$argv]] {
	runtest $tname $all_tests($tname)
}

puts {=========================}
tcltest::cleanupTests

# stop the erlang node
exec -ignorestderr echo q(). | to_erl "$pipedir"
