/* This is a generated file. DO NOT EDIT! */

#ifdef LJLIB_MODULE_base
#undef LJLIB_MODULE_base
static const lua_CFunction lj_lib_cf_base[] = {
  lj_ffh_assert,
  lj_ffh_next,
  lj_ffh_pairs,
  lj_ffh_ipairs_aux,
  lj_ffh_ipairs,
  lj_ffh_setmetatable,
  lj_cf_getfenv,
  lj_cf_setfenv,
  lj_ffh_rawget,
  lj_cf_rawset,
  lj_cf_rawequal,
  lj_cf_unpack,
  lj_cf_select,
  lj_ffh_tonumber,
  lj_ffh_tostring,
  lj_cf_error,
  lj_ffh_pcall,
  lj_cf_loadfile,
  lj_cf_load,
  lj_cf_loadstring,
  lj_cf_dofile,
  lj_cf_gcinfo,
  lj_cf_collectgarbage,
  lj_cf_newproxy,
  lj_cf_print
};
static const uint8_t lj_lib_init_base[] = {
2,0,28,70,97,115,115,101,114,116,195,110,105,108,199,98,111,111,108,101,97,
110,252,1,200,117,115,101,114,100,97,116,97,198,115,116,114,105,110,103,197,
117,112,118,97,108,198,116,104,114,101,97,100,197,112,114,111,116,111,200,102,
117,110,99,116,105,111,110,197,116,114,97,99,101,197,99,100,97,116,97,197,116,
97,98,108,101,252,9,198,110,117,109,98,101,114,132,116,121,112,101,68,110,101,
120,116,253,69,112,97,105,114,115,64,253,70,105,112,97,105,114,115,140,103,
101,116,109,101,116,97,116,97,98,108,101,76,115,101,116,109,101,116,97,116,
97,98,108,101,7,103,101,116,102,101,110,118,7,115,101,116,102,101,110,118,70,
114,97,119,103,101,116,6,114,97,119,115,101,116,8,114,97,119,101,113,117,97,
108,6,117,110,112,97,99,107,6,115,101,108,101,99,116,72,116,111,110,117,109,
98,101,114,72,116,111,115,116,114,105,110,103,5,101,114,114,111,114,69,112,
99,97,108,108,134,120,112,99,97,108,108,8,108,111,97,100,102,105,108,101,4,
108,111,97,100,10,108,111,97,100,115,116,114,105,110,103,6,100,111,102,105,
108,101,6,103,99,105,110,102,111,14,99,111,108,108,101,99,116,103,97,114,98,
97,103,101,252,2,8,110,101,119,112,114,111,120,121,200,116,111,115,116,114,
105,110,103,5,112,114,105,110,116,252,3,200,95,86,69,82,83,73,79,78,250,255
};
#endif

#ifdef LJLIB_MODULE_coroutine
#undef LJLIB_MODULE_coroutine
static const lua_CFunction lj_lib_cf_coroutine[] = {
  lj_cf_coroutine_status,
  lj_cf_coroutine_running,
  lj_cf_coroutine_isyieldable,
  lj_cf_coroutine_create,
  lj_ffh_coroutine_yield,
  lj_ffh_coroutine_resume,
  lj_cf_coroutine_wrap
};
static const uint8_t lj_lib_init_coroutine[] = {
30,13,7,6,115,116,97,116,117,115,7,114,117,110,110,105,110,103,11,105,115,121,
105,101,108,100,97,98,108,101,6,99,114,101,97,116,101,69,121,105,101,108,100,
70,114,101,115,117,109,101,254,4,119,114,97,112,255
};
#endif

#ifdef LJLIB_MODULE_math
#undef LJLIB_MODULE_math
static const lua_CFunction lj_lib_cf_math[] = {
  lj_ffh_math_abs,
  lj_ffh_math_sqrt,
  lj_ffh_math_log,
  lj_ffh_math_atan2,
  lj_ffh_math_ldexp,
  lj_ffh_math_min,
  lj_cf_math_random,
  lj_cf_math_randomseed
};
static const uint8_t lj_lib_init_math[] = {
38,16,30,67,97,98,115,133,102,108,111,111,114,132,99,101,105,108,68,115,113,
114,116,133,108,111,103,49,48,131,101,120,112,131,115,105,110,131,99,111,115,
131,116,97,110,132,97,115,105,110,132,97,99,111,115,132,97,116,97,110,132,115,
105,110,104,132,99,111,115,104,132,116,97,110,104,133,102,114,101,120,112,132,
109,111,100,102,67,108,111,103,249,3,100,101,103,0,1,2,0,0,1,2,24,1,0,0,76,
1,2,0,241,135,158,166,3,220,203,178,130,4,249,3,114,97,100,0,1,2,0,0,1,2,24,
1,0,0,76,1,2,0,243,244,148,165,20,198,190,199,252,3,69,97,116,97,110,50,131,
112,111,119,132,102,109,111,100,69,108,100,101,120,112,67,109,105,110,131,109,
97,120,251,24,45,68,84,251,33,9,64,194,112,105,250,251,0,0,0,0,0,0,240,127,
196,104,117,103,101,250,252,2,6,114,97,110,100,111,109,252,2,10,114,97,110,
100,111,109,115,101,101,100,255
};
#endif

#ifdef LJLIB_MODULE_bit
#undef LJLIB_MODULE_bit
static const lua_CFunction lj_lib_cf_bit[] = {
  lj_ffh_bit_tobit,
  lj_ffh_bit_bnot,
  lj_ffh_bit_bswap,
  lj_ffh_bit_lshift,
  lj_ffh_bit_band,
  lj_cf_bit_tohex
};
static const uint8_t lj_lib_init_bit[] = {
64,40,12,69,116,111,98,105,116,68,98,110,111,116,69,98,115,119,97,112,70,108,
115,104,105,102,116,134,114,115,104,105,102,116,135,97,114,115,104,105,102,
116,131,114,111,108,131,114,111,114,68,98,97,110,100,131,98,111,114,132,98,
120,111,114,5,116,111,104,101,120,255
};
#endif

#ifdef LJLIB_MODULE_string
#undef LJLIB_MODULE_string
static const lua_CFunction lj_lib_cf_string[] = {
  lj_ffh_string_byte,
  lj_ffh_string_char,
  lj_ffh_string_sub,
  lj_cf_string_rep,
  lj_ffh_string_reverse,
  lj_cf_string_dump,
  lj_cf_string_find,
  lj_cf_string_match,
  lj_cf_string_gmatch,
  lj_cf_string_gsub,
  lj_cf_string_format
};
static const uint8_t lj_lib_init_string[] = {
76,51,14,249,3,108,101,110,0,1,2,0,0,0,3,16,0,5,0,21,1,0,0,76,1,2,0,68,98,121,
116,101,68,99,104,97,114,67,115,117,98,3,114,101,112,71,114,101,118,101,114,
115,101,133,108,111,119,101,114,133,117,112,112,101,114,4,100,117,109,112,4,
102,105,110,100,5,109,97,116,99,104,254,6,103,109,97,116,99,104,4,103,115,117,
98,6,102,111,114,109,97,116,255
};
#endif

#ifdef LJLIB_MODULE_table
#undef LJLIB_MODULE_table
static const lua_CFunction lj_lib_cf_table[] = {
  lj_cf_table_maxn,
  lj_cf_table_insert,
  lj_cf_table_concat,
  lj_cf_table_sort
};
static const uint8_t lj_lib_init_table[] = {
90,57,9,249,8,102,111,114,101,97,99,104,105,0,2,9,0,0,0,15,16,0,12,0,16,1,9,
0,41,2,1,0,21,3,0,0,41,4,1,0,77,2,8,128,18,6,1,0,18,7,5,0,59,8,5,0,66,6,3,2,
10,6,0,0,88,7,1,128,76,6,2,0,79,2,248,127,75,0,1,0,249,7,102,111,114,101,97,
99,104,0,2,10,0,0,0,16,16,0,12,0,16,1,9,0,43,2,0,0,18,3,0,0,41,4,0,0,88,5,7,
128,18,7,1,0,18,8,5,0,18,9,6,0,66,7,3,2,10,7,0,0,88,8,1,128,76,7,2,0,70,5,3,
3,82,5,247,127,75,0,1,0,249,4,103,101,116,110,0,1,2,0,0,0,3,16,0,12,0,21,1,
0,0,76,1,2,0,4,109,97,120,110,6,105,110,115,101,114,116,249,6,114,101,109,111,
118,101,0,2,10,0,0,2,30,16,0,12,0,21,2,0,0,11,1,0,0,88,3,7,128,8,2,0,0,88,3,
23,128,59,3,2,0,43,4,0,0,64,4,2,0,76,3,2,0,88,3,18,128,16,1,14,0,41,3,1,0,3,
3,1,0,88,3,14,128,3,1,2,0,88,3,12,128,59,3,1,0,22,4,1,1,18,5,2,0,41,6,1,0,77,
4,4,128,23,8,1,7,59,9,7,0,64,9,8,0,79,4,252,127,43,4,0,0,64,4,2,0,76,3,2,0,
75,0,1,0,0,2,249,4,109,111,118,101,0,5,12,0,0,0,35,16,0,12,0,16,1,14,0,16,2,
14,0,16,3,14,0,11,4,0,0,88,5,1,128,18,4,0,0,16,4,12,0,3,1,2,0,88,5,24,128,33,
5,1,3,0,2,3,0,88,6,4,128,2,3,1,0,88,6,2,128,4,4,0,0,88,6,9,128,18,6,1,0,18,
7,2,0,41,8,1,0,77,6,4,128,32,10,5,9,59,11,9,0,64,11,10,4,79,6,252,127,88,6,
8,128,18,6,2,0,18,7,1,0,41,8,255,255,77,6,4,128,32,10,5,9,59,11,9,0,64,11,10,
4,79,6,252,127,76,4,2,0,6,99,111,110,99,97,116,4,115,111,114,116,254,254,255
};
#endif

#ifdef LJLIB_MODULE_io_method
#undef LJLIB_MODULE_io_method
static const lua_CFunction lj_lib_cf_io_method[] = {
  lj_cf_io_method_close,
  lj_cf_io_method_read,
  lj_cf_io_method_write,
  lj_cf_io_method_flush,
  lj_cf_io_method_seek,
  lj_cf_io_method_setvbuf,
  lj_cf_io_method_lines,
  lj_cf_io_method___gc,
  lj_cf_io_method___tostring
};
static const uint8_t lj_lib_init_io_method[] = {
96,57,10,5,99,108,111,115,101,4,114,101,97,100,5,119,114,105,116,101,5,102,
108,117,115,104,4,115,101,101,107,7,115,101,116,118,98,117,102,5,108,105,110,
101,115,4,95,95,103,99,10,95,95,116,111,115,116,114,105,110,103,252,1,199,95,
95,105,110,100,101,120,250,255
};
#endif

#ifdef LJLIB_MODULE_io
#undef LJLIB_MODULE_io
static const lua_CFunction lj_lib_cf_io[] = {
  lj_cf_io_open,
  lj_cf_io_popen,
  lj_cf_io_tmpfile,
  lj_cf_io_close,
  lj_cf_io_read,
  lj_cf_io_write,
  lj_cf_io_flush,
  lj_cf_io_input,
  lj_cf_io_output,
  lj_cf_io_lines,
  lj_cf_io_type
};
static const uint8_t lj_lib_init_io[] = {
105,57,12,252,2,192,250,4,111,112,101,110,5,112,111,112,101,110,7,116,109,112,
102,105,108,101,5,99,108,111,115,101,4,114,101,97,100,5,119,114,105,116,101,
5,102,108,117,115,104,5,105,110,112,117,116,6,111,117,116,112,117,116,5,108,
105,110,101,115,4,116,121,112,101,255
};
#endif

#ifdef LJLIB_MODULE_os
#undef LJLIB_MODULE_os
static const lua_CFunction lj_lib_cf_os[] = {
  lj_cf_os_execute,
  lj_cf_os_remove,
  lj_cf_os_rename,
  lj_cf_os_tmpname,
  lj_cf_os_getenv,
  lj_cf_os_exit,
  lj_cf_os_clock,
  lj_cf_os_date,
  lj_cf_os_time,
  lj_cf_os_difftime,
  lj_cf_os_setlocale
};
static const uint8_t lj_lib_init_os[] = {
116,57,11,7,101,120,101,99,117,116,101,6,114,101,109,111,118,101,6,114,101,
110,97,109,101,7,116,109,112,110,97,109,101,6,103,101,116,101,110,118,4,101,
120,105,116,5,99,108,111,99,107,4,100,97,116,101,4,116,105,109,101,8,100,105,
102,102,116,105,109,101,9,115,101,116,108,111,99,97,108,101,255
};
#endif

#ifdef LJLIB_MODULE_debug
#undef LJLIB_MODULE_debug
static const lua_CFunction lj_lib_cf_debug[] = {
  lj_cf_debug_getregistry,
  lj_cf_debug_getmetatable,
  lj_cf_debug_setmetatable,
  lj_cf_debug_getfenv,
  lj_cf_debug_setfenv,
  lj_cf_debug_getinfo,
  lj_cf_debug_getlocal,
  lj_cf_debug_setlocal,
  lj_cf_debug_getupvalue,
  lj_cf_debug_setupvalue,
  lj_cf_debug_upvalueid,
  lj_cf_debug_upvaluejoin,
  lj_cf_debug_sethook,
  lj_cf_debug_gethook,
  lj_cf_debug_debug,
  lj_cf_debug_traceback
};
static const uint8_t lj_lib_init_debug[] = {
127,57,16,11,103,101,116,114,101,103,105,115,116,114,121,12,103,101,116,109,
101,116,97,116,97,98,108,101,12,115,101,116,109,101,116,97,116,97,98,108,101,
7,103,101,116,102,101,110,118,7,115,101,116,102,101,110,118,7,103,101,116,105,
110,102,111,8,103,101,116,108,111,99,97,108,8,115,101,116,108,111,99,97,108,
10,103,101,116,117,112,118,97,108,117,101,10,115,101,116,117,112,118,97,108,
117,101,9,117,112,118,97,108,117,101,105,100,11,117,112,118,97,108,117,101,
106,111,105,110,7,115,101,116,104,111,111,107,7,103,101,116,104,111,111,107,
5,100,101,98,117,103,9,116,114,97,99,101,98,97,99,107,255
};
#endif

#ifdef LJLIB_MODULE_jit
#undef LJLIB_MODULE_jit
static const lua_CFunction lj_lib_cf_jit[] = {
  lj_cf_jit_on,
  lj_cf_jit_off,
  lj_cf_jit_flush,
  lj_cf_jit_status,
  lj_cf_jit_attach
};
static const uint8_t lj_lib_init_jit[] = {
143,57,9,2,111,110,3,111,102,102,5,102,108,117,115,104,6,115,116,97,116,117,
115,6,97,116,116,97,99,104,252,5,194,111,115,250,252,4,196,97,114,99,104,250,
252,3,203,118,101,114,115,105,111,110,95,110,117,109,250,252,2,199,118,101,
114,115,105,111,110,250,255
};
#endif

#ifdef LJLIB_MODULE_jit_util
#undef LJLIB_MODULE_jit_util
static const lua_CFunction lj_lib_cf_jit_util[] = {
  lj_cf_jit_util_funcinfo,
  lj_cf_jit_util_funcbc,
  lj_cf_jit_util_funck,
  lj_cf_jit_util_funcuvname,
  lj_cf_jit_util_traceinfo,
  lj_cf_jit_util_traceir,
  lj_cf_jit_util_tracek,
  lj_cf_jit_util_tracesnap,
  lj_cf_jit_util_tracemc,
  lj_cf_jit_util_traceexitstub,
  lj_cf_jit_util_ircalladdr
};
static const uint8_t lj_lib_init_jit_util[] = {
148,57,11,8,102,117,110,99,105,110,102,111,6,102,117,110,99,98,99,5,102,117,
110,99,107,10,102,117,110,99,117,118,110,97,109,101,9,116,114,97,99,101,105,
110,102,111,7,116,114,97,99,101,105,114,6,116,114,97,99,101,107,9,116,114,97,
99,101,115,110,97,112,7,116,114,97,99,101,109,99,13,116,114,97,99,101,101,120,
105,116,115,116,117,98,10,105,114,99,97,108,108,97,100,100,114,255
};
#endif

#ifdef LJLIB_MODULE_jit_opt
#undef LJLIB_MODULE_jit_opt
static const lua_CFunction lj_lib_cf_jit_opt[] = {
  lj_cf_jit_opt_start
};
static const uint8_t lj_lib_init_jit_opt[] = {
159,57,1,5,115,116,97,114,116,255
};
#endif

#ifdef LJLIB_MODULE_jit_profile
#undef LJLIB_MODULE_jit_profile
static const lua_CFunction lj_lib_cf_jit_profile[] = {
  lj_cf_jit_profile_start,
  lj_cf_jit_profile_stop,
  lj_cf_jit_profile_dumpstack
};
static const uint8_t lj_lib_init_jit_profile[] = {
160,57,3,5,115,116,97,114,116,4,115,116,111,112,9,100,117,109,112,115,116,97,
99,107,255
};
#endif

#ifdef LJLIB_MODULE_ffi_meta
#undef LJLIB_MODULE_ffi_meta
static const lua_CFunction lj_lib_cf_ffi_meta[] = {
  lj_cf_ffi_meta___index,
  lj_cf_ffi_meta___newindex,
  lj_cf_ffi_meta___eq,
  lj_cf_ffi_meta___len,
  lj_cf_ffi_meta___lt,
  lj_cf_ffi_meta___le,
  lj_cf_ffi_meta___concat,
  lj_cf_ffi_meta___call,
  lj_cf_ffi_meta___add,
  lj_cf_ffi_meta___sub,
  lj_cf_ffi_meta___mul,
  lj_cf_ffi_meta___div,
  lj_cf_ffi_meta___mod,
  lj_cf_ffi_meta___pow,
  lj_cf_ffi_meta___unm,
  lj_cf_ffi_meta___tostring,
  lj_cf_ffi_meta___pairs,
  lj_cf_ffi_meta___ipairs
};
static const uint8_t lj_lib_init_ffi_meta[] = {
163,57,19,7,95,95,105,110,100,101,120,10,95,95,110,101,119,105,110,100,101,
120,4,95,95,101,113,5,95,95,108,101,110,4,95,95,108,116,4,95,95,108,101,8,95,
95,99,111,110,99,97,116,6,95,95,99,97,108,108,5,95,95,97,100,100,5,95,95,115,
117,98,5,95,95,109,117,108,5,95,95,100,105,118,5,95,95,109,111,100,5,95,95,
112,111,119,5,95,95,117,110,109,10,95,95,116,111,115,116,114,105,110,103,7,
95,95,112,97,105,114,115,8,95,95,105,112,97,105,114,115,195,102,102,105,203,
95,95,109,101,116,97,116,97,98,108,101,250,255
};
#endif

#ifdef LJLIB_MODULE_ffi_clib
#undef LJLIB_MODULE_ffi_clib
static const lua_CFunction lj_lib_cf_ffi_clib[] = {
  lj_cf_ffi_clib___index,
  lj_cf_ffi_clib___newindex,
  lj_cf_ffi_clib___gc
};
static const uint8_t lj_lib_init_ffi_clib[] = {
181,57,3,7,95,95,105,110,100,101,120,10,95,95,110,101,119,105,110,100,101,120,
4,95,95,103,99,255
};
#endif

#ifdef LJLIB_MODULE_ffi_callback
#undef LJLIB_MODULE_ffi_callback
static const lua_CFunction lj_lib_cf_ffi_callback[] = {
  lj_cf_ffi_callback_free,
  lj_cf_ffi_callback_set
};
static const uint8_t lj_lib_init_ffi_callback[] = {
184,57,3,4,102,114,101,101,3,115,101,116,252,1,199,95,95,105,110,100,101,120,
250,255
};
#endif

#ifdef LJLIB_MODULE_ffi
#undef LJLIB_MODULE_ffi
static const lua_CFunction lj_lib_cf_ffi[] = {
  lj_cf_ffi_cdef,
  lj_cf_ffi_new,
  lj_cf_ffi_cast,
  lj_cf_ffi_typeof,
  lj_cf_ffi_typeinfo,
  lj_cf_ffi_istype,
  lj_cf_ffi_sizeof,
  lj_cf_ffi_alignof,
  lj_cf_ffi_offsetof,
  lj_cf_ffi_errno,
  lj_cf_ffi_string,
  lj_cf_ffi_copy,
  lj_cf_ffi_fill,
  lj_cf_ffi_abi,
  lj_cf_ffi_metatype,
  lj_cf_ffi_gc,
  lj_cf_ffi_load
};
static const uint8_t lj_lib_init_ffi[] = {
186,57,23,4,99,100,101,102,3,110,101,119,4,99,97,115,116,6,116,121,112,101,
111,102,8,116,121,112,101,105,110,102,111,6,105,115,116,121,112,101,6,115,105,
122,101,111,102,7,97,108,105,103,110,111,102,8,111,102,102,115,101,116,111,
102,5,101,114,114,110,111,6,115,116,114,105,110,103,4,99,111,112,121,4,102,
105,108,108,3,97,98,105,252,8,192,250,8,109,101,116,97,116,121,112,101,252,
7,192,250,2,103,99,252,5,192,250,4,108,111,97,100,252,4,193,67,250,252,3,194,
111,115,250,252,2,196,97,114,99,104,250,255
};
#endif

