#!/usr/bin/env wish

# explore-gui.tcl
#	a GUI for exploratory testing.
#
# This was created in order execute arbitrary commands without having
# to type much.

package require etclface

# Data Handles
#	- All the data are kept in a single nest dictionary
#	- level 1 is the set of handle types, key=type, e.g. ec, pid, etc.
#	- level 2 is the set of handle names, key=name, e.g. ec1, ec2, pid1, pid2, etc.
#	  - also contains an index, initially zero, incremented before
#	    adding a handle.
#	- level 3 is the per handle data (a dictionary)
set Handles [dict create]

# for forms data entry
set ::init_nodename {etfnode}
set ::init_cookie {secretcookie}

set ::conn_echandle {}
set ::conn_nodename {erlnode@localhost}

proc diag {msg} {
	puts stderr "$::argv0: $msg"
}

proc new_form {name descr formproc actionproc} {
	set root .${name}
	# let's be brutal!
	catch [destroy $root]

	toplevel ${root} 
	wm title ${root} $descr

	$formproc $root

	button	${root}.ok	-text OK	-command $actionproc
	button	${root}.cancel	-text Cancel	-command "destroy ${root}"
	grid ${root}.ok ${root}.cancel
}

proc form_conn {root} {
	if {![dict exists $::Handles ec index]} {
		tk_messageBox -type ok -message "No ec handles, call init first"
		destroy $root
		return
	}

	label	${root}.lab_handle -text "ec Handle"
	set eclist [dict keys [dict get $::Handles ec] ec*]
	set ::conn_echandle [lindex $eclist 0]
	tk_optionMenu ${root}.mb_handle ::conn_echandle {*}$eclist

	label	${root}.lab_nodename -text "Remote Node"
	entry	${root}.ent_nodename -textvariable ::conn_nodename

	grid ${root}.lab_handle ${root}.mb_handle
	grid ${root}.lab_nodename ${root}.ent_nodename
}

proc form_init {root} {
	label	${root}.lab_node -text "nodename"
	entry	${root}.ent_node -textvariable ::init_nodename -validate all
	grid ${root}.lab_node ${root}.ent_node

	label	${root}.lab_cookie -text "cookie"
	entry	${root}.ent_cookie -textvariable ::init_cookie -validate all
	grid ${root}.lab_cookie ${root}.ent_cookie
}

proc do_conn {} {
	if {![dict exists $::Handles ec $::conn_echandle]} {
		tk_messageBox -type ok -message "Please select an ec Handle" -icon error
		return
	}
	if [catch {	set ec [dict get $::Handles ec $::conn_echandle handle]
			set fd [etclface::connect $ec $::conn_nodename]
			set ch [etclface::make_chan $fd R]
			} result] {
		tk_messageBox -type ok -message $::errorInfo -icon error
	} else {
		
		add_handle fd "fd $fd chan $ch echandle $::conn_echandle nodename $::conn_nodename"
	}
	destroy .form_conn
}

proc do_init {} {
	if [catch {	if [string length $::init_cookie] {
				etclface::init $::init_nodename $::init_cookie
			} else {
				etclface::init $::init_nodename
			} } result ] {
		tk_messageBox -type ok -message $result -icon error
	} else {
		add_handle ec "handle $result nodename $::init_nodename cookie $::init_cookie"
	}
	destroy .form_init
}

proc add_handle {type data} {
	# create the type specific dictionary, if this is the first ever handle of this type
	if {![dict exists $::Handles $type]} {
		dict set ::Handles $type [dict create index 0]
	}
	# get the next index
	dict with ::Handles {
		dict incr $type index
	}
	set index [dict get $::Handles $type index]
	# name is ec1, ec2, pid4, etc
	set name ${type}${index}
	# save the handle (e.g. ec0x1234) and the data
	dict set ::Handles $type $name [dict create {*}$data]
	diag "add_handle: $::Handles"
}

#  MAIN  ##########################

button .conn	-text conn	-command {new_form form_conn {Connection Form} form_conn do_conn}
button .init	-text init	-command {new_form form_init {Initialization Form} form_init do_init}
button .quit	-text Quit	-command exit

grid .conn
grid .init
grid .quit

