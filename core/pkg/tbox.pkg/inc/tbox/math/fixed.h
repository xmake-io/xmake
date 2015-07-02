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
 * @file        fixed.h
 * @ingroup     math
 *
 */
#ifndef TB_MATH_FIXED_H
#define TB_MATH_FIXED_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "fixed6.h"
#include "fixed16.h"
#include "fixed30.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define TB_FIXED_ONE                TB_FIXED16_ONE
#define TB_FIXED_HALF               TB_FIXED16_HALF
#define TB_FIXED_MAX                TB_FIXED16_MAX
#define TB_FIXED_MIN                TB_FIXED16_MIN
#define TB_FIXED_NAN                TB_FIXED16_NAN
#define TB_FIXED_INF                TB_FIXED16_INF
#define TB_FIXED_PI                 TB_FIXED16_PI
#define TB_FIXED_SQRT2              TB_FIXED16_SQRT2
#define TB_FIXED_NEAR0              TB_FIXED16_NEAR0

// conversion
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#   define tb_fixed_to_float(x)     tb_fixed16_to_float(x)
#   define tb_float_to_fixed(x)     tb_float_to_fixed16(x)
#endif

#define tb_long_to_fixed(x)         tb_long_to_fixed16(x)
#define tb_fixed_to_long(x)         tb_fixed16_to_long(x)

#define tb_fixed6_to_fixed(x)       tb_fixed6_to_fixed16(x)
#define tb_fixed_to_fixed6(x)       tb_fixed16_to_fixed6(x)

#define tb_fixed30_to_fixed(x)      tb_fixed30_to_fixed16(x)
#define tb_fixed_to_fixed30(x)      tb_fixed16_to_fixed30(x)

// round
#define tb_fixed_round(x)           tb_fixed16_round(x)
#define tb_fixed_ceil(x)            tb_fixed16_ceil(x)
#define tb_fixed_floor(x)           tb_fixed16_floor(x)

// nearly equal?
#define tb_fixed_near_eq(x, y)      tb_fixed16_near_eq(x, y)

// operations
#define tb_fixed_abs(x)             tb_fixed16_abs(x)
#define tb_fixed_avg(x, y)          tb_fixed16_avg(x, y)
#define tb_fixed_lsh(x, y)          tb_fixed16_lsh(x, y)
#define tb_fixed_rsh(x, y)          tb_fixed16_rsh(x, y)
#define tb_fixed_mul(x, y)          tb_fixed16_mul(x, y)
#define tb_fixed_div(x, y)          tb_fixed16_div(x, y)
#define tb_fixed_imul(x, y)         tb_fixed16_imul(x, y)
#define tb_fixed_idiv(x, y)         tb_fixed16_idiv(x, y)
#define tb_fixed_imuldiv(x, y, z)   tb_fixed16_imuldiv(x, y, z)
#define tb_fixed_imulsub(x, y, z)   tb_fixed16_imulsub(x, y, z)
#define tb_fixed_invert(x)          tb_fixed16_invert(x)
#define tb_fixed_sqre(x)            tb_fixed16_sqre(x)
#define tb_fixed_sqrt(x)            tb_fixed16_sqrt(x)
#define tb_fixed_sin(x)             tb_fixed16_sin(x)
#define tb_fixed_cos(x)             tb_fixed16_cos(x)
#define tb_fixed_sincos(x, s, c)    tb_fixed16_sincos(x, s, c)
#define tb_fixed_tan(x)             tb_fixed16_tan(x)
#define tb_fixed_asin(x)            tb_fixed16_asin(x)
#define tb_fixed_acos(x)            tb_fixed16_acos(x)
#define tb_fixed_atan(x)            tb_fixed16_atan(x)
#define tb_fixed_atan2(y, x)        tb_fixed16_atan2(y, x)
#define tb_fixed_exp(x)             tb_fixed16_exp(x)
#define tb_fixed_exp1(x)            tb_fixed16_exp1(x)
#define tb_fixed_expi(x)            tb_fixed16_expi(x)
#define tb_fixed_ilog2(x)           tb_fixed16_ilog2(x)




#endif

