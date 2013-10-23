
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

@*The Code.

The \etf commands are collected in a number of groups.

@c

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

	if (Tcl_PkgProvide(ti, "Etclface", "0.1") != TCL_OK) {
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
static Tcl_ObjCmdProc Etclface_encode_atom;
static Tcl_ObjCmdProc Etclface_encode_empty_list;
static Tcl_ObjCmdProc Etclface_encode_list_header;
static Tcl_ObjCmdProc Etclface_init;
static Tcl_ObjCmdProc Etclface_nodename;
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
	{"etclface::encode::atom", Etclface_encode_atom},@/
	{"etclface::encode::empty_list", Etclface_encode_empty_list},@/
	{"etclface::encode::list_header", Etclface_encode_list_header},@/
	{"etclface::init", Etclface_init},@/
	{"etclface::nodename", Etclface_nodename},@/
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

\.{erl\_interface} provides two functions for initializing
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

@*2\.{etclface::init nodename ?cookie?}.

Initialize and return a handle to an \.{ec} structure, with own name
\.{nodename} and \.{cookie}.

@<Initialization commands@>=
static int
Etclface_init(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*nodename, *cookie;
	ei_cnode	*ec;
	char		echandle[100];

	if ((objc<2) || (objc>3)) {
		Tcl_WrongNumArgs(ti, 1, objv, "nodename ?cookie?");
		return TCL_ERROR;
	}

	nodename = Tcl_GetString(objv[1]);
	cookie = (objc == 2) ? NULL : Tcl_GetString(objv[2]);

	ec = (ei_cnode *)Tcl_AttemptAlloc(sizeof(ei_cnode));
	if (ec == NULL) {
		Tcl_SetResult(ti, "Could not allocate memory for ei_cnode", TCL_STATIC);
		return TCL_ERROR;
	}

	if (ei_connect_init(ec, nodename, cookie, 0) < 0) {
		Tcl_SetResult(ti, "ei_connect_init failed", TCL_STATIC);
		return TCL_ERROR;
	}

	sprintf(echandle, "ec%p", ec);
	Tcl_SetResult(ti, echandle, TCL_VOLATILE);
	return TCL_OK;
}

@*2\.{etclface::xinit host alive node ipaddr ?cookie?}.

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

	if ((objc<5) || (objc>6)) {
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
		Tcl_SetResult(ti, "Could not allocate memory for ei_cnode", TCL_STATIC);
		return TCL_ERROR;
	}

	int res = ei_connect_xinit(ec, host, alive, node, ipaddr, cookie, (short)0);
	Tcl_Free((char *)ipaddr);
	if (res<0) {
		Tcl_SetResult(ti, "ei_connect_xinit failed", TCL_STATIC);
		return TCL_ERROR;
	}

	sprintf(echandle, "ec%p", ec);
	Tcl_SetResult(ti, echandle, TCL_VOLATILE);
	return TCL_OK;
}

@*1Connection Commands.

\.{erl\_interface} provides four functions for establishing a connection
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

@*2\.{etclface::connect ec nodename ?timeout?}.

Establish a connection to node \.{nodename} using the \.{ec} handle
obtained from \.{etclface::init} or \.{xinit}.

@<Connection commands@>=
static int
Etclface_connect(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char *echandle;
	ei_cnode *ec;
	char *nodename;
	unsigned timeout;

	if ((objc<3) || (objc>4)) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec nodename ?timeout?");
		return TCL_ERROR;
	}

	echandle = Tcl_GetString(objv[1]);
	sscanf(echandle, "ec%p", &ec);

	nodename = Tcl_GetString(objv[2]);

	if (objc == 3) {
		timeout = 0;
	} else {
		if (get_timeout(ti, objv[3], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	int fd;
	if ((fd = ei_connect_tmo(ec, nodename, timeout)) < 0) {
		char errstr[100];
		sprintf(errstr, "ei_connect failed (fd=%d, erl_errno=%d)", fd, erl_errno);
		Tcl_SetResult(ti, errstr, TCL_VOLATILE);
		return TCL_ERROR;
	}

	char fdstr[100];
	sprintf(fdstr, "%d", fd);
	Tcl_SetResult(ti, fdstr, TCL_VOLATILE);

	return TCL_OK;
}

@*2\.{etclface::xconnect ec ipaddr alivename ?timeout?}.

Establish a connection to node \.{alivename@@ipaddr} using the \.{ec}
handle obtained from \.{etclface::init} or \.{xinit}.

@<Connection commands@>=
static int
Etclface_xconnect(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*alivename, *echandle;
	ei_cnode	*ec;
	Erl_IpAddr	ipaddr;
	unsigned	timeout;
	int		fd;
	char		fdstr[100];

	if ((objc<4) || (objc>5)) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec ipaddr alivename ?timeout?");
		return TCL_ERROR;
	}

	echandle = Tcl_GetString(objv[1]);
	sscanf(echandle, "ec%p", &ec);

	if (get_ipaddr(ti, objv[2], &ipaddr) == TCL_ERROR)
		return TCL_ERROR;

	alivename = Tcl_GetString(objv[3]);

	if (objc == 4) {
		timeout = 0;
	} else {
		if (get_timeout(ti, objv[4], &timeout) == TCL_ERROR)
			return TCL_ERROR;
	}

	if ((fd = ei_xconnect_tmo(ec, ipaddr, alivename, timeout)) < 0) {
		char errstr[100];
		sprintf(errstr, "ei_connect failed (fd=%d, erl_errno=%d)", fd, erl_errno);
		Tcl_SetResult(ti, errstr, TCL_VOLATILE);
		return TCL_ERROR;
	}

	sprintf(fdstr, "%d", fd);
	Tcl_SetResult(ti, fdstr, TCL_VOLATILE);

	return TCL_OK;
}


@*1Send Commands.

@*2\.{reg\_send ec fd server xb}.

Send a message consisting of one or more \.{term}s to a registered process
\.{server}, using the \.{ec} handle otained from \.{etclface::init}
and \.{fd} obtained from \.{etclface::connect}.

@<Send commands@>=
static int
Etclface_reg_send(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	if (objc != 5) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec fd server xb");
		return TCL_ERROR;
	}

	char *echandle;
	echandle = Tcl_GetString(objv[1]);
	ei_cnode *ec;
	sscanf(echandle, "ec%p", &ec);

	int fd;
	if (Tcl_GetInt(ti, Tcl_GetString(objv[2]), &fd) == TCL_ERROR) {
		return TCL_ERROR;
	}

	char *serverport;
	serverport = Tcl_GetString(objv[3]);

	char *xbhandle;
	ei_x_buff	*xb;
	xbhandle = Tcl_GetString(objv[4]);
	sscanf(xbhandle, "xb%p", &xb);

	if (ei_reg_send(ec, fd, serverport, xb->buff, xb->index) != 0) {
		char errstr[100];
		sprintf(errstr, "ei_reg_send failed (%d)", erl_errno);
		Tcl_SetResult(ti, errstr, TCL_VOLATILE);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@*1Receive Commands.

@<Receive commands@>=
static int
Etclface_receive(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	return TCL_OK;
}

@*1Buffer Commands.

Erlang has several data types, while Tcl treats everything as character
strings, although, for efficiency, Tcl can internally maintain numeric
data as numbers. The encode commands will convert from Tcl data types
to Erlang types ready for transmission to other Erlang nodes.

\.{erl\_interface} provides two groups of encode functions, and within
each group there is one function for each Erlang data type. For now,
at least, a limited useful subset of these functions will be exposed as
Tcl commands. Of the two groups, only those with the \.{ei\_x\_} prefix
are implemented, and of these we shall start with a limited main group.

The \.{ei\_x\_*} functions encode the data into the \.{ei\_x\_buff}
data structure.

@*2\.{etclface::xb\_new ?-withversion?}.

Creates a new \.{ei\_x\_buff} structure and initializes the buffer
using \.{ei\_x\_new()}, or optionally with an initial version byte using
\.{ei\_x\_new\_with\_version()}.

@<Buffer commands@>=
static int
Etclface_xb_new(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_x_buff *xb;

	if ((objc!=1) && (objc!=2)) {
		Tcl_WrongNumArgs(ti, 1, objv, "?-withversion");
		return TCL_ERROR;
	}
	if ((objc==2) && strcmp(Tcl_GetString(objv[1]), "-withversion")) {
		Tcl_SetResult(ti, "Only -withversion allowed as argument.", TCL_STATIC);
		return TCL_ERROR;
	}

	xb = (ei_x_buff *)Tcl_AttemptAlloc(sizeof(ei_x_buff));
	if (xb == NULL) {
		Tcl_SetResult(ti, "Could not allocate memory for ei_x_buff", TCL_STATIC);
		return TCL_ERROR;
	}

	int res;
	if (objc==1) {
		res = ei_x_new(xb);
	} else {
		res = ei_x_new_with_version(xb);
	}
	if (res < 0) {
		Tcl_Free((char *)xb);
		char errstr[100];
		sprintf(errstr, "ei_x_new/ei_x_new_with_version failed (erl_errno=%d)", erl_errno);
		Tcl_SetResult(ti, errstr, TCL_VOLATILE);
		return TCL_ERROR;
	}

	char xbhandle[100];
	sprintf(xbhandle, "xb%p", xb);
	Tcl_SetResult(ti, xbhandle, TCL_VOLATILE);

	return TCL_OK;
}

@*2\.{etclface::xb\_free xb}.

Free up the internal buffer allocated to \.{xb} using \.{ei\_x\_free()},
but does not free up \.{xb} itself.

@<Buffer commands@>=
static int
Etclface_xb_free(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char *xbhandle;
	ei_x_buff *xb;

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	xbhandle = Tcl_GetString(objv[1]);
	sscanf(xbhandle, "xb%p", &xb);

	if (ei_x_free(xb) < 0) {
		char errstr[100];
		sprintf(errstr, "ei_x_free failed (erl_errno=%d)", erl_errno);
		Tcl_SetResult(ti, errstr, TCL_VOLATILE);
		return TCL_ERROR;
	}

	return TCL_OK;
}

@*2\.{etclface::xb\_show xb}.

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
	char *xbhandle, result[100];
	ei_x_buff *xb;

	if (objc!=2) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb");
		return TCL_ERROR;
	}

	xbhandle = Tcl_GetString(objv[1]);
	sscanf(xbhandle, "xb%p", &xb);

	sprintf(result, "buff %p buffsz %d index %d", xb->buff, xb->buffsz, xb->index);
	Tcl_SetResult(ti, result, TCL_VOLATILE);

	return TCL_OK;
}

@*1Encode Commands.

\.{erl\_interface} provides many encode functions, we shall start with
the most commonly used Erlang data types, then add more encode commands
over time.

@*2\.{etclface::encode::atom xb atom}.

Takes and existing \.{ei\_x\_buff} and adds the string \.{atom} as an
atom in binary format.

@<Encode commands@>=
static int
Etclface_encode_atom(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	char		*xbhandle, *atom;
	ei_x_buff	*xb;

	if (objc!=3) {
		Tcl_WrongNumArgs(ti, 1, objv, "xb atom");
		return TCL_ERROR;
	}

	xbhandle = Tcl_GetString(objv[1]);
	sscanf(xbhandle, "xb%p", &xb);

	atom = Tcl_GetString(objv[2]);

	if (ei_x_encode_atom(xb, atom) < 0) {
		char errstr[100];
		sprintf(errstr, "ei_x_encode_atom failed (erl_errno=%d)", erl_errno);
		Tcl_SetResult(ti, errstr, TCL_VOLATILE);
	}

	return TCL_OK;
}

@*2\.{etclface::encode::list\_header xb arity}.

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

	char *xbhandle = Tcl_GetString(objv[1]);
	sscanf(xbhandle, "xb%p", &xb);

	if (Tcl_GetInt(ti, Tcl_GetString(objv[2]), &arity) == TCL_ERROR)
		return TCL_ERROR;
	if (arity < 0) {
		Tcl_SetResult(ti, "arity cannot be negative.", TCL_STATIC);
		return TCL_ERROR;
	}

	if (ei_x_encode_list_header(xb, arity) < 0) {
		char errstr[100];
		sprintf(errstr, "ei_x_encode_list_header failed (erl_errno=%d)", erl_errno);
		Tcl_SetResult(ti, errstr, TCL_VOLATILE);
	}

	return TCL_OK;
}

@*2\.{etclface::encode::empty\_list xb}.

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

	char *xbhandle = Tcl_GetString(objv[1]);
	sscanf(xbhandle, "xb%p", &xb);

	if (ei_x_encode_empty_list(xb) < 0) {
		char errstr[100];
		sprintf(errstr, "ei_x_encode_empty_list failed (erl_errno=%d)", erl_errno);
		Tcl_SetResult(ti, errstr, TCL_VOLATILE);
	}

	return TCL_OK;
}
@*1Decode Commands.

@<Decode commands@>=
static int
Etclface_decode(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	return TCL_OK;
}

@*1Utility Commands.
These are various commands for accessing the \.{ei\_cnode} data structures.

@*2\.{etclface::self ec}.

Return the "pseudo" pid of this process

@<Utility commands@>=
static int
Etclface_self(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	char *echandle;
	echandle = Tcl_GetString(objv[1]);
	ei_cnode *ec;
	sscanf(echandle, "ec%p", &ec);

	erlang_pid *self;
	self = ei_self(ec);

	char pidstr[100];
	sprintf(pidstr, "<%d.%d.%d>", self->num, self->serial, self->creation);

	Tcl_SetResult(ti, pidstr, TCL_VOLATILE);
	return TCL_OK;
}

@*2\.{etclface::nodename ec}.

Return the node name of the cnode.

@<Utility commands@>=
static int
Etclface_nodename(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	if (objc != 2) {
		Tcl_WrongNumArgs(ti, 1, objv, "ec");
		return TCL_ERROR;
	}

	char *echandle;
	echandle = Tcl_GetString(objv[1]);
	ei_cnode *ec;
	sscanf(echandle, "ec%p", &ec);

	char *nodename;
	nodename = (char *)ei_thisnodename(ec);

	Tcl_SetResult(ti, nodename, TCL_VOLATILE);
	return TCL_OK;
}

@*2\.{etclface::tracelevel ?level?}.

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
	char levelstr[100];

	if ((objc<1) || (objc>2)) {
		Tcl_WrongNumArgs(ti, 1, objv, "?level?");
		return TCL_ERROR;
	}

	if (objc == 1) {
		sprintf(levelstr, "%d", ei_get_tracelevel());
		Tcl_SetResult(ti, levelstr, TCL_VOLATILE);
		return TCL_OK;
	}

	if (Tcl_GetInt(ti, Tcl_GetString(objv[1]), &level) == TCL_ERROR)
		return TCL_ERROR;
	ei_set_tracelevel(level);

	return TCL_OK;
}

@*1Internal Helper Functions.

These are a set of functions for internal consumption, they help avoid
duplication.

@ Extract and convert a timeout value. Given a Tcl object pointer,
attempt to convert to unsigned int, if successful, the timeout value
isn returned in the \.{timeout} parameter.

@<Internal helper functions@>=
static int
get_timeout(Tcl_Interp *ti, Tcl_Obj *tclobj, unsigned *timeout) {
	int tmo;
	if (Tcl_GetInt(ti, Tcl_GetString(tclobj), &tmo) == TCL_ERROR)
		return TCL_ERROR;
	if (tmo < 0) {
		Tcl_SetResult(ti, "timeout cannot be negative", TCL_STATIC);
		return TCL_ERROR;
	}
	*timeout = tmo;
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
		Tcl_SetResult(ti, "Could not allocate memory for ipaddr", TCL_STATIC);
		return TCL_ERROR;
	}
	if (!inet_aton(Tcl_GetString(tclobj), inaddr)) {
		Tcl_Free((char *)inaddr);
		Tcl_SetResult(ti, "Invalid ipaddr", TCL_STATIC);
		return TCL_ERROR;
	}
	*ipaddr = (Erl_IpAddr)inaddr;
	return TCL_OK;
}

