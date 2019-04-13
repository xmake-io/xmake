/*!The Treasure Box Library
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        prefix.S
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef TB_ARCH_ELF
#   define ELF
#   define EXTERN_ASM
#else
#   define ELF          @
#   define EXTERN_ASM   _
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * arch
 */

#if defined(TB_ARCH_ARM_v8)
        .arch armv8-a
#elif defined(TB_ARCH_ARM_v7A)
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
#if defined(TB_ARCH_ARM) && !defined(TB_ARCH_ARM64)
        .syntax unified
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * eabi
 */
#if defined(TB_ARCH_ELF) && defined(TB_ARCH_ARM) && !defined(TB_ARCH_ARM64)
        .eabi_attribute 25, 1 
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/*! function
 * 
 * @code
    function func_xxxx, export=1
        ...
    endfunc
   @endcode
 */
.macro function name, export=0
    .macro endfunc
ELF     .size \name, . - \name
        .purgem endfunc
    .endm

        .text
        .align TB_CPU_BITBYTE
    .if \export
        .global EXTERN_ASM\name
ELF     .type   EXTERN_ASM\name, %function
ELF     .hidden EXTERN_ASM\name
EXTERN_ASM\name:
    .else
ELF     .type   \name, %function
ELF     .hidden \name
\name:
    .endif
.endm

/*! label
 * 
 * @code
    label name
        ...
   @endcode
 */
.macro label name
        .align TB_CPU_BITBYTE
\name:
.endm

