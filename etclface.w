
%% etclface-main.w
%%	Main module of the etclface cweb files.

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

\datethis

%%\pagewidth=6.5in % a4 width=8.5, less 2x1 in for margins
%%\pageheight=10in
%\fullpageheight=9in
%%\setpage

%%\parindent=0pt
%%\parskip=1pt

\def\title{etclface - Erlang/Tcl Interface}
\def\author{Fred Youhanaie}
\def\version{(Version 0.1)}

\ifx\pdfoutput\undefined\else
	\pdfinfo{
		/Title	(\title)
		/Author	(\author)
	}
\fi

@i boilerplate.w

%% \fig{file} will insert an eps/pdf picture file
\def\fig#1{
	\medskip
	\ifx\pdfoutput\undefined
		\input epsf.tex \epsfbox{#1.eps}
	\else
		\pdfximage {#1.pdf}\pdfrefximage\pdflastximage
	\fi
	\medskip
}

%% \url will create the proper links for the PDF files.
\def\url#1{\ifx\pdfoutput\undefined\.{#1}\else\pdfURL{\.{#1}}{#1}\fi}

%% \bul provide bullet points
\def\bul{\hfil\item{\romannumeral\count255} \advance\count255 by 1}
%% the following needs to be repeated for each set of new bullet points
\count255=1

%% To a C programmer NULL is more familiar than Lambda.
@s NULL normal

@*Introduction. \.{etclface} is a Tcl/Tk extension that exposes a minimal
set of \.{erl\_interface} functions. \.{erl\_interface} is part of the
core Erlang/OTP distribution.

@*Installation. The build and installation is done using \.{cmake},
see \url{http://cmake.org}.

@*Testing. There are two sets of test scripts, one for tests initiated
from the Erlang side, and the other for tests run on the Tcl side.

@*The code.

@c

#include <tcl.h>
#include <erl_interface.h>
#include <ei.h>

@<erl interface cinit@>;
@<erl interface connect@>;
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

	if (Tcl_PkgProvide(ti, "Etclface", "1.0") != TCL_OK) {
		return TCL_ERROR;
	}

	Tcl_CreateObjCommand(ti, "etclface::init", (Tcl_ObjCmdProc *) erli_cinit, NULL, NULL);
@#
	Tcl_CreateObjCommand(ti, "etclface::connect", (Tcl_ObjCmdProc *) erli_connect, NULL, NULL);

	return TCL_OK;
@#
}

@ \.{erli\_cinit} expects two arguments, \.{nodename} and \.{cookie},
it calls \.{ei\_connect\_init} and if successful, it will return a
stringified handle to the \.{ec} structure in the form of a hexadecimal
number prefixed with \.{ec0x}. The storage for the structure is allocated
dynamically, so it will need to be de-allocated when not needed.

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

@ \.{erli\_connect} expects two arguments, the \.{ec} handle from the
\.{connect\_init} call and a nodename to connect to.

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
		//erl_err_quit("ei_connect");
		return TCL_ERROR;
	}

	char fdstr[100];
	sprintf(fdstr, "%d", fd);
	Tcl_SetResult(ti, fdstr, TCL_VOLATILE);

	return TCL_OK;
@#
}



@*Licensing of the Software.

\.{etclface} is free software, you can redistribute it and/or modify it
under the terms of the BSD License, see
\url{http://opensource.org/licenses/BSD-2-Clause}.

\medskip

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

\count255=1
\bul Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

\bul Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

\medskip

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS~IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@*Index.
