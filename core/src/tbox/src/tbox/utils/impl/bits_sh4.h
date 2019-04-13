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
 * @file        bits_sh4.h
 *
 */
#ifndef TB_UTILS_IMPL_BITS_SH4_H
#define TB_UTILS_IMPL_BITS_SH4_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
// swap
#ifndef tb_bits_swap_u16
#   define tb_bits_swap_u16(x)              tb_bits_swap_u16_asm(x)
#endif
#ifndef tb_bits_swap_u32
#   define tb_bits_swap_u32(x)              tb_bits_swap_u32_asm(x)
#endif
/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// swap
static __tb_inline__ tb_uint16_t const tb_bits_swap_u16_asm(tb_uint16_t x)
{
    __tb_asm__("swap.b %0,%0" : "+r"(x));
    return x;
}

static __tb_inline__ tb_uint32_t const tb_bits_swap_u32_asm(tb_uint32_t x)
{
    __tb_asm__( "swap.b %0,%0\n"
                "swap.w %0,%0\n"
                "swap.b %0,%0\n"
                : "+r"(x));
    return x;
}


#endif

