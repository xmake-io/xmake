# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= lua-cjson

# module type
lua-cjson_TYPE 			= LIB

# config
lua-cjson_CONFIG 		= n

# core files
lua-cjson_C_FILES 		+= \
						lua-cjson/dtoa \
						lua-cjson/g_fmt \
						lua-cjson/strbuf \
						lua-cjson/lua_cjson

# cflags
# Use internal strtod() / g_fmt() code for performance and disable multi-thread
lua-cjson_CFLAGS 		+= -DNDEBUG -DUSE_INTERNAL_FPCONV

# includes
lua-cjson_INC_DIRS 		+= ../lua/lua
lua-cjson_CXFLAGS 		+= -DLUA_COMPAT_5_1 -DLUA_COMPAT_5_2 -DLUA_COMPAT_5_3

# use given system library?
lua-cjson_C_FILES  		:= $(if $(findstring cjson,$(base_LIBNAMES)),,$(lua-cjson_C_FILES))
lua-cjson_INC_FILES  	:= $(if $(findstring cjson,$(base_LIBNAMES)),,$(lua-cjson_INC_FILES))

# suffix
include $(PRO_DIR)/suffix.mak

