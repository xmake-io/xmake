# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= lua

# module type
lua_TYPE 				= LIB

# config
lua_CONFIG 				= n

# core files
lua_C_FILES 			+= \
						lua/lauxlib \
						lua/liolib \
						lua/lopcodes \
						lua/lstate \
						lua/lobject \
						lua/lmathlib \
						lua/loadlib \
						lua/lvm \
						lua/lfunc \
						lua/lstrlib \
						lua/linit \
						lua/lstring \
						lua/lundump \
						lua/lctype \
						lua/ltable \
						lua/ldump \
						lua/loslib \
						lua/lgc \
						lua/lzio \
						lua/ldblib \
						lua/lutf8lib \
						lua/lmem \
						lua/lcorolib \
						lua/lcode \
						lua/ltablib \
						lua/lbitlib \
						lua/lapi \
						lua/lbaselib \
						lua/ldebug \
						lua/lparser \
						lua/llex \
						lua/ltm \
						lua/ltests \
						lua/ldo

# is windows?
iswin =
ifeq ($(PLAT),windows)
	iswin = yes
endif
ifeq ($(PLAT),msys)
	iswin = yes
endif
ifeq ($(PLAT),mingw)
	iswin = yes
endif
ifeq ($(PLAT),cygwin)
	iswin = yes
endif

lua_CFLAGS 				:= -std=c99 -DLUA_COMPAT_5_1 -DLUA_COMPAT_5_2
ifdef iswin
lua_CFLAGS_PLAT 		:= -DLUA_USE_WINDOWS
endif

ifeq ($(PLAT),macosx)
lua_CFLAGS 				+= -Wno-error=string-plus-int
lua_CFLAGS_PLAT 		:= -DLUA_USE_MACOSX
endif

ifeq ($(lua_CFLAGS_PLAT),)
lua_CFLAGS_PLAT 		:= -DLUA_USE_LINUX
endif
lua_CFLAGS 				+= $(lua_CFLAGS_PLAT)

# use given system library?
lua_C_FILES 			:= $(if $(findstring lua,$(base_LIBNAMES)),,$(lua_C_FILES))
lua_ASM_FILES 			:= $(if $(findstring lua,$(base_LIBNAMES)),,$(lua_ASM_FILES))
lua_INC_FILES 			:= $(if $(findstring lua,$(base_LIBNAMES)),,$(lua_INC_FILES))
lua_OBJ_FILES 			:= $(if $(findstring lua,$(base_LIBNAMES)),,$(lua_OBJ_FILES))

# suffix
include $(PRO_DIR)/suffix.mak

