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
 * @file        math.h
 * @ingroup     libm
 *
 */
#ifndef TB_LIBM_MATH_H
#define TB_LIBM_MATH_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#   include "nan.h"
#   include "inf.h"
#   include "maf.h"
#   include "mif.h"
#   include "pi.h"
#   include "fabs.h"
#   include "round.h"
#   include "ceil.h"
#   include "floor.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT

// is infinite?
tb_long_t       tb_isinf(tb_double_t x);
tb_long_t       tb_isinff(tb_float_t x);

// is finite?
tb_long_t       tb_isfin(tb_double_t x);
tb_long_t       tb_isfinf(tb_float_t x);

// is nan?
tb_long_t       tb_isnan(tb_double_t x);
tb_long_t       tb_isnanf(tb_float_t x);

// sqrt
tb_double_t     tb_sqrt(tb_double_t x);
tb_float_t      tb_sqrtf(tb_float_t x);

// sin
tb_double_t     tb_sin(tb_double_t x);
tb_float_t      tb_sinf(tb_float_t x);

// cos
tb_double_t     tb_cos(tb_double_t x);
tb_float_t      tb_cosf(tb_float_t x);

// tan
tb_double_t     tb_tan(tb_double_t x);
tb_float_t      tb_tanf(tb_float_t x);

// atan
tb_double_t     tb_atan(tb_double_t x);
tb_float_t      tb_atanf(tb_float_t x);

// exp
tb_double_t     tb_exp(tb_double_t x);
tb_float_t      tb_expf(tb_float_t x);

// expi
tb_double_t     tb_expi(tb_long_t x);
tb_float_t      tb_expif(tb_long_t x);

// exp1
tb_double_t     tb_exp1(tb_double_t x);
tb_float_t      tb_exp1f(tb_float_t x);

// asin
tb_double_t     tb_asin(tb_double_t x);
tb_float_t      tb_asinf(tb_float_t x);

// acos
tb_double_t     tb_acos(tb_double_t x);
tb_float_t      tb_acosf(tb_float_t x);

// atan2
tb_double_t     tb_atan2(tb_double_t y, tb_double_t x);
tb_float_t      tb_atan2f(tb_float_t y, tb_float_t x);

// log2
tb_double_t     tb_log2(tb_double_t x);
tb_float_t      tb_log2f(tb_float_t x);

// sincos
tb_void_t       tb_sincos(tb_double_t x, tb_double_t* s, tb_double_t* c);
tb_void_t       tb_sincosf(tb_float_t x, tb_float_t* s, tb_float_t* c);

// pow
tb_double_t     tb_pow(tb_double_t x, tb_double_t y);
tb_float_t      tb_powf(tb_float_t x, tb_float_t y);

// fmod
tb_double_t     tb_fmod(tb_double_t x, tb_double_t y);
tb_float_t      tb_fmodf(tb_float_t x, tb_float_t y);
#endif

// ilog2i
tb_uint32_t     tb_ilog2i(tb_uint32_t x);

// isqrti
tb_uint32_t     tb_isqrti(tb_uint32_t x);
tb_uint32_t     tb_isqrti64(tb_uint64_t x);

// idivi8
tb_uint32_t     tb_idivi8(tb_uint32_t x, tb_uint8_t y);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
