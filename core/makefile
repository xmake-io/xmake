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
	@echo "" > /tmp/$(PRO_NAME).out
	@echo make $(PRO_NAME)
	@$(MAKE) --no-print-directory -C $(SRC_DIR) 

# make rebuild
rebuild : .null
	@$(MAKE) c
	$(if $(findstring msys,$(HOST)),,-@$(MAKE) -j4)
	@$(MAKE)
	@$(MAKE) i

# make install
install : .null
	@echo "" > /tmp/$(PRO_NAME).out
	@echo install $(PRO_NAME)
	@$(MAKE) --no-print-directory -C $(SRC_DIR)
	@$(MAKE) --no-print-directory -C $(SRC_DIR) install

# make lipo
lipo : .null
	./tool/lipo $(PRO_NAME) $(DEBUG) $(SDK) $(ARCH1) $(ARCH2)

# make clean
clean : .null
	@echo "" > /tmp/$(PRO_NAME).out
	@echo clean $(PRO_NAME)
	@$(MAKE) --no-print-directory -C $(SRC_DIR) clean

# make update
update : .null
	@echo "" > /tmp/$(PRO_NAME).out
	@echo update $(PRO_NAME)
	@$(MAKE) --no-print-directory -C $(SRC_DIR) update
	@$(MAKE) --no-print-directory -C $(SRC_DIR)
	@$(MAKE) --no-print-directory -C $(SRC_DIR) install

# make output
output : .null
	@echo output $(PRO_NAME)
	@cat /tmp/$(PRO_NAME).out

# make error
error : .null
	@echo error $(PRO_NAME)
	@cat /tmp/$(PRO_NAME).out | egrep -i "error|undefined|cannot|错误" | cat

# make warning
warning : .null
	@echo warning $(PRO_NAME)
	@cat /tmp/$(PRO_NAME).out | egrep warning

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
HOST 		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i linux},linux,))
HOST 		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i darwin},mac,))
HOST 		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i cygwin},cygwin,))
HOST 		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i mingw},msys,))
HOST 		:=$(if $(HOST),$(HOST),$(if ${shell uname | egrep -i msvc},msys,))
HOST 		:=$(if $(HOST),$(HOST),linux)

# platform
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i linux},linux,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i darwin},mac,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i cygwin},cygwin,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i mingw},mingw,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i msvc},msvc,))
PLAT 		:=$(if $(PLAT),$(PLAT),linux)

# architecture
ifeq ($(ARCH),)

ARCH 		:=$(if $(findstring msvc,$(PLAT)),x86,$(ARCH))
ARCH 		:=$(if $(findstring mingw,$(PLAT)),x86,$(ARCH))
ARCH 		:=$(if $(findstring mac,$(PLAT)),x$(shell getconf LONG_BIT),$(ARCH))
ARCH 		:=$(if $(findstring linux,$(PLAT)),x$(shell getconf LONG_BIT),$(ARCH))
ARCH 		:=$(if $(findstring x32,$(ARCH)),x86,$(ARCH))
ARCH 		:=$(if $(findstring ios,$(PLAT)),armv7,$(ARCH))
ARCH 		:=$(if $(findstring android,$(PLAT)),armv7,$(ARCH))

endif

# debug
DEBUG 		:=$(if $(DEBUG),$(DEBUG),y)

# debug type
DTYPE 		:=$(if $(findstring y,$(DEBUG)),d,r)

# small
SMALL 		:=$(if $(SMALL),$(SMALL),n)
SMALL 		:=$(if $(findstring ios,$(PLAT)),y,$(SMALL))
SMALL 		:=$(if $(findstring android,$(PLAT)),y,$(SMALL))

# demo
DEMO 		:=$(if $(DEMO),$(DEMO),y)

# profile
PROF 		:=$(if $(PROF),$(PROF),n)

# arm
ARM 		:=$(if $(findstring arm,$(ARCH)),y,n)

# x86
x86 		:=$(if $(findstring x86,$(ARCH)),y,n)

# x64
x64 		:=$(if $(findstring x64,$(ARCH)),y,n)

# sh4
SH4 		:=$(if $(findstring sh4,$(ARCH)),y,n)

# mips
MIPS 		:=$(if $(findstring mips,$(ARCH)),y,n)

# sparc
SPARC 		:=$(if $(findstring sparc,$(ARCH)),y,n)

# the project directory
PRO_DIR		:=$(abspath .)

# the package directory
PKG_DIR 	:= $(if $(PACKAGE),$(PACKAGE),$(PRO_DIR)/pkg)

# the tool directory
TOOL_DIR 	:= $(PRO_DIR)/tool

# flag
CXFLAG		:= $(if $(CXFLAG),$(CXFLAG),)

# ccache
ifeq ($(CCACHE),n)
CCACHE		:= 
else
CCACHE		:=$(shell if [ -f "/usr/bin/ccache" ]; then echo "ccache"; elif [ -f "/usr/local/bin/ccache" ]; then echo "ccache"; else echo ""; fi )
endif

# distcc
ifeq ($(DISTCC),y)
DISTCC		:=$(shell if [ -f "/usr/bin/distcc" ]; then echo "distcc"; elif [ -f "/usr/local/bin/distcc" ]; then echo "distcc"; else echo ""; fi )
else
DISTCC		:= 
endif

# sed
ifeq ($(HOST),mac)
#SED			:= sed -i ''
SED			:= perl -pi -e
else
SED			:= sed -i
endif

# echo
ifeq ($(HOST),msys)
ECHO 		:= echo -e
else
ECHO 		:= echo
endif

# make upper 
ifeq ($(HOST),mac)
define MAKE_UPPER
${shell echo $(1) | perl -p -e "s/(.*)/\U\1/g"}
endef
else
define MAKE_UPPER
${shell echo $(1) | sed "s/\(.*\)/\U\1/g"}
endef
endif

# select package directory
ifneq ($(PACKAGE),)
PKG_DIR 	:= $(PACKAGE)
endif

# make upper package name
define MAKE_UPPER_PACKAGE_NAME
$(1)_upper 	:= $(call MAKE_UPPER,$(1))
endef
$(foreach name, $(PKG_NAMES), $(eval $(call MAKE_UPPER_PACKAGE_NAME,$(name))))

# probe packages
define PROBE_PACKAGE
$($(1)_upper) :=$(if $($($(1)_upper)),$($($(1)_upper)),\
				$(shell if [ -d "$(PKG_DIR)/$(1).pkg/lib/$(PLAT)/$(ARCH)" ]; then \
					echo "y"; \
				elif [ -z "`$(TOOL_DIR)/jcat/jcat --filter=.compiler.$(PLAT).$(ARCH).$(if $(findstring y,$(DEBUG)),debug,release) $(PKG_DIR)/$(1).pkg/manifest.json`" ]; then \
					echo "n"; \
				else \
					echo "y"; \
				fi ))
endef
$(foreach name, $(PKG_NAMES), $(eval $(call PROBE_PACKAGE,$(name))))

# make package info
define MAKE_PACKAGE_INFO
"   "$(1)":\t\t"$($($(1)_upper))"\n"
endef
define MAKE_PACKAGE_INFO_
$(if $(findstring y,$($(1))),__autoconf_head_$(PRO_PREFIX)CONFIG_PACKAGE_HAVE_$(1)_autoconf_tail__,)
endef

# load package options
define LOAD_PACKAGE_OPTIONS
$(if $(findstring y,$($($(1)_upper))),\
	"$($(1)_upper) ="$($($(1)_upper))"\n" \
	"$(1)_INCPATH ="$(shell echo `$(TOOL_DIR)/jcat/jcat --filter=.compiler.$(PLAT).$(ARCH).$(if $(findstring y,$(DEBUG)),debug,release).incpath $(PKG_DIR)/$(1).pkg/manifest.json` )"\n" \
	"$(1)_LIBPATH ="$(shell echo `$(TOOL_DIR)/jcat/jcat --filter=.compiler.$(PLAT).$(ARCH).$(if $(findstring y,$(DEBUG)),debug,release).libpath $(PKG_DIR)/$(1).pkg/manifest.json` )"\n" \
	"$(1)_INCFLAGS ="$(shell echo `$(TOOL_DIR)/jcat/jcat --filter=.compiler.$(PLAT).$(ARCH).$(if $(findstring y,$(DEBUG)),debug,release).incflags $(PKG_DIR)/$(1).pkg/manifest.json` )"\n" \
	"$(1)_LIBFLAGS ="$(shell echo `$(TOOL_DIR)/jcat/jcat --filter=.compiler.$(PLAT).$(ARCH).$(if $(findstring y,$(DEBUG)),debug,release).libflags $(PKG_DIR)/$(1).pkg/manifest.json` )"\n" \
	"$(1)_LIBNAMES ="$(shell if [ -f $(PKG_DIR)/$(1).pkg/manifest.json ]; then echo `$(TOOL_DIR)/jcat/jcat --filter=.compiler.$(PLAT).$(ARCH).$(if $(findstring y,$(DEBUG)),debug,release).libs $(PKG_DIR)/$(1).pkg/manifest.json`; else echo $(1)$(DTYPE); fi)"\n" \
	"export "$($(1)_upper)"\n" \
	"export "$(1)_INCPATH"\n" \
	"export "$(1)_LIBPATH"\n" \
	"export "$(1)_LIBNAMES"\n" \
	"export "$(1)_INCFLAGS"\n" \
	"export "$(1)_LIBFLAGS"\n\n" \
,\
	"$($(1)_upper) ="$($($(1)_upper))"\n" \
	"export "$($(1)_upper)"\n\n")
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
	@$(ECHO) "    plat:\t\t"$(PLAT)
	@$(ECHO) "    arch:\t\t"$(ARCH)
	@$(ECHO) "    host:\t\t"$(HOST)
	@$(ECHO) "    demo:\t\t"$(DEMO)
	@$(ECHO) "    prof:\t\t"$(PROF)
	@$(ECHO) "    debug:\t\t"$(DEBUG)
	@$(ECHO) "    small:\t\t"$(SMALL)
	@$(ECHO) "    ccache:\t\t"$(CCACHE)
	@$(ECHO) "    distcc:\t\t"$(DISTCC)
	@$(ECHO) ""
	@$(ECHO) "packages:"
	@$(ECHO) ""$(foreach name, $(PKG_NAMES), $(call MAKE_PACKAGE_INFO,$(name)))
	@$(ECHO) ""
	@$(ECHO) "directories:"
	@$(ECHO) "    install:\t\t"$(abspath $(INSTALL))
	@$(ECHO) "    package:\t\t"$(PACKAGE)
	@$(ECHO) ""
	@$(ECHO) "toolchains:"
	@$(ECHO) "    bin:\t\t"$(BIN)
	@$(ECHO) "    pre:\t\t"$(PRE)
	@$(ECHO) "    sdk:\t\t"$(SDK)
	@$(ECHO) ""
	@$(ECHO) "flags:"
	@$(ECHO) "    cflag:\t\t"$(CFLAG)
	@$(ECHO) "    ccflag:\t\t"$(CCFLAG)
	@$(ECHO) "    cxflag:\t\t"$(CXFLAG)
	@$(ECHO) "    mflag:\t\t"$(MFLAG)
	@$(ECHO) "    mmflag:\t\t"$(MMFLAG)
	@$(ECHO) "    mxflag:\t\t"$(MXFLAG)
	@$(ECHO) "    ldflag:\t\t"$(LDFLAG)
	@$(ECHO) "    asflag:\t\t"$(ASFLAG)
	@$(ECHO) "    arflag:\t\t"$(ARFLAG)
	@$(ECHO) "    shflag:\t\t"$(SHFLAG)
	@$(ECHO) ""
	@$(ECHO) "# config"									> .config.mak
	@$(ECHO) "IS_CONFIG =y"								>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# project"								>> .config.mak
	@$(ECHO) "PRO_DIR ="$(PRO_DIR)						>> .config.mak
	@$(ECHO) "export PRO_DIR"							>> .config.mak
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
	@$(ECHO) ""$(call MAKE_UPPER,$(PLAT))" =y" 			>> .config.mak
	@$(ECHO) "export PLAT"								>> .config.mak
	@$(ECHO) "export "$(call MAKE_UPPER,$(PLAT)) 		>> .config.mak
	@$(ECHO) ""											>> .config.mak
	@$(ECHO) "# architecture"							>> .config.mak
	@$(ECHO) "ARCH ="$(ARCH)							>> .config.mak
	@$(ECHO) "ARM ="$(ARM)								>> .config.mak
	@$(ECHO) "x86 ="$(x86)								>> .config.mak
	@$(ECHO) "x64 ="$(x64)								>> .config.mak
	@$(ECHO) "SH4 ="$(SH4)								>> .config.mak
	@$(ECHO) "MIPS ="$(MIPS)							>> .config.mak
	@$(ECHO) "SPARC ="$(SPARC)							>> .config.mak
	@$(ECHO) "export ARCH"								>> .config.mak
	@$(ECHO) "export ARM"								>> .config.mak
	@$(ECHO) "export x86"								>> .config.mak
	@$(ECHO) "export x64"								>> .config.mak
	@$(ECHO) "export SH4"								>> .config.mak
	@$(ECHO) "export MIPS"								>> .config.mak
	@$(ECHO) "export SPARC"								>> .config.mak
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
	@$(ECHO) $(foreach name, $(PKG_NAMES), $(call LOAD_PACKAGE_OPTIONS,$(name))) >> .config.mak

# ######################################################################################
# help
# #

# make help
help : .null
	@cat $(PRO_DIR)/INSTALL

