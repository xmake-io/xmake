# ######################################################################################
# make define
# #

# append names
NAMES 			+= $(NAMES-y)

# ccache hook compiler for optimizating make
ifneq ($(CCACHE),)
CC 				:= $(CCACHE) $(CC)
MM 				:= $(CCACHE) $(MM)
endif

# distcc hook compiler for optimizating make
ifneq ($(DISTCC),)
CC 				:= $(DISTCC) $(CC)
MM 				:= $(DISTCC) $(MM)
AS 				:= $(DISTCC) $(AS)
endif

# redirect output
ifeq ($(OUT),)
OUT 			:= $(if $(findstring msys,$(HOST)),&>,2>)
export 			OUT
endif

# append flags
CFLAGS 			+= $(CFLAG) $(CFLAGS-y)
CXFLAGS 		+= $(CXFLAG) $(CXFLAGS-y)
CCFLAGS 		+= $(CCFLAG) $(CCFLAGS-y)
MFLAGS 			+= $(MFLAG) $(MFLAGS-y)
MMFLAGS 		+= $(MMFLAG) $(MMFLAGS-y)
MXFLAGS 		+= $(MXFLAG) $(MXFLAGS-y)
LDFLAGS 		+= $(LDFLAG) $(LDFLAGS-y)
ASFLAGS 		+= $(ASFLAG) $(ASFLAGS-y)
ARFLAGS 		+= $(ARFLAG) $(ARFLAGS-y)
SHFLAGS 		+= $(SHFLAG) $(SHFLAGS-y)

# append debug flags
CFLAGS_DEBUG 	+= $(CFLAGS_DEBUG-y)
CXFLAGS_DEBUG 	+= $(CXFLAGS_DEBUG-y)
CCFLAGS_DEBUG 	+= $(CCFLAGS_DEBUG-y)
MFLAGS_DEBUG 	+= $(MFLAGS_DEBUG-y)
MMFLAGS_DEBUG 	+= $(MMFLAGS_DEBUG-y)
MXFLAGS_DEBUG 	+= $(MXFLAGS_DEBUG-y)
LDFLAGS_DEBUG 	+= $(LDFLAGS_DEBUG-y)
ASFLAGS_DEBUG 	+= $(ASFLAGS_DEBUG-y)
ARFLAGS_DEBUG 	+= $(ARFLAGS_DEBUG-y)
SHFLAGS_DEBUG 	+= $(SHFLAGS_DEBUG-y)

# append release flags
CFLAGS_RELEASE 	+= $(CFLAGS_RELEASE-y)
CXFLAGS_RELEASE += $(CXFLAGS_RELEASE-y)
CCFLAGS_RELEASE += $(CCFLAGS_RELEASE-y)
MFLAGS_RELEASE 	+= $(MFLAGS_RELEASE-y)
MMFLAGS_RELEASE += $(MMFLAGS_RELEASE-y)
MXFLAGS_RELEASE += $(MXFLAGS_RELEASE-y)
LDFLAGS_RELEASE += $(LDFLAGS_RELEASE-y)
ASFLAGS_RELEASE += $(ASFLAGS_RELEASE-y)
ARFLAGS_RELEASE += $(ARFLAGS_RELEASE-y)
SHFLAGS_RELEASE += $(SHFLAGS_RELEASE-y)

# append projects
SUB_PROS 		+= $(SUB_PROS-y)

# make suffix
LIB_SUFFIX 		:= $(DTYPE)$(LIB_SUFFIX)
DLL_SUFFIX 		:= $(DTYPE)$(DLL_SUFFIX)

# append debug flags
ifeq ($(DEBUG),y)
CFLAGS 			+= $(CFLAGS_DEBUG)
CXFLAGS 		+= $(CXFLAGS_DEBUG)
CCFLAGS 		+= $(CCFLAGS_DEBUG)
MFLAGS 			+= $(MFLAGS_DEBUG)
MMFLAGS 		+= $(MMFLAGS_DEBUG)
MXFLAGS 		+= $(MXFLAGS_DEBUG)
LDFLAGS 		+= $(LDFLAGS_DEBUG)
ASFLAGS 		+= $(ASFLAGS_DEBUG)
ARFLAGS 		+= $(ARFLAGS_DEBUG)
SHFLAGS 		+= $(SHFLAGS_DEBUG)
else
CFLAGS 			+= $(CFLAGS_RELEASE)
CXFLAGS 		+= $(CXFLAGS_RELEASE)
CCFLAGS 		+= $(CCFLAGS_RELEASE)
MFLAGS 			+= $(MFLAGS_RELEASE)
MMFLAGS 		+= $(MMFLAGS_RELEASE)
MXFLAGS 		+= $(MXFLAGS_RELEASE)
LDFLAGS 		+= $(LDFLAGS_RELEASE)
ASFLAGS 		+= $(ASFLAGS_RELEASE)
ARFLAGS 		+= $(ARFLAGS_RELEASE)
SHFLAGS 		+= $(SHFLAGS_RELEASE)
endif

# append files-y, dirs-y, pkgs-y
define APPEND_FILES_AND_DIRS_y
$(1)_C_FILES 	+= $($(1)_C_FILES-y)
$(1)_CC_FILES 	+= $($(1)_CC_FILES-y)
$(1)_CPP_FILES 	+= $($(1)_CPP_FILES-y)
$(1)_M_FILES 	+= $($(1)_M_FILES-y)
$(1)_MM_FILES 	+= $($(1)_MM_FILES-y)
$(1)_ASM_FILES 	+= $($(1)_ASM_FILES-y)
$(1)_OBJ_FILES 	+= $($(1)_OBJ_FILES-y)
$(1)_INC_FILES 	+= $($(1)_INC_FILES-y)
$(1)_INC_DIRS 	+= $($(1)_INC_DIRS-y)
$(1)_LIB_DIRS 	+= $($(1)_LIB_DIRS-y)
$(1)_LIBS 		+= $($(1)_LIBS-y)
$(1)_PKGS 		+= $($(1)_PKGS-y)
$(1)_PKG_NAME 	:= $(if $($(1)_PKG_NAME),$($(1)_PKG_NAME),$(1))
endef
$(foreach name, $(NAMES), $(eval $(call APPEND_FILES_AND_DIRS_y,$(name))))

# the current directory
CUR_DIR 		:= $(abspath .)

# select package directory
ifneq ($(PACKAGE),)
PKG_DIR  		:= $(PACKAGE)
endif

# append package includes
define APPEND_PACKAGE_INC_DIRS
INC_DIRS 		+= $(PKG_DIR)/$(1).pkg/inc/$(PLAT)/$(BUILD_ARCH) $(PKG_DIR)/$(1).pkg/inc/$(PLAT) $(PKG_DIR)/$(1).pkg/inc $($(1)_INCPATH)
endef
$(foreach name, $(PKG_NAMES), $(eval $(call APPEND_PACKAGE_INC_DIRS,$(name))))

# make native directory
ifeq ($(PLAT),msvc)
PKG_DIR_DRIVEN 	:= $(word 1,$(subst /, ,$(PKG_DIR)))
PKG_DIR_NATIVE 	:= $(patsubst /$(PKG_DIR_DRIVEN)/%,$(PKG_DIR_DRIVEN):/%,$(PKG_DIR))
CUR_DIR_DRIVEN 	:= $(word 1,$(subst /, ,$(CUR_DIR)))
CUR_DIR_NATIVE 	:= $(patsubst /$(CUR_DIR_DRIVEN)/%,$(CUR_DIR_DRIVEN):/%,$(CUR_DIR))
else
PKG_DIR_NATIVE 	:= $(PKG_DIR)
CUR_DIR_NATIVE 	:= $(CUR_DIR)
endif

# append package options
define APPEND_PACKAGE_OPTIONS_FOR_MODULE
$(1)_LIBS 		+= $($(2)_LIBNAMES)
$(1)_INC_DIRS 	+= $($(2)_INCPATH)
$(1)_LIB_DIRS 	+= $($(2)_LIBPATH) $(PKG_DIR_NATIVE)/$(2).pkg/lib/release/$(PLAT)/$(BUILD_ARCH)
$(1)_CXFLAGS 	+= $($(2)_INCFLAGS)
$(1)_MXFLAGS 	+= $($(2)_INCFLAGS)
$(1)_LDFLAGS 	+= $($(2)_LIBFLAGS)
$(1)_SHFLAGS 	+= $($(2)_LIBFLAGS)
endef
define APPEND_PACKAGE_OPTIONS
$(foreach pkg, $($(1)_PKGS), $(eval $(call APPEND_PACKAGE_OPTIONS_FOR_MODULE,$(1),$(pkg))))
endef
$(foreach name, $(NAMES), $(eval $(call APPEND_PACKAGE_OPTIONS,$(name))))

# remove repeat files and dirs
define REMOVE_REPEAT_FILES_AND_DIRS
$(1)_C_FILES 	:= $(sort $($(1)_C_FILES))
$(1)_CC_FILES 	:= $(sort $($(1)_CC_FILES))
$(1)_CPP_FILES 	:= $(sort $($(1)_CPP_FILES))
$(1)_M_FILES 	:= $(sort $($(1)_M_FILES))
$(1)_MM_FILES 	:= $(sort $($(1)_MM_FILES))
$(1)_ASM_FILES 	:= $(sort $($(1)_ASM_FILES))
$(1)_OBJ_FILES 	:= $(sort $($(1)_OBJ_FILES))
$(1)_INC_FILES 	:= $(sort $($(1)_INC_FILES))
$(1)_INC_DIRS 	:= $(sort $($(1)_INC_DIRS))
$(1)_LIB_DIRS 	:= $(sort $($(1)_LIB_DIRS))
endef
$(foreach name, $(NAMES), $(eval $(call REMOVE_REPEAT_FILES_AND_DIRS,$(name))))

# make flags
define MAKE_FLAGS
$(1)_CFLAGS 	:= $(CFLAGS) $($(1)_CFLAGS) $($(1)_CFLAGS-y)
$(1)_CCFLAGS 	:= $(CCFLAGS) $($(1)_CCFLAGS) $($(1)_CCFLAGS-y)
$(1)_CXFLAGS 	:= $(CXFLAGS) $(addprefix $(CXFLAGS-I), $(INC_DIRS)) $(addprefix $(CXFLAGS-I), $($(1)_INC_DIRS)) $($(1)_CXFLAGS) $($(1)_CXFLAGS-y)
$(1)_MFLAGS 	:= $(MFLAGS) $($(1)_MFLAGS) $($(1)_MFLAGS-y)
$(1)_MMFLAGS 	:= $(MMFLAGS) $($(1)_MMFLAGS) $($(1)_MMFLAGS-y)
$(1)_MXFLAGS 	:= $(MXFLAGS) $(addprefix $(MXFLAGS-I), $(INC_DIRS)) $(addprefix $(MXFLAGS-I), $($(1)_INC_DIRS)) $($(1)_MXFLAGS) $($(1)_MXFLAGS-y)
$(1)_LDFLAGS 	:= $(LDFLAGS) $(addprefix $(LDFLAGS-L), $(LIB_DIRS)) $(addprefix $(LDFLAGS-L), $($(1)_LIB_DIRS)) $($(1)_LDFLAGS) $($(1)_LDFLAGS-y) $(addsuffix $(LDFLAGS-f), $(addprefix $(LDFLAGS-l), $($(1)_LIBS)))
$(1)_ASFLAGS 	:= $(ASFLAGS) $(addprefix $(ASFLAGS-I), $(INC_DIRS)) $(addprefix $(ASFLAGS-I), $($(1)_INC_DIRS)) $($(1)_ASFLAGS) $($(1)_ASFLAGS-y)
$(1)_ARFLAGS 	:= $(ARFLAGS) $($(1)_ARFLAGS-y)
$(1)_SHFLAGS 	:= $(SHFLAGS) $(addprefix $(LDFLAGS-L), $(LIB_DIRS)) $(addprefix $(LDFLAGS-L), $($(1)_LIB_DIRS)) $($(1)_SHFLAGS) $($(1)_SHFLAGS-y) $(addsuffix $(LDFLAGS-f), $(addprefix $(LDFLAGS-l), $($(1)_LIBS)))
endef
$(foreach name, $(NAMES), $(eval $(call MAKE_FLAGS,$(name))))

# append native flags
define MAKE_FLAGS_NATIVE
$(1)_CXFLAGS 	+= -Fd"$(CUR_DIR_NATIVE)/$(1)$(DTYPE).pdb"
$(1)_LDFLAGS 	+= -pdb:"$(CUR_DIR_NATIVE)/$(1)$(DTYPE).pdb"
$(1)_ARFLAGS 	+= -pdb:"$(CUR_DIR_NATIVE)/$(1)$(DTYPE).pdb"
$(1)_SHFLAGS 	+= -pdb:"$(CUR_DIR_NATIVE)/$(1)$(DTYPE).pdb"
endef
ifeq ($(PLAT),msvc)
$(foreach name, $(NAMES), $(eval $(call MAKE_FLAGS_NATIVE,$(name))))
endif

# make objects and source files
define MAKE_OBJS_AND_SRCS_FILES
$(1)_OBJS 		:= $(addsuffix $(OBJ_SUFFIX), $($(1)_FILES))
$(1)_SRCS 		:= $(addsuffix .c, $($(1)_C_FILES)) $(addsuffix .cc, $($(1)_CC_FILES)) $(addsuffix .cpp, $($(1)_CPP_FILES)) $(addsuffix .m, $($(1)_M_FILES)) $(addsuffix .mm, $($(1)_MM_FILES)) $(addsuffix $(ASM_SUFFIX), $($(1)_ASM_FILES))
endef
$(foreach name, $(NAMES), $(eval $(name)_FILES := $($(name)_C_FILES) $($(name)_CC_FILES) $($(name)_CPP_FILES) $($(name)_M_FILES) $($(name)_MM_FILES) $($(name)_ASM_FILES)))
$(foreach name, $(NAMES), $(eval $(call MAKE_OBJS_AND_SRCS_FILES,$(name))))

# ######################################################################################
# make all
# #

define MAKE_OBJ_C
$(1)$(OBJ_SUFFIX) : $(1).c
	@echo $(CCACHE) $(DISTCC) compile.$(DTYPE) $(1).c
	@$(CC) $(2) $(3) $(CXFLAGS-o)$(1)$(OBJ_SUFFIX) $(1).c $(OUT) $(TMP_DIR)/$(PRO_NAME).out
endef

define MAKE_OBJ_CC
$(1)$(OBJ_SUFFIX) : $(1).cc
	@echo $(CCACHE) $(DISTCC) compile.$(DTYPE) $(1).cc
	@$(CC) $(2) $(3) $(CXFLAGS-o)$(1)$(OBJ_SUFFIX) $(1).cc $(OUT) $(TMP_DIR)/$(PRO_NAME).out
endef

define MAKE_OBJ_CPP
$(1)$(OBJ_SUFFIX) : $(1).cpp
	@echo $(CCACHE) $(DISTCC) compile.$(DTYPE) $(1).cpp
	@$(CC) $(2) $(3) $(CXFLAGS-o)$(1)$(OBJ_SUFFIX) $(1).cpp $(OUT) $(TMP_DIR)/$(PRO_NAME).out
endef

define MAKE_OBJ_M
$(1)$(OBJ_SUFFIX) : $(1).m
	@echo $(CCACHE) $(DISTCC) compile.$(DTYPE) $(1).m
	@$(MM) -x objective-c $(2) $(3) $(MXFLAGS-o)$(1)$(OBJ_SUFFIX) $(1).m $(OUT) $(TMP_DIR)/$(PRO_NAME).out
endef

define MAKE_OBJ_MM
$(1)$(OBJ_SUFFIX) : $(1).mm
	@echo $(CCACHE) $(DISTCC) compile.$(DTYPE) $(1).mm
	@$(MM) -x objective-c++ $(2) $(3) $(MXFLAGS-o)$(1)$(OBJ_SUFFIX) $(1).mm $(OUT) $(TMP_DIR)/$(PRO_NAME).out
endef

define MAKE_OBJ_ASM_WITH_CC
$(1)$(OBJ_SUFFIX) : $(1)$(ASM_SUFFIX)
	@echo $(CCACHE) $(DISTCC) compile.$(DTYPE) $(1)$(ASM_SUFFIX)
	@$(CC) $(2) $(CXFLAGS-o)$(1)$(OBJ_SUFFIX) $(1)$(ASM_SUFFIX) $(OUT) $(TMP_DIR)/$(PRO_NAME).out
endef

define MAKE_OBJ_ASM_WITH_AS
$(1)$(OBJ_SUFFIX) : $(1)$(ASM_SUFFIX)
	@echo compile.$(DTYPE) $(1)$(ASM_SUFFIX)
	@$(AS) $(2) $(ASFLAGS-o)$(1)$(OBJ_SUFFIX) $(1)$(ASM_SUFFIX) $(OUT) $(TMP_DIR)/$(PRO_NAME).out
endef

define MAKE_ALL
$(1)_$(2)_all: $($(2)_PREFIX)$(1)$($(2)_SUFFIX)
	$($(1)_SUFFIX_CMD1)
	$($(1)_SUFFIX_CMD2)
	$($(1)_SUFFIX_CMD3)
	$($(1)_SUFFIX_CMD4)
	$($(1)_SUFFIX_CMD5)

$($(2)_PREFIX)$(1)$($(2)_SUFFIX): $($(1)_OBJS) $(addsuffix $(OBJ_SUFFIX), $($(1)_OBJ_FILES))
$(foreach file, $($(1)_C_FILES), $(eval $(call MAKE_OBJ_C,$(file),$($(1)_CXFLAGS),$($(1)_CFLAGS))))
$(foreach file, $($(1)_CC_FILES), $(eval $(call MAKE_OBJ_CC,$(file),$($(1)_CXFLAGS),$($(1)_CCFLAGS))))
$(foreach file, $($(1)_CPP_FILES), $(eval $(call MAKE_OBJ_CPP,$(file),$($(1)_CXFLAGS),$($(1)_CCFLAGS))))
$(foreach file, $($(1)_M_FILES), $(eval $(call MAKE_OBJ_M,$(file),$($(1)_MXFLAGS),$($(1)_MFLAGS))))
$(foreach file, $($(1)_MM_FILES), $(eval $(call MAKE_OBJ_MM,$(file),$($(1)_MXFLAGS),$($(1)_MMFLAGS))))

$(if $(AS)
,$(foreach file, $($(1)_ASM_FILES), $(eval $(call MAKE_OBJ_ASM_WITH_AS,$(file),$($(1)_ASFLAGS))))
,$(foreach file, $($(1)_ASM_FILES), $(eval $(call MAKE_OBJ_ASM_WITH_CC,$(file),$($(1)_CXFLAGS))))
)

$(BIN_PREFIX)$(1)$(BIN_SUFFIX): $($(1)_OBJS) $(addsuffix $(OBJ_SUFFIX), $($(1)_OBJ_FILES))
	@echo link $$@
	-@$(RM) $$@
	@$(LD) $(LDFLAGS-o)$$@ $$^ $($(1)_LDFLAGS) $(OUT) $(TMP_DIR)/$(PRO_NAME).out

$(LIB_PREFIX)$(1)$(LIB_SUFFIX): $($(1)_OBJS) $(addsuffix $(OBJ_SUFFIX), $($(1)_OBJ_FILES))
	@echo link $$@
	-@$(RM) $$@
	@$(AR) $($(1)_ARFLAGS) $(ARFLAGS-o)$$@ $$^ $(OUT) $(TMP_DIR)/$(PRO_NAME).out
	$(if $(RANLIB),@$(RANLIB) $$@,)

$(DLL_PREFIX)$(1)$(DLL_SUFFIX): $($(1)_OBJS) $(addsuffix $(OBJ_SUFFIX), $($(1)_OBJ_FILES))
	@echo link $$@
	-@$(RM) $$@
	@$(LD) $(LDFLAGS-o)$$@ $$^ $($(1)_SHFLAGS) $(OUT) $(TMP_DIR)/$(PRO_NAME).out
endef


define MAKE_ALL_SUB_PROS
SUB_PROS_$(1)_all: $(foreach pro, $(DEP_PROS), DEP_PROS_$(pro)_all)
	@echo make $(1)
	+@$(MAKE) --no-print-directory -C $(1)
endef

define MAKE_ALL_DEP_PROS
DEP_PROS_$(1)_all:
	@echo make $(1)
	+@$(MAKE) --no-print-directory -C $(1)
endef

all: \
	$(foreach name, $(NAMES), $(if $($(name)_FILES), $(name)_$($(name)_TYPE)_all, )) \
	$(foreach pro, $(SUB_PROS), SUB_PROS_$(pro)_all)

$(foreach name, $(NAMES), $(if $($(name)_FILES), $(eval $(call MAKE_ALL,$(name),$($(name)_TYPE))), ))
$(foreach pro, $(SUB_PROS), $(eval $(call MAKE_ALL_SUB_PROS,$(pro))))
$(foreach pro, $(DEP_PROS), $(eval $(call MAKE_ALL_DEP_PROS,$(pro))))

# ######################################################################################
# make install
# #

# select install path
ifneq ($(INSTALL),)
BIN_DIR  		:= $(INSTALL)
endif

# expand install files
define EXPAND_INSTALL_FILES
$(1)_INC_FILES 	:= $(addprefix $(CUR_DIR)/, $(sort $($(1)_INC_FILES)))
$(1)_LIB_FILES 	:= $(addprefix $(CUR_DIR)/, $(sort $(if $(findstring LIB,$($(1)_TYPE)),$(LIB_PREFIX)$(1)$(LIB_SUFFIX),)))
$(1)_DLL_FILES 	:= $(addprefix $(CUR_DIR)/, $(sort $(if $(findstring DLL,$($(1)_TYPE)),$(DLL_PREFIX)$(1)$(DLL_SUFFIX),)))
$(1)_BIN_FILES 	:= $(addprefix $(CUR_DIR)/, $(sort $(if $(findstring BIN,$($(1)_TYPE)),$(BIN_PREFIX)$(1)$(BIN_SUFFIX),)))
endef
$(foreach name, $(NAMES), $(eval $(call EXPAND_INSTALL_FILES,$(name))))

# append native install files
define EXPAND_INSTALL_FILES_NATIVE
$(1)_$($(1)_TYPE)_FILES += $(CUR_DIR)/$(1)$(DTYPE).pdb
endef
ifeq ($(PLAT),msvc)
$(foreach name, $(NAMES), $(eval $(call EXPAND_INSTALL_FILES_NATIVE,$(name))))
endif

# make include dirs
define MAKE_INSTALL_INC_DIRS
$(1)_INC_DIRS_ := $(dir $(patsubst $(SRC_DIR)/$(2)/%,$(BIN_DIR)/$(2).pkg/inc/$(2)/%,$(1)))
endef

# make library dirs
define MAKE_INSTALL_LIB_DIRS
$(1)_LIB_DIRS_ := $(dir $(patsubst $(SRC_DIR)/$(2)/%,$(BIN_DIR)/$(2).pkg/lib/$(PLAT)/$(BUILD_ARCH)/%,$(1)))
endef

# make dynamic dirs
define MAKE_INSTALL_DLL_DIRS
$(1)_DLL_DIRS_ := $(dir $(patsubst $(SRC_DIR)/$(2)/%,$(BIN_DIR)/$(2).pkg/lib/$(PLAT)/$(BUILD_ARCH)/%,$(1)))
endef

# make binary dirs
define MAKE_INSTALL_BIN_DIRS
$(1)_BIN_DIRS_ := $(dir $(patsubst $(SRC_DIR)/$(2)/%,$(BIN_DIR)/$(2).pkg/bin/$(PLAT)/$(BUILD_ARCH)/%,$(1)))
endef

# make install files
define MAKE_INSTALL_FILES
$(foreach file, $($(1)_INC_FILES), $(eval $(call MAKE_INSTALL_INC_DIRS,$(file),$($(1)_PKG_NAME))))
$(foreach file, $($(1)_LIB_FILES), $(eval $(call MAKE_INSTALL_LIB_DIRS,$(file),$($(1)_PKG_NAME))))
$(foreach file, $($(1)_DLL_FILES), $(eval $(call MAKE_INSTALL_DLL_DIRS,$(file),$($(1)_PKG_NAME))))
$(foreach file, $($(1)_BIN_FILES), $(eval $(call MAKE_INSTALL_BIN_DIRS,$(file),$($(1)_PKG_NAME))))

INSTALL_FILES 	+= $($(1)_INC_FILES) $($(1)_LIB_FILES) $($(1)_DLL_FILES) $($(1)_BIN_FILES) $(if $(findstring y,$($(1)_CONFIG)),$(CFG_FILE),)

$(CFG_FILE)_DIRS_ := $(BIN_DIR)/$($(1)_PKG_NAME).pkg/inc/$(PLAT)/$(BUILD_ARCH)
endef
$(foreach name, $(NAMES), $(eval $(call MAKE_INSTALL_FILES,$(name))))

define MAKE_INSTALL_INC_FILES
$(1)_install:
	-@$(MKDIR) $($(1)_INC_DIRS_)
	-@$(CP) $(1) $($(1)_INC_DIRS_)
endef

define MAKE_INSTALL_LIB_FILES
$(1)_install:
	-@$(MKDIR) $($(1)_LIB_DIRS_)
	-@$(CP) $(1) $($(1)_LIB_DIRS_)
endef

define MAKE_INSTALL_DLL_FILES
$(1)_install:
	-@$(MKDIR) $($(1)_DLL_DIRS_)
	-@$(CP) $(1) $($(1)_DLL_DIRS_)
endef

define MAKE_INSTALL_BIN_FILES
$(1)_install:
	-@$(MKDIR) $($(1)_BIN_DIRS_)
	-@$(CP) $(1) $($(1)_BIN_DIRS_)
endef

$(CFG_FILE)_install:
	-@$(MKDIR) $($(CFG_FILE)_DIRS_)
	-@$(CP) $(CFG_FILE) $($(CFG_FILE)_DIRS_)

# make install
define MAKE_INSTALL
$(foreach file, $($(1)_INC_FILES), $(eval $(call MAKE_INSTALL_INC_FILES,$(file))))
$(foreach file, $($(1)_LIB_FILES), $(eval $(call MAKE_INSTALL_LIB_FILES,$(file))))
$(foreach file, $($(1)_DLL_FILES), $(eval $(call MAKE_INSTALL_DLL_FILES,$(file))))
$(foreach file, $($(1)_BIN_FILES), $(eval $(call MAKE_INSTALL_BIN_FILES,$(file))))
endef
$(foreach name, $(NAMES), $(eval $(call MAKE_INSTALL,$(name))))

install: $(foreach file, $(INSTALL_FILES), $(file)_install) $(foreach pro, $(SUB_PROS), SUB_PROS_$(pro)_install)
	$(INSTALL_SUFFIX_CMD1)
	$(INSTALL_SUFFIX_CMD2)
	$(INSTALL_SUFFIX_CMD3)
	$(INSTALL_SUFFIX_CMD4)
	$(INSTALL_SUFFIX_CMD5)

# make sub-projects
define MAKE_INSTALL_SUB_PROS
SUB_PROS_$(1)_install:
	@echo install $(1)
	@$(MAKE) --no-print-directory -C $(1) install
endef

# make dep-projects
define MAKE_INSTALL_DEP_PROS
DEP_PROS_$(1)_install: $(foreach pro, $(DEP_PROS), DEP_PROS_$(pro)_install)
	@echo install $(1)
	@$(MAKE) --no-print-directory -C $(1) install
endef
$(foreach pro, $(SUB_PROS), $(eval $(call MAKE_INSTALL_SUB_PROS,$(pro))))
$(foreach pro, $(DEP_PROS), $(eval $(call MAKE_INSTALL_DEP_PROS,$(pro))))

# ######################################################################################
# make clean
# #
define MAKE_CLEAN
$(1)_$(2)_clean:
	-@$(RM) $($(2)_PREFIX)$(1)$($(2)_SUFFIX)
	-@$(RM) $($(1)_OBJS)
	-@$(RM) *.ilk *.manifest *.pdb *.idb *.dmp
endef

define MAKE_CLEAN_SUB_PROS
SUB_PROS_$(1)_clean: $(foreach pro, $(DEP_PROS), DEP_PROS_$(pro)_clean)
	@echo clean $(1)
	+@$(MAKE) --no-print-directory -C $(1) clean
endef

define MAKE_CLEAN_DEP_PROS
DEP_PROS_$(1)_clean:
	@echo clean $(1)
	+@$(MAKE) --no-print-directory -C $(1) clean
endef

clean: \
	$(foreach name, $(NAMES), $(name)_$($(name)_TYPE)_clean) \
	$(foreach pro, $(SUB_PROS), SUB_PROS_$(pro)_clean)

$(foreach name, $(NAMES), $(eval $(call MAKE_CLEAN,$(name),$($(name)_TYPE))))
$(foreach pro, $(SUB_PROS), $(eval $(call MAKE_CLEAN_SUB_PROS,$(pro))))
$(foreach pro, $(DEP_PROS), $(eval $(call MAKE_CLEAN_DEP_PROS,$(pro))))

# ######################################################################################
# make update
# #

define MAKE_UPDATE_SUB_PROS
SUB_PROS_$(1)_update: $(foreach pro, $(DEP_PROS), DEP_PROS_$(pro)_update)
	@echo update $(1)
	@$(MAKE) --no-print-directory -C $(1) update
endef

define MAKE_UPDATE_DEP_PROS
DEP_PROS_$(1)_update:
	@echo update $(1)
	@$(MAKE) --no-print-directory -C $(1) update
endef

update: .null $(foreach pro, $(SUB_PROS), SUB_PROS_$(pro)_update)
	-@$(RM) *.b *.a *.so *.exe *.dll *.lib *.pdb *.ilk

$(foreach pro, $(SUB_PROS), $(eval $(call MAKE_UPDATE_SUB_PROS,$(pro))))
$(foreach pro, $(DEP_PROS), $(eval $(call MAKE_UPDATE_DEP_PROS,$(pro))))

# ######################################################################################
# null
# #
.null :


