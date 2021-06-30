# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= sv

# module type
sv_TYPE 				= LIB

# config
sv_CONFIG 				= n

# core files
sv_C_FILES 				+= \
						sv/src/comp \
						sv/src/id \
						sv/src/num \
						sv/src/range \
						sv/src/semvers \
						sv/src/utils \
						sv/src/version

# includes
sv_INC_DIRS  			+= sv/include

# use system tbox library?
sv_C_FILES 				:= $(if $(findstring sv,$(base_LIBNAMES)),,$(sv_C_FILES))
sv_INC_DIRS 			:= $(if $(findstring sv,$(base_LIBNAMES)),,$(sv_INC_DIRS))

# suffix
include $(PRO_DIR)/suffix.mak

