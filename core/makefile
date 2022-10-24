# main makefile

# ######################################################################################
# includes
# #
${shell if [ ! -f ".config.mak" ]; then touch .config.mak; fi }
include .config.mak

# ######################################################################################
# make shortcut
# #
a : all
f : config
r : rebuild
i : install
c : clean
u : update
o : output
e : error
w : warning
d : doc
h : help

# ######################################################################################
# make projects
# #
ifeq ($(IS_CONFIG), y)

# include prefix
include prefix.mak

# select install path
ifneq ($(INSTALL),)
BIN_DIR := $(INSTALL)
endif

# make all
all : .null
	@echo "" > $(TMP_DIR)/$(PRO_NAME).out
	@echo make $(PRO_NAME)
	+@$(MAKE) --no-print-directory -C $(SRC_DIR) || cat $(TMP_DIR)/$(PRO_NAME).out

# make rebuild
rebuild : .null
	+@$(MAKE) c
	+@$(MAKE)
	+@$(MAKE) i

# make install
install : .null
	@echo "" > $(TMP_DIR)/$(PRO_NAME).out
	@echo install $(PRO_NAME)
	+@$(MAKE) --no-print-directory -C $(SRC_DIR)
	+@$(MAKE) --no-print-directory -C $(SRC_DIR) install

# make clean
clean : .null
	@echo "" > $(TMP_DIR)/$(PRO_NAME).out
	@echo clean $(PRO_NAME)
	+@$(MAKE) --no-print-directory -C $(SRC_DIR) clean

# make output
output : .null
	@echo output $(PRO_NAME)
	@cat $(TMP_DIR)/$(PRO_NAME).out

# make error
error : .null
	@echo error $(PRO_NAME)
	@cat $(TMP_DIR)/$(PRO_NAME).out | egrep -i "error|undefined|cannot|错误" | cat

# make warning
warning : .null
	@echo warning $(PRO_NAME)
	@cat $(TMP_DIR)/$(PRO_NAME).out | egrep warning

# make doc
doc : .null
	doxygen ./doc/doxygen/doxygen.conf

else

# include project
include project.mak

# ######################################################################################
# no-config
# #
all :
	make -r f
	make -r r

rebuild :
	make -r f
	make -r r

install :
	make -r f
	make -r i

lipo : help
clean :
	make -r f
	make -r c

update :
	make -r f
	make -r u

output :
error :
warning :
doc :
	make -r f
	make -r d

endif

# ######################################################################################
# null
# #

.null :

# ######################################################################################
# config
# #

# host
HOST		:=$(if ${shell uname | egrep -i linux},linux,)
HOST		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i darwin},macosx,))
HOST		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i cygwin},cygwin,))
HOST		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i msys},msys,))
HOST		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i mingw},msys,))
HOST		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i windows},msys,))
HOST		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i bsd},bsd,))
HOST		:=$(if $(HOST),$(HOST),linux)

# platform
PLAT		:=$(if ${shell uname | egrep -i linux},linux,)
PLAT		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i darwin},macosx,))
PLAT		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i cygwin},cygwin,))
PLAT		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i msys},msys,))
PLAT		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i mingw},msys,))
PLAT		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i windows},windows,))
PLAT		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i bsd},bsd,))
PLAT		:=$(if $(PLAT),$(PLAT),linux)

# architecture
ifeq ($(BUILD_ARCH),)
ifneq ($(MSYSTEM_CARCH),)
MSYSARCH	:= $(if $(findstring mingw32,$(shell which gcc)),i386,$(MSYSTEM_CARCH))
else
MSYSARCH	:= x$(shell getconf LONG_BIT)
endif
BUILD_ARCH	:=$(if $(findstring windows,$(PLAT)),x86,$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring msys,$(PLAT)),$(MSYSARCH),$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring cygwin,$(PLAT)),x$(shell getconf LONG_BIT),$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring macosx,$(PLAT)),$(shell uname -m),$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring linux,$(PLAT)),$(shell uname -m),$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring bsd,$(PLAT)),x$(shell getconf LONG_BIT),$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring iphoneos,$(PLAT)),arm64,$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring android,$(PLAT)),armv7,$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring i686,$(BUILD_ARCH)),i386,$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring x32,$(BUILD_ARCH)),i386,$(BUILD_ARCH))
BUILD_ARCH	:=$(if $(findstring x64,$(BUILD_ARCH)),x86_64,$(BUILD_ARCH))

# on termux/ci
ifneq ($(TERMUX_ARCH),)
BUILD_ARCH	:= $(TERMUX_ARCH)
endif
endif

# translate architecture, e.g. armhf/armv7l -> arm, arm64-v8a -> arm64
BUILD_ARCH	:= $(if $(findstring aarch64,$(BUILD_ARCH)),arm64,$(BUILD_ARCH))
BUILD_ARCH	:= $(if $(findstring arm64,$(BUILD_ARCH)),arm64,$(BUILD_ARCH))
ifneq ($(BUILD_ARCH),arm64)
BUILD_ARCH	:= $(if $(findstring arm,$(BUILD_ARCH)),arm,$(BUILD_ARCH))
endif
BUILD_ARCH	:= $(if $(findstring i686,$(BUILD_ARCH)),i386,$(BUILD_ARCH))

# debug
DEBUG		:=$(if $(DEBUG),$(DEBUG),n)

# debug type
DTYPE		:=$(if $(findstring y,$(DEBUG)),d,r)

# small
SMALL		:=$(if $(SMALL),$(SMALL),n)
SMALL		:=$(if $(findstring iphoneos,$(PLAT)),y,$(SMALL))
SMALL		:=$(if $(findstring android,$(PLAT)),y,$(SMALL))

# demo
DEMO		:=$(if $(DEMO),$(DEMO),y)

# profile
PROF		:=$(if $(PROF),$(PROF),n)

# arm
ARM			:=$(if $(findstring arm,$(BUILD_ARCH)),y,n)

# x86
x86			:=$(if $(findstring i386,$(BUILD_ARCH)),y,n)

# x64
x64			:=$(if $(findstring x86_64,$(BUILD_ARCH)),y,n)

# sh4
SH4			:=$(if $(findstring sh4,$(BUILD_ARCH)),y,n)

# mips
MIPS		:=$(if $(findstring mips,$(BUILD_ARCH)),y,n)

# sparc
SPARC		:=$(if $(findstring sparc,$(BUILD_ARCH)),y,n)

# the project directory
PRO_DIR		:=$(abspath .)

# the package directory
PKG_DIR		:= $(if $(PACKAGE),$(PACKAGE),$(PRO_DIR)/pkg)

# the tool directory
TOOL_DIR	:= $(PRO_DIR)/tool

# flag
CXFLAG		:= $(if $(CXFLAG),$(CXFLAG),)

# ccache
CCACHE		:=
DISTCC		:=

# sed
ifeq ($(HOST),macosx)
SED			:= perl -pi -e
SEDX		:= perl -p -e
else
ifeq ($(HOST),bsd)
SED			:= perl -pi -e
SEDX		:= perl -p -e
else
SED			:= sed -i
SEDX		:= sed
endif
endif

# echo
ifeq ($(HOST),macosx)
SHELL		= bash
endif
ifeq ($(HOST),linux)
SHELL		= bash
endif
ifeq ($(HOST),bsd)
SHELL		= bash
endif
ECHO		:= echo -e

# make upper
define MAKE_UPPER
${shell echo $(1) | $(SEDX) "s/\(.*\)/\U\1/g"}
endef

# config base
ifeq ($(PLAT),macosx)
base_LIBPATH	:= /usr/local/lib
base_LIBNAMES	:= curses readline m dl pthread
endif

ifeq ($(PLAT),windows)
base_LIBPATH	:=
base_LIBNAMES	:= ws2_32
endif

ifeq ($(PLAT),linux)
base_LIBPATH	:=
base_LIBNAMES	:=
base_LIBNAMES	+= $(shell if { cat detect/curses.c | $(CC) -xc - -lcurses -ltinfo -o /dev/null 2>/dev/null; }; then echo curses tinfo; fi )
base_LIBNAMES	+= $(shell if { cat detect/readline.c | $(CC) -xc - -lreadline -o /dev/null 2>/dev/null; }; then echo readline; fi )
base_LIBNAMES	+= $(shell if { cat detect/tbox.c | $(CC) -xc - -ltbox -o /dev/null 2>/dev/null; }; then echo tbox; fi )
base_LIBNAMES	+= $(shell if { cat detect/lua-cjson.c | $(CC) -xc - -llua5.1-cjson -lluajit-5.1 -o /dev/null 2>/dev/null; }; then echo lua5.1-cjson; fi )
base_LIBNAMES	+= $(shell if { cat detect/sv.c | $(CC) -xc - -lsv -o /dev/null 2>/dev/null; }; then echo sv; fi )
ifeq ($(LUAJIT_SYSTEM),y)
base_LIBNAMES	+= $(shell if { cat detect/luajit.c | $(CC) -xc - $(shell pkg-config --libs --cflags luajit) -o /dev/null 2>/dev/null; }; then echo luajit-5.1; fi )
endif
ifneq ($(TERMUX_ARCH),) # on termux/ci?
base_LIBNAMES	+= m dl
else
base_LIBNAMES	+= m dl pthread
endif
endif

ifeq ($(PLAT),bsd)
base_LIBPATH	:=
base_LIBNAMES	:=
base_LIBNAMES	+= $(shell if { cat detect/curses.c | $(CC) -xc - -lcurses -ltinfo -o /dev/null 2>/dev/null; }; then echo curses tinfo; fi )
base_LIBNAMES	+= $(shell if { cat detect/readline.c | $(CC) -xc - -lreadline -o /dev/null 2>/dev/null; }; then echo readline; fi )
base_LIBNAMES	+= m pthread
endif

# get branch and commit
ifeq ($(BRANCH),)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
endif
ifeq ($(COMMIT),)
COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null)
endif

# check jit compiler
ifeq ($(PLAT),linux)
luajit_JIT :=$(shell if [ -f "/etc/redhat-release" ]; then echo "nojit"; else echo "jit"; fi )
ifeq ($(BUILD_ARCH),mips64) # maybe it is not very stable yet, we need to disable it
luajit_JIT :=nojit
endif
else
luajit_JIT :=jit
endif
ifeq ($(PLAT),iphoneos)
luajit_JIT :=nojit
endif

# select package directory
ifneq ($(PACKAGE),)
PKG_DIR		:= $(PACKAGE)
endif

# make upper package name
define MAKE_UPPER_PACKAGE_NAME
$(1)_upper	:= $(call MAKE_UPPER,$(1))
endef
$(foreach name, $(PKG_NAMES), $(eval $(call MAKE_UPPER_PACKAGE_NAME,$(name))))

# probe packages
define PROBE_PACKAGE
$($(1)_upper) :=y
endef
$(foreach name, $(PKG_NAMES), $(eval $(call PROBE_PACKAGE,$(name))))

# make package info
define MAKE_PACKAGE_INFO
"	"$(1)":\t\t"$($($(1)_upper))"\n"
endef
define MAKE_PACKAGE_INFO_
$(if $(findstring y,$($(1))),__autoconf_head_$(PRO_PREFIX)CONFIG_PACKAGE_HAVE_$(1)_autoconf_tail__,)
endef

# config
config : .null
	-@cp $(PRO_DIR)/plat/$(PLAT)/config.h $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/\[major\]/$(PRO_VERSION_MAJOR)/g" $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/\[minor\]/$(PRO_VERSION_MINOR)/g" $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/\[alter\]/$(PRO_VERSION_ALTER)/g" $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/\[build\]/`date +%Y%m%d%H%M`/g" $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/\[debug\]/\($(if $(findstring y,$(DEBUG)),1,0)\)/g" $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/\[small\]/\($(if $(findstring y,$(SMALL)),1,0)\)/g" $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/\/\/.*\[packages\]/$(foreach name, $(PKG_NAMES), $(call MAKE_PACKAGE_INFO_,$($(name)_upper)))/g" $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/__autoconf_head_/\#define /g" $(PRO_DIR)/$(PRO_NAME).config.h
	-@$(SED) "s/_autoconf_tail__\s*/\n/g" $(PRO_DIR)/$(PRO_NAME).config.h
	@$(ECHO) ""
	@$(ECHO) "============================================================================="
	@$(ECHO) "compile:"
	@$(ECHO) "	  plat:\t\t"$(PLAT)
	@$(ECHO) "	  arch:\t\t"$(BUILD_ARCH)
	@$(ECHO) "	  host:\t\t"$(HOST)
	@$(ECHO) "	  demo:\t\t"$(DEMO)
	@$(ECHO) "	  prof:\t\t"$(PROF)
	@$(ECHO) "	  debug:\t\t"$(DEBUG)
	@$(ECHO) "	  small:\t\t"$(SMALL)
	@$(ECHO) "	  ccache:\t\t"$(CCACHE)
	@$(ECHO) "	  distcc:\t\t"$(DISTCC)
	@$(ECHO) "	  branch:\t\t"$(BRANCH)
	@$(ECHO) "	  commit:\t\t"$(COMMIT)
	@$(ECHO) "	  luajit:\t\t"$(luajit_JIT)
	@$(ECHO) ""
	@$(ECHO) "packages:"
	@$(ECHO) ""$(foreach name, $(PKG_NAMES), $(call MAKE_PACKAGE_INFO,$(name)))
	@$(ECHO) ""
	@$(ECHO) "directories:"
	@$(ECHO) "	  install:\t\t"$(abspath $(INSTALL))
	@$(ECHO) "	  package:\t\t"$(PACKAGE)
	@$(ECHO) "	  backend:\t\t"$(RUNTIME)
	@$(ECHO) ""
	@$(ECHO) "toolchains:"
	@$(ECHO) "	  bin:\t\t"$(BIN)
	@$(ECHO) "	  pre:\t\t"$(PRE)
	@$(ECHO) "	  sdk:\t\t"$(SDK)
	@$(ECHO) ""
	@$(ECHO) "flags:"
	@$(ECHO) "	  cflag:\t\t"$(CFLAG)
	@$(ECHO) "	  ccflag:\t\t"$(CCFLAG)
	@$(ECHO) "	  cxflag:\t\t"$(CXFLAG)
	@$(ECHO) "	  mflag:\t\t"$(MFLAG)
	@$(ECHO) "	  mmflag:\t\t"$(MMFLAG)
	@$(ECHO) "	  mxflag:\t\t"$(MXFLAG)
	@$(ECHO) "	  ldflag:\t\t"$(LDFLAG)
	@$(ECHO) "	  asflag:\t\t"$(ASFLAG)
	@$(ECHO) "	  arflag:\t\t"$(ARFLAG)
	@$(ECHO) "	  shflag:\t\t"$(SHFLAG)
	@$(ECHO) ""
	@$(ECHO) "# config"									> .config.mak
	@$(ECHO) "IS_CONFIG =y"								>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# project"								>> .config.mak
	@$(ECHO) "PRO_DIR ="$(PRO_DIR)						>> .config.mak
	@$(ECHO) "export PRO_DIR"							>> .config.mak
	@$(ECHO) "BRANCH ="$(BRANCH)						>> .config.mak
	@$(ECHO) "export BRANCH"							>> .config.mak
	@$(ECHO) "COMMIT ="$(COMMIT)						>> .config.mak
	@$(ECHO) "export COMMIT"							>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# profile"								>> .config.mak
	@$(ECHO) "PROF ="$(PROF)							>> .config.mak
	@$(ECHO) "export PROF"								>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# debug"									>> .config.mak
	@$(ECHO) "DEBUG ="$(DEBUG)							>> .config.mak
	@$(ECHO) "DTYPE ="$(DTYPE)							>> .config.mak
	@$(ECHO) "export DEBUG"								>> .config.mak
	@$(ECHO) "export DTYPE"								>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# small"									>> .config.mak
	@$(ECHO) "SMALL ="$(SMALL)							>> .config.mak
	@$(ECHO) "export SMALL"								>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# host"									>> .config.mak
	@$(ECHO) "HOST ="$(HOST)							>> .config.mak
	@$(ECHO) "export HOST"								>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# install"								>> .config.mak
	@$(ECHO) "INSTALL ="$(abspath $(INSTALL))			>> .config.mak
	@$(ECHO) "export INSTALL"							>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# flags"									>> .config.mak
	@$(ECHO) "CFLAG ="$(CFLAG)							>> .config.mak
	@$(ECHO) "CCFLAG ="$(CCFLAG)						>> .config.mak
	@$(ECHO) "CXFLAG ="$(CXFLAG)						>> .config.mak
	@$(ECHO) "MFLAG ="$(MFLAG)							>> .config.mak
	@$(ECHO) "MMFLAG ="$(MMFLAG)						>> .config.mak
	@$(ECHO) "MXFLAG ="$(MXFLAG)						>> .config.mak
	@$(ECHO) "LDFLAG ="$(LDFLAG)						>> .config.mak
	@$(ECHO) "ASFLAG ="$(ASFLAG)						>> .config.mak
	@$(ECHO) "ARFLAG ="$(ARFLAG)						>> .config.mak
	@$(ECHO) "SHFLAG ="$(SHFLAG)						>> .config.mak
	@$(ECHO) "export CFLAG"								>> .config.mak
	@$(ECHO) "export CCFLAG"							>> .config.mak
	@$(ECHO) "export CXFLAG"							>> .config.mak
	@$(ECHO) "export MFLAG"								>> .config.mak
	@$(ECHO) "export MMFLAG"							>> .config.mak
	@$(ECHO) "export MXFLAG"							>> .config.mak
	@$(ECHO) "export LDFLAG"							>> .config.mak
	@$(ECHO) "export ASFLAG"							>> .config.mak
	@$(ECHO) "export ARFLAG"							>> .config.mak
	@$(ECHO) "export SHFLAG"							>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# platform"								>> .config.mak
	@$(ECHO) "PLAT ="$(PLAT)							>> .config.mak
	@$(ECHO) ""$(call MAKE_UPPER,$(PLAT))" =y"			>> .config.mak
	@$(ECHO) "export PLAT"								>> .config.mak
	@$(ECHO) "export "$(call MAKE_UPPER,$(PLAT))		>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# architecture"							>> .config.mak
	@$(ECHO) "BUILD_ARCH ="$(BUILD_ARCH)				>> .config.mak
	@$(ECHO) "ARM ="$(ARM)								>> .config.mak
	@$(ECHO) "x86 ="$(x86)								>> .config.mak
	@$(ECHO) "x64 ="$(x64)								>> .config.mak
	@$(ECHO) "SH4 ="$(SH4)								>> .config.mak
	@$(ECHO) "MIPS ="$(MIPS)							>> .config.mak
	@$(ECHO) "SPARC ="$(SPARC)							>> .config.mak
	@$(ECHO) "export BUILD_ARCH"						>> .config.mak
	@$(ECHO) "export ARM"								>> .config.mak
	@$(ECHO) "export x86"								>> .config.mak
	@$(ECHO) "export x64"								>> .config.mak
	@$(ECHO) "export SH4"								>> .config.mak
	@$(ECHO) "export MIPS"								>> .config.mak
	@$(ECHO) "export SPARC"								>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# backend"								>> .config.mak
	@$(ECHO) "RUNTIME ="$(RUNTIME)						>> .config.mak
	@$(ECHO) "export RUNTIME"							>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# demo"									>> .config.mak
	@$(ECHO) "DEMO ="$(DEMO)							>> .config.mak
	@$(ECHO) "export DEMO"								>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# toolchain"								>> .config.mak
	@$(ECHO) "SDK ="$(SDK)								>> .config.mak
	@$(ECHO) "BIN ="$(BIN)								>> .config.mak
	@$(ECHO) "PRE ="$(PRE)								>> .config.mak
	@$(ECHO) "CCACHE ="$(CCACHE)						>> .config.mak
	@$(ECHO) "DISTCC ="$(DISTCC)						>> .config.mak
	@$(ECHO) "export SDK"								>> .config.mak
	@$(ECHO) "export BIN"								>> .config.mak
	@$(ECHO) "export PRE"								>> .config.mak
	@$(ECHO) "export CCACHE"							>> .config.mak
	@$(ECHO) "export DISTCC"							>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# packages"								>> .config.mak
	@$(ECHO) "PACKAGE ="$(PACKAGE)						>> .config.mak
	@$(ECHO) "PKG_DIR ="$(PKG_DIR)						>> .config.mak
	@$(ECHO) "export PACKAGE"							>> .config.mak
	@$(ECHO) "export PKG_DIR"							>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "TBOX =y"									>> .config.mak
	@$(ECHO) "tbox_INCPATH ="							>> .config.mak
	@$(ECHO) "tbox_LIBPATH ="							>> .config.mak
	@$(ECHO) "tbox_INCFLAGS ="							>> .config.mak
	@$(ECHO) "tbox_LIBFLAGS ="							>> .config.mak
	@$(ECHO) "tbox_LIBNAMES =tbox"						>> .config.mak
	@$(ECHO) "export TBOX"								>> .config.mak
	@$(ECHO) "export tbox_INCPATH"						>> .config.mak
	@$(ECHO) "export tbox_LIBPATH"						>> .config.mak
	@$(ECHO) "export tbox_LIBNAMES"						>> .config.mak
	@$(ECHO) "export tbox_INCFLAGS"						>> .config.mak
	@$(ECHO) "export tbox_LIBFLAGS"						>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "BASE =y"									>> .config.mak
	@$(ECHO) "base_INCPATH ="							>> .config.mak
	@$(ECHO) "base_LIBPATH =$(base_LIBPATH)"			>> .config.mak
	@$(ECHO) "base_INCFLAGS ="							>> .config.mak
	@$(ECHO) "base_LIBFLAGS ="							>> .config.mak
	@$(ECHO) "base_LIBNAMES =$(base_LIBNAMES)"			>> .config.mak
	@$(ECHO) "export BASE"								>> .config.mak
	@$(ECHO) "export base_INCPATH"						>> .config.mak
	@$(ECHO) "export base_LIBPATH"						>> .config.mak
	@$(ECHO) "export base_LIBNAMES"						>> .config.mak
	@$(ECHO) "export base_INCFLAGS"						>> .config.mak
	@$(ECHO) "export base_LIBFLAGS"						>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "luajit_JIT =$(luajit_JIT)"				>> .config.mak
	@$(ECHO) "export luajit_JIT"						>> .config.mak

# ######################################################################################
# help
# #

# make help
help : .null
	@cat $(PRO_DIR)/INSTALL

