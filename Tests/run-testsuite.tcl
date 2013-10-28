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

foreach tname [lsort [array names all_tests {*}$argv]] {
	runtest $tname $all_tests($tname)
}

puts {=========================}
tcltest::cleanupTests

