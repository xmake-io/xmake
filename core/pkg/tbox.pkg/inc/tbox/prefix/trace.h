/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        trace.h
 *
 */
#ifndef TB_PREFIX_TRACE_H
#define TB_PREFIX_TRACE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "type.h"
#include "keyword.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the trace prefix
#ifndef __tb_prefix__ 
#   define __tb_prefix__                                    tb_null
#endif

// the trace module name
#ifndef TB_TRACE_MODULE_NAME
#   define TB_TRACE_MODULE_NAME                             tb_null
#endif

// the trace module debug
#ifndef TB_TRACE_MODULE_DEBUG
#   define TB_TRACE_MODULE_DEBUG                            (1)
#endif

// trace prefix
#if defined(TB_COMPILER_IS_GCC)
#   define tb_trace_p(prefix, fmt, arg ...)                 do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, fmt __tb_newline__, ## arg); } while (0)
#   define tb_tracef_p(prefix, fmt, arg ...)                do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, fmt, ## arg); } while (0)
#   ifdef __tb_debug__
#       define tb_trace_error_p(prefix, fmt, arg ...)       do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[error]: " fmt " at %s(): %d, %s" __tb_newline__, ##arg, __tb_func__, __tb_line__, __tb_file__); tb_trace_sync(); } while (0)
#       define tb_trace_assert_p(prefix, fmt, arg ...)      do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[assert]: " fmt " at %s(): %d, %s" __tb_newline__, ##arg, __tb_func__, __tb_line__, __tb_file__); tb_trace_sync(); } while (0)
#       define tb_trace_warning_p(prefix, fmt, arg ...)     do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[warning]: " fmt " at %s(): %d, %s" __tb_newline__, ##arg, __tb_func__, __tb_line__, __tb_file__); tb_trace_sync(); } while (0)
#       define tb_tracef_error_p(prefix, fmt, arg ...)      do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[error]: " fmt " at %s(): %d, %s", ##arg, __tb_func__, __tb_line__, __tb_file__); tb_trace_sync(); } while (0)
#       define tb_tracef_assert_p(prefix, fmt, arg ...)     do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[assert]: " fmt " at %s(): %d, %s", ##arg, __tb_func__, __tb_line__, __tb_file__); tb_trace_sync(); } while (0)
#       define tb_tracef_warning_p(prefix, fmt, arg ...)    do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[warning]: " fmt " at %s(): %d, %s", ##arg, __tb_func__, __tb_line__, __tb_file__); tb_trace_sync(); } while (0)
#   else
#       define tb_trace_error_p(prefix, fmt, arg ...)       
#       define tb_trace_assert_p(prefix, fmt, arg ...)       
#       define tb_trace_warning_p(prefix, fmt, arg ...)       
#       define tb_tracef_error_p(prefix, fmt, arg ...)       
#       define tb_tracef_assert_p(prefix, fmt, arg ...)       
#       define tb_tracef_warning_p(prefix, fmt, arg ...)       
#   endif
#elif defined(TB_COMPILER_IS_MSVC) && TB_COMPILER_VERSION_BE(13, 0)
#   define tb_trace_p(prefix, fmt, ...)                     do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, fmt __tb_newline__, __VA_ARGS__); } while (0)
#   define tb_tracef_p(prefix, fmt, ...)                    do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, fmt, __VA_ARGS__); } while (0)
#   ifdef __tb_debug__
#       define tb_trace_error_p(prefix, fmt, ...)           do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[error]: at %s(): %d, %s: " fmt __tb_newline__, __tb_func__, __tb_line__, __tb_file__, __VA_ARGS__); tb_trace_sync(); } while (0)
#       define tb_trace_assert_p(prefix, fmt, ...)          do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[assert]: at %s(): %d, %s: " fmt __tb_newline__, __tb_func__, __tb_line__, __tb_file__, __VA_ARGS__); tb_trace_sync(); } while (0)
#       define tb_trace_warning_p(prefix, fmt, ...)         do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[warning]: at %s(): %d, %s: " fmt __tb_newline__, __tb_func__, __tb_line__, __tb_file__, __VA_ARGS__); tb_trace_sync(); } while (0)
#       define tb_tracef_error_p(prefix, fmt, ...)          do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[error]: at %s(): %d, %s: " fmt, __tb_func__, __tb_line__, __tb_file__, __VA_ARGS__); tb_trace_sync(); } while (0)
#       define tb_tracef_assert_p(prefix, fmt, ...)         do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[assert]: at %s(): %d, %s: " fmt, __tb_func__, __tb_line__, __tb_file__, __VA_ARGS__); tb_trace_sync(); } while (0)
#       define tb_tracef_warning_p(prefix, fmt, ...)        do { tb_trace_done(prefix, TB_TRACE_MODULE_NAME, "[warning]: at %s(): %d, %s: " fmt, __tb_func__, __tb_line__, __tb_file__, __VA_ARGS__); tb_trace_sync(); } while (0)
#   else
#       define tb_trace_error_p(prefix, fmt, ...)       
#       define tb_trace_assert_p(prefix, fmt, ...)       
#       define tb_trace_warning_p(prefix, fmt, ...)       
#       define tb_tracef_error_p(prefix, fmt, ...)       
#       define tb_tracef_assert_p(prefix, fmt, ...)       
#       define tb_tracef_warning_p(prefix, fmt, ...)       
#   endif
#else
#   define tb_trace_p
#   define tb_trace_error_p
#   define tb_trace_assert_p
#   define tb_trace_warning_p
#   define tb_tracef_p
#   define tb_tracef_error_p
#   define tb_tracef_assert_p
#   define tb_tracef_warning_p
#endif

/* trace
 *
 * at file xxxx.c:
 *
 * // macros
 * #define TB_TRACE_MODULE_NAME     "module"
 * #define TB_TRACE_MODULE_DEBUG    (1)
 *
 * // includes
 * #include "tbox.h"
 *
 * // trace
 * tb_trace_d("trace debug");
 * tb_trace_i("trace info");
 * tb_trace_e("trace error");
 * tb_trace_w("trace warning");
 *
 * // output for debug
 * "[prefix]: [module]: trace debug"
 * "[prefix]: [module]: trace info"
 * "[prefix]: [module]: [error]: trace error" at func: xxx, line: xxx, file: xxx
 * "[prefix]: [module]: [warning]: trace warning" at func: xxx, line: xxx, file: xxx
 *
 * // output for release or TB_TRACE_MODULE_DEBUG == 0
 * "[prefix]: [module]: trace info"
 * "[prefix]: [module]: [error]: trace error" at func: xxx, line: xxx, file: xxx
 * "[prefix]: [module]: [warning]: trace warning" at func: xxx, line: xxx, file: xxx
 *
 * note: [module]: will be not output if TB_TRACE_MODULE_NAME is not defined
 *
 */
#if TB_TRACE_MODULE_DEBUG && defined(__tb_debug__) 
#   if defined(TB_COMPILER_IS_GCC)
#       define TB_TRACE_DEBUG
#       define tb_trace_d(fmt, arg ...)                 tb_trace_p(__tb_prefix__, fmt, ## arg)
#       define tb_tracef_d(fmt, arg ...)                tb_tracef_p(__tb_prefix__, fmt, ## arg)
#       define tb_tracet_d(fmt, arg ...)                tb_trace_tail(fmt, ## arg)
#   elif defined(TB_COMPILER_IS_MSVC) && TB_COMPILER_VERSION_BE(13, 0)
#       define TB_TRACE_DEBUG
#       define tb_trace_d(fmt, ...)                     tb_trace_p(__tb_prefix__, fmt, __VA_ARGS__)
#       define tb_tracef_d(fmt, ...)                    tb_tracef_p(__tb_prefix__, fmt, __VA_ARGS__)
#       define tb_tracet_d(fmt, ...)                    tb_trace_tail(fmt, __VA_ARGS__)
#   else
#       define tb_trace_d
#       define tb_tracef_d
#       define tb_tracet_d
#   endif
#else
#   if defined(TB_COMPILER_IS_GCC) || (defined(TB_COMPILER_IS_MSVC) && TB_COMPILER_VERSION_BE(13, 0))
#       define tb_trace_d(fmt, ...)         
#       define tb_tracef_d(fmt, ...)            
#       define tb_tracet_d(fmt, ...)            
#   else
#       define tb_trace_d
#       define tb_tracef_d
#       define tb_tracet_d
#   endif
#endif

#if defined(TB_COMPILER_IS_GCC)
#   define tb_trace_i(fmt, arg ...)                 tb_trace_p(__tb_prefix__, fmt, ## arg)
#   define tb_trace_e(fmt, arg ...)                 tb_trace_error_p(__tb_prefix__, fmt, ## arg)
#   define tb_trace_a(fmt, arg ...)                 tb_trace_assert_p(__tb_prefix__, fmt, ## arg)
#   define tb_trace_w(fmt, arg ...)                 tb_trace_warning_p(__tb_prefix__, fmt, ## arg)
#   define tb_tracef_i(fmt, arg ...)                tb_tracef_p(__tb_prefix__, fmt, ## arg)
#   define tb_tracef_e(fmt, arg ...)                tb_tracef_error_p(__tb_prefix__, fmt, ## arg)
#   define tb_tracef_a(fmt, arg ...)                tb_tracef_assert_p(__tb_prefix__, fmt, ## arg)
#   define tb_tracef_w(fmt, arg ...)                tb_tracef_warning_p(__tb_prefix__, fmt, ## arg)
#   define tb_tracet_i(fmt, arg ...)                tb_trace_tail(fmt, ## arg)
#   define tb_tracet_e(fmt, arg ...)                tb_trace_tail(fmt, ## arg)
#   define tb_tracet_a(fmt, arg ...)                tb_trace_tail(fmt, ## arg)
#   define tb_tracet_w(fmt, arg ...)                tb_trace_tail(fmt, ## arg)
#elif defined(TB_COMPILER_IS_MSVC) && TB_COMPILER_VERSION_BE(13, 0)
#   define tb_trace_i(fmt, ...)                     tb_trace_p(__tb_prefix__, fmt, __VA_ARGS__)
#   define tb_trace_e(fmt, ...)                     tb_trace_error_p(__tb_prefix__, fmt, __VA_ARGS__)
#   define tb_trace_a(fmt, ...)                     tb_trace_assert_p(__tb_prefix__, fmt, __VA_ARGS__)
#   define tb_trace_w(fmt, ...)                     tb_trace_warning_p(__tb_prefix__, fmt, __VA_ARGS__)
#   define tb_tracef_i(fmt, ...)                    tb_tracef_p(__tb_prefix__, fmt, __VA_ARGS__)
#   define tb_tracef_e(fmt, ...)                    tb_tracef_error_p(__tb_prefix__, fmt, __VA_ARGS__)
#   define tb_tracef_a(fmt, ...)                    tb_tracef_assert_p(__tb_prefix__, fmt, __VA_ARGS__)
#   define tb_tracef_w(fmt, ...)                    tb_tracef_warning_p(__tb_prefix__, fmt, __VA_ARGS__)
#   define tb_tracet_i(fmt, ...)                    tb_trace_tail(fmt, __VA_ARGS__)
#   define tb_tracet_e(fmt, ...)                    tb_trace_tail(fmt, __VA_ARGS__)
#   define tb_tracet_a(fmt, ...)                    tb_trace_tail(fmt, __VA_ARGS__)
#   define tb_tracet_w(fmt, ...)                    tb_trace_tail(fmt, __VA_ARGS__)
#else
#   define tb_trace_i
#   define tb_trace_e
#   define tb_trace_a
#   define tb_trace_w
#   define tb_tracef_i
#   define tb_tracef_e
#   define tb_tracef_a
#   define tb_tracef_w
#   define tb_tracet_i
#   define tb_tracet_e
#   define tb_tracet_a
#   define tb_tracet_w
#endif

// trace once
#if defined(TB_COMPILER_IS_GCC)
#   define tb_trace1_d(fmt, arg ...)                do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_d(fmt, ## arg); __trace_once = tb_true; } } while (0)
#   define tb_trace1_i(fmt, arg ...)                do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_i(fmt, ## arg); __trace_once = tb_true; } } while (0)
#   define tb_trace1_e(fmt, arg ...)                do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_e(fmt, ## arg); __trace_once = tb_true; } } while (0)
#   define tb_trace1_a(fmt, arg ...)                do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_a(fmt, ## arg); __trace_once = tb_true; } } while (0)
#   define tb_trace1_w(fmt, arg ...)                do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_w(fmt, ## arg); __trace_once = tb_true; } } while (0)
#elif defined(TB_COMPILER_IS_MSVC) && TB_COMPILER_VERSION_BE(13, 0)
#   define tb_trace1_d(fmt, ...)                    do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_d(fmt, __VA_ARGS__); __trace_once = tb_true; } } while (0)
#   define tb_trace1_i(fmt, ...)                    do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_i(fmt, __VA_ARGS__); __trace_once = tb_true; } } while (0)
#   define tb_trace1_e(fmt, ...)                    do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_e(fmt, __VA_ARGS__); __trace_once = tb_true; } } while (0)
#   define tb_trace1_a(fmt, ...)                    do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_a(fmt, __VA_ARGS__); __trace_once = tb_true; } } while (0)
#   define tb_trace1_w(fmt, ...)                    do { static tb_bool_t __trace_once = tb_false; if (!__trace_once) { tb_trace_w(fmt, __VA_ARGS__); __trace_once = tb_true; } } while (0)
#else
#   define tb_trace1_i
#endif

// trace info only?
#ifdef TB_CONFIG_TRACE_INFO_ONLY
#   undef TB_TRACE_DEBUG
#   undef TB_TRACE_MODULE_DEBUG
#   undef tb_trace_d
#   undef tb_trace_e
#   undef tb_trace_a
#   undef tb_trace_w
#   undef tb_tracef_d
#   undef tb_tracef_e
#   undef tb_tracef_a
#   undef tb_tracef_w
#   undef tb_tracet_d
#   undef tb_tracet_e
#   undef tb_tracet_a
#   undef tb_tracet_w
#   undef tb_trace1_d
#   undef tb_trace1_e
#   undef tb_trace1_a
#   undef tb_trace1_w
#   define TB_TRACE_MODULE_DEBUG    (0)
#   if defined(TB_COMPILER_IS_GCC)
#       define tb_trace_d(fmt, arg ...)                 
#       define tb_trace_e(fmt, arg ...)                 
#       define tb_trace_a(fmt, arg ...)                 
#       define tb_trace_w(fmt, arg ...)                 
#       define tb_tracef_d(fmt, arg ...)                
#       define tb_tracef_e(fmt, arg ...)                
#       define tb_tracef_a(fmt, arg ...)                
#       define tb_tracef_w(fmt, arg ...)                
#       define tb_tracet_d(fmt, arg ...)                
#       define tb_tracet_e(fmt, arg ...)                
#       define tb_tracet_a(fmt, arg ...)                
#       define tb_tracet_w(fmt, arg ...)                
#       define tb_trace1_d(fmt, arg ...)                
#       define tb_trace1_e(fmt, arg ...)                
#       define tb_trace1_a(fmt, arg ...)                
#       define tb_trace1_w(fmt, arg ...)               
#   elif defined(TB_COMPILER_IS_MSVC) && TB_COMPILER_VERSION_BE(13, 0)
#       define tb_trace_d(fmt, ...)                     
#       define tb_trace_e(fmt, ...)                     
#       define tb_trace_a(fmt, ...)                     
#       define tb_trace_w(fmt, ...)                     
#       define tb_tracef_d(fmt, ...)                    
#       define tb_tracef_e(fmt, ...)                    
#       define tb_tracef_a(fmt, ...)                    
#       define tb_tracef_w(fmt, ...)                    
#       define tb_tracet_d(fmt, ...)                   
#       define tb_tracet_e(fmt, ...)                    
#       define tb_tracet_a(fmt, ...)                    
#       define tb_tracet_w(fmt, ...)                  
#       define tb_trace1_d(fmt, ...)                   
#       define tb_trace1_e(fmt, ...)                    
#       define tb_trace1_a(fmt, ...)                    
#       define tb_trace1_w(fmt, ...)                     
#   else
#       define tb_trace_d
#       define tb_trace_e
#       define tb_trace_a
#       define tb_trace_w
#       define tb_tracef_d
#       define tb_tracef_e
#       define tb_tracef_a
#       define tb_tracef_w
#       define tb_tracet_d
#       define tb_tracet_e
#       define tb_tracet_a
#       define tb_tracet_w
#       define tb_trace1_d
#       define tb_trace1_e
#       define tb_trace1_a
#       define tb_trace1_w
#   endif
#endif

// noimpl
#define tb_trace_noimpl()                           tb_trace1_w("noimpl")

// nosafe
#define tb_trace_nosafe()                           tb_trace1_w("nosafe")

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */
tb_void_t       tb_trace_sync(tb_noarg_t);
tb_void_t       tb_trace_done(tb_char_t const* prefix, tb_char_t const* module, tb_char_t const* format, ...);
tb_void_t       tb_trace_tail(tb_char_t const* format, ...);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif


