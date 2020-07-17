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
lua-cjson_INC_DIRS 		+= \
						../luajit/luajit/src

# suffix
include $(PRO_DIR)/suffix.mak

