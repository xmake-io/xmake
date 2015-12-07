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

