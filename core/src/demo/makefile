include $(PRO_DIR)/prefix.mak

NAMES 				= demo
demo_TYPE 			= BIN
demo_C_FILES 		+= xmake
demo_PKGS-$(BASE)  	+= base
demo_CXFLAGS 		+= -D__tb_prefix__=\"xmake\"

demo_LIBS 			+= xmake$(DTYPE)
demo_LIB_DIRS 		+= ../xmake

# lcurses
demo_LIBS 			+= lcurses$(DTYPE)
demo_LIB_DIRS 		+= ../lcurses

# tbox
tbox_DTYPE 			:= $(if $(findstring tbox,$(base_LIBNAMES)),,$(DTYPE))
demo_LIBS 			+= tbox$(tbox_DTYPE)
demo_INC_DIRS 		+= ../ ../tbox/tbox/src ../tbox/inc/$(PLAT)
demo_LIB_DIRS 	    += ../tbox

# luajit
ifndef LUAJIT_LIBS
LUAJIT_LIBS 		:= luajit$(DTYPE)
endif
ifndef LUAJIT_INC_DIRS
LUAJIT_INC_DIRS 	:= ../luajit/luajit/src
endif
ifndef LUAJIT_LIB_DIRS
LUAJIT_LIB_DIRS 	:= ../luajit
endif
demo_LIBS 			+= $(LUAJIT_LIBS)
demo_INC_DIRS 	    += $(LUAJIT_INC_DIRS)
demo_LIB_DIRS 		+= $(LUAJIT_LIB_DIRS)

# sv
ifndef LIBSV_LIBS
LIBSV_LIBS 			:= sv$(DTYPE)
endif
ifndef LIBSV_INC_DIRS
LIBSV_INC_DIRS 		:= ../sv/sv/include
endif
ifndef LIBSV_LIB_DIRS
LIBSV_LIB_DIRS 		:= ../sv
endif
demo_LIBS 			+= $(LIBSV_LIBS)
demo_INC_DIRS 		+= $(LIBSV_INC_DIRS)
demo_LIB_DIRS 		+= $(LIBSV_LIB_DIRS)

# lua-cjson
ifndef LUA_CJSON_LIBS
LUA_CJSON_LIBS 		:= lua-cjson$(DTYPE)
endif
ifndef LUA_CJSON_LIB_DIRS
LUA_CJSON_LIB_DIRS 	:= ../lua-cjson
endif
demo_LIBS 			+= $(LUA_CJSON_LIBS)
demo_LIB_DIRS 		+= $(LUA_CJSON_LIB_DIRS)

demo_LIBS 			+= $(BASE_LIBS)

include $(PRO_DIR)/suffix.mak

