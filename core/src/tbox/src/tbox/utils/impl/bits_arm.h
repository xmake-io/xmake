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
 * @file        bits_arm.h
 *
 */
#ifndef TB_UTILS_IMPL_BITS_ARM_H
#define TB_UTILS_IMPL_BITS_ARM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if defined(TB_ASSEMBLER_IS_GAS) && !defined(TB_ARCH_ARM64)

// swap
#if TB_ARCH_ARM_VERSION >= 6
#   ifndef tb_bits_swap_u16
#       define tb_bits_swap_u16(x)          tb_bits_swap_u16_asm(x)
#   endif
#endif
#ifndef tb_bits_swap_u32
#   define tb_bits_swap_u32(x)              tb_bits_swap_u32_asm(x)
#endif

// FIXME: for ios
//#define tb_bits_get_ubits32_impl(p, b, n)     tb_bits_get_ubits32_impl_asm(p, b, n)

#endif /* TB_ASSEMBLER_IS_GAS */

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#if defined(TB_ASSEMBLER_IS_GAS) && !defined(TB_ARCH_ARM64)

// swap
#if (TB_ARCH_ARM_VERSION >= 6)
static __tb_inline__ tb_uint16_t const tb_bits_swap_u16_asm(tb_uint16_t x)
{
    __tb_asm__ __tb_volatile__("rev16 %0, %0" : "+r"(x));
    return x;
}
#endif

static __tb_inline__ tb_uint32_t const tb_bits_swap_u32_asm(tb_uint32_t x)
{
#if (TB_ARCH_ARM_VERSION >= 6)
    __tb_asm__("rev %0, %0" : "+r"(x));
#else
    __tb_register__ tb_uint32_t t;
    __tb_asm__ __tb_volatile__
    ( 
        "eor %1, %0, %0, ror #16 \n"
        "bic %1, %1, #0xff0000   \n"
        "mov %0, %0, ror #8      \n"
        "eor %0, %0, %1, lsr #8  \n"
        : "+r"(x), "=&r"(t)
    );
#endif
    return x;
}

#if 0
static __tb_inline__ tb_uint32_t tb_bits_get_ubits32_impl_asm(tb_byte_t const* p, tb_size_t b, tb_size_t n)
{
#ifdef __tb_small__
    __tb_register__ tb_uint32_t x;
    __tb_asm__ __tb_volatile__
    (
        "ldrb r6, [%1], #1\n"
        "ldrb r7, [%1], #1\n"
        "ldrb r8, [%1], #1\n"
        "ldrb r9, [%1], #1\n"
        "ldrb %1, [%1]\n"
        "orr %0, r6, lsl %2\n"
        "sub %2, %2, #8\n"
        "cmp %3, #8\n"
        "orrhi %0, r7, lsl %2\n"
        "sub %2, %2, #8\n"
        "cmp %3, #16\n"
        "orrhi %0, r8, lsl %2\n"
        "sub %2, %2, #8\n"
        "cmp %3, #24\n"
        "orrhi %0, r9, lsl %2\n"
        "rsb %2, %2, #8\n"
        "cmp %3, #32\n"
        "orrhi %0, %1, lsr %2\n"
        "rsb %4, %4, #32\n"
        "mov %0, %0, lsr %4\n"


        : "=&r"(x)
        : "r"(p), "r"(b + 24), "r"(b + n), "r"(n), "0"(0)
        : "r6", "r7", "r8", "r9"
    );

    return x;
#else
    __tb_register__ tb_uint32_t x;
    __tb_asm__ __tb_volatile__
    (
        "   cmp %3, #32\n"
        "   bhi 1f\n"
        "   cmp %3, #24\n"
        "   bhi 2f\n"
        "   cmp %3, #16\n"
        "   bhi 3f\n"
        "   cmp %3, #8\n"
        "   bhi 4f\n"
        "   ldrb %1, [%1]\n"
        "   orr %0, %1, lsl %2\n"
        "   b   5f\n"
        "1:\n"
        "   ldrb r6, [%1], #1\n"
        "   ldrb r7, [%1], #1\n"
        "   ldrb r8, [%1], #1\n"
        "   ldrb r9, [%1], #1\n"
        "   ldrb %1, [%1]\n"
        "   orr %0, r6, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r7, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r8, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r9, lsl %2\n"
        "   rsb %2, %2, #8\n"
        "   orr %0, %1, lsr %2\n"
        "   b   5f\n"
        "2:\n"
        "   ldrb r6, [%1], #1\n"
        "   ldrb r7, [%1], #1\n"
        "   ldrb r8, [%1], #1\n"
        "   ldrb r9, [%1], #1\n"
        "   orr %0, r6, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r7, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r8, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r9, lsl %2\n"
        "   b   5f\n"
        "3:\n"
        "   ldrb r6, [%1], #1\n"
        "   ldrb r7, [%1], #1\n"
        "   ldrb r8, [%1], #1\n"
        "   orr %0, r6, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r7, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r8, lsl %2\n"
        "   b   5f\n"
        "4:\n"
        "   ldrb r6, [%1], #1\n"
        "   ldrb r7, [%1], #1\n"
        "   orr %0, r6, lsl %2\n"
        "   sub %2, %2, #8\n"
        "   orr %0, r7, lsl %2\n"
        "5:\n"
        "   rsb %4, %4, #32\n"
        "   mov %0, %0, lsr %4\n"

        : "=&r"(x)
        : "r"(p), "r"(b + 24), "r"(b + n), "r"(n), "0"(0)
        : "r6", "r7", "r8", "r9"
    );

    return x;
#endif
}
#endif

#endif /* TB_ASSEMBLER_IS_GAS */


#endif

