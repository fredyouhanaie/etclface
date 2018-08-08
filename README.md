
# etclface - An Erlang/Tcl Interface

This is a [Tcl](https://tcl.tk) extension that will allow software written
in Tcl and [Erlang](https://www.erlang.org/) to communicate using the
Erlang/OTP interface, `erl_interface`.


## Introduction

Erlang provides two native interfaces that enable communication between
Erlang processes and external programs using Erlang's message passing
mechanism.

One of these interfaces is `erl_interface`, which allows the external
program to register as a node in a Distributed Erlang network and exchange
messages with Erlang processes.

Some of the aims of the Tcl extension are:

* Let a Tcl application use Erlang for processing.
* Let an Erlang application use a Tcl/Tk based GUI, or other Tcl
extensions such as Expect.

The initial version will only expose enough `erl_interface` functions to
allow a Tcl application to communicate with Erlang nodes.  Currently,
there are many functions in `erl_interface`, however, only the following
subset will be provided:

* register with epmd as a node
* send/receive messages
* decode/encode between internal and Tcl types


## Build and Installation


### Prerequisites

You will need the following software/packages:

* Tcl/Tk 8.5 or higher
* Erlang/OTP, R15B03 or higher
* TeX, if producing the documentation
* Cweb, which can be obtained from
  [here](http://www.literateprogramming.com/cweb_download.html), or
  automatically installed with the TeX Live package.
* cmake
* ccmake, not mandatory, but a useful tool for editing cmake parameters
* make
* C compiler, GCC was used during development
* tcllib, provides doctools and dtplite, which is needed for the man
  page


### Build

Once you have the source files on a local disk, change to the `etclface`
directory, then

	mkdir -pv _build	# for out-of-source builds
	cd _build
	cmake ..
	make				# to create the library
	make man			# to create the man page
	make doc			# optional, for the PDF docs


### Installation

if the build is successful, then you should have the following files
in the `_build` directory:

* libetclface.so
* etclface.3tcl.gz
* etclface.pdf (if `make doc` was run)

You can then install the library, by default under `/usr/local/`, with

	make install		# ensure you have permissions

The PDF file is not installed anywhere, it is up to you to move/copy
it somewhere convenient.

You can also change the installation directory when configuring cmake,
e.g.

	mkdir -pv _build
	cd _build
	cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local ..

The `$HOME/.local` directory in the above example is standard on the
Linux systems, and it allows users to have their own private
equivalent of `/usr/local` directory.

Every time `make install` is run, the file
`_build/install_manifest.txt` will contain the list of the installed
files.


## Testing

The software has been tested on Debian GNU/Linux only. The test
scripts can be found in the `Tests` directory.

To run the testsuite:

	cd _build
	make tests

The testsuite will start a local erlang node in the background, using
`run_erl`, that will be used to test the communication betwen the Tcl
and Erlang processes. The erlang node will only be active during the
test. While active, the erlang node will write to log files in
`/tmp/erlnode/`.

If, for some reason, the erlang node is left running, it can be
stopped as follows, note that the trailing `/` is required:

	echo 'q().' | to_erl /tmp/erlnode/


## Documentation

There are two pieces of documentation, a man page and a single PDF
file generated from the `CWEB` source code.

The man page is generated from the `etclace.man` file and, once
installed, can be accessed using `man etclface`. It describes all the
Tcl commands implemented by `etclface`.

The PDF file contains the implementation details, including the
complete source code.


## Feedback and Contributions

Comments and feedback are welcome, please use the issue tracker for
this.

Please use pull requests for patch contributions.


Enjoy!

Fred Youhanaie

