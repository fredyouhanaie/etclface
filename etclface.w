
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

%%\parindent=0pt	%% NOTE parindent messes up the code indentation
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

\def\etf{\.{etclface}\,}

%% To a C programmer NULL is more familiar than Lambda.
@s NULL normal

%% Treat the Tcl data types as reserved words during typesetting.
@s ClientData int
@s Tcl_Obj int
@s Tcl_Interp int
@s Tcl_ObjCmdProc int

%% Treat the erl_interface data types as reserved words during typesetting.
@s ei_cnode int
@s ei_x_buff int
@s erlang_pid int
@s Erl_IpAddr int

@*Introduction.

\etf is a Tcl/Tk extension that exposes a minimal set of
\.{erl\_interface} functions. \.{erl\_interface} is part of the core
Erlang/OTP distribution.

Just like Erlang, Tcl/Tk is a mature dynamic scripting language.
In fact both languages started over 25 years ago in the mid-eighties.
As a result of this there is a large body of applications written in the
two languages. Although there are similar applications written in both
languages, such as web servers, there are also other software that are
only available in one or the other language. \etf provides a conduit
between applications written in the two languages.

The purpose of this extension is twofold:

\bul To allow Erlang processes to communicate with software written in
Tcl/Tk, and

\bul to allow Tcl/Tk software to leverage the concurrent environment
provided by Erlang/OTP.

@*Implementation Notes.

There are two sets of communication modules within \.{erl\_interface}, the
old \.{erl\_*} ones and the newer \.{ei\_*} set. For \etf we are using the
latter.

@ Data Types.

Tcl understands one data type only, character strings, although the
underlying commands can interpret the character strings in different ways,
and one way of combining basic types, lists.

Erlang, on the other hand, has several types, and the extension needs
to be able to convert between the types appropriately.

@ Components.

The basic interface is written in \Cee.

@ Installation. The build and installation is done using \.{cmake},
see \url{http://cmake.org}.

@ Testing. There are two sets of test scripts, one for tests initiated
from the Erlang side, and the other for tests run on the Tcl side.

@i etclface-code.w

@*Licensing of the Software.

\etf is free software, you can redistribute it and/or modify it
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
