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
 * @file        keyword.h
 *
 */
#ifndef TB_PREFIX_KEYWORD_H
#define TB_PREFIX_KEYWORD_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "compiler.h"
#include "cpu.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the register keyword will be deprecated in C++ 
#ifndef __cplusplus 
#   define __tb_register__                      register
#else
#   define __tb_register__                      
#endif
#define __tb_volatile__                         volatile
#define __tb_func__                             __FUNCTION__
#define __tb_file__                             __FILE__
#define __tb_line__                             __LINE__

#if defined(TB_COMPILER_IS_MSVC)

#   define __tb_asm__                           __asm
#   define __tb_inline__                        __inline
#   define __tb_inline_force__                  __forceinline
#   define __tb_cdecl__                         __cdecl
#   define __tb_stdcall__                       __stdcall
#   define __tb_fastcall__                      __fastcall
#   define __tb_thiscall__                      __thiscall
#   define __tb_packed__ 
#   define __tb_aligned__(a)                    __declspec(align(a))

#elif defined(TB_COMPILER_IS_GCC)

#   define __tb_asm__                           __asm__
#   define __tb_inline__                        __inline__
#   define __tb_inline_force__                  __inline__ __attribute__((always_inline))
#   define __tb_packed__                        __attribute__((packed, aligned(1)))
#   define __tb_aligned__(a)                    __attribute__((aligned(a)))
    // gcc will generate attribute ignored warning
#   if defined(__x86_64) \
    || defined(__amd64__) \
    || defined(__amd64) \
    || defined(_M_IA64) \
    || defined(_M_X64)
#       define __tb_cdecl__                     
#       define __tb_stdcall__                   
#       define __tb_fastcall__                  
#       define __tb_thiscall__                  
#   else
#       define __tb_cdecl__                     __attribute__((__cdecl__))
#       define __tb_stdcall__                   __attribute__((__stdcall__))
#       define __tb_fastcall__                  __attribute__((__fastcall__))
#       define __tb_thiscall__                  __attribute__((__thiscall__))
#   endif
#else

#   define __tb_asm__               
#   define __tb_inline__                        inline
#   define __tb_inline_force__                  inline
#   define __tb_func__                  
#   define __tb_file__                          ""
#   define __tb_line__                          (0)

#   define __tb_cdecl__     
#   define __tb_stdcall__       
#   define __tb_fastcall__      
#   define __tb_thiscall__
#   define __tb_packed__ 
#   define __tb_aligned__(a) 

#endif

/*! @def __tb_cpu_aligned__
 *
 * the cpu byte alignment
 */
#if (TB_CPU_BITBYTE == 8)
#   define __tb_cpu_aligned__                   __tb_aligned__(8)
#elif (TB_CPU_BITBYTE == 4)
#   define __tb_cpu_aligned__                   __tb_aligned__(4)
#elif (TB_CPU_BITBYTE == 2)
#   define __tb_cpu_aligned__                   __tb_aligned__(2)
#else
#   error unknown cpu bytes
#endif

// like
#if defined(TB_COMPILER_IS_GCC) && __GNUC__ > 2
#   define __tb_likely__(x)                     __builtin_expect((x), 1)
#   define __tb_unlikely__(x)                   __builtin_expect((x), 0)
#else
#   define __tb_likely__(x)                     (x)
#   define __tb_unlikely__(x)                   (x)
#endif

// debug
#ifdef __tb_debug__
#   define __tb_debug_decl__                    , tb_char_t const* func_, tb_size_t line_, tb_char_t const* file_
#   define __tb_debug_vals__                    , __tb_func__, __tb_line__, __tb_file__
#   define __tb_debug_args__                    , func_, line_, file_
#else 
#   define __tb_debug_decl__ 
#   define __tb_debug_vals__ 
#   define __tb_debug_args__ 
#endif

// small
#undef __tb_small__
#ifdef TB_CONFIG_SMALL
#   define __tb_small__
#endif

// newline
#ifdef TB_CONFIG_OS_WINDOWS
#   define __tb_newline__                       "\r\n"
#else
#   define __tb_newline__                       "\n"
#endif

// the string only for the large mode
#ifdef __tb_small__
#   define __tb_lstring__(x)                    tb_null
#else
#   define __tb_lstring__(x)                    x
#endif

// the string only for the debug mode
#ifdef __tb_debug__
#   define __tb_dstring__(x)                    x
#else
#   define __tb_dstring__(x)                    tb_null
#endif

// extern c
#ifdef __cplusplus
#   define __tb_extern_c__                      extern "C" 
#   define __tb_extern_c_enter__                extern "C" {
#   define __tb_extern_c_leave__                }
#else
#   define __tb_extern_c__
#   define __tb_extern_c_enter__
#   define __tb_extern_c_leave__                
#endif

// export for the shared library
#if defined(TB_COMPILER_IS_MSVC)
#   define __tb_export__                        __declspec(dllexport)
#elif defined(TB_COMPILER_IS_GCC) && ((__GNUC__ >= 4) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 3))
#   define __tb_export__                        __attribute__((visibility("default")))
#else
#   define __tb_export__         
#endif

// has feature
#ifdef __has_feature
#   define __tb_has_feature__(x)                            __has_feature(x)
#else
#   define __tb_has_feature__(x)                            0
#endif

// has include
#ifdef __has_include
#   define __tb_has_include__(x)                            __has_include(x)
#else
#   define __tb_has_include__(x)                            0
#endif

// has builtin
#ifdef __has_builtin
#   define __tb_has_builtin__(x)                            __has_builtin(x)
#else
#   define __tb_has_builtin__(x)                            0
#endif

// no_sanitize_address
#if __tb_has_feature__(address_sanitizer) || defined(__SANITIZE_ADDRESS__)
#   define __tb_no_sanitize_address__                       __attribute__((no_sanitize_address))
#else
#   define __tb_no_sanitize_address__
#endif

// macros
#define __tb_mstring__(x)                                   #x
#define __tb_mstring_ex__(x)                                __tb_mstring__(x)

#define __tb_mconcat__(a, b)                                a##b
#define __tb_mconcat_ex__(a, b)                             __tb_mconcat__(a, b)

#define __tb_mconcat3__(a, b, c)                            a##b##c
#define __tb_mconcat3_ex__(a, b, c)                         __tb_mconcat3__(a, b, c)

#define __tb_mconcat4__(a, b, c, d)                         a##b##c##d
#define __tb_mconcat4_ex__(a, b, c, d)                      __tb_mconcat4__(a, b, c, d)

#define __tb_mconcat5__(a, b, c, d, e)                      a##b##c##d##e
#define __tb_mconcat5_ex__(a, b, c, d, e)                   __tb_mconcat5__(a, b, c, d, e)

#define __tb_mconcat6__(a, b, c, d, e, f)                   a##b##c##d##e##f
#define __tb_mconcat6_ex__(a, b, c, d, e, f)                __tb_mconcat6__(a, b, c, d, e, f)

#define __tb_mconcat7__(a, b, c, d, e, f, g)                a##b##c##d##e##f##g
#define __tb_mconcat7_ex__(a, b, c, d, e, f, g)             __tb_mconcat7__(a, b, c, d, e, f, g)

#define __tb_mconcat8__(a, b, c, d, e, f, g, h)             a##b##c##d##e##f##g##h
#define __tb_mconcat8_ex__(a, b, c, d, e, f, g, h)          __tb_mconcat8__(a, b, c, d, e, f, g, h)

#define __tb_mconcat9__(a, b, c, d, e, f, g, h, i)          a##b##c##d##e##f##g##h##i
#define __tb_mconcat9_ex__(a, b, c, d, e, f, g, h, i)       __tb_mconcat9__(a, b, c, d, e, f, g, h, i)

#define __tb_mstrcat__(a, b)                                a b
#define __tb_mstrcat3__(a, b, c)                            a b c
#define __tb_mstrcat4__(a, b, c, d)                         a b c d
#define __tb_mstrcat5__(a, b, c, d, e)                      a b c d e
#define __tb_mstrcat6__(a, b, c, d, e, f)                   a b c d e f
#define __tb_mstrcat7__(a, b, c, d, e, f, g)                a b c d e f g
#define __tb_mstrcat8__(a, b, c, d, e, f, g, h)             a b c d e f g h
#define __tb_mstrcat9__(a, b, c, d, e, f, g, h, i)          a b c d e f g h i


#endif


