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
 * @file        prefix.S
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef TB_ARCH_ARM_THUMB
#   define A @
#   define T
#else
#   define A
#   define T @
#endif

#ifdef TB_ARCH_ELF
#   define ELF
#   define EXTERN_ASM
#else
#   define ELF @
#   define EXTERN_ASM _
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * arch
 */

#if defined(TB_ARCH_ARM_v7A)
        .arch armv7-a
#elif defined(TB_ARCH_ARM_v7)
        .arch armv7
#elif defined(TB_ARCH_ARM_v6) 
        .arch armv6
#elif defined(TB_ARCH_ARM_v5te) 
        .arch armv5te
#elif defined(TB_ARCH_ARM_v5) 
        .arch armv5
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * fpu
 */

#if defined(TB_ARCH_ARM_NEON) && !defined(TB_ARCH_ARM64)
        .fpu neon
#elif defined(TB_ARCH_VFP)
        .fpu vfp
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * syntax
 */
#ifndef TB_ARCH_ARM64
        .syntax unified
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * thumb
 */

// will crash
//T       .thumb

/* //////////////////////////////////////////////////////////////////////////////////////
 * eabi
 */
#ifndef TB_ARCH_ARM64
ELF     .eabi_attribute 25, 1 
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/*! function
 * 
 * @code
    function func_xxxx, export=1
        ...
        bx lr
    endfunc
   @endcode
 */
.macro function name, export=0
    .macro endfunc
ELF     .size \name, . - \name
        .endfunc
        .purgem endfunc
    .endm

        .text
#ifdef TB_ARCH_ARM64
        .align 8
#else 
        .align 4
#endif
    .if \export
        .global EXTERN_ASM\name
EXTERN_ASM\name:
    .endif
ELF     .type \name, %function
        .func \name
\name:
.endm

/*! label
 * 
 * @code
    label name
       xxx
       xxx
       bl name
   @endcode
 */
.macro label name
#ifdef TB_ARCH_ARM64
        .align 8
#else 
        .align 4
#endif
\name:
.endm
