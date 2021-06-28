# preifx
include $(PRO_DIR)/prefix.mak

# module name
NAMES 											= demo

# type
demo_TYPE 										= BIN

# files
demo_C_FILES 									+= xmake

# packages
demo_PKGS-$(BASE)  								+= base

# debug suffix
tbox_DTYPE 										:= $(if $(findstring tbox,$(base_LIBNAMES)),,$(DTYPE))

# others
demo_LIBS 										+= xmake$(DTYPE) lcurses$(DTYPE) tbox$(tbox_DTYPE) luajit$(DTYPE) sv$(DTYPE) lua-cjson$(DTYPE) $(BASE_LIBS)
demo_INC_DIRS 									+= ../ ../tbox/tbox/src ../tbox/inc/$(PLAT) ../luajit/luajit/src ../sv/sv/include
demo_LIB_DIRS 									+= ../xmake ../tbox ../luajit ../sv ../lcurses ../lua-cjson
demo_CXFLAGS 									+= -D__tb_prefix__=\"xmake\"

# suffix
include $(PRO_DIR)/suffix.mak

