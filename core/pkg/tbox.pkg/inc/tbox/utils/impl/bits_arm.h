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

