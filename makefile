# is debug?
debug  		:=n
verbose 	:=

#debug   	:=y
#verbose 	:=-v

# prefix
ifeq ($(prefix),) # compatible with brew script (make install PREFIX=xxx DESTDIR=/xxx)
ifeq ($(PREFIX),)
prefix 		:=$(if $(findstring /usr/local/bin,$(PATH)),/usr/local,/usr)
else
prefix 		:=$(PREFIX)
endif
endif

# the temporary directory
ifeq ($(TMPDIR),)
TMP_DIR 	:=$(if $(TMP_DIR),$(TMP_DIR),/tmp)
else
# for termux
TMP_DIR 	:=$(if $(TMP_DIR),$(TMP_DIR),$(TMPDIR))
endif

# platform
PLAT 		:=$(if ${shell uname | egrep -i linux},linux,)
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i darwin},macosx,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i cygwin},cygwin,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i msys},msys,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i mingw},msys,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i windows},windows,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i bsd},bsd,))
PLAT 		:=$(if $(PLAT),$(PLAT),linux)

# architecture
ifeq ($(ARCH),)
ifneq ($(MSYSTEM_CARCH),)
MSYSARCH 	:= $(if $(findstring mingw32,$(shell which gcc)),i386,$(MSYSTEM_CARCH))
else
MSYSARCH 	:= x$(shell getconf LONG_BIT)
endif
ARCH 		:=$(if $(findstring windows,$(PLAT)),x86,$(ARCH))
ARCH 		:=$(if $(findstring msys,$(PLAT)),$(MSYSARCH),$(ARCH))
ARCH 		:=$(if $(findstring cygwin,$(PLAT)),x$(shell getconf LONG_BIT),$(ARCH))
ARCH 		:=$(if $(findstring macosx,$(PLAT)),x$(shell getconf LONG_BIT),$(ARCH))
ARCH 		:=$(if $(findstring linux,$(PLAT)),$(shell uname -m),$(ARCH))
ARCH 		:=$(if $(findstring bsd,$(PLAT)),x$(shell getconf LONG_BIT),$(ARCH))
ARCH 		:=$(if $(findstring iphoneos,$(PLAT)),armv7,$(ARCH))
ARCH 		:=$(if $(findstring android,$(PLAT)),armv7,$(ARCH))
ARCH 		:=$(if $(findstring i686,$(ARCH)),i386,$(ARCH)) # from msys/mingw32
ARCH 		:=$(if $(findstring x32,$(ARCH)),i386,$(ARCH))
ARCH 		:=$(if $(findstring x64,$(ARCH)),x86_64,$(ARCH))

# for arm linux? 
ifeq ($(PLAT),linux)
ifneq ($(TERMUX_ARCH),)
ARCHSTR 	:= $(TERMUX_ARCH) # on termux/ci
else
ARCHSTR 	:= $(shell uname -m) # on arm device, e.g. termux app
endif
ARCH 		:= $(if $(findstring aarch64,$(ARCHSTR)),arm64,$(ARCH))
ARCH 		:= $(if $(findstring arm64,$(ARCHSTR)),arm64,$(ARCH))
ARCH 		:= $(if $(findstring armv7,$(ARCHSTR)),armv7,$(ARCH))
ARCH 		:= $(if $(findstring arm,$(ARCHSTR)),arm,$(ARCH))
ARCH 		:= $(if $(findstring i686,$(ARCHSTR)),i386,$(ARCH)) 
endif
endif

# conditionally map ARCH from amd64 to x86_64 if set from the outside
#
# Some OS provide a definition for $(ARCH) through an environment
# variable. It might be set to amd64 which implies x86_64. Since e.g.
# luajit expects either i386 or x86_64, the value amd64 is transformed
# to match a directory for a platform dependent implementation.
ARCH 		:=$(if $(findstring amd64,$(ARCH)),x86_64,$(ARCH))

# is windows?
iswin =
ifeq ($(PLAT),windows)
	iswin = yes
endif
ifeq ($(PLAT),msys)
	iswin = yes
endif
ifeq ($(PLAT),cygwin)
	iswin = yes
endif

destdir 		    :=$(if $(DESTDIR),$(DESTDIR)/$(prefix),$(prefix))
xmake_dir_install   :=$(destdir)/share/xmake
xmake_core          :=./core/src/demo/demo.b
ifdef iswin
xmake_core_install  :=$(destdir)/bin/xmake.exe
else
xmake_core_install  :=$(destdir)/bin/xmake
endif

tip:
	@echo 'Usage: '
	@echo '    $ make build'
	@echo '    $ sudo make install [PREFIX=/usr/local] [DESTDIR=/xxx]'

build:
	@echo compiling xmake-core ...
	@if [ -f core/.config.mak ]; then rm core/.config.mak; fi
	@$(MAKE) -C core --no-print-directory f DEBUG=$(debug)
	@$(MAKE) -C core --no-print-directory c
	@$(MAKE) -C core --no-print-directory

install:
	@echo installing to $(destdir) ...
	@echo plat: $(PLAT)
	@echo arch: $(ARCH)
	@# create the xmake install directory
	@if [ -d $(xmake_dir_install) ]; then rm -rf $(xmake_dir_install); fi
	@if [ ! -d $(xmake_dir_install) ]; then mkdir -p $(xmake_dir_install); fi
	@# ensure bin directory exists for PKGBUILD/pkg
	@if [ ! -d $(destdir)/bin ]; then mkdir -p $(destdir)/bin; fi
	@# install the xmake directory
	@cp -r xmake/* $(xmake_dir_install)
	@# install the xmake core file
	@cp $(xmake_core) $(xmake_core_install)
	@chmod 777 $(xmake_core_install)
	@# remove xmake.out
	@if [ -f "$(TMP_DIR)/xmake.out" ]; then rm $(TMP_DIR)/xmake.out; fi
	@# ok
	@echo ok!

uninstall:
	@echo uninstalling from $(destdir) ...
	@if [ -d $(xmake_dir_install) ]; then rm -rf $(xmake_dir_install); fi
	@echo ok!

test:
	@xmake lua --verbose tests/run.lua $(name)
	@echo ok!

.PHONY: tip build install uninstall
