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
 * @file        fixed16_arm.h
 *
 */
#ifndef TB_MATH_IMPL_FIXED16_ARM_H
#define TB_MATH_IMPL_FIXED16_ARM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"


/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef TB_ASSEMBLER_IS_GAS

#if 0
#   define tb_fixed16_mul(x, y)             tb_fixed16_mul_asm(x, y)
#endif

#endif /* TB_ASSEMBLER_IS_GAS */

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#if defined(TB_ASSEMBLER_IS_GAS) && !defined(TB_ARCH_ARM64)
static __tb_inline__ tb_fixed16_t tb_fixed16_mul_asm(tb_fixed16_t x, tb_fixed16_t y)
{
    __tb_register__ tb_fixed16_t t;
    __tb_asm__ __tb_volatile__
    ( 
        "smull  %0, %2, %1, %3          \n"     // r64 = (l, h) = x * y
        "mov    %0, %0, lsr #16         \n"     // to fixed16: r64 >>= 16
        "orr    %0, %0, %2, lsl #16     \n"     // x = l = (h << (32 - 16)) | (l >> 16);

        : "=r"(x), "=&r"(y), "=r"(t)
        : "r"(x), "1"(y)
    );
    return x;
}
#endif

#endif

