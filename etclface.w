
%% etclface-main.w
%%	Main module of the etclface cweb files.

%% Copyright (c) 2013-2024 Fred Youhanaie
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

%%\parindent=0pt	%% NOTE parindent messes up the code indentation
%%\parskip=1pt

\def\title{etclface - An Erlang/Tcl Interface}
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

\def\etf{\.{etclface}\ }
\def\erliface{\.{erl\_interface}\ }

%% To a C programmer NULL is more familiar than Lambda.
@s NULL normal

%% Treat the various data types as reserved words when typesetting.

@s ClientData int
@s Tcl_Channel int
@s Tcl_Interp int
@s Tcl_ObjCmdProc int
@s Tcl_Obj int

@s ei_cnode int
@s ei_term int
@s ei_x_buff int
@s erlang_msg int
@s erlang_pid int
@s erlang_ref int
@s ErlConnect int
@s Erl_IpAddr int

@s EtclfaceCommand_s int
@s EtclfaceCommand_t int

@*Introduction.

\etf is a Tcl/Tk extension that exposes a minimal set of \erliface
functions. \erliface is part of the core Erlang/OTP distribution.

Just like Erlang, Tcl/Tk is a mature dynamic scripting language. In
fact both languages started 30 or so years ago in the mid-eighties. As
a result of this there is a large body of applications written in the
two languages. Although there are similar applications written in
both languages, such as web servers, there are also other software
that are only available in one or the other language. \etf provides a
conduit between applications written in the two languages.

The purpose of this extension is twofold:

\count255=1
\bul To allow Erlang processes to communicate with software written in
Tcl/Tk, and

\bul to allow Tcl/Tk software to leverage the concurrent environment
provided by Erlang/OTP.

@*Implementation Notes.

Historically, there used to be two sets of communication modules in
the \erliface libraries, the old \.{erl\_*} ones and the newer
\.{ei\_*} set. The former was deprecated as of OTP 22 and removed in
OTP 23. For \etf we have always used the latter.

@ {\bf \tt CWEB}. The programming language used in creating the
extension is \.{CWEB}, which consists of standard \Cee\ code together
with the annotations describing the code segments. This is known as
Literate Programming. The web site
\url{http://literateprogramming.com} is a good starting point for
those not familiar with the concept.

Literate Programming allows one to produce from a single source file a
typeset documentation (this note) as well as a compilable \Cee\ source
code.

@ {\bf Error Handling}. All commands return \.{TCL\_OK} on success or
\.{TCL\_ERROR} on failure. Tcl scripts can use the \.{catch} command
to handle the error conditions. For all errors raised by \etf, the
\.{errorCode} variable will be set appropriately. In all cases,
\.{errorCode} will be a list made up of three elements, "\.{ETCLFACE\
{\it code}\ {\it message}}". The first part distinguishes our errors
from other Tcl errors, all \etf errors will have this prefix. The
second part will be one of the error return codes from the \erliface
library, such as \.{ERL\_ERROR}, \.{ERL\_TIMEOUT} etc, but without the
\.{ERL\_} prefix.

For example, if the \.{etclface::connect} command fails due to the
\.{ei\_connect\_tmo()} failing, the Tcl variable \.{errorCode} may
contain "\.{ETCLFACE\ ERROR\ \{[5]\ ei\_connect\_tmo\ failed\}}".

In addition to \.{errorCode}, the variable \.{errorInfo} may also be
set. This provides a more detailed explanation of the error condition
intended to be read by people.

More details can be found in the Tcl man pages for \.{tclvars} and
\.{catch}.

@ {\bf Data Types and Data Structures}.

Tcl understands one data type only, character strings, although the
underlying commands can interpret the character strings in different
ways, and one way of combining basic types, lists.

Erlang, on the other hand, has several types, and the extension needs
to be able to convert between the types appropriately.

Here, we need to consider the data type representations within three
languages, Erlang, Tcl and \Cee\, since all conversions between Erlang
and Tcl types will be through \Cee.

Erlang lists and tuples are represented as lists in Tcl.

@ {\bf The Components}.

The basic interface is written in \Cee. The source code can be found
at the end of this document, see the section {\it The Source Code}.

There will also be an additional library written in Tcl that will
provide a higher level functionality, such as encoding and decoding of
Erlang terms to and from Tcl data types, such as lists and
dictionaries.

@ {\bf Installation}. The software is available in source form and can
be downloaded, or cloned, from github, see
\url{https://github.com/fredyouhanaie/etclface}.

The build and installation is done using \.{cmake}, see
\url{http://cmake.org}.

@ {\bf Testing}. There are two sets of test scripts, one for tests
initiated from the Erlang side, and the other for tests run on the Tcl
side.

The tests on the Tcl side are based on the \.{tcltest} package are
located in in the \.{Tests/} directory. The test cases are in
individual Tcl procs within the \.{etclface-testsuite.tcl} file. These
tests are run via the \.{run-testsuite.tcl} wrapper. The wrapper will
run all the tests, unless a pattern of test names is supplied on the
command line.

@i etclface-code.w

@*Licensing of the Software.

\etf is free software, you can redistribute it and/or modify it under
the terms of the BSD License, see
\url{http://opensource.org/licenses/BSD-2-Clause}.

\medskip

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

\count255=1 \bul Redistributions of source code must retain the above
copyright notice, this list of conditions and the following
disclaimer.

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
