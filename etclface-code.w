
%% etclface-code.w
%%	The actual code for the etclface cweb files.

%% Copyright (c) 2013 Fred Youhanaie
%% All rights reserved.
%%
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions
%% are met:
%%
%%	* Redistributions of source code must retain the above copyright
%%	  notice, this list of conditions and the following disclaimer.
%%
%%	* Redistributions in binary form must reproduce the above copyright
%%	  notice, this list of conditions and the following disclaimer
%%	  in the documentation and/or other materials provided with the
%%	  distribution.
%%
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
%% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
%% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
%% A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
%% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
%% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
%% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
%% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
%% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
%% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
%% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@*The Source Code.

The \etf commands are collected in a number of groups.

@c

#include <string.h>
#include <tcl.h>
#include <erl_interface.h>
#include <ei.h>

@<Command declarations@>;
@<Internal helper functions@>;
@<Initialization commands@>;
@<Connection commands@>;
@<Send commands@>;
@<Receive commands@>;
@<Buffer commands@>;
@<Encode commands@>;
@<Decode commands@>;
@<Utility commands@>;
@<AppInit@>;

@ We follow the standard format for all Tcl extensions. \.{Etclface\_Init}
initializes the library and declares the commands. We require \.{Tcl}
version 8.5 or higher, This vesion has been around for some time now,
so we can expect it to be available at most sites.

@<AppInit@>=
int
Etclface_Init(Tcl_Interp *ti)
{
	if (Tcl_InitStubs(ti, "8.5", 0) == NULL) {
		return TCL_ERROR;
	}

	if (Tcl_PkgRequire(ti, "Tcl", "8.5", 0) == NULL) {
		return TCL_ERROR;
	}

	if (Tcl_PkgProvide(ti, "etclface", "0.1") != TCL_OK) {
		return TCL_ERROR;
	}

	EtclfaceCommand_t *etfcmd = EtclfaceCommand;
	while (etfcmd->proc != NULL) {
		Tcl_CreateObjCommand(ti, etfcmd->name, etfcmd->proc, NULL, NULL);
		etfcmd++;
	}

	return TCL_OK;
}

@*1The Commands.

All the Tcl commands and their associated functions are defined in the
|EtclfaceCommand| array, which is then added to Tcl in the |Etclface_Init|
function.

@<Command declarations@>=
typedef struct EtclfaceCommand_s {
	char		*name;
	Tcl_ObjCmdProc	*proc;
} EtclfaceCommand_t;

@ We need to forward declare the functions first, in alphabetical order.

@<Command declarations@>=
static Tcl_ObjCmdProc Etclface_connect;
static Tcl_ObjCmdProc Etclface_decode_atom;
static Tcl_ObjCmdProc Etclface_decode_long;
static Tcl_ObjCmdProc Etclface_disconnect;
static Tcl_ObjCmdProc Etclface_ec_free;
static Tcl_ObjCmdProc Etclface_ec_show;
static Tcl_ObjCmdProc Etclface_encode_atom;
static Tcl_ObjCmdProc Etclface_encode_boolean;
static Tcl_ObjCmdProc Etclface_encode_char;
static Tcl_ObjCmdProc Etclface_encode_double;
static Tcl_ObjCmdProc Etclface_encode_empty_list;
static Tcl_ObjCmdProc Etclface_encode_list_header;
static Tcl_ObjCmdProc Etclface_encode_long;
static Tcl_ObjCmdProc Etclface_encode_pid;
static Tcl_ObjCmdProc Etclface_encode_string;
static Tcl_ObjCmdProc Etclface_encode_tuple_header;
static Tcl_ObjCmdProc Etclface_init;
static Tcl_ObjCmdProc Etclface_nodename;
static Tcl_ObjCmdProc Etclface_pid_show;
static Tcl_ObjCmdProc Etclface_receive;
static Tcl_ObjCmdProc Etclface_reg_send;
static Tcl_ObjCmdProc Etclface_self;
static Tcl_ObjCmdProc Etclface_tracelevel;
static Tcl_ObjCmdProc Etclface_xb_free;
static Tcl_ObjCmdProc Etclface_xb_new;
static Tcl_ObjCmdProc Etclface_xb_show;
static Tcl_ObjCmdProc Etclface_xconnect;
static Tcl_ObjCmdProc Etclface_xinit;


@ These are the command names and their associated functions, in
alphabetical order. The last element must be a \.{\{NULL,NULL\}}

@<Command declarations@>=
static EtclfaceCommand_t EtclfaceCommand[] = {@/
	{"etclface::connect", Etclface_connect},@/
	{"etclface::decode_atom", Etclface_decode_atom},@/
	{"etclface::decode_long", Etclface_decode_long},@/
	{"etclface::disconnect", Etclface_disconnect},@/
	{"etclface::ec_free", Etclface_ec_free},@/
	{"etclface::ec_show", Etclface_ec_show},@/
	{"etclface::encode_atom", Etclface_encode_atom},@/
	{"etclface::encode_boolean", Etclface_encode_boolean},@/
	{"etclface::encode_char", Etclface_encode_char},@/
	{"etclface::encode_double", Etclface_encode_double},@/
	{"etclface::encode_empty_list", Etclface_encode_empty_list},@/
	{"etclface::encode_list_header", Etclface_encode_list_header},@/
	{"etclface::encode_long", Etclface_encode_long},@/
	{"etclface::encode_pid", Etclface_encode_pid},@/
	{"etclface::encode_string", Etclface_encode_string},@/
	{"etclface::encode_tuple_header", Etclface_encode_tuple_header},@/
	{"etclface::init", Etclface_init},@/
	{"etclface::nodename", Etclface_nodename},@/
	{"etclface::pid_show", Etclface_pid_show},@/
	{"etclface::receive", Etclface_receive},@/
	{"etclface::reg_send", Etclface_reg_send},@/
	{"etclface::self", Etclface_self},@/
	{"etclface::tracelevel", Etclface_tracelevel},@/
	{"etclface::xb_free", Etclface_xb_free},@/
	{"etclface::xb_new", Etclface_xb_new},@/
	{"etclface::xb_show", Etclface_xb_show},@/
	{"etclface::xconnect", Etclface_xconnect},@/
	{"etclface::xinit", Etclface_xinit},@/

	{NULL, NULL}	/* marks the end of the list*/
};


@*1Initialization Commands.

\erliface provides two functions for initializing
the local \.{cnode} data structures, \.{ei\_connect\_init()} and
\.{ei\_connect\_xinit()}. Although it is possible to use a single command
with two distinct calling sequences, at least for now, we will stay with
two separate commands.

If successful, both commands will return a stringified handle to the
\.{ec} structure in the form of a hexadecimal number prefixed with
\.{ec0x}, e.g. \.{ec0x88074f0}. The storage for the structure is allocated
dynamically, so it will need to be de-allocated when not needed.

If the \.{cookie} parameter is missing, it will be obtained from
\.{erlang.cookie} file in user's home directory.

@ \.{etclface::init nodename ?cookie?}.

Initialize and return a handle to an \.{ec} structure, with own name
\.{nodename} and \.{cookie}.

@<Initialization commands@>=
static int
Etclface_init(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*nodename, *cookie;
	ei_cnode	*ec;
	char		echandle[100];

	if ((objc!=2) && (objc!=3)) {
		Tcl_WrongNumArgs(ti, 1, objv, "nodename ?cookie?");
		return TCL_ERROR;
	}

	nodename = Tcl_GetString(objv[1]);
	cookie = (objc == 2) ? NULL : Tcl_GetString(objv[2]);

	ec = (ei_cnode *)Tcl_AttemptAlloc(sizeof(ei_cnode));
	if (ec == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for ei_cnode", 0);
		return TCL_ERROR;
	}

	if (ei_connect_init(ec, nodename, cookie, 0) == ERL_ERROR) {
		ErrorReturn(ti, "ERROR", "ei_connect_init failed", erl_errno);
		return TCL_ERROR;
	}

	sprintf(echandle, "ec%p", ec);
	Tcl_SetObjResult(ti, Tcl_NewStringObj(echandle, -1));
	return TCL_OK;
}

@ \.{etclface::xinit host alive node ipaddr ?cookie?}.

Initialize and return a handle to an \.{ec} structure, with own name
\.{nodename} and \.{cookie}.

@<Initialization commands@>=
static int
Etclface_xinit(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*alive, *cookie, *host, *node;
	Erl_IpAddr	ipaddr;
	ei_cnode	*ec;
	char		echandle[100];

	if ((objc!=5) && (objc!=6)) {
		Tcl_WrongNumArgs(ti, 1, objv, "host alive node ipaddr ?cookie?");
		return TCL_ERROR;
	}

	host  = Tcl_GetString(objv[1]);
	alive = Tcl_GetString(objv[2]);
	node  = Tcl_GetString(objv[3]);

	if (get_ipaddr(ti, objv[4], &ipaddr) == TCL_ERROR)
		return TCL_ERROR;

	cookie = (objc == 5) ? NULL : Tcl_GetString(objv[5]);

	ec = (ei_cnode *)Tcl_AttemptAlloc(sizeof(ei_cnode));
	if (ec == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for ei_cnode", 0);
		return TCL_ERROR;
	}

	int res = ei_connect_xinit(ec, host, alive, node, ipaddr, cookie, (short)0);
	Tcl_Free((char *)ipaddr);
	if (res == ERL_ERROR) {
		ErrorReturn(ti, "ERROR", "ei_connect_xinit failed", erl_errno);
		return TCL_ERROR;
	}

	sprintf(echandle, "ec%p", ec);
	Tcl_SetObjResult(ti, Tcl_NewStringObj(echandle, -1));
	return TCL_OK;
}

@*1Connection Commands.

\erliface provides four functions for establishing a connection
to another node. Two, \.{ei\_connect()} and \.{ei\_connect\_tmo()},
expect a single remote nodename in the form of \.{alivename@@hostname},
while the other two, \.{ei\_xconnect()} and \.{ei\_xconnect\_tmo()},
expect an IP address and an alivename. Within each pair, one function
accepts a \.{timeout} value in milliseconds, while the other will wait
indefinitely for a connection. Using $0$ for the timeout value is the
same as having no timeout.

Here we provide just two commands, \.{connect} and \.{xconnect}. Both
can be called with an optional timeout value.

If successful, both commands will return the socket file descriptor
\.{fd}, which should be used for subsequent calls to various send/receive
commands.

@ \.{etclface::connect ec nodename ?timeout?}.

Establish a connection to node \.{nodename} using the \.{ec} handle
obtained from \.{etclface::init} or \.{xinit}.

@<Connection commands@>=
static int
Etclface_connect(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode *ec;
	char *nodename;
	unsigned timeout;

	if ((objc!=3) && (objc!=4)) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec nodename ?timeout?");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	nodename = Tcl_GetString(objv[2]);

	if (objc == 3) {
		timeout = 0;
	} @+else {
		if (get_timeout(ti, objv[3], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	int fd;
	if ((fd = ei_connect_tmo(ec, nodename, timeout)) == ERL_ERROR) {
		ErrorReturn(ti, "ERROR", "ei_connect_tmo failed", erl_errno);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewIntObj(fd));

	return TCL_OK;
}

@ \.{etclface::xconnect ec ipaddr alivename ?timeout?}.

Establish a connection to node \.{alivename@@ipaddr} using the \.{ec}
handle obtained from \.{etclface::init} or \.{xinit}.

@<Connection commands@>=
static int
Etclface_xconnect(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*alivename;
	ei_cnode	*ec;
	Erl_IpAddr	ipaddr;
	unsigned	timeout;
	int		fd;

	if ((objc!=4) && (objc!=5)) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec ipaddr alivename ?timeout?");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	if (get_ipaddr(ti, objv[2], &ipaddr) == TCL_ERROR)
		return TCL_ERROR;

	alivename = Tcl_GetString(objv[3]);

	if (objc == 4) {
		timeout = 0;
	} @+else {
		if (get_timeout(ti, objv[4], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	if ((fd = ei_xconnect_tmo(ec, ipaddr, alivename, timeout))  == ERL_ERROR) {
		ErrorReturn(ti, "ERROR", "ei_xconnect_tmo failed", erl_errno);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewIntObj(fd));

	return TCL_OK;
}

@ \.{etclface::disconnect fd}.

Closes the socket connection with \.{fd} file descriptor.

@<Connection commands@>=
static int
Etclface_disconnect(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	int fd;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "fd");
		return TCL_ERROR;
	}

	if (Tcl_GetIntFromObj(ti, objv[1], &fd) == TCL_ERROR)
		return TCL_ERROR;

	if (close(fd) < 0) {
		ErrorReturn(ti, "ERROR", "close failed", errno);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@*1Send Commands.

@ \.{reg\_send ec fd server xb}.

Send a message consisting of an Erlang term stored in \.{xb} to a
registered process \.{server}, using the \.{ec} handle otained from
\.{etclface::init} or \.{etclface::xinit}, and \.{fd} obtained from
\.{etclface::connect}.

@<Send commands@>=
static int
Etclface_reg_send(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	if ((objc < 5) || (objc>6)) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec fd server xb ?timeout?");
		return TCL_ERROR;
	}

	ei_cnode *ec;
	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	int fd;
	if (Tcl_GetIntFromObj(ti, objv[2], &fd) == TCL_ERROR)
		return TCL_ERROR;

	char *serverport;
	serverport = Tcl_GetString(objv[3]);

	ei_x_buff *xb;
	if (get_xb(ti, objv[4], &xb) == TCL_ERROR)
		return TCL_ERROR;

	unsigned int timeout;
	if (objc = 5) {
		timeout = 0U;
	} @+else {
		if (get_timeout(ti, objv[5], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	if (ei_reg_send_tmo(ec, fd, serverport, xb->buff, xb->index, timeout) == ERL_ERROR) {
		ErrorReturn(ti, "ERROR", "ei_reg_send_tmo failed", erl_errno);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@*1Receive Commands.

\erliface provides many receive functions, however, here we only provide
a single command to receive a message.

The command expects the file descriptor (\.{fd}) of an existing connection
on the command line, and an optional timeout value, which will default
to an indefinite wait.

Once a message is received successfully, the command will return the
type of message received, along with the message, if relevant.

@ \.{etclface::receive fd ?timeout?}.


@<Receive commands@>=
static int
Etclface_receive(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	int		fd, timeout;
	erlang_msg	msg;
	ei_x_buff	*xb;

	if ((objc!=2) && (objc!=3)) {
		Tcl_WrongNumArgs(ti, 1, objv, "fd ?timeout?");
		return TCL_ERROR;
	}

	if (Tcl_GetIntFromObj(ti, objv[1], &fd) == TCL_ERROR)
		return TCL_ERROR;

	if (objc == 2) {
		timeout = 0;
	} @+else {
		if (get_timeout(ti, objv[2], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	xb = (ei_x_buff *)Tcl_AttemptAlloc(sizeof(ei_x_buff));
	if (xb == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for ei_x_buff", 0);
		return TCL_ERROR;
	}
	if (ei_x_new(xb) == ERL_ERROR) {
		ErrorReturn(ti, "ERROR", "ei_x_new failed to initialize ei_x_buff", 0);
		Tcl_Free((char *)xb);
		return TCL_ERROR;
	}

	@<Receive message@>;
	@<Unpack received message@>;

	return TCL_OK;
}

@ Wait for message. We ignore ticks.

@<Receive message@>=
	int res;
	while ((res = ei_xreceive_msg_tmo(fd, &msg, xb, timeout)) == ERL_TICK)@/
		;

	if (res == ERL_TIMEOUT) {
		ErrorReturn(ti, "TIMEOUT", "ei_xreceive_msg_tmo timed out", 0);
		return TCL_ERROR;
	}

	if (res != ERL_MSG) {
		ErrorReturn(ti, "ERROR", "ei_xreceive_msg_tmo failed", erl_errno);
		return TCL_ERROR;
	}

@ Check the received message. Unpack the message meta data and add to
the Tcl result as a dictionary.

@<Unpack received message@>=
	Tcl_Obj *msgdict = Tcl_NewDictObj();
	Tcl_DictObjPut(ti, msgdict, Tcl_NewStringObj("msgtype", -1), Tcl_NewLongObj(msg.msgtype));

	switch (msg.msgtype) {
	case ERL_SEND:
		Tcl_DictObjPut(ti, msgdict, Tcl_NewStringObj("to", -1), pid2dict(ti, &msg.to));
		break;
	case ERL_REG_SEND:
		Tcl_DictObjPut(ti, msgdict, Tcl_NewStringObj("from", -1), pid2dict(ti, &msg.from));
		break;
	case ERL_LINK:
	case ERL_UNLINK:
	case ERL_EXIT:
		Tcl_DictObjPut(ti, msgdict, Tcl_NewStringObj("to", -1), pid2dict(ti, &msg.to));
		Tcl_DictObjPut(ti, msgdict, Tcl_NewStringObj("from", -1), pid2dict(ti, &msg.from));
		break;
	}
	Tcl_SetObjResult(ti, msgdict);

@*1Buffer Commands.

Erlang has several data types, while Tcl treats everything as character
strings, although, for efficiency, Tcl can internally maintain numeric
data as numbers. The encode commands will convert from Tcl data types
to Erlang types ready for transmission to other Erlang nodes.

\erliface provides two groups of encode functions, and within
each group there is one function for each Erlang data type. For now,
at least, a limited useful subset of these functions will be exposed as
Tcl commands. Of the two groups, only those with the \.{ei\_x\_} prefix
are implemented, and of these we shall start with a limited main group.

The \.{ei\_x\_encode\_*} functions encode the data into the
\.{ei\_x\_buff} data structure.

@ \.{etclface::xb\_new ?-withversion?}.

Creates a new \.{ei\_x\_buff} structure and initializes the buffer
using \.{ei\_x\_new()}, or optionally with an initial version byte using
\.{ei\_x\_new\_with\_version()}.

@<Buffer commands@>=
static int
Etclface_xb_new(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;

	if ((objc!=1) && (objc!=2)) {
		Tcl_WrongNumArgs(ti, 1, objv, "?-withversion?");
		return TCL_ERROR;
	}
	if ((objc==2) && strcmp(Tcl_GetString(objv[1]), "-withversion")) {
		ErrorReturn(ti, "ERROR", "Only -withversion allowed as argument", 0);
		return TCL_ERROR;
	}

	xb = (ei_x_buff *)Tcl_AttemptAlloc(sizeof(ei_x_buff));
	if (xb == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for ei_x_buff", 0);
		return TCL_ERROR;
	}

	int res = (objc == 1) ? ei_x_new(xb) : ei_x_new_with_version(xb);
	if (res < 0) {
		Tcl_Free((char *)xb);
		ErrorReturn(ti, "ERROR", "ei_x_new/ei_x_new_with_version failed", erl_errno);
		return TCL_ERROR;
	}

	char xbhandle[100];
	sprintf(xbhandle, "xb%p", xb);
	Tcl_SetObjResult(ti, Tcl_NewStringObj(xbhandle, -1));

	return TCL_OK;
}

@ \.{etclface::xb\_free xb}.

Free up memory taken up by \.{xb} as well as the internal buffer allocated
to \.{xb}.

@<Buffer commands@>=
static int
Etclface_xb_free(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_x_free(xb) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_free failed", erl_errno);
		return TCL_ERROR;
	}

	Tcl_Free((char *)xb);

	return TCL_OK;
}

@ \.{etclface::xb\_show xb}.

Show the contents of the \.{xb} structure. This is mainly for debugging,
or for those who are curious about the workings of the encode/decode
commands.

The output will be in the form of \.{buff p buffsz d index d}, where \.{p}
is a pointer and the \.{d}s are integers. This lends itself to being parsed as an array, e.g.
\.{array set [etclface::xb\_show \$xb]}

@<Buffer commands@>=
static int
Etclface_xb_show(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char result[100];

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	ei_x_buff *xb;
	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	sprintf(result, "buff %p buffsz %d index %d", xb->buff, xb->buffsz, xb->index);
	Tcl_SetObjResult(ti, Tcl_NewStringObj(result, -1));

	return TCL_OK;
}

@*1Encode Commands.

\erliface provides many encode functions, we shall start with
the most commonly used Erlang data types, then add more encode commands
over time.

@ \.{etclface::encode\_atom xb atom}.

Takes an existing \.{ei\_x\_buff} and adds the string \.{atom} as an
atom in binary format.

@<Encode commands@>=
static int
Etclface_encode_atom(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*atom;
	ei_x_buff	*xb;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb atom");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	atom = Tcl_GetString(objv[2]);

	if (ei_x_encode_atom(xb, atom) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_atom failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_boolean xb boolean}.

Takes an existing \.{ei\_x\_buff} and adds the boolean value to it.

Note that in Tcl \.{1}, \.{true}, \.{on} and \.{yes} are classed as True,
while \.{0}, \.{false}, \.{off} and \.{no} are classed as False.

@<Encode commands@>=
static int
Etclface_encode_boolean(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	int boolean;
	ei_x_buff *xb;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb boolean");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetBooleanFromObj(ti, objv[2], &boolean) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_x_encode_boolean(xb, boolean) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_boolean failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_char xb char}.

Takes an existing \.{ei\_x\_buff} and adds the char value to it.

@<Encode commands@>=
static int
Etclface_encode_char(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	const char *chstr;
	ei_x_buff *xb;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb char");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	chstr = Tcl_GetString(objv[2]);
	if (strlen(chstr) != 1) {
		ErrorReturn(ti, "ERROR", "char must be a single character", 0);
		return TCL_ERROR;
	}

	if (ei_x_encode_char(xb, chstr[0]) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_char failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_double xb double}.

Takes an existing \.{ei\_x\_buff} and adds the double value to it.

@<Encode commands@>=
static int
Etclface_encode_double(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	double dbl;
	ei_x_buff *xb;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb double");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetDoubleFromObj(ti, objv[2], &dbl) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_x_encode_double(xb, dbl) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_double failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_long xb long}.

Takes an existing \.{ei\_x\_buff} and adds the long value to it.

@<Encode commands@>=
static int
Etclface_encode_long(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	long lng;
	ei_x_buff *xb;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb long");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetLongFromObj(ti, objv[2], &lng) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_x_encode_long(xb, lng) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_long failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_string xb string}.

Takes an existing \.{ei\_x\_buff} and adds the string to it.

@<Encode commands@>=
static int
Etclface_encode_string(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	const char *str;
	ei_x_buff *xb;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb string");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	str = Tcl_GetString(objv[2]);

	if (ei_x_encode_string(xb, str) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_string failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_list\_header xb arity}.

Initialize encoding of a list using \.{ei\_x\_encode\_list\_header()}.

@<Encode commands@>=
static int
Etclface_encode_list_header(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;
	int arity;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb arity");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(ti, objv[2], &arity) == TCL_ERROR)
		return TCL_ERROR;
	if (arity < 0) {
		ErrorReturn(ti, "ERROR", "arity cannot be negative", 0);
		return TCL_ERROR;
	}

	if (ei_x_encode_list_header(xb, arity) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_list_header failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_empty\_list xb}.

Terminate the encoding of a list using \.{ei\_x\_encode\_empty\_list}.

@<Encode commands@>=
static int
Etclface_encode_empty_list(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_x_encode_empty_list(xb) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_empty_list failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_tuple\_header xb arity}.

Initialize encoding of a tuple using \.{ei\_x\_encode\_tuple\_header()}.

@<Encode commands@>=
static int
Etclface_encode_tuple_header(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;
	int arity;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb arity");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(ti, objv[2], &arity) == TCL_ERROR)
		return TCL_ERROR;
	if (arity < 0) {
		ErrorReturn(ti, "ERROR", "arity cannot be negative", 0);
		return TCL_ERROR;
	}

	if (ei_x_encode_tuple_header(xb, arity) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_tuple_header failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::encode\_pid xb pid}.

Encode an \.{Erlang\_Pid} in the \.{ei\_x\_buff} structure.

@<Encode commands@>=
static int
Etclface_encode_pid(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff  *xb;
	erlang_pid *pid;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb pid");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (get_pid(ti, objv[2], &pid) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_x_encode_pid(xb, pid) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_pid failed", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}


@*1Decode Commands.

The decode commands implement the various \.{ei\_decode\_*} functions
provided by \erliface.

@ \.{etclface::decode\_atom xb}.

@<Decode commands@>=
static int
Etclface_decode_atom(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	int		index=0;
	char		atom[MAXATOMLEN+1];

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_atom(xb->buff, &index, atom) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_atom failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewStringObj(atom, -1));
	return TCL_OK;
}

@ \.{etclface::decode\_long xb}.

@<Decode commands@>=
static int
Etclface_decode_long(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	int		index=0;
	long		longnum;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_long(xb->buff, &index, &longnum) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_long failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewLongObj(longnum));
	return TCL_OK;
}

@*1Utility Commands.
These are various commands for accessing the \.{ei\_cnode} data structures.

@ \.{etclface::pid\_show pid}.

Given a \.{pid} handle, return its contents as a dictionary.

@<Utility commands@>=
static int
Etclface_pid_show(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	erlang_pid *pid;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "pid");
		return TCL_ERROR;
	}

	if (get_pid(ti, objv[1], &pid) == TCL_ERROR)
		return TCL_ERROR;

	Tcl_SetObjResult(ti, pid2dict(ti, pid));

	return TCL_OK;
}



@ \.{etclface::self ec}.

Return the pid handle for the given \.{ei\_cnode}. The handle will
be of the form \.{pid0x123456}, which can be used in subsequent
\.{etclface::encode\_pid} commands, and any that accept a pid.

@<Utility commands@>=
static int
Etclface_self(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	ei_cnode *ec;
	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	erlang_pid *self;
	self = ei_self(ec);

	char pidhandle[100];
	sprintf(pidhandle, "pid%p", self);

	Tcl_SetObjResult(ti, Tcl_NewStringObj(pidhandle, -1));
	return TCL_OK;
}

@ \.{etclface::nodename ec}.

Return the node name of the cnode.

@<Utility commands@>=
static int
Etclface_nodename(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	ei_cnode *ec;
	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	char *nodename;
	nodename = (char *)ei_thisnodename(ec);

	Tcl_SetObjResult(ti, Tcl_NewStringObj(nodename, -1));
	return TCL_OK;
}

@ \.{etclface::tracelevel ?level?}.

Get or Set the trace level using the \.{ei\_get\_tracelevel()} and
\.{ei\_set\_tracelevel()} functions. On its own, the command will return
the current trace level. If the an integer is supplied, the level will
be set to that value.

The trace levels are explained in the \.{ei\_connect} manual page.

@<Utility commands@>=
static int
Etclface_tracelevel(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	int level;

	if ((objc<1) || (objc>2)) {
		Tcl_WrongNumArgs(ti, 1, objv, "?level?");
		return TCL_ERROR;
	}

	if (objc == 1) {
		Tcl_SetObjResult(ti, Tcl_NewIntObj(level));
		return TCL_OK;
	}

	if (Tcl_GetIntFromObj(ti, objv[1], &level) == TCL_ERROR)
		return TCL_ERROR;

	ei_set_tracelevel(level);

	return TCL_OK;
}

@ \.{etclface::ec\_free ec}.

Free the memory taken up by an \.{ei\_cnode} handle that has been created
with \.{etclface::init} or \.{xinit}.

Currently there is no check for the validity of the pointer! In the
near future the creation and deletion of such handles will be tracked
internally. We rely on the programmer to, for example, not free the same
handle twice!

@<Utility commands@>=
static int
Etclface_ec_free(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode *ec;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	Tcl_Free((char *)ec);

	return TCL_OK;
}

@ \.{etclface::ec\_show ec}.

Return the contents of an \.{ei\_cnode} as a dictionary.

@<Utility commands@>=
static int
Etclface_ec_show(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode *ec;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	Tcl_SetObjResult(ti, ec2dict(ti, ec));

	return TCL_OK;
}

@*1Internal Helper Functions.

These are a set of functions for internal consumption, they help avoid
duplication.

@ \.{ErrorReturn}. Set the Tcl result for errors. We set the \.{errorCode}
Tcl variable to the triple \.{ETCLFACE} and the supplied error code and
message. We also set the command result to a string made up of the blank
separated element of the above triple. Also, if \.{errorno} is non-zero,
we added it to the \.{errorInfo} Tcl variable.

@<Internal helper functions@>=
static void
ErrorReturn(Tcl_Interp *ti, const char *errorcode, const char *errormsg, const int errorno)
{
	Tcl_SetErrorCode(ti, "ETCLFACE", errorcode, errormsg, NULL);
	Tcl_AppendResult(ti, "ETCLFACE ", errorcode, " ", errormsg, NULL);
	if (errorno != 0) {
		Tcl_AppendObjToErrorInfo(ti, Tcl_NewIntObj(errorno));
		Tcl_AppendObjToErrorInfo(ti, Tcl_NewStringObj(Tcl_ErrnoMsg(errorno), -1));
	}
	return;
}

@ Extract and convert a timeout value. Given a Tcl object pointer,
attempt to convert to unsigned int, if successful, the timeout value
isn returned in the \.{timeout} parameter.

@<Internal helper functions@>=
static int
get_timeout(Tcl_Interp *ti, Tcl_Obj *tclobj, unsigned *timeout) {
	int tmo;
	if (Tcl_GetIntFromObj(ti, tclobj, &tmo) == TCL_ERROR)
		return TCL_ERROR;
	if (tmo < 0) {
		ErrorReturn(ti, "ERROR", "timeout cannot be negative", 0);
		return TCL_ERROR;
	}
	*timeout = tmo;
	return TCL_OK;
}

@ Extract and convert an \.{xb} handle.

@<Internal helper functions@>=
static int
get_xb(Tcl_Interp *ti, Tcl_Obj *tclobj, ei_x_buff **xb)
{
	const char *xbhandle = Tcl_GetString(tclobj);
	if (sscanf(xbhandle, "xb%p", xb) != 1) {
		ErrorReturn(ti, "ERROR", "Invalid xb handle", 0);
		return TCL_ERROR;
	}
	return TCL_OK;
}

@ Extract and convert an \.{ec} handle.

@<Internal helper functions@>=
static int
get_ec(Tcl_Interp *ti, Tcl_Obj *tclobj, ei_cnode **ec)
{
	const char *echandle = Tcl_GetString(tclobj);
	if (sscanf(echandle, "ec%p", ec) != 1) {
		ErrorReturn(ti, "ERROR", "Invalid ec handle", 0);
		return TCL_ERROR;
	}
	return TCL_OK;
}

@ Extract and convert an IP address. Given a Tcl Object pointer, attempt
to convert it to an \.{Erl\_IpAddr} type IP address. We allocate memory
for the structure here, which should be freed by the caller when not
needed.

@<Internal helper functions@>=
static int
get_ipaddr(Tcl_Interp *ti, Tcl_Obj *tclobj, Erl_IpAddr *ipaddr) {
	struct in_addr	*inaddr;
	inaddr = (struct in_addr *)Tcl_AttemptAlloc(sizeof(ei_cnode));
	if (inaddr == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for ipaddr", 0);
		return TCL_ERROR;
	}
	if (!inet_aton(Tcl_GetString(tclobj), inaddr)) {
		Tcl_Free((char *)inaddr);
		ErrorReturn(ti, "ERROR", "Invalid ipaddr", 0);
		return TCL_ERROR;
	}
	*ipaddr = (Erl_IpAddr)inaddr;
	return TCL_OK;
}

@ \.{get\_pid}. Extract a pid handle from an object.

@<Internal helper functions@>=
static int
get_pid(Tcl_Interp *ti, Tcl_Obj *tclobj, erlang_pid **pid)
{
	const char* pidhandle;
	pidhandle = Tcl_GetString(tclobj);
	if (sscanf(pidhandle, "pid%p", pid) != 1) {
		ErrorReturn(ti, "ERROR", "Invalid pid handle", 0);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{pid2dict}. Given a valid pid pointer, convert its contents to a dictionary.

@<Internal helper functions@>=
static Tcl_Obj*
pid2dict(Tcl_Interp *ti, erlang_pid *pid) {
	Tcl_Obj *piddict = Tcl_NewDictObj();

	Tcl_DictObjPut(ti, piddict, Tcl_NewStringObj("node", -1), Tcl_NewStringObj(pid->node, -1));
	Tcl_DictObjPut(ti, piddict, Tcl_NewStringObj("num", -1), Tcl_NewIntObj(pid->num));
	Tcl_DictObjPut(ti, piddict, Tcl_NewStringObj("serial", -1), Tcl_NewIntObj(pid->serial));
	Tcl_DictObjPut(ti, piddict, Tcl_NewStringObj("creation", -1), Tcl_NewIntObj(pid->creation));

	return piddict;
}

@ \.{ec2dict}. Given a valid ec pointer, convert its contents to a dictionary.

@<Internal helper functions@>=
static Tcl_Obj*
ec2dict(Tcl_Interp *ti, ei_cnode *ec) {
	Tcl_Obj *ecdict = Tcl_NewDictObj();

	Tcl_DictObjPut(ti, ecdict, Tcl_NewStringObj("hostname", -1), Tcl_NewStringObj(ec->thishostname, -1));
	Tcl_DictObjPut(ti, ecdict, Tcl_NewStringObj("nodename", -1), Tcl_NewStringObj(ec->thisnodename, -1));
	Tcl_DictObjPut(ti, ecdict, Tcl_NewStringObj("alivename", -1), Tcl_NewStringObj(ec->thisalivename, -1));
	Tcl_DictObjPut(ti, ecdict, Tcl_NewStringObj("cookie", -1), Tcl_NewStringObj(ec->ei_connect_cookie, -1));
	Tcl_DictObjPut(ti, ecdict, Tcl_NewStringObj("creation", -1), Tcl_NewIntObj(ec->creation));
	Tcl_DictObjPut(ti, ecdict, Tcl_NewStringObj("self", -1), pid2dict(ti, &ec->self));

	return ecdict;
}

