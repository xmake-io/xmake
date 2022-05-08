# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= lz4

# module type
lz4_TYPE 				= LIB

# config
lz4_CONFIG 				= n

# core files
lz4_C_FILES 			+= \
						lz4/lib/lz4 \
						lz4/lib/lz4frame \
						lz4/lib/lz4hc \
						lz4/lib/xxhash

# use given system library?
lz4_C_FILES 			:= $(if $(findstring lz4,$(base_LIBNAMES)),,$(lz4_C_FILES))
lz4_ASM_FILES 			:= $(if $(findstring lz4,$(base_LIBNAMES)),,$(lz4_ASM_FILES))
lz4_INC_FILES 			:= $(if $(findstring lz4,$(base_LIBNAMES)),,$(lz4_INC_FILES))
lz4_OBJ_FILES 			:= $(if $(findstring lz4,$(base_LIBNAMES)),,$(lz4_OBJ_FILES))

# suffix
include $(PRO_DIR)/suffix.mak

