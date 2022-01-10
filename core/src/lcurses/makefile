# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= lcurses

# module type
lcurses_TYPE 			= LIB

# config
lcurses_CONFIG 			= n

# curses files
lcurses_C_FILES 		+= lcurses

# curses flags
lcurses_CXFLAGS 		+= $(if $(findstring curses,$(base_LIBNAMES)),-DXM_CONFIG_API_HAVE_CURSES,)

# includes
ifeq ($(RUNTIME),luajit)
lcurses_INC_DIRS 		+= ../luajit/luajit/src
lcurses_CXFLAGS 		+= -DUSE_LUAJIT
endif
ifeq ($(RUNTIME),lua)
lcurses_INC_DIRS 		+= ../lua/lua
lcurses_CXFLAGS 		+= -DLUA_COMPAT_5_1 -DLUA_COMPAT_5_2 -DLUA_COMPAT_5_3
endif

# suffix
include $(PRO_DIR)/suffix.mak

