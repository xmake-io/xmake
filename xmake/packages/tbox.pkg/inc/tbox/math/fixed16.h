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
 * @file        fixed16.h
 * @ingroup     math
 *
 */
#ifndef TB_MATH_FIXED16_H
#define TB_MATH_FIXED16_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "int32.h"
#include "../libm/libm.h"
#ifdef TB_ARCH_ARM
#   include "impl/fixed16_arm.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// constant
#define TB_FIXED16_ONE                      (1 << 16)
#define TB_FIXED16_HALF                     (1 << 15)
#define TB_FIXED16_MAX                      (TB_MAXS32)
#define TB_FIXED16_MIN                      (TB_MINS32)
#define TB_FIXED16_NAN                      ((tb_int_t)0x80000000)
#define TB_FIXED16_INF                      (TB_MAXS32)
#define TB_FIXED16_PI                       (0x3243f)
#define TB_FIXED16_SQRT2                    (92682)
#define TB_FIXED16_NEAR0                    (1 << 4)

// conversion
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#   ifndef tb_fixed16_to_float
#       define tb_fixed16_to_float(x)       ((tb_float_t)((x) * 1.5258789e-5))
#   endif
#   ifndef tb_float_to_fixed16
#       define tb_float_to_fixed16(x)       ((tb_fixed16_t)((x) * TB_FIXED16_ONE))
#   endif
#endif

#ifdef __tb_debug__
#   define tb_long_to_fixed16(x)            tb_long_to_fixed16_check(x)
#   define tb_fixed16_to_long(x)            tb_fixed16_to_long_check(x)
#else
#   define tb_long_to_fixed16(x)            (tb_fixed16_t)((x) << 16)
#   define tb_fixed16_to_long(x)            (tb_long_t)((x) >> 16)
#endif

// round
#define tb_fixed16_round(x)                 (((x) + TB_FIXED16_HALF) >> 16)

// ceil
#define tb_fixed16_ceil(x)                  (((x) + TB_FIXED16_ONE - 1) >> 16)

// floor
#define tb_fixed16_floor(x)                 ((x) >> 16)

// abs
#define tb_fixed16_abs(x)                   tb_abs(x)

// avg
#define tb_fixed16_avg(x, y)                (((x) + (y)) >> 1)
   
// nearly equal?
#define tb_fixed16_near_eq(x, y)            (tb_fixed16_abs((x) - (y)) <= TB_FIXED16_NEAR0)
   
// mul
#ifndef tb_fixed16_mul
#   ifdef __tb_debug__
#       define tb_fixed16_mul(x, y)         tb_fixed16_mul_check(x, y)
#   else
#       define tb_fixed16_mul(x, y)         ((tb_fixed16_t)(((tb_hong_t)(x) * (y)) >> 16))
#   endif
#endif

// div
#ifndef tb_fixed16_div
#   ifdef __tb_debug__
#       define tb_fixed16_div(x, y)         tb_fixed16_div_check(x, y)
#   else
#       define tb_fixed16_div(x, y)         ((tb_fixed16_t)((((tb_hong_t)(x)) << 16) / (y)))
#   endif
#endif
    
// imul
#ifndef tb_fixed16_imul
#   ifdef __tb_debug__
#       define tb_fixed16_imul(x, y)        tb_fixed16_imul_check(x, y)
#   else
#       define tb_fixed16_imul(x, y)        ((tb_fixed16_t)((x) * (y)))
#   endif
#endif

// idiv
#ifndef tb_fixed16_idiv
#   ifdef __tb_debug__
#       define tb_fixed16_idiv(x, y)        tb_fixed16_idiv_check(x, y)
#   else
#       define tb_fixed16_idiv(x, y)        ((tb_fixed16_t)((x) / (y)))
#   endif
#endif

// imuldiv
#ifndef tb_fixed16_imuldiv
#   ifdef __tb_debug__
#       define tb_fixed16_imuldiv(x, y, z)  tb_fixed16_imuldiv_check(x, y, z)
#   else
#       define tb_fixed16_imuldiv(x, y, z)  ((tb_fixed16_t)(((tb_hong_t)(x) * (y)) / (z)))
#   endif
#endif

// imulsub
#ifndef tb_fixed16_imulsub
#   ifdef __tb_debug__
#       define tb_fixed16_imulsub(x, y, z)  tb_fixed16_imulsub_check(x, y, z)
#   else
#       define tb_fixed16_imulsub(x, y, z)  ((tb_fixed16_t)(((tb_hong_t)(x) * (y)) - (z)))
#   endif
#endif

// lsh
#ifndef tb_fixed16_lsh
#   define tb_fixed16_lsh(x, y)             ((x) << (y))
#endif
    
// rsh
#ifndef tb_fixed16_rsh
#   define tb_fixed16_rsh(x, y)             ((x) >> (y))
#endif

// invert: 1 / x
#ifndef tb_fixed16_invert
#   define tb_fixed16_invert(x)             tb_fixed16_div(TB_FIXED16_ONE, x)
#endif

// sqre
#ifndef tb_fixed16_sqre
#   ifdef __tb_debug__
#       define tb_fixed16_sqre(x)           tb_fixed16_sqre_check(x)
#   else
#       define tb_fixed16_sqre(x)           ((tb_fixed16_t)(((tb_hong_t)(x) * (x)) >> 16))
#   endif
#endif

// sqrt
#ifndef tb_fixed16_sqrt
#   define tb_fixed16_sqrt(x)               tb_fixed16_sqrt_int32(x)
#endif

// sin
#ifndef tb_fixed16_sin
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_sin(x)            tb_fixed16_sin_float(x)
#   else
#       define tb_fixed16_sin(x)            tb_fixed16_sin_int32(x)
#   endif
#endif

// cos
#ifndef tb_fixed16_cos
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_cos(x)            tb_fixed16_cos_float(x)
#   else
#       define tb_fixed16_cos(x)            tb_fixed16_cos_int32(x)
#   endif
#endif

// sincos
#ifndef tb_fixed16_sincos
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_sincos(x, s, c)   tb_fixed16_sincos_float(x, s, c)
#   else
#       define tb_fixed16_sincos(x, s, c)   tb_fixed16_sincos_int32(x, s, c)
#   endif
#endif

// tan
#ifndef tb_fixed16_tan
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_tan(x)            tb_fixed16_tan_float(x)
#   else
#       define tb_fixed16_tan(x)            tb_fixed16_tan_int32(x)
#   endif
#endif

// asin
#ifndef tb_fixed16_asin
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_asin(x)           tb_fixed16_asin_float(x)
#   else
#       define tb_fixed16_asin(x)           tb_fixed16_asin_int32(x)
#   endif
#endif

// acos
#ifndef tb_fixed16_acos
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_acos(x)           tb_fixed16_acos_float(x)
#   else
#       define tb_fixed16_acos(x)           tb_fixed16_acos_int32(x)
#   endif
#endif

// atan
#ifndef tb_fixed16_atan
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_atan(x)           tb_fixed16_atan_float(x)
#   else
#       define tb_fixed16_atan(x)           tb_fixed16_atan_int32(x)
#   endif
#endif

// atan2
#ifndef tb_fixed16_atan2
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_atan2(y, x)       tb_fixed16_atan2_float(y, x)
#   else
#       define tb_fixed16_atan2(y, x)       tb_fixed16_atan2_int32(y, x)
#   endif
#endif

// exp
#ifndef tb_fixed16_exp
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_exp(x)            tb_fixed16_exp_float(x)
#   else
#       define tb_fixed16_exp(x)            tb_fixed16_exp_int32(x)
#   endif
#endif

#ifndef tb_fixed16_expi
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_expi(x)           tb_fixed16_expi_float(x)
#   else
#       define tb_fixed16_expi(x)           tb_assert(0)
#   endif
#endif

#ifndef tb_fixed16_exp1
#   ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#       define tb_fixed16_exp1(x)           tb_fixed16_exp1_float(x)
#   else
#       define tb_fixed16_exp1(x)           tb_assert(0)
#   endif
#endif

// log
#ifndef tb_fixed16_ilog2
#   define tb_fixed16_ilog2(x)              tb_fixed16_ilog2_int32(x)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! compute the invert of the fixed-point value
 *
 * @param x     the fixed-point x-value
 *
 * @return      the result
 */
tb_fixed16_t    tb_fixed16_invert_int32(tb_fixed16_t x);

/*! compute the sin and cos value of the fixed-point value
 *
 * @param x     the fixed-point x-value
 * @param s     the sin fixed-point value
 * @param c     the cos fixed-point value
 */
tb_void_t       tb_fixed16_sincos_int32(tb_fixed16_t x, tb_fixed16_t* s, tb_fixed16_t* c);

/*! compute the atan2 value of the fixed-point value
 *
 * @param y     the fixed-point y-value
 * @param x     the fixed-point x-value
 *
 * @return      the result
 */
tb_fixed16_t    tb_fixed16_atan2_int32(tb_fixed16_t y, tb_fixed16_t x);

/*! compute the asin value of the fixed-point value
 *
 * @param x     the fixed-point x-value
 *
 * @return      the result
 */
tb_fixed16_t    tb_fixed16_asin_int32(tb_fixed16_t x);

/*! compute the atan value of the fixed-point value
 *
 * @param x     the fixed-point x-value
 *
 * @return      the result
 */
tb_fixed16_t    tb_fixed16_atan_int32(tb_fixed16_t x);

/*! compute the exp value of the fixed-point value
 *
 * @param x     the fixed-point x-value
 *
 * @return      the result
 */
tb_fixed16_t    tb_fixed16_exp_int32(tb_fixed16_t x);

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */
static __tb_inline__ tb_fixed16_t tb_long_to_fixed16_check(tb_long_t x)
{
    // check overflow
    tb_assert(x == (tb_int16_t)x);

    // ok
    return (tb_fixed16_t)(x << 16);
}
static __tb_inline__ tb_long_t tb_fixed16_to_long_check(tb_fixed16_t x)
{
    // check overflow
    tb_assert(x >= TB_FIXED16_MIN && x <= TB_FIXED16_MAX);

    // ok
    return (x >> 16);
}
static __tb_inline__ tb_fixed16_t tb_fixed16_mul_check(tb_fixed16_t x, tb_fixed16_t y)
{
    // done
    tb_hong_t v = (((tb_hong_t)x * y) >> 16);

    // check overflow
    tb_assert(v == (tb_int32_t)v);

    // ok
    return (tb_fixed16_t)v;
}
static __tb_inline__ tb_fixed16_t tb_fixed16_div_check(tb_fixed16_t x, tb_fixed16_t y)
{
    // check
    tb_assert(y);

    // done
    tb_hong_t v = ((((tb_hong_t)x) << 16) / y);

    // check overflow
    tb_assert(v == (tb_int32_t)v);

    // ok
    return (tb_fixed16_t)v;
}
static __tb_inline__ tb_fixed16_t tb_fixed16_sqre_check(tb_fixed16_t x)
{
    // done
    tb_hong_t v = (((tb_hong_t)x * x) >> 16);

    // check overflow
    tb_assert(v == (tb_int32_t)v);

    // ok
    return (tb_fixed16_t)v;
}
static __tb_inline__ tb_fixed16_t tb_fixed16_imul_check(tb_fixed16_t x, tb_long_t y)
{
    // done
    tb_hong_t v = ((tb_hong_t)x * y);

    // check overflow
    tb_assert(v == (tb_int32_t)v);

    // ok
    return (tb_fixed16_t)v;
}
static __tb_inline__ tb_fixed16_t tb_fixed16_idiv_check(tb_fixed16_t x, tb_long_t y)
{
    // check
    tb_assert(y);

    // ok
    return (tb_fixed16_t)(x / y);
}
static __tb_inline__ tb_fixed16_t tb_fixed16_imuldiv_check(tb_fixed16_t x, tb_long_t y, tb_long_t z)
{
    // done
    tb_hong_t v = ((tb_hong_t)x * y) / z;

    // check overflow
    tb_assert(v == (tb_int32_t)v);

    // ok
    return (tb_fixed16_t)v;
}
static __tb_inline__ tb_fixed16_t tb_fixed16_imulsub_check(tb_fixed16_t x, tb_long_t y, tb_long_t z)
{
    // done
    tb_hong_t v = ((tb_hong_t)x * y) - z;

    // check overflow
    tb_assert(v == (tb_int32_t)v);

    // ok
    return (tb_fixed16_t)v;
}
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
static __tb_inline__ tb_fixed16_t tb_fixed16_sin_float(tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_sinf(tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_fixed16_t tb_fixed16_cos_float(tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_cosf(tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_void_t tb_fixed16_sincos_float(tb_fixed16_t x, tb_fixed16_t* s, tb_fixed16_t* c)
{
    tb_float_t sf, cf;
    tb_sincosf(tb_fixed16_to_float(x), &sf, &cf);
    if (s) *s = tb_float_to_fixed16(sf);
    if (s) *c = tb_float_to_fixed16(cf);
}
static __tb_inline__ tb_fixed16_t tb_fixed16_tan_float(tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_tanf(tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_fixed16_t tb_fixed16_asin_float(tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_asinf(tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_fixed16_t tb_fixed16_acos_float(tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_acosf(tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_fixed16_t tb_fixed16_atan_float(tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_atanf(tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_fixed16_t tb_fixed16_atan2_float(tb_fixed16_t y, tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_atan2f(tb_fixed16_to_float(y), tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_fixed16_t tb_fixed16_exp_float(tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_expf(tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_fixed16_t tb_fixed16_exp1_float(tb_fixed16_t x)
{
    return tb_float_to_fixed16(tb_exp1f(tb_fixed16_to_float(x)));
}
static __tb_inline__ tb_fixed16_t tb_fixed16_expi_float(tb_long_t x)
{
    return tb_float_to_fixed16(tb_expif(x));
}
#endif
static __tb_inline__ tb_fixed16_t tb_fixed16_sqrt_int32(tb_fixed16_t x)
{
    tb_assert(x > 0);
    return (x > 0? (tb_isqrti(x) << 8) : 0);
}
static __tb_inline__ tb_uint32_t tb_fixed16_ilog2_int32(tb_fixed16_t x)
{
    tb_assert(x > 0);
    tb_uint32_t lg = tb_ilog2i(x);
    return (lg > 16? (lg - 16) : 0);
}
static __tb_inline__ tb_fixed16_t tb_fixed16_sin_int32(tb_fixed16_t x)
{
    tb_fixed16_t s = 0;
    tb_fixed16_sincos_int32(x, &s, tb_null);
    return s;
}
static __tb_inline__ tb_fixed16_t tb_fixed16_cos_int32(tb_fixed16_t x)
{
    tb_fixed16_t c = 0;
    tb_fixed16_sincos_int32(x, tb_null, &c);
    return c;
}
static __tb_inline__ tb_fixed16_t tb_fixed16_tan_int32(tb_fixed16_t x)
{
    tb_fixed16_t s = 0;
    tb_fixed16_t c = 0;
    tb_fixed16_sincos_int32(x, &s, &c);
    return tb_fixed16_div(s, c);
}
static __tb_inline__ tb_fixed16_t tb_fixed16_acos_int32(tb_fixed16_t x)
{
    // asin + acos = pi / 2
    tb_fixed16_t z = tb_fixed16_asin_int32(x);
    return ((TB_FIXED16_PI >> 1) - z);
}


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

