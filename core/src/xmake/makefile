# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= xmake

# module type
xmake_TYPE 				= LIB

# config
xmake_CONFIG 			= y

# core files
xmake_C_FILES 			+= \
						xmake \
						machine \
						path/absolute \
						path/translate \
						path/is_absolute \
						string/startswith \
						preprocessor/loadx 
						

# flags
xmake_CXFLAGS 			+= -D__tb_prefix__=\"xmake\"

# header files
xmake_INC_FILES 		= \
						xmake.h \
						machine.h \
						config.h \
						prefix.h \
						prefix/prefix.h \
						prefix/config.h \
						prefix/version.h 
						

# demo
SUB_PROS-$(DEMO) 		+= ../demo

# suffix
include $(PRO_DIR)/suffix.mak

