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
lcurses_INC_DIRS  		+= ../luajit/luajit/src

# suffix
include $(PRO_DIR)/suffix.mak

