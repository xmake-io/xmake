# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= luajit

# module type
luajit_TYPE 			= LIB

# config
luajit_CONFIG 			= n

# core files
luajit_C_FILES 			+= \
						luajit/src/lib_aux \
						luajit/src/lib_base \
						luajit/src/lib_bit \
						luajit/src/lib_debug \
						luajit/src/lib_ffi \
						luajit/src/lib_init \
						luajit/src/lib_io \
						luajit/src/lib_jit \
						luajit/src/lib_math \
						luajit/src/lib_os \
						luajit/src/lib_package \
						luajit/src/lib_string \
						luajit/src/lib_table \
						luajit/src/lj_alloc \
						luajit/src/lj_api \
						luajit/src/lj_asm \
						luajit/src/lj_bc \
						luajit/src/lj_bcread \
						luajit/src/lj_bcwrite \
						luajit/src/lj_carith \
						luajit/src/lj_ccall \
						luajit/src/lj_ccallback \
						luajit/src/lj_cconv \
						luajit/src/lj_cdata \
						luajit/src/lj_char \
						luajit/src/lj_clib \
						luajit/src/lj_cparse \
						luajit/src/lj_crecord \
						luajit/src/lj_ctype \
						luajit/src/lj_debug \
						luajit/src/lj_dispatch \
						luajit/src/lj_err \
						luajit/src/lj_ffrecord \
						luajit/src/lj_func \
						luajit/src/lj_gc \
						luajit/src/lj_gdbjit \
						luajit/src/lj_ir \
						luajit/src/lj_lex \
						luajit/src/lj_lib \
						luajit/src/lj_load \
						luajit/src/lj_mcode \
						luajit/src/lj_meta \
						luajit/src/lj_obj \
						luajit/src/lj_opt_dce \
						luajit/src/lj_opt_fold \
						luajit/src/lj_opt_loop \
						luajit/src/lj_opt_mem \
						luajit/src/lj_opt_narrow \
						luajit/src/lj_opt_sink \
						luajit/src/lj_opt_split \
						luajit/src/lj_parse \
						luajit/src/lj_record \
						luajit/src/lj_snap \
						luajit/src/lj_state \
						luajit/src/lj_str \
						luajit/src/lj_strscan \
						luajit/src/lj_tab \
						luajit/src/lj_trace \
						luajit/src/lj_udata \
						luajit/src/lj_vmevent \
						luajit/src/lj_vmmath \
						luajit/src/lj_buf \
						luajit/src/lj_strfmt \
						luajit/src/lj_strfmt_num \
						luajit/src/lj_profile \
						luajit/src/lj_prng

# is windows?
iswin =
ifeq ($(PLAT),windows)
	iswin = yes
endif
ifeq ($(PLAT),msys)
	iswin = yes
endif
ifeq ($(PLAT),cygwin)
	iswin = yes
endif

# autogen plat and arch
GENPLAT := $(PLAT)
GENARCH := $(ARCH)
ifeq ($(ARCH),arm64-v8a)
GENARCH := arm64
endif
ifeq ($(ARCH),armv7)
GENARCH := arm
endif

# asm files
ifdef iswin
ifeq ($(ARCH),x86_64)
GENARCH := x64
endif
ifeq ($(ARCH),i386)
GENARCH := x86
endif
GENPLAT := windows
luajit_OBJ_FILES 		+= \
						autogen/$(GENPLAT)/$(luajit_JIT)/$(GENARCH)/lj_vm
else
luajit_ASM_FILES 		+= \
						autogen/$(GENPLAT)/$(luajit_JIT)/$(GENARCH)/lj_vm
endif

# includes
luajit_INC_DIRS 		+= \
						autogen/$(GENPLAT)/$(luajit_JIT)/$(GENARCH)

# disable jit compiler
ifeq ($(luajit_JIT),nojit)
luajit_CXFLAGS 			+= -DLUAJIT_DISABLE_JIT
endif
luajit_CXFLAGS 			+= -Wno-error=unused-function
										
# suffix
include $(PRO_DIR)/suffix.mak

