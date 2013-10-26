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
tcltest::configure -verbose {start skip pass}

# we expect the test suite to be in the same directory as this one
source [file join [file dirname $argv0] etclface-testsuite.tcl]

# wrapper for all tests
proc runtest {tname tdesc} {
	tcltest::test $tname "$tdesc" {
		-body $tname
		-returnCodes ok
	}
}

array set all_tests {
	init_1		{etclface::init with no arguments}
	init_2		{etclface::init with no cookie}
	init_3		{etclface::init with cookie}
	xinit_1		{etclface::xinit with no arguments}
	xinit_2		{etclface::xinit with no cookie}
	xinit_3		{etclface::xinit with cookie}
	connect_1	{etclface::connect with no arguments}
	connect_2	{etclface::connect with no timeout}
	connect_3	{etclface::connect with timeout}
	connect_4	{etclface::connect with bad argument}
	xconnect_1	{etclface::xconnect with no arguments}
	xconnect_2	{etclface::xconnect with no timeout}
	xconnect_3	{etclface::xconnect with timeout}
	xconnect_4	{etclface::xconnect with bad argument}
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

