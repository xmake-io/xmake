include $(PRO_DIR)/prefix.mak

NAMES 				= demo
demo_TYPE 			= BIN
demo_C_FILES 		+= xmake
demo_PKGS-$(BASE)  	+= base
demo_CXFLAGS 		+= -D__tb_prefix__=\"xmake\"

demo_LIBS 			+= xmake$(DTYPE)
demo_LIB_DIRS 		+= ../xmake

# tbox
tbox_DTYPE 			:= $(if $(findstring tbox,$(base_LIBNAMES)),,$(DTYPE))
demo_LIBS 			+= tbox$(tbox_DTYPE)
demo_INC_DIRS 		+= ../ ../tbox/tbox/src ../tbox/inc/$(PLAT)
demo_LIB_DIRS 	    += ../tbox

# lua
lua_LIBS    	   	:= $(if $(findstring lua,$(base_LIBNAMES)),,lua$(DTYPE))
demo_LIBS 			+= $(lua_LIBS)
demo_INC_DIRS 	    += ../lua/lua
demo_LIB_DIRS 		+= ../lua

# sv
sv_DTYPE 			:= $(if $(findstring sv,$(base_LIBNAMES)),,$(DTYPE))
demo_LIBS 			+= sv$(sv_DTYPE)
demo_INC_DIRS 		+= ../sv/sv/include
demo_LIB_DIRS 		+= ../sv

# lua-cjson
lua-cjson_LIBS 	   	:= $(if $(findstring cjson,$(base_LIBNAMES)),,lua-cjson$(DTYPE))
demo_LIBS 			+= $(lua-cjson_LIBS)
demo_LIB_DIRS 		+= ../lua-cjson

# lz4
lz4_DTYPE 			:= $(if $(findstring lz4,$(base_LIBNAMES)),,$(DTYPE))
demo_LIBS 			+= lz4$(lz4_DTYPE)
demo_LIB_DIRS 		+= ../lz4

demo_LIBS 			+= $(BASE_LIBS)

include $(PRO_DIR)/suffix.mak

