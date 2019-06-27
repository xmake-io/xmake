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
						luajit/src/lj_profile

# asm files
ifeq ($(PLAT),windows)
luajit_OBJ_FILES 		+= \
						autogen/$(PLAT)/$(luajit_JIT)/$(ARCH)/lj_vm
else
luajit_ASM_FILES 		+= \
						autogen/$(PLAT)/$(luajit_JIT)/$(ARCH)/lj_vm
endif

# includes
luajit_INC_DIRS 		+= \
						autogen/$(PLAT)/$(luajit_JIT)/$(ARCH)

# disable jit compiler
ifeq ($(luajit_JIT),nojit)
luajit_CXFLAGS 			+= -DLUAJIT_DISABLE_JIT
endif

# enable lua5.2 compat, @see http://luajit.org/extensions.html
#luajit_CXFLAGS 			+= -DLUAJIT_ENABLE_LUA52COMPAT -Wno-error=unused-function

										
# suffix
include $(PRO_DIR)/suffix.mak

