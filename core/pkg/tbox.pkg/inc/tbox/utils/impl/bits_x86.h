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
 * @file        bits_x86.h
 *
 */
#ifndef TB_UTILS_IMPL_BITS_x86_H
#define TB_UTILS_IMPL_BITS_x86_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef TB_ASSEMBLER_IS_GAS

// swap
#ifndef tb_bits_swap_u16
#   define tb_bits_swap_u16(x)              tb_bits_swap_u16_asm(x)
#endif
#ifndef tb_bits_swap_u32
#   define tb_bits_swap_u32(x)              tb_bits_swap_u32_asm(x)
#endif
#ifndef tb_bits_swap_u64
#   define tb_bits_swap_u64(x)              tb_bits_swap_u64_asm(x)
#endif

#endif /* TB_ASSEMBLER_IS_GAS */
/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#ifdef TB_ASSEMBLER_IS_GAS

// swap
static __tb_inline__ tb_uint16_t const tb_bits_swap_u16_asm(tb_uint16_t x)
{
    __tb_asm__ __tb_volatile__("rorw    $8, %w0" : "+r"(x));
    return x;
}

static __tb_inline__ tb_uint32_t const tb_bits_swap_u32_asm(tb_uint32_t x)
{
#if 1
    __tb_asm__ __tb_volatile__("bswap   %0" : "+r" (x));
#else
    __tb_asm__ __tb_volatile__
    (
        "rorw   $8,  %w0 \n"    //!< swap low 16 bits
        "rorl   $16, %0  \n"    //!< swap x by word
        "rorw   $8,  %w0"       //!< swap low 16 bits

        : "+r"(x)
    );
#endif
    return x;
}

static __tb_inline__ tb_hize_t const tb_bits_swap_u64_asm(tb_hize_t x)
{
    __tb_register__ tb_size_t esi, edi;
    __tb_asm__ __tb_volatile__
    (
        "lodsl\n"
        "bswap  %%eax\n"
        "movl   %%eax, %%ebx\n"
        "lodsl\n"
        "bswap  %%eax\n"
        "stosl\n"
        "movl   %%ebx, %%eax\n"
        "stosl\n"

        : "=&S" (esi), "=&D" (edi)
        : "0"(&x), "1"(&x)
        : "memory", "eax", "ebx"
    );
    return x;
}

#endif /* TB_ASSEMBLER_IS_GAS */

#endif

