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
 * @file        arch.h
 *
 */
#ifndef TB_PREFIX_ARCH_H
#define TB_PREFIX_ARCH_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "keyword.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/* arch
 *
 * gcc builtin macros for gcc -dM -E - < /dev/null
 *
 * .e.g gcc -m64 -dM -E - < /dev/null | grep 64
 * .e.g gcc -m32 -dM -E - < /dev/null | grep 86
 * .e.g gcc -march=armv6 -dM -E - < /dev/null | grep ARM
 */
#if defined(__i386) \
    || defined(__i686) \
    || defined(__i386__) \
    || defined(__i686__) \
    || defined(_M_IX86)
#   define TB_ARCH_x86
#   if defined(__i386) || defined(__i386__)
#       define  TB_ARCH_STRING              "i386"
#   elif defined(__i686) || defined(__i686__)
#       define  TB_ARCH_STRING              "i686"
#   elif defined(_M_IX86)
#       if (_M_IX86 == 300)
#           define  TB_ARCH_STRING          "i386"
#       elif (_M_IX86 == 400)
#           define  TB_ARCH_STRING          "i486"
#       elif (_M_IX86 == 500 || _M_IX86 == 600)
#           define  TB_ARCH_STRING          "Pentium"
#       endif
#   else
#       define TB_ARCH_STRING               "x86"
#   endif
#elif defined(__x86_64) \
    || defined(__amd64__) \
    || defined(__amd64) \
    || defined(_M_IA64) \
    || defined(_M_X64)
#   define TB_ARCH_x64
#   if defined(__x86_64)
#       define  TB_ARCH_STRING              "x86_64"
#   elif defined(__amd64__) || defined(__amd64)
#       define  TB_ARCH_STRING              "amd64"
#   else
#       define TB_ARCH_STRING               "x64"
#   endif
#elif defined(__arm__) || defined(__arm64) || defined(__arm64__)
#   define TB_ARCH_ARM
#   if defined(__ARM_ARCH)
#       define TB_ARCH_ARM_VERSION          __ARM_ARCH
#       if __ARM_ARCH >= 7
#           define TB_ARCH_ARM_v7
#           define  TB_ARCH_STRING          "armv7"
#       elif __ARM_ARCH >= 6
#           define TB_ARCH_ARM_v6
#           define  TB_ARCH_STRING          "armv6"
#       else
#           define TB_ARCH_ARM_v5
#           define TB_ARCH_STRING           "armv5"
#       endif
#   elif defined(__ARM64_ARCH_8__)
#       define TB_ARCH_ARM64
#       define TB_ARCH_ARM_VERSION          (8)
#       define TB_ARCH_ARM_v8
#       define  TB_ARCH_STRING              "arm64"
#   elif defined(__ARM_ARCH_7A__)
#       define TB_ARCH_ARM_VERSION          (7)
#       define TB_ARCH_ARM_v7A
#       define  TB_ARCH_STRING              "armv7a"
#   elif defined(__ARM_ARCH_7__)
#       define TB_ARCH_ARM_VERSION          (7)
#       define TB_ARCH_ARM_v7
#       define  TB_ARCH_STRING              "armv7"
#   elif defined(__ARM_ARCH_6__)
#       define TB_ARCH_ARM_VERSION          (6)
#       define TB_ARCH_ARM_v6
#       define  TB_ARCH_STRING              "armv6"
#   elif defined(__ARM_ARCH_5TE__)
#       define TB_ARCH_ARM_VERSION          (5)
#       define TB_ARCH_ARM_v5te
#       define  TB_ARCH_STRING              "armv5te"
#   elif defined(__ARM_ARCH_5__)
#       define TB_ARCH_ARM_VERSION          (5)
#       define TB_ARCH_ARM_v5
#       define  TB_ARCH_STRING              "armv5"
#   else 
#       error unknown arm arch version
#   endif
#   if !defined(TB_ARCH_ARM64) && (defined(__arm64) || defined(__arm64__))
#       define TB_ARCH_ARM64
#       ifndef TB_ARCH_STRING
#           define TB_ARCH_STRING           "arm64"
#       endif
#   endif
#   ifndef TB_ARCH_STRING
#       define TB_ARCH_STRING               "arm"
#   endif
#   if defined(__thumb__)
#       define TB_ARCH_ARM_THUMB
#       define TB_ARCH_STRING_2             "_thumb"
#   endif
#   if defined(__ARM_NEON__)
#       define TB_ARCH_ARM_NEON
#       define TB_ARCH_STRING_3             "_neon"
#   endif 
#elif defined(mips) \
    || defined(_mips) \
    || defined(__mips__)
#   define TB_ARCH_MIPS
#   define TB_ARCH_STRING                   "mips"
#else
//#     define TB_ARCH_SPARC
//#     define TB_ARCH_PPC
//#     define TB_ARCH_SH4
#   error unknown arch
#   define TB_ARCH_STRING                   "unknown_arch"
#endif

// sse
#if defined(TB_ARCH_x86) || defined(TB_ARCH_x64)
#   if defined(__SSE__)
#       define TB_ARCH_SSE
#       define TB_ARCH_STRING_2             "_sse"
#   endif
#   if defined(__SSE2__)
#       define TB_ARCH_SSE2
#       undef TB_ARCH_STRING_2
#       define TB_ARCH_STRING_2             "_sse2"
#   endif
#   if defined(__SSE3__)
#       define TB_ARCH_SSE3
#       undef TB_ARCH_STRING_2
#       define TB_ARCH_STRING_2             "_sse3"
#   endif
#endif

// vfp
#if defined(__VFP_FP__)
#   define TB_ARCH_VFP
#   define TB_ARCH_STRING_4                 "_vfp"
#endif

// elf
#if defined(__ELF__)
#   define TB_ARCH_ELF
#   define TB_ARCH_STRING_5                 "_elf"
#endif

// mach
#if defined(__MACH__)
#   define TB_ARCH_MACH
#   define TB_ARCH_STRING_5                 "_mach"
#endif

#ifndef TB_ARCH_STRING_1
#   define TB_ARCH_STRING_1                 ""
#endif

#ifndef TB_ARCH_STRING_2
#   define TB_ARCH_STRING_2                 ""
#endif

#ifndef TB_ARCH_STRING_3
#   define TB_ARCH_STRING_3                 ""
#endif

#ifndef TB_ARCH_STRING_4
#   define TB_ARCH_STRING_4                 ""
#endif

#ifndef TB_ARCH_STRING_5
#   define TB_ARCH_STRING_5                 ""
#endif


// version string
#ifndef TB_ARCH_VERSION_STRING
#   define TB_ARCH_VERSION_STRING           __tb_mstrcat6__(TB_ARCH_STRING, TB_ARCH_STRING_1, TB_ARCH_STRING_2, TB_ARCH_STRING_3, TB_ARCH_STRING_4, TB_ARCH_STRING_5)
#endif

#endif


