
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

@*The code.

@c

#include <tcl.h>
#include <erl_interface.h>
#include <ei.h>

@<erl interface cinit@>;
@<erl interface connect@>;
@<erl interface reg send@>;
@<AppInit@>;

@ We follow the standard format for all Tcl extensions. \.{Etclface\_Init}
initializes the library and declares the commands. We require \.{Tcl}
version 8.5, This vesion has been around for some time now, so we can
expect it to be available at most sites.

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

	Tcl_CreateObjCommand(ti, "etclface::init", (Tcl_ObjCmdProc *) erli_cinit, NULL, NULL);
@#
	Tcl_CreateObjCommand(ti, "etclface::connect", (Tcl_ObjCmdProc *) erli_connect, NULL, NULL);
@#
	Tcl_CreateObjCommand(ti, "etclface::reg_send", (Tcl_ObjCmdProc *) erli_reg_send, NULL, NULL);

	return TCL_OK;
@#
}

@ \.{etclface::init nodename cookie}

Initialize and return a handle to an \.{ec} structure, with own name
\.{nodename} and \.{cookie}.

If successful, the command will return a stringified handle to the \.{ec}
structure in the form of a hexadecimal number prefixed with \.{ec0x}. The
storage for the structure is allocated dynamically, so it will need to
be de-allocated when not needed.

@<erl interface cinit@>=
static int
erli_cinit(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	ei_cnode *ec;
	char ecstr[100];
	char *nodename, *cookie;

	if (objc != 3) {
		Tcl_WrongNumArgs(ti,1 ,objv, "nodename cookie");
		return TCL_ERROR;
	}

	nodename = Tcl_GetString(objv[1]);
	cookie = Tcl_GetString(objv[2]);

	ec = (ei_cnode *)Tcl_AttemptAlloc(sizeof(ei_cnode));
	if (ec == NULL) {
		Tcl_SetResult(ti, "Could not allocate memory for ei_cnode", TCL_STATIC);
		return TCL_ERROR;
	}

	if (ei_connect_init(ec, nodename, cookie, 0) < 0) {
		Tcl_SetResult(ti, "ei_connect_init failed", TCL_STATIC);
		return TCL_ERROR;
	}

	sprintf(ecstr, "ec0x%0x", ec);
	Tcl_SetResult(ti, ecstr, TCL_VOLATILE);
	return TCL_OK;
@#
}

@ \.{etclface::connect ec nodename}

Establish a connection to node \.{nodename} using the \.{ec} handle
obtained from \.{etclface::init}.

If successful, the command will return the file descriptor \.{fd}, which
should be used for subsequent calls to various send/receive commands.

@<erl interface connect@>=
static int
erli_connect(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	if (objc != 3) {
		Tcl_WrongNumArgs(ti,1 ,objv, "ec nodename");
		return TCL_ERROR;
	}

	char *echandle;
	echandle = Tcl_GetString(objv[1]);
	ei_cnode *ec;
	sscanf(echandle, "ec%p", &ec);

	char *nodename;
	nodename = Tcl_GetString(objv[2]);

	int fd;
	if ((fd = ei_connect(ec, nodename)) < 0) {
		char errstr[100];
		sprintf(errstr, "ei_connect failed (fd=%d, erl_errno=%d)", fd, erl_errno);
		Tcl_SetResult(ti, errstr, TCL_STATIC);
		return TCL_ERROR;
	}

	char fdstr[100];
	sprintf(fdstr, "%d", fd);
	Tcl_SetResult(ti, fdstr, TCL_VOLATILE);

	return TCL_OK;
@#
}

@ \.{erli\_reg\_send ec fd server term ?term...?}

Send a message consisting of one or more \.{term}s to a registered process
\.{server}, using the \.{ec} handle otained from \.{etclface::init}
and \.{fd} obtained from \.{etclface::connect}.

@<erl interface reg send@>=
static int
erli_reg_send(ClientData cd, Tcl_Interp *ti, int objc, Tcl_Obj *const objv[])
{
	if (objc < 5) {
		Tcl_WrongNumArgs(ti,1 ,objv, "ec fd server term ?term...?");
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

	char *term;
	term = Tcl_GetString(objv[4]);

	ei_x_buff x;
	ei_x_new(&x);
	ei_x_format(&x, "~a", term);
	if (ei_reg_send(ec, fd, serverport, x.buff, x.index) != 0) {
		ei_x_free(&x);
		char errstr[100];
		sprintf(errstr, "ei_reg_send: [%d] %s", erl_errno, strerror(erl_errno));
		Tcl_SetResult(ti, errstr, TCL_STATIC);
		return TCL_ERROR;
	}
	ei_x_free(&x);
	return TCL_OK;
}

