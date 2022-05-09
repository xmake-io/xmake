# is debug?
debug  		:=n

# verbose
ifneq ($(VERBOSE),y)
VECHO = @
endif

# prefix
ifeq ($(prefix),) # compatible with brew script (make install PREFIX=xxx DESTDIR=/xxx)
ifeq ($(PREFIX),)
prefix 		:=$(if $(findstring /usr/local/bin,$(PATH)),/usr/local,/usr)
else
prefix 		:=$(PREFIX)
endif
endif

# use luajit or lua backend
ifeq ($(RUNTIME),)
RUNTIME 	:=lua
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
ifeq ($(BUILD_ARCH),)
ifneq ($(MSYSTEM_CARCH),)
MSYSARCH 	:= $(if $(findstring mingw32,$(shell which gcc)),i386,$(MSYSTEM_CARCH))
else
MSYSARCH 	:= x$(shell getconf LONG_BIT)
endif
BUILD_ARCH 	:=$(if $(findstring windows,$(PLAT)),x86,$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring msys,$(PLAT)),$(MSYSARCH),$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring cygwin,$(PLAT)),x$(shell getconf LONG_BIT),$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring macosx,$(PLAT)),$(shell uname -m),$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring linux,$(PLAT)),$(shell uname -m),$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring bsd,$(PLAT)),x$(shell getconf LONG_BIT),$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring iphoneos,$(PLAT)),arm64,$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring android,$(PLAT)),armv7,$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring i686,$(BUILD_ARCH)),i386,$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring x32,$(BUILD_ARCH)),i386,$(BUILD_ARCH))
BUILD_ARCH 	:=$(if $(findstring x64,$(BUILD_ARCH)),x86_64,$(BUILD_ARCH))

# on termux/ci
ifneq ($(TERMUX_ARCH),)
BUILD_ARCH 	:= $(TERMUX_ARCH)
endif
endif

# translate architecture, e.g. armhf/armv7l -> arm, arm64-v8a -> arm64
BUILD_ARCH 	:= $(if $(findstring aarch64,$(BUILD_ARCH)),arm64,$(BUILD_ARCH))
BUILD_ARCH 	:= $(if $(findstring arm64,$(BUILD_ARCH)),arm64,$(BUILD_ARCH))
ifneq ($(BUILD_ARCH),arm64)
BUILD_ARCH 	:= $(if $(findstring arm,$(BUILD_ARCH)),arm,$(BUILD_ARCH))
endif
BUILD_ARCH 	:= $(if $(findstring i686,$(BUILD_ARCH)),i386,$(BUILD_ARCH))

# is windows?
iswin =
ifeq ($(PLAT),windows)
	iswin = yes
endif
ifeq ($(PLAT),msys)
	iswin = yes
endif
ifeq ($(PLAT),mingw)
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
xrepo_bin_install   :=$(destdir)/bin/xrepo

build:
	@echo compiling xmake-core ...
	@if [ -f core/.config.mak ]; then rm core/.config.mak; fi
	+@$(MAKE) -C core --no-print-directory f DEBUG=$(debug) RUNTIME=$(RUNTIME)
	+@$(MAKE) -C core --no-print-directory c
	+@$(MAKE) -C core --no-print-directory

clean:
	+@$(MAKE) -C core --no-print-directory c

install:
	@echo installing to $(destdir) ...
	@echo plat: $(PLAT)
	@echo arch: $(BUILD_ARCH)
	@# create the xmake install directory
	@if [ -d $(xmake_dir_install) ]; then rm -rf $(xmake_dir_install); fi
	@if [ ! -d $(xmake_dir_install) ]; then mkdir -p $(xmake_dir_install); fi
	@# ensure bin directory exists for PKGBUILD/pkg
	@if [ ! -d $(destdir)/bin ]; then mkdir -p $(destdir)/bin; fi
	@# install the xmake directory
	@cp -r xmake/* $(xmake_dir_install)
	@# install the xmake core file, @note we need remove old binary first on mac M1, otherwise it will be killed
	@if [ -f $(xmake_core_install) ]; then rm $(xmake_core_install); fi
	@cp -p $(xmake_core) $(xmake_core_install)
	@chmod 755 $(xmake_core_install)
	@# install the xrepo bin file
	@cp -p ./scripts/xrepo.sh $(xrepo_bin_install)
	@chmod 755 $(xrepo_bin_install)
	@# remove xmake.out
	@if [ -f "$(TMP_DIR)/xmake.out" ]; then rm $(TMP_DIR)/xmake.out; fi
	@# ok
	@echo ok!

uninstall:
	@echo uninstalling from $(destdir) ...
	@if [ -d $(xmake_dir_install) ]; then rm -rf $(xmake_dir_install); fi
	@if [ -f $(xmake_core_install) ]; then rm $(xmake_core_install); fi
	@if [ -f $(xrepo_bin_install) ]; then rm $(xrepo_bin_install); fi
	@echo ok!

test:
	@xmake lua --verbose tests/run.lua $(name)
	@echo ok!

.PHONY: build install uninstall
