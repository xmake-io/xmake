# prefix makefile

# include project
include 		$(PRO_DIR)/project.mak

# the temporary directory
ifeq ($(TMPDIR),)
TMP_DIR 		:=$(if $(TMP_DIR),$(TMP_DIR),/tmp)
else
# for termux
TMP_DIR 		:=$(if $(TMP_DIR),$(TMP_DIR),$(TMPDIR))
endif

# the source directory
SRC_DIR 		= $(PRO_DIR)/src

# the binary directory
BIN_DIR 		= $(PRO_DIR)/bin

# the platform directory
PLAT_DIR 		= $(PRO_DIR)/plat/$(PLAT)

# the tool directory
TOOL_DIR 		= $(PRO_DIR)/tool

# the default include directory
INC_DIRS 		= $(PRO_DIR)

# the config file path
CFG_FILE 		= $(PRO_DIR)/$(PRO_NAME).config.h

# include platform prefix
-include 		$(PLAT_DIR)/prefix.mak

