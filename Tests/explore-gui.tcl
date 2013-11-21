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
set ::conn_echandle {}
set ::conn_nodename {erlnode@localhost}

set ::init_nodename {etfnode}
set ::init_cookie {secretcookie}

set ::regsend_echandle {}
set ::regsend_fdhandle {}
set ::regsend_server   {server1}
set ::regsend_xbhandle {}


proc diag {msg} {
	puts stderr "$::argv0: $msg"
}

# new_form
# create and display a form in a separate window
# - the form will be on its own top level wiondow
# - it will be identified by the "name" parameter
# - if one is already active, it will be destroyed/replaced
proc new_form {name descr formproc actionproc} {
	set root .${name}
	# let's be brutal!
	catch [destroy $root]

	toplevel ${root} 
	wm title ${root} $descr

	if [catch "$formproc $root"] {
		destroy $root
		return
	}

	button	${root}.ok	-text OK	-command $actionproc
	button	${root}.cancel	-text Cancel	-command "destroy ${root}"
	grid ${root}.ok ${root}.cancel
}

# check_handle
# check and provide a menu of handles for the user to choose
proc check_handle {type root handle_var} {
	if {![dict exists $::Handles ${type} index]} {
		tk_messageBox -type ok -message "No ${type} handles found."
		return -code error
	}
	label	${root}.${type}_lab_handle -text "$type Handle"
	set handlelist [dict keys [dict get $::Handles $type] ${type}*]
	set $handle_var [lindex $handlelist 0]
	tk_optionMenu ${root}.${type}_mb_handle $handle_var {*}$handlelist
	return
}

# form_conn
# collect parameters for etclface::connect
# - this is expected to be called from within new_form
proc form_conn {root} {
	if [catch {check_handle ec $root ::conn_echandle}] { return -code error}

	label	${root}.lab_nodename -text "Remote Node"
	entry	${root}.ent_nodename -textvariable ::conn_nodename

	grid ${root}.ec_lab_handle ${root}.ec_mb_handle
	grid ${root}.lab_nodename ${root}.ent_nodename
}

# form_init
# collect parameters for etclface::init
# - this is expected to be called from within new_form
proc form_init {root} {
	label	${root}.lab_node -text "nodename"
	entry	${root}.ent_node -textvariable ::init_nodename -validate all
	grid ${root}.lab_node ${root}.ent_node

	label	${root}.lab_cookie -text "cookie"
	entry	${root}.ent_cookie -textvariable ::init_cookie -validate all
	grid ${root}.lab_cookie ${root}.ent_cookie
}

# form_regsend
# collect parameters for etclface::reg_send
# - this is expected to be called from within new_form
proc form_regsend {root} {
	if [catch {check_handle ec $root ::regsend_echandle}] { return -code error}
	if [catch {check_handle fd $root ::regsend_fdhandle}] { return -code error}

	label	${root}.lab_server -text "Remote process name"
	entry	${root}.ent_server -textvariable ::regsend_server
	if [catch {check_handle xb $root ::regsend_xbhandle}] { return -code error}

	grid ${root}.ec_lab_handle ${root}.ec_mb_handle
	grid ${root}.fd_lab_handle ${root}.fd_mb_handle
	grid ${root}.lab_server    ${root}.ent_server
	grid ${root}.xb_lab_handle ${root}.xb_mb_handle
}

# do_conn
# verify paremeters and execute etclface::connect
# - this is expected to be called via the form_conn's OK button
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

# do_init
# verify paremeters and execute etclface::init
# - this is expected to be called via the form_init's OK button
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

# do_regsend
# verify paremeters and execute etclface::reg_send
# - this is expected to be called via the form_regsend's OK button
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
button .regsend	-text regsend	-command {new_form form_regsend {Registered Send Form} form_regsend do_regsend}
button .quit	-text Quit	-command exit

grid .conn
grid .init
grid .regsend
grid .quit

