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
 * @file        cpu.h
 *
 */
#ifndef TB_PREFIX_CPU_H
#define TB_PREFIX_CPU_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// check 64-bits
#if defined(__LP64__) \
    || defined(__64BIT__) \
    || defined(_LP64) \
    || defined(__x86_64) \
    || defined(__x86_64__) \
    || defined(__amd64) \
    || defined(__amd64__) \
    || defined(__arm64) \
    || defined(__arm64__) \
    || defined(__sparc64__) \
    || defined(__PPC64__) \
    || defined(__ppc64__) \
    || defined(__powerpc64__) \
    || defined(_M_X64) \
    || defined(_M_AMD64) \
    || defined(_M_IA64) \
    || (defined(__WORDSIZE) && (__WORDSIZE == 64)) \
    || defined(TCC_TARGET_X86_64)
#   define TB_CPU_BITSIZE       (64)
#   define TB_CPU_BITBYTE       (8)
#   define TB_CPU_BITALIGN      (7)
#   define TB_CPU_BIT32         (0)
#   define TB_CPU_BIT64         (1)
#   define TB_CPU_SHIFT         (6)
#else
#   define TB_CPU_BITSIZE       (32)
#   define TB_CPU_BITBYTE       (4)
#   define TB_CPU_BITALIGN      (3)
#   define TB_CPU_BIT32         (1)
#   define TB_CPU_BIT64         (0)
#   define TB_CPU_SHIFT         (5)
#endif

#endif


