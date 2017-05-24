# is debug?
debug  :=n
verbose:=

#debug  :=y
#verbose:=-v

# prefix
prefix:=$(if $(prefix),$(prefix),$(if $(findstring /usr/local/bin,$(PATH)),/usr/local,/usr))

# platform
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i linux},linux,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i darwin},macosx,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i cygwin},cygwin,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i mingw},mingw,))
PLAT 		:=$(if $(PLAT),$(PLAT),$(if ${shell uname | egrep -i windows},windows,))
PLAT 		:=$(if $(PLAT),$(PLAT),linux)

# architecture
ifeq ($(ARCH),)

ARCH 		:=$(if $(findstring windows,$(PLAT)),x86,$(ARCH))
ARCH 		:=$(if $(findstring mingw,$(PLAT)),x86,$(ARCH))
ARCH 		:=$(if $(findstring macosx,$(PLAT)),x$(shell getconf LONG_BIT),$(ARCH))
ARCH 		:=$(if $(findstring linux,$(PLAT)),x$(shell getconf LONG_BIT),$(ARCH))
ARCH 		:=$(if $(findstring x32,$(ARCH)),i386,$(ARCH))
ARCH 		:=$(if $(findstring x64,$(ARCH)),x86_64,$(ARCH))
ARCH 		:=$(if $(findstring iphoneos,$(PLAT)),armv7,$(ARCH))
ARCH 		:=$(if $(findstring android,$(PLAT)),armv7,$(ARCH))

endif

xmake_dir_install   :=$(prefix)/share/xmake
xmake_core          :=./core/src/demo/demo.b
xmake_core_install  :=$(xmake_dir_install)/xmake
xmake_loader        :=/tmp/xmake_loader
xmake_loader_install:=$(prefix)/bin/xmake

tip:
	@echo 'Usage: '
	@echo '    $ make build'
	@echo '    $ sudo make install [prefix=/usr/local]'

build:
	@echo compiling xmake-core ...
	@if [ -f core/.config.mak ]; then rm core/.config.mak; fi
	@$(MAKE) -C core --no-print-directory f DEBUG=$(debug)
	@$(MAKE) -C core --no-print-directory c
	@$(MAKE) -C core --no-print-directory

install:
	@echo installing to $(prefix) ...
	@echo plat: $(PLAT)
	@echo arch: $(ARCH)
	@# create the xmake install directory
	@if [ -d $(xmake_dir_install) ]; then rm -rf $(xmake_dir_install); fi
	@if [ ! -d $(xmake_dir_install) ]; then mkdir -p $(xmake_dir_install); fi
	@# install the xmake core file
	@cp $(xmake_core) $(xmake_core_install)
	@chmod 777 $(xmake_core_install)
	@# install the xmake directory
	@cp -r xmake/* $(xmake_dir_install)
	@# make the xmake loader
	@echo '#!/bin/bash' > $(xmake_loader)
	@echo 'export XMAKE_PROGRAM_DIR=$(xmake_dir_install)' >> $(xmake_loader)
	@echo '$(xmake_core_install) $(verbose) "$$@"' >> $(xmake_loader)
	@# install the xmake loader
	@if [ ! -d $(prefix)/bin ]; then mkdir -p $(prefix)/bin; fi
	@mv $(xmake_loader) $(xmake_loader_install)
	@chmod 777 $(xmake_loader_install)
	@# remove xmake.out
	@if [ -f '/tmp/xmake.out' ]; then rm /tmp/xmake.out; fi
	@# ok
	@echo ok!

uninstall:
	@echo uninstalling from $(prefix) ...
	@if [ -f $(prefix)/bin/xmake ]; then rm $(prefix)/bin/xmake; fi
	@if [ -d $(prefix)/share/xmake ]; then rm -rf $(prefix)/share/xmake; fi
	@echo ok!

test:
	@xmake lua --backtrace tests/test.lua $(name)
	@echo ok!

.PHONY: tip build install uninstall
