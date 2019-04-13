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
 * @file        fixed30_arm.h
 *
 */
#ifndef TB_MATH_IMPL_FIXED30_ARM_H
#define TB_MATH_IMPL_FIXED30_ARM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef TB_ASSEMBLER_IS_GAS

#if 0
#   define tb_fixed30_mul(x, y)             tb_fixed30_mul_asm(x, y)
#endif

#endif /* TB_ASSEMBLER_IS_GAS */

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
#if defined(TB_ASSEMBLER_IS_GAS)
static __tb_inline__ tb_fixed30_t tb_fixed30_mul_asm(tb_fixed30_t x, tb_fixed30_t y)
{
    __tb_register__ tb_fixed30_t t;
    __tb_asm__ __tb_volatile__
    (
        "smull  %0, %2, %1, %3          \n"     // r64 = (l, h) = x * y
        "mov    %0, %0, lsr #30         \n"     // to fixed30: r64 >>= 30
        "orr    %0, %0, %2, lsl #2      \n"     // x = l = (h << (32 - 30)) | (l >> 30);

        : "=r"(x), "=&r"(y), "=r"(t)
        : "r"(x), "1"(y)
    );
    return x;
}
#endif


#endif

