
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

#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <unistd.h>
#include <tcl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ei.h>

@<Command declarations@>;
@<Internal helper functions@>;
@<Initialisation commands@>;
@<Connection commands@>;
@<Send commands@>;
@<Receive commands@>;
@<Buffer commands@>;
@<Encode commands@>;
@<Decode commands@>;
@<Data handling commands@>;
@<Utility commands@>;
@<AppInit@>;

@ We follow the standard format for all Tcl extensions. \.{Etclface\_Init}
initialises the library and declares the commands. We require \.{Tcl}
version 8.5 or higher, This version has been around for some time now,
so we can expect it to be available at most sites.

@<AppInit@>=
#define TCLVERSION "8.5"
int
Etclface_Init(Tcl_Interp *ti)
{
#ifdef USE_TCL_STUBS
	if (Tcl_InitStubs(ti, TCLVERSION, 0) == NULL) {
		return TCL_ERROR;
	}
#endif

	if (Tcl_PkgRequire(ti, "Tcl", TCLVERSION, 0) == NULL) {
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

@ We need to forward declare the functions first.

@<Command declarations@>=
static Tcl_ObjCmdProc	Etclface_init, Etclface_xinit;
@#
static Tcl_ObjCmdProc	Etclface_accept, Etclface_connect, Etclface_disconnect,
			Etclface_listen, Etclface_make_chan, Etclface_publish,
			Etclface_socket, Etclface_xconnect;
@#
static Tcl_ObjCmdProc	Etclface_receive, Etclface_reg_send, Etclface_send;
@#
static Tcl_ObjCmdProc	Etclface_decode_atom, Etclface_decode_boolean, Etclface_decode_char,
			Etclface_decode_double, Etclface_decode_list, Etclface_decode_long,
			Etclface_decode_pid, Etclface_decode_ref, Etclface_decode_string,
			Etclface_decode_term, Etclface_decode_tuple, Etclface_decode_version;
@#
static Tcl_ObjCmdProc	Etclface_encode_atom, Etclface_encode_boolean, Etclface_encode_char,
			Etclface_encode_double, Etclface_encode_empty_list,
			Etclface_encode_list_header, Etclface_encode_long, Etclface_encode_pid,
			Etclface_encode_ref, Etclface_encode_string, Etclface_encode_tuple_header;
@#
static Tcl_ObjCmdProc	Etclface_ref_free, Etclface_ref_new, Etclface_ref_print, Etclface_ref_show;
@#
static Tcl_ObjCmdProc	Etclface_xb_free, Etclface_xb_new, Etclface_xb_print, Etclface_xb_reset,
			Etclface_xb_show, Etclface_xb_skip;
@#
static Tcl_ObjCmdProc	Etclface_ec_free, Etclface_ec_show;
@#
static Tcl_ObjCmdProc	Etclface_nodename, Etclface_pid_show, Etclface_self, Etclface_tracelevel;

@ These are the command names and their associated functions, in
alphabetical order. The last element must be a \.{\{NULL, NULL\}}.

@<Command declarations@>=
static EtclfaceCommand_t EtclfaceCommand[] = {@/
	{"etclface::accept", Etclface_accept},@/
	{"etclface::connect", Etclface_connect},@/
	{"etclface::decode_atom", Etclface_decode_atom},@/
	{"etclface::decode_boolean", Etclface_decode_boolean},@/
	{"etclface::decode_char", Etclface_decode_char},@/
	{"etclface::decode_double", Etclface_decode_double},@/
	{"etclface::decode_list", Etclface_decode_list},@/
	{"etclface::decode_long", Etclface_decode_long},@/
	{"etclface::decode_pid", Etclface_decode_pid},@/
	{"etclface::decode_ref", Etclface_decode_ref},@/
	{"etclface::decode_string", Etclface_decode_string},@/
	{"etclface::decode_term", Etclface_decode_term},@/
	{"etclface::decode_tuple", Etclface_decode_tuple},@/
	{"etclface::decode_version", Etclface_decode_version},@/
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
	{"etclface::encode_ref", Etclface_encode_ref},@/
	{"etclface::encode_string", Etclface_encode_string},@/
	{"etclface::encode_tuple_header", Etclface_encode_tuple_header},@/
	{"etclface::init", Etclface_init},@/
	{"etclface::listen", Etclface_listen},@/
	{"etclface::make_chan", Etclface_make_chan},@/
	{"etclface::nodename", Etclface_nodename},@/
	{"etclface::pid_show", Etclface_pid_show},@/
	{"etclface::publish", Etclface_publish},@/
	{"etclface::receive", Etclface_receive},@/
	{"etclface::ref_free", Etclface_ref_free},@/
	{"etclface::ref_new", Etclface_ref_new},@/
	{"etclface::ref_print", Etclface_ref_print},@/
	{"etclface::ref_show", Etclface_ref_show},@/
	{"etclface::reg_send", Etclface_reg_send},@/
	{"etclface::self", Etclface_self},@/
	{"etclface::send", Etclface_send},@/
	{"etclface::socket", Etclface_socket},@/
	{"etclface::tracelevel", Etclface_tracelevel},@/
	{"etclface::xb_free", Etclface_xb_free},@/
	{"etclface::xb_new", Etclface_xb_new},@/
	{"etclface::xb_print", Etclface_xb_print},@/
	{"etclface::xb_reset", Etclface_xb_reset},@/
	{"etclface::xb_show", Etclface_xb_show},@/
	{"etclface::xb_skip", Etclface_xb_skip},@/
	{"etclface::xconnect", Etclface_xconnect},@/
	{"etclface::xinit", Etclface_xinit},@/

@#
	{NULL, NULL}	/* marks the end of the list*/
};

@*1Initialisation Commands.

\erliface provides two functions for initialising
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

The \.{ei\_connect\_init()} and \.{ei\_connect\_xinit()} functions in
\erliface expect a \.{creation} value to be passed from the caller. For
now, we are setting this to zero on all calls, however, in future we
may maintain an internal autoincremented counter for this. The reason
behind the decision is to keep the extension simple and stateless.

@ \.{etclface::init nodename ?cookie?}.

Initialize and return a handle to an \.{ec} structure, with own name
\.{nodename} and \.{cookie}.

@<Initialisation commands@>=
static int
Etclface_init(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*nodename, *cookie;
	ei_cnode	*ec;

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

	if (ei_connect_init(ec, nodename, cookie, 0) < 0) {
		ErrorReturn(ti, "ERROR", "ei_connect_init failed", erl_errno);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_ObjPrintf("ec0x%lx", (long unsigned int)ec));

	return TCL_OK;
}

@ \.{etclface::xinit host alive node ipaddr ?cookie?}.

Initialize and return a handle to an \.{ec} structure, with own name
\.{nodename} and \.{cookie}.

@<Initialisation commands@>=
static int
Etclface_xinit(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*alive, *cookie, *host, *node;
	Erl_IpAddr	ipaddr;
	ei_cnode	*ec;

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
	if (res < 0) {
		ErrorReturn(ti, "ERROR", "ei_connect_xinit failed", erl_errno);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_ObjPrintf("ec0x%lx", (long unsigned int)ec));

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
	if ((fd = ei_connect_tmo(ec, nodename, timeout)) < 0) {
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

	if ((fd = ei_xconnect_tmo(ec, ipaddr, alivename, timeout)) < 0) {
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

@ \.{etclface::socket addr port}.

Create socket to listen on for connections from other nodes. The command
will also bind to the socket ready to be listened on. If successful,
the file descriptor for the socket will be returned.

The command will not do any name translations for \.{addr} or \.{port}. It
is left to the caller to do any translation needed, although, a named
version of the command can be provided as part of the higher level \etf
Tcl library.

@<Connection commands@>=
static int
Etclface_socket(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char			*host;
	int			fd, port;
	struct sockaddr_in	sinaddr;

	if (objc != 3) {
		Tcl_WrongNumArgs(ti, 1, objv, "host port");
		return TCL_ERROR;
	}

	host = Tcl_GetString(objv[1]);
	if (Tcl_GetIntFromObj(ti, objv[2], &port) == TCL_ERROR) {
		return TCL_ERROR;
	}
	if ((port<0) || port > USHRT_MAX) {
		ErrorReturn(ti, "ERROR", "Port number value is too high", 0);
		return TCL_ERROR;
	}

	memset(&sinaddr, 0, sizeof(struct sockaddr_in));
	sinaddr.sin_family = AF_INET;
	if (strcmp(host, "-")) {
		if (inet_aton(host, &sinaddr.sin_addr) == 0) {
			ErrorReturn(ti, "ERROR", "Invalid address", 0);
			return TCL_ERROR;
		}
	} @+else {
		sinaddr.sin_addr.s_addr = INADDR_ANY;
	}
	sinaddr.sin_port = htons(port);

	fd = socket(AF_INET, SOCK_STREAM, 0);
	if (fd < 0) {
		ErrorReturn(ti, "ERROR", "failed to get socket", errno);
		return TCL_ERROR;
	}

	if (bind(fd, (struct sockaddr *)&sinaddr, sizeof(struct sockaddr)) < 0) {
		close(fd);
		ErrorReturn(ti, "ERROR", "failed to bind to socket", errno);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewIntObj(fd));

	return TCL_OK;
}

@ \.{etclface::make\_chan fd flag}.

Given an already open file descriptor, \.{fd}, create a corresponding
Tcl channel. If successful, the channel name is returned. The channel
name can be used to create Tcl event handlers, such as when a new message
has arrived on the open \.{fd}, however, in order to receive the message
the caller should use the corresponding \.{fd} with \.{etclface::receive}.
It is up to the caller to keep track of the channel/\.{fd} mappings.

The \.{flag} should be one of \.{R}, \.{W} or \.{RW}, indicating whether
the \.{fd} is readable, writable or both, respectively.

@<Connection commands@>=
static int
Etclface_make_chan(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	long int	fd;
	int		flag;
	Tcl_Channel	chan;
	char		*flagstr;

	if (objc != 3) {
		Tcl_WrongNumArgs(ti, 1, objv, "fd flag");
		return TCL_ERROR;
	}

	if (Tcl_GetLongFromObj(ti, objv[1], &fd) == TCL_ERROR)
		return TCL_ERROR;

	if (fcntl(fd, F_GETFD) < 0) {
		ErrorReturn(ti, "ERROR", "file descriptor is not open", errno);
		return TCL_ERROR;
	}

	flagstr = Tcl_GetString(objv[2]);
	if (!strcmp(flagstr, "R")) {
		flag = TCL_READABLE;
	} @+else if (!strcmp(flagstr, "W")) {
		flag = TCL_WRITABLE;
	} @+else if (!strcmp(flagstr, "RW")) {
		flag = TCL_READABLE | TCL_WRITABLE;
	} @+else {
		ErrorReturn(ti, "ERROR", "Invalid flag, should be R, W or RW", 0);
		return TCL_ERROR;
	}

	chan = Tcl_MakeFileChannel((ClientData)fd, flag);
	if (chan == NULL) {
		ErrorReturn(ti, "ERROR", "Tcl_MakeFileChannel failed", 0);
		return TCL_ERROR;
	}

	Tcl_RegisterChannel(ti, chan);

	Tcl_SetObjResult(ti, Tcl_NewStringObj(Tcl_GetChannelName(chan), -1));

	return TCL_OK;
}

@ \.{etclface::listen fd backlog}.

Listen on a socket that has been set up with \.{etclface::socket}.

@<Connection commands@>=
static int
Etclface_listen(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	int fd, backlog;

	if (objc != 3) {
		Tcl_WrongNumArgs(ti, 1, objv, "fd backlog");
		return TCL_ERROR;
	}

	if (Tcl_GetIntFromObj(ti, objv[1], &fd) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(ti, objv[2], &backlog) == TCL_ERROR)
		return TCL_ERROR;

	if (listen(fd, backlog) < 0) {
		ErrorReturn(ti, "ERROR", "failed to listen on socket", errno);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::publish ec port ?timeout?}.

Register a port with epmd by calling \.{ei\_publish()}.

@<Connection commands@>=
static int
Etclface_publish(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode	*ec;
	int		port, timeout, fd;

	if ((objc<3) || (objc>4)) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec port ?timeout?");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(ti, objv[2], &port) == TCL_ERROR)
		return TCL_ERROR;

	if (objc == 3) {
		timeout = 0;
	} @+else {
		if (get_timeout(ti, objv[3], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	if ((fd=ei_publish_tmo(ec, port, timeout)) < 0) {
		ErrorReturn(ti, "ERROR", "ei_publish failed", erl_errno);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewIntObj(fd));

	return TCL_OK;
}

@ \.{etclface::accept ec fd ?timeout?}.

Wait for and accept a connection from another erlang node. if successful,
i.e. no error or timeout, then the contents of the \.{ErlConnect}
structure is returned in the form of a dictionary.

@<Connection commands@>=
static int
Etclface_accept(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode	*ec;
	int		fd, timeout, newfd;
	ErlConnect	econn;
	struct in_addr	addr;

	if ((objc<3) || (objc>4)) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec fd ?timeout?");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(ti, objv[2], &fd) == TCL_ERROR)
		return TCL_ERROR;

	if (objc == 3) {
		timeout = 0;
	} @+else {
		if (get_timeout(ti, objv[3], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	if ((newfd = ei_accept_tmo(ec, fd, &econn, timeout)) < 0) {
		ErrorReturn(ti, "ERROR", "ei_accept failed", erl_errno);
		return TCL_ERROR;
	}

	Tcl_Obj *dict = Tcl_NewDictObj();
	Tcl_DictObjPut(ti, dict, Tcl_NewStringObj("fd", -1), Tcl_NewIntObj(newfd));
	Tcl_DictObjPut(ti, dict, Tcl_NewStringObj("nodename", -1), Tcl_NewStringObj(econn.nodename,-1));
	memcpy(&addr, econn.ipadr, sizeof(addr));
	Tcl_DictObjPut(ti, dict, Tcl_NewStringObj("nodeaddr", -1), Tcl_NewStringObj(inet_ntoa(addr), -1));

	Tcl_SetObjResult(ti, dict);

	return TCL_OK;
}

@*1Send Commands.

@ \.{etclface::reg\_send ec fd server xb ?timeout?}.

Send a message consisting of an Erlang term stored in \.{xb} to a
registered process \.{server}, using the \.{ec} handle obtained from
\.{etclface::init} or \.{etclface::xinit}, and \.{fd} obtained from
\.{etclface::connect}.

@<Send commands@>=
static int
Etclface_reg_send(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode *ec;
	int fd;
	char *serverport;
	unsigned int timeout;

	if ((objc < 5) || (objc>6)) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec fd server xb ?timeout?");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(ti, objv[2], &fd) == TCL_ERROR)
		return TCL_ERROR;

	serverport = Tcl_GetString(objv[3]);

	ei_x_buff *xb;
	if (get_xb(ti, objv[4], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (objc = 5) {
		timeout = 0U;
	} @+else {
		if (get_timeout(ti, objv[5], &timeout) < 0)
			return TCL_ERROR;
	}

	if (ei_reg_send_tmo(ec, fd, serverport, xb->buff, xb->index, timeout) < 0) {
		ErrorReturn(ti, "ERROR", "ei_reg_send_tmo failed", erl_errno);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@ \.{etclface::send fd pid xb ?timeout?}.

Send a message consisting of an Erlang term stored in \.{xb} to a process
identified by \.{pid}, and \.{fd} obtained from \.{etclface::connect},
or \.{etclface::xconnect}.

@<Send commands@>=
static int
Etclface_send(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	int fd;
	erlang_pid *pid;
	unsigned int timeout;
	ei_x_buff *xb;

	if ((objc < 4) || (objc>5)) {
		Tcl_WrongNumArgs(ti, 1, objv, "fd pid xb ?timeout?");
		return TCL_ERROR;
	}

	if (Tcl_GetIntFromObj(ti, objv[1], &fd) == TCL_ERROR)
		return TCL_ERROR;

	if (get_pid(ti, objv[2], &pid) == TCL_ERROR)
		return TCL_ERROR;

	if (get_xb(ti, objv[3], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (objc = 4) {
		timeout = 0U;
	} @+else {
		if (get_timeout(ti, objv[4], &timeout) < 0)
			return TCL_ERROR;
	}

	if (ei_send_tmo(fd, pid, xb->buff, xb->index, timeout) < 0) {
		ErrorReturn(ti, "ERROR", "ei_send_tmo failed", erl_errno);
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

@ \.{etclface::receive fd xb ?timeout?}.

Wait for a message. If received succeefully, put the message into an
xbuff identified by \.{xb}.

@<Receive commands@>=
static int
Etclface_receive(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	int		fd, timeout;
	erlang_msg	msg;
	ei_x_buff	*xb;

	if ((objc!=3) && (objc!=4)) {
		Tcl_WrongNumArgs(ti, 1, objv, "fd xb ?timeout?");
		return TCL_ERROR;
	}

	if (Tcl_GetIntFromObj(ti, objv[1], &fd) == TCL_ERROR)
		return TCL_ERROR;

	if (get_xb(ti, objv[2], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (objc == 3) {
		timeout = 0;
	} @+else {
		if (get_timeout(ti, objv[3], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	@<Receive message@>;
	@<Unpack received message@>;

	return TCL_OK;
}

@ Wait for a message. If we get a tick (keep alive message) from another
node, we return \.{TICK} to the caller. Timeouts and errors are returned
as error, although, in future a timeout may be treated as a normal return.

@<Receive message@>=
	int res;

	res = ei_xreceive_msg_tmo(fd, &msg, xb, timeout);

	if (res == ERL_TICK) {
		Tcl_SetObjResult(ti, Tcl_NewStringObj("TICK", -1));
		return TCL_OK;
	}

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

Creates a new \.{ei\_x\_buff} structure and initialises the buffer
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

	Tcl_SetObjResult(ti, Tcl_ObjPrintf("xb0x%lx", (long unsigned int)xb));

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
	ei_x_buff *xb;

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	Tcl_Obj *xbdict = Tcl_NewDictObj();
	Tcl_DictObjPut(ti, xbdict, Tcl_NewStringObj("buff", -1), Tcl_ObjPrintf("0x%0lx", (long unsigned int)xb->buff));
	Tcl_DictObjPut(ti, xbdict, Tcl_NewStringObj("buffsz", -1), Tcl_NewIntObj(xb->buffsz));
	Tcl_DictObjPut(ti, xbdict, Tcl_NewStringObj("index", -1), Tcl_NewIntObj(xb->index));

	Tcl_SetObjResult(ti, xbdict);

	return TCL_OK;
}

@ \.{etclface::xb\_print xb}.

Print the term in \.{xb} in human readable form. If successful, the
contents of the term will be returned in the form familiar to the Erlang
folk, but it is not readily parsable in Tcl.

We normally use \.{Tcl\_AttemptAlloc} to allocate dynamic memory, however,
in here we use malloc and free instead, since \.{ei\_s\_print\_term()}
may use \.{realloc} if needed.

@<Buffer commands@>=
static int
Etclface_xb_print(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;
	char *buff = NULL;

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if ((buff = malloc(BUFSIZ)) == NULL) {
		ErrorReturn(ti, "ERROR", "could not allocate memory for buffer", 0);
		return TCL_ERROR;
	}

	if (ei_s_print_term(&buff, xb->buff, &xb->index) < 0) {
		ErrorReturn(ti, "ERROR", "xb does not contain a valid term", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewStringObj(buff, -1));
	free(buff); // OK to free since buff has been copied

	return TCL_OK;
}

@ \.{etclface::xb\_reset xb}.

Reset the index to the start of the buffer.

@<Buffer commands@>=
static int
Etclface_xb_reset(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	xb->index = 0;

	return TCL_OK;
}

@ \.{etclface::xb\_skip xb}.

Move the index forward to point to the next term.

@<Buffer commands@>=
static int
Etclface_xb_skip(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_skip_term(xb->buff, &xb->index) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_skip failed", 0);
		return TCL_ERROR;
	}

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
	int		uchar;
	ei_x_buff	*xb;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb char");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(ti, objv[2], &uchar) == TCL_ERROR)
		return TCL_ERROR;

	if (uchar < 0 || uchar > 255) {
		ErrorReturn(ti, "ERROR", "char must be a number in the range 0..255", 0);
		return TCL_ERROR;
	}

	if (ei_x_encode_char(xb, uchar) < 0) {
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

@ \.{etclface::encode\_ref xb ref}.

Takes an existing \.{ei\_x\_buff} and adds the ref handle to it.

@<Encode commands@>=
static int
Etclface_encode_ref(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	erlang_ref	*ref;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb ref");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (get_ref(ti, objv[2], &ref) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_x_encode_ref(xb, ref) < 0) {
		ErrorReturn(ti, "ERROR", "ei_x_encode_ref failed", 0);
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

All the decode commands operate on an \.{ei\_x\_buff} and expect the
\.{index} to point to the next term to be decoded. The commands,
\.{xb\_reset} and \.{xb\_skip} can be used to position the index at the
desired term.

After a successful decode operation the index will be updated to point
to the next term.

@ \.{etclface::decode\_atom xb}.

Extract the next term from \.{xb} as an atom and, if successful, return
it as a string.

@<Decode commands@>=
static int
Etclface_decode_atom(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	char		atom[MAXATOMLEN+1];

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_atom(xb->buff, &xb->index, atom) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_atom failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewStringObj(atom, -1));
	return TCL_OK;
}

@ \.{etclface::decode\_boolean xb}.

Extract the next term from \.{xb} as a boolean, if successful, a \.{0}
or \.{1} will be returned.

@<Decode commands@>=
static int
Etclface_decode_boolean(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	int		boolean;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_boolean(xb->buff, &xb->index, &boolean) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_boolean failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewBooleanObj(boolean));
	return TCL_OK;
}

@ \.{etclface::decode\_char xb}.

Extract the next term from \.{xb} as a char, if successful, an integer
is returned.

@<Decode commands@>=
static int
Etclface_decode_char(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	unsigned char	uchar;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_char(xb->buff, &xb->index, &uchar) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_char failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewIntObj(uchar));
	return TCL_OK;
}

@ \.{etclface::decode\_double xb}.

Extract the next term from \.{xb} as a double, if successful, a double
is returned.

@<Decode commands@>=
static int
Etclface_decode_double(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	double		dbl;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_double(xb->buff, &xb->index, &dbl) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_double failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewDoubleObj(dbl));
	return TCL_OK;
}

@ \.{etclface::decode\_list xb}.

Attempts to decode the list in \.{xb}. If successful, the arity of the
list will be returned. It is then up to the caller to go through the
terms of the list and decode them individually.

@<Decode commands@>=
static int
Etclface_decode_list(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	int		arity;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_list_header(xb->buff, &xb->index, &arity) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_list_header failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewIntObj(arity));

	return TCL_OK;
}

@ \.{etclface::decode\_long xb}.

Extract the next term in \.{xb} as a long integer and, if successful,
return an integer.

@<Decode commands@>=
static int
Etclface_decode_long(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	long		longnum;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_long(xb->buff, &xb->index, &longnum) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_long failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewLongObj(longnum));
	return TCL_OK;
}

@ \.{etclface::decode\_pid xb}.

Extract the next term in \.{xb} as a pid and, if successful, return a
pid handle.

@<Decode commands@>=
static int
Etclface_decode_pid(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	erlang_pid	*pid;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	pid = (erlang_pid *)Tcl_AttemptAlloc(sizeof(erlang_pid));
	if (pid == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for pid", 0);
		TCL_ERROR;
	}

	if (ei_decode_pid(xb->buff, &xb->index, pid) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_pid failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_ObjPrintf("pid0x%lx", (long unsigned int)pid));

	return TCL_OK;
}

@ \.{etclface::decode\_ref xb}.

Extract the next term in \.{xb} as a ref and, if successful, return a ref handle.

@<Decode commands@>=
static int
Etclface_decode_ref(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	erlang_ref	*ref;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	ref = (erlang_ref *)Tcl_AttemptAlloc(sizeof(erlang_ref));
	if (ref == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for ref", 0);
		TCL_ERROR;
	}

	if (ei_decode_ref(xb->buff, &xb->index, ref) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_ref failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_ObjPrintf("ref0x%lx", (long unsigned int)ref));

	return TCL_OK;
}

@ \.{etclface::decode\_string xb}.

Assuming that the next term in \.{xb} is a string, extract it and return
as a string obj.

Unfortunately we are expected to know the length of the string before
hand, and supply {\it enough space} to receive a copy of the string.

The only way to do so safely is to first decode the string with a \.{NULL}
destination address, note the change in the index, then allocate space
to receive the string based on the change in the index.

@<Decode commands@>=
static int
Etclface_decode_string(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	char		*str;
	int		index;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	index = xb->index;
	if (ei_decode_string(xb->buff, &index, NULL) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_string failed", 0);
		return TCL_ERROR;
	}
	str = Tcl_AttemptAlloc(1+index-xb->index);
	if (str == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for string", 0);
		return TCL_ERROR;
	}

	if (ei_decode_string(xb->buff, &xb->index, str) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_string failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewStringObj(str, -1));
	return TCL_OK;
}

@ \.{etclface::decode\_term xb}.

Extract the term encoded in the xbuff \.{xb}. The contents of the
\.{term} structure returned by the function \.{ei\_decode\_ei\_term()}
is converted to a dict and assigned to the return result. The contents
of the dictionary will depend on the type of term.

@<Decode commands@>=
static int
Etclface_decode_term(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	ei_term		*term;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	term = (ei_term *)Tcl_AttemptAlloc(sizeof(ei_term));
	if (term == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for ei_term", 0);
		return TCL_ERROR;
	}

	int res = ei_decode_ei_term(xb->buff, &xb->index, term);
	if (res < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_term failed", 0);
		return TCL_ERROR;
	}

	Tcl_Obj *termdict = Tcl_NewDictObj();
	Tcl_DictObjPut(ti, termdict, Tcl_NewStringObj("type", -1), Tcl_NewStringObj(&term->ei_type, 1));

	@<Decode the term@>;

	Tcl_SetObjResult(ti, termdict);

	return TCL_OK;

}

@ Decode a term returned in |term|. Depending on the type field, the
|value|, |arity| or |size| keys will be added to the dictionary.

If the term is an erlang pid, new storage will be allocated for the pid
and a handle returned as the value.

@<Decode the term@>=
		Tcl_Obj		*valueobj = NULL;
		erlang_pid	*pid;
		erlang_ref	*ref;
		switch (term->ei_type) {

		case ERL_SMALL_INTEGER_EXT:
		case ERL_INTEGER_EXT:@/
			valueobj = Tcl_NewIntObj(term->value.i_val);
			break;
@#
		case ERL_FLOAT_EXT:
		case NEW_FLOAT_EXT:@/
			valueobj = Tcl_NewDoubleObj(term->value.d_val);
			break;
@#
		case ERL_ATOM_EXT:
		case ERL_SMALL_ATOM_EXT:
		case ERL_ATOM_UTF8_EXT:
		case ERL_SMALL_ATOM_UTF8_EXT:@/
			valueobj = Tcl_NewStringObj(term->value.atom_name, -1);
			break;
@#
		case ERL_PID_EXT:@/
			pid = (erlang_pid *)Tcl_AttemptAlloc(sizeof(erlang_pid));
			if (pid == NULL) {
				ErrorReturn(ti, "ERROR", "Could not allocate memory for pid", 0);
				return TCL_ERROR;
			}
			memmove(pid, &term->value.pid, sizeof(erlang_pid));
			valueobj = Tcl_ObjPrintf("pid0x%lx", (long unsigned int)pid);
			break;
@#
		case ERL_REFERENCE_EXT:
		case ERL_NEW_REFERENCE_EXT:@/
			ref = (erlang_ref *)Tcl_AttemptAlloc(sizeof(erlang_ref));
			if (ref == NULL) {
				ErrorReturn(ti, "ERROR", "Could not allocate memory for ref", 0);
				return TCL_ERROR;
			}
			memmove(ref, &term->value.ref, sizeof(erlang_ref));
			valueobj = Tcl_ObjPrintf("ref0x%lx", (long unsigned int)ref);
			break;
@#
		case ERL_PORT_EXT:@/
			valueobj = Tcl_NewStringObj("PORT", -1);
			break;
@#
		case ERL_SMALL_TUPLE_EXT:
		case ERL_LARGE_TUPLE_EXT:
		case ERL_LIST_EXT:
		case ERL_NIL_EXT:@/
			Tcl_DictObjPut(ti, termdict, Tcl_NewStringObj("arity", -1), Tcl_NewIntObj(term->arity));
			break;
@#
		case ERL_STRING_EXT:
		case ERL_BINARY_EXT:@/
			Tcl_DictObjPut(ti, termdict, Tcl_NewStringObj("size", -1), Tcl_NewIntObj(term->size));
@#
		}
		if (valueobj != NULL) {
			Tcl_DictObjPut(ti, termdict, Tcl_NewStringObj("value", -1), valueobj);
		}

@ \.{etclface::decode\_tuple xb}.

Attempts to decode the tuple in \.{xb}. If successful, the arity of the
tuple will be returned. It is then up to the caller to go through the
terms of the tuple and decode them individually.

@<Decode commands@>=
static int
Etclface_decode_tuple(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	int		arity;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_tuple_header(xb->buff, &xb->index, &arity) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_tuple_header failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewIntObj(arity));

	return TCL_OK;
}

@ \.{etclface::decode\_version xb}.

Extract the version encoded in the xbuff \.{xb}. We normally expect the
version to be at the beginning of the buffer.

@<Decode commands@>=
static int
Etclface_decode_version(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff	*xb;
	int		version;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	if (get_xb(ti, objv[1], &xb) == TCL_ERROR)
		return TCL_ERROR;

	if (ei_decode_version(xb->buff, &xb->index, &version) < 0) {
		ErrorReturn(ti, "ERROR", "ei_decode_version failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(ti, Tcl_NewIntObj(version));

	return TCL_OK;
}

@*1Data Handling Commands.

These commands are primarily for handling opaque data structures. For
each opaque data type, we have a set of commands to create, destroy and
display the contents of the structure.

The same naming convention is used across all data types: \.{X\_new}
will create a new instance of type X, \.{X\_free} will free up memory
allocated to that instance of X, \.{X\_show} will return the contents as
a dictionary and \.{X\_print} will produce a stringified version of the
contents in a format similar to that found in Erlang. The latter can be
used to compare two instances of a data type for equality.

@ \.{etclface::ref\_new ec}.

Create a unique erlang reference for the node in \.{bf}. Here we use
the system clock time in seconds and micro-seconds for the first two,
and the random number for the third.

@<Data handling commands@>=
static int
Etclface_ref_new(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode	*ec;
	Tcl_Time	t;
	erlang_ref	*ref;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	ref = (erlang_ref *)Tcl_AttemptAlloc(sizeof(erlang_ref));
	if (ref == NULL) {
		ErrorReturn(ti, "ERROR", "Could not allocate memory for ref", 0);
		return TCL_ERROR;
	}

	Tcl_GetTime(&t);
	strcpy(ref->node, ei_thisnodename(ec));
	ref->n[0]	= t.usec & 0xffff ;
	ref->n[1]	= t.sec;
	ref->n[2]	= random();
	ref->len	= 3;
	ref->creation	= 0;

	Tcl_SetObjResult(ti, Tcl_ObjPrintf("ref0x%lx", (long unsigned int)ref));

	return TCL_OK;
}

@ \.{etclface::ref\_free ref}.

Free up memory allocated to a reference object.

@<Data handling commands@>=
static int
Etclface_ref_free(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	erlang_ref *ref;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ref");
		return TCL_ERROR;
	}

	if (get_ref(ti, objv[1], &ref) == TCL_ERROR)
		return TCL_ERROR;

	Tcl_Free((char *)ref);

	return TCL_OK;
}

@ \.{etclface::ref\_print ref}.

Return the stringified version of the contents of the reference.

@<Data handling commands@>=
static int
Etclface_ref_print(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	erlang_ref *ref;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ref");
		return TCL_ERROR;
	}

	if (get_ref(ti, objv[1], &ref) == TCL_ERROR)
		return TCL_ERROR;

	Tcl_SetObjResult(ti, Tcl_ObjPrintf("#Ref<%s.%d.%d.%d.%d>", ref->node,
		ref->n[0], ref->n[1], ref->n[2], ref->creation));

	return TCL_OK;
}

@ \.{etclface::ref\_show ref}.

Return the contents of ref as a dictionary.

@<Data handling commands@>=
static int
Etclface_ref_show(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	erlang_ref *ref;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ref");
		return TCL_ERROR;
	}

	if (get_ref(ti, objv[1], &ref) == TCL_ERROR)
		return TCL_ERROR;

	Tcl_SetObjResult(ti, ref2dict(ti, ref));

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
	ei_cnode *ec;
	erlang_pid *self;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

	self = ei_self(ec);
	Tcl_SetObjResult(ti, Tcl_ObjPrintf("pid0x%lx", (long unsigned int)self));

	return TCL_OK;
}

@ \.{etclface::nodename ec}.

Return the node name of the cnode.

@<Utility commands@>=
static int
Etclface_nodename(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode *ec;
	char *nodename;

	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	if (get_ec(ti, objv[1], &ec) == TCL_ERROR)
		return TCL_ERROR;

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
		Tcl_SetObjResult(ti, Tcl_NewIntObj(ei_get_tracelevel()));
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
		Tcl_AppendObjToErrorInfo(ti, Tcl_ObjPrintf("\n[%d] %s", errorno, Tcl_ErrnoMsg(errorno)));
	}
	return;
}

@ Extract and convert a timeout value. Given a Tcl object pointer,
attempt to convert to unsigned int, if successful, the timeout value
is returned in the \.{timeout} parameter.

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

@ \.{get\_ref}. Extract a ref handle from an object.

@<Internal helper functions@>=
static int
get_ref(Tcl_Interp *ti, Tcl_Obj *tclobj, erlang_ref **ref)
{
	const char* refhandle;
	refhandle = Tcl_GetString(tclobj);
	if (sscanf(refhandle, "ref%p", ref) != 1) {
		ErrorReturn(ti, "ERROR", "Invalid ref handle", 0);
		return TCL_ERROR;
	}

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

@ \.{ref2dict}. Given a valid ref pointer, convert its contents to a dictionary.

@<Internal helper functions@>=
static Tcl_Obj*
ref2dict(Tcl_Interp *ti, erlang_ref *ref) {
	Tcl_Obj *refdict = Tcl_NewDictObj();

	Tcl_DictObjPut(ti, refdict, Tcl_NewStringObj("node", -1), Tcl_NewStringObj(ref->node, -1));
	Tcl_DictObjPut(ti, refdict, Tcl_NewStringObj("creation", -1), Tcl_NewIntObj(ref->creation));
	Tcl_DictObjPut(ti, refdict, Tcl_NewStringObj("n0", -1), Tcl_NewIntObj(ref->n[0]));
	Tcl_DictObjPut(ti, refdict, Tcl_NewStringObj("n1", -1), Tcl_NewIntObj(ref->n[1]));
	Tcl_DictObjPut(ti, refdict, Tcl_NewStringObj("n2", -1), Tcl_NewIntObj(ref->n[2]));

	return refdict;
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

