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
static __tb_inline__ tb_uint16_t tb_bits_swap_u16_asm(tb_uint16_t x)
{
    __tb_asm__ __tb_volatile__("rorw    $8, %w0" : "+r"(x));
    return x;
}

static __tb_inline__ tb_uint32_t tb_bits_swap_u32_asm(tb_uint32_t x)
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

static __tb_inline__ tb_hize_t tb_bits_swap_u64_asm(tb_hize_t x)
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

