# prefix
include $(PRO_DIR)/prefix.mak

# projects
SUB_PROS 	+= demo
ifeq ($(RUNTIME),luajit)
DEP_PROS 	+= luajit
endif
ifeq ($(RUNTIME),lua)
DEP_PROS 	+= lua
endif
DEP_PROS 	+= lcurses sv lua-cjson tbox xmake

# suffix
include $(PRO_DIR)/suffix.mak

