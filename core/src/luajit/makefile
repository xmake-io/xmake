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
						src/lib_aux \
						src/lib_base \
						src/lib_bit \
						src/lib_debug \
						src/lib_ffi \
						src/lib_init \
						src/lib_io \
						src/lib_jit \
						src/lib_math \
						src/lib_os \
						src/lib_package \
						src/lib_string \
						src/lib_table \
						src/lj_alloc \
						src/lj_api \
						src/lj_asm \
						src/lj_bc \
						src/lj_bcread \
						src/lj_bcwrite \
						src/lj_carith \
						src/lj_ccall \
						src/lj_ccallback \
						src/lj_cconv \
						src/lj_cdata \
						src/lj_char \
						src/lj_clib \
						src/lj_cparse \
						src/lj_crecord \
						src/lj_ctype \
						src/lj_debug \
						src/lj_dispatch \
						src/lj_err \
						src/lj_ffrecord \
						src/lj_func \
						src/lj_gc \
						src/lj_gdbjit \
						src/lj_ir \
						src/lj_lex \
						src/lj_lib \
						src/lj_load \
						src/lj_mcode \
						src/lj_meta \
						src/lj_obj \
						src/lj_opt_dce \
						src/lj_opt_fold \
						src/lj_opt_loop \
						src/lj_opt_mem \
						src/lj_opt_narrow \
						src/lj_opt_sink \
						src/lj_opt_split \
						src/lj_parse \
						src/lj_record \
						src/lj_snap \
						src/lj_state \
						src/lj_str \
						src/lj_strscan \
						src/lj_tab \
						src/lj_trace \
						src/lj_udata \
						src/lj_vmevent \
						src/lj_vmmath \
						src/lj_buf \
						src/lj_strfmt \
						src/lj_strfmt_num \
						src/lj_profile

# asm files
ifeq ($(PLAT),windows)
luajit_OBJ_FILES 		+= \
						src/autogen/$(PLAT)/$(luajit_JIT)/$(ARCH)/lj_vm
else
luajit_ASM_FILES 		+= \
						src/autogen/$(PLAT)/$(luajit_JIT)/$(ARCH)/lj_vm
endif

# includes
luajit_INC_DIRS 		+= \
						src/autogen/$(PLAT)/$(luajit_JIT)/$(ARCH)

# disable jit compiler
ifeq ($(luajit_JIT),nojit)
luajit_CXFLAGS 			+= -DLUAJIT_DISABLE_JIT
endif

										
# suffix
include $(PRO_DIR)/suffix.mak

