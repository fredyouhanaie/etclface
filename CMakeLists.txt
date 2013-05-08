
# Copyright (c) 2013 Fred Youhanaie
# All rights reserved.

cmake_minimum_required (VERSION 2.8)

project (etclface C)

#
# The end result of the make run is to produce one or both of the
# following files:
#	libetclface.so
#		This is the library that is loaded by Tcl/Tk
#	etclface.pdf
#		This is the typeset documentation
#		(includes the source code)
#
# The source for both targets is the cweb file "etclface.w",
#	etclface.w --(ctangle)-> etclface.c --(gcc/ld)-> libetclface.so
#	etclface.w --(cweave)-> etclface.tex --(pdftex)-> etclface.pdf

# These can be overridden on command line, or via edit_cache target
#
# We need the directories for the erl_interface lib and include files
# These are normally under ERL_ROOT/lib/erl_interface-x.y.z/
# The erlang shell, erl, is normally under ERL_ROOT/bin, so we use erl
# to find the ERL_ROOT directory
#
find_program (ERL_PROG_PATH "erl")
get_filename_component(ERL_PATH ${ERL_PROG_PATH} PATH)
get_filename_component(ERL_ROOT ${ERL_PATH} PATH)
file(GLOB ERLIFACE_DIR "${ERL_ROOT}/lib/erl_interface-*")
##set (ERLIFACE_DIR "/opt/erlang-R16B/lib/erl_interface-3.7.11"
	##CACHE PATH "erl_interface root directory."
##)
set (ERLIFACE_INC_DIR "${ERLIFACE_DIR}/include"
	CACHE PATH "erl_interface.h include directory."
)
set (ERLIFACE_LIB_DIR "${ERLIFACE_DIR}/lib"
	CACHE PATH "erl_interface and ei lib directory."
)
unset (ERL_PROG_PATH CACHE)

find_package (TclStub REQUIRED)

# TCL_INCLUDE_PATH is supplied by TclStub package
include_directories (${TCL_INCLUDE_PATH} ${ERLIFACE_INC_DIR})
link_directories (${ERLIFACE_LIB_DIR})

# Tell cmake/make that everything is generated from the cweb sources
set (CWEB_MAIN
	${CMAKE_SOURCE_DIR}/etclface.w
)
set (CWEB_SRCS
	${CWEB_MAIN}
	${CMAKE_SOURCE_DIR}/boilerplate.w
)

# library source, generated from *.w files
set (ETCLFACE_SRC ${CMAKE_BINARY_DIR}/etclface.c)
set_source_files_properties (${ETCLFACE_SRC} PROPERTIES GENERATED TRUE)

# Tcl package index,
# so that the Tcl command "package require etclface" can find the extension
set (PKG_INDEX_SRC "${CMAKE_SOURCE_DIR}/pkgIndex.tcl.in")
set (PKG_INDEX "${CMAKE_BINARY_DIR}/pkgIndex.tcl")
set_source_files_properties (${PKG_INDEX} PROPERTIES GENERATED TRUE)

# documentation source, generated from *.w
set (TEXFILE ${CMAKE_BINARY_DIR}/etclface.tex)
set_source_files_properties (${TEXFILE} PROPERTIES GENERATED TRUE)

# deliverable documentation
set (PDFFILE ${CMAKE_BINARY_DIR}/etclface.pdf)

# cmake needs to know about cweb/TeX intermediate files, for clean up
set (files_to_clean etclface.idx etclface.toc etclface.scn etclface.log)
set_directory_properties (PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${files_to_clean}")

set (CMAKE_SKIP_RPATH TRUE) # No RPATH please!
#
add_definitions (-DUSE_TCL_STUBS)
#
# The following were taken from
# otp_src_R16B/lib/erl_interface/src/eidefs.mk.in
add_definitions (-D_THREAD_SAFE -D_REENTRANT -DPOSIX_THREADS -D_POSIX_THREAD_SAFE_FUNCTIONS)
#
# Create a shared object (libetclface.so)
add_library (etclface SHARED ${ETCLFACE_SRC})
target_link_libraries (etclface ${TCL_STUB_LIBRARY} erl_interface ei pthread)

#
# The C source is generated from the *.w source with the ctangle command
# we need the extra env since normally the build and source directories are different
add_custom_command (
	OUTPUT		${ETCLFACE_SRC}
	COMMAND		env CWEBINPUTS=${CMAKE_SOURCE_DIR} ctangle ${CWEB_MAIN}
	DEPENDS		${CWEB_SRCS}
)

#
# the pdf documentation involves a couple of explicit steps
#
add_custom_target (doc SOURCES ${PDFFILE})
#
# we need the additional env to accomodate out-of-source builds
# Note, the trailing ':' is important
add_custom_command (
	OUTPUT		${PDFFILE}
	MAIN_DEPENDENCY	${TEXFILE}
	COMMAND		env TEXINPUTS=${CMAKE_SOURCE_DIR}: pdftex
	ARGS		${TEXFILE}
)
#
# we need the additional env to accomodate out-of-source builds
add_custom_command (
	OUTPUT		${TEXFILE}
	DEPENDS		${CWEB_SRCS}
	COMMAND		env CWEBINPUTS=${CMAKE_SOURCE_DIR} cweave
	ARGS		${CWEB_MAIN}
)

#
# and finally to install ...
install (
	TARGETS			etclface
	LIBRARY	DESTINATION	lib
)

# pkgIndex.tcl - so that "package require etclface" can find the library
install (
	FILES			${PKG_INDEX}
	DESTINATION		${CMAKE_INSTALL_PREFIX}/lib/tcltk/etclface
)
configure_file (${PKG_INDEX_SRC} ${PKG_INDEX} @ONLY)

