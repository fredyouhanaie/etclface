#!/usr/bin/env tclsh

# run-testsuite.tcl
#	run the tests
#
# - run the tests listed on the command line
# - run all the tests, if no tests supplied on the command line
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

if {$argc == 0} {
	set tests [lsort [array names all_tests]]
} else {
	set tests $argv
}

foreach tname $tests {
	if {$tname in [array names all_tests]} {
		runtest $tname $all_tests($tname)
	} else {
		puts stderr "Unknown test name >$tname<"
	}
}

puts {=========================}
tcltest::cleanupTests

