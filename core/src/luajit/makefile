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
						repo/src/lib_aux \
						repo/src/lib_base \
						repo/src/lib_bit \
						repo/src/lib_debug \
						repo/src/lib_ffi \
						repo/src/lib_init \
						repo/src/lib_io \
						repo/src/lib_jit \
						repo/src/lib_math \
						repo/src/lib_os \
						repo/src/lib_package \
						repo/src/lib_string \
						repo/src/lib_table \
						repo/src/lj_alloc \
						repo/src/lj_api \
						repo/src/lj_asm \
						repo/src/lj_bc \
						repo/src/lj_bcread \
						repo/src/lj_bcwrite \
						repo/src/lj_carith \
						repo/src/lj_ccall \
						repo/src/lj_ccallback \
						repo/src/lj_cconv \
						repo/src/lj_cdata \
						repo/src/lj_char \
						repo/src/lj_clib \
						repo/src/lj_cparse \
						repo/src/lj_crecord \
						repo/src/lj_ctype \
						repo/src/lj_debug \
						repo/src/lj_dispatch \
						repo/src/lj_err \
						repo/src/lj_ffrecord \
						repo/src/lj_func \
						repo/src/lj_gc \
						repo/src/lj_gdbjit \
						repo/src/lj_ir \
						repo/src/lj_lex \
						repo/src/lj_lib \
						repo/src/lj_load \
						repo/src/lj_mcode \
						repo/src/lj_meta \
						repo/src/lj_obj \
						repo/src/lj_opt_dce \
						repo/src/lj_opt_fold \
						repo/src/lj_opt_loop \
						repo/src/lj_opt_mem \
						repo/src/lj_opt_narrow \
						repo/src/lj_opt_sink \
						repo/src/lj_opt_split \
						repo/src/lj_parse \
						repo/src/lj_record \
						repo/src/lj_snap \
						repo/src/lj_state \
						repo/src/lj_str \
						repo/src/lj_strscan \
						repo/src/lj_tab \
						repo/src/lj_trace \
						repo/src/lj_udata \
						repo/src/lj_vmevent \
						repo/src/lj_vmmath \
						repo/src/lj_buf \
						repo/src/lj_strfmt \
						repo/src/lj_strfmt_num \
						repo/src/lj_profile

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

