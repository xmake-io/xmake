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
