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
 * @file        fixed16.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "fixed16.h"
#include "fixed30.h"
#include "int32.h"
#include "../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

#if 1
static tb_fixed16_t const tb_fixed16_cordic_atan2i_table[30] =
{ 
        0x20000000  // 45.000000
    ,   0x12e4051d  // 26.565051
    ,   0x9fb385b   // 14.036243
    ,   0x51111d4   // 7.125016
    ,   0x28b0d43   // 3.576334
    ,   0x145d7e1   // 1.789911
    ,   0xa2f61e    // 0.895174
    ,   0x517c55    // 0.447614
    ,   0x28be53    // 0.223811
    ,   0x145f2e    // 0.111906
    ,   0xa2f98     // 0.055953
    ,   0x517cc     // 0.027976
    ,   0x28be6     // 0.013988
    ,   0x145f3     // 0.006994
    ,   0xa2f9      // 0.003497
    ,   0x517c      // 0.001749
    ,   0x28be      // 0.000874
    ,   0x145f      // 0.000437
    ,   0xa2f       // 0.000219
    ,   0x517       // 0.000109
    ,   0x28b       // 0.000055
    ,   0x145       // 0.000027
    ,   0xa2        // 0.000014
    ,   0x51        // 0.000007
    ,   0x28        // 0.000003
    ,   0x14        // 0.000002
    ,   0xa         // 0.000001
    ,   0x5         // 0.000000
    ,   0x2         // 0.000000
    ,   0x1         // 0.000000
};

#else
static tb_fixed16_t const tb_fixed16_cordic_atan2i_table[16] =
{ 
        0x1fff9122  // 45.000000
    ,   0x12e3bf5e  // 26.565051
    ,   0x9fafb14   // 14.036243
    ,   0x510e816   // 7.125016
    ,   0x28aeb8c   // 3.576334
    ,   0x145c742   // 1.789911
    ,   0xa2cf42    // 0.895174
    ,   0x515342    // 0.447614
    ,   0x289542    // 0.223811
    ,   0x143642    // 0.111906
    ,   0xa06c2     // 0.055953
    ,   0x4ef02     // 0.027976
    ,   0x26322     // 0.013988
    ,   0x11d32     // 0.006994
    ,   0x7a3a      // 0.003497
    ,   0x28be      // 0.001749

};

#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// |angle| < 90 degrees
static tb_void_t tb_fixed16_cordic_rotation(tb_fixed30_t* x0, tb_fixed30_t* y0, tb_fixed16_t z0) 
{
    tb_int_t i = 0;
    tb_fixed16_t atan2i = 0;
    tb_fixed16_t z = z0;
    tb_fixed30_t x = *x0;
    tb_fixed30_t y = *y0;
    tb_fixed30_t xi = 0;
    tb_fixed30_t yi = 0;
    tb_fixed16_t const* patan2i = tb_fixed16_cordic_atan2i_table;

    do 
    {
        xi = x >> i;
        yi = y >> i;

#if 1
        atan2i = *patan2i++;
#elif 0
        atan2i = tb_double_to_fixed16(atan(1. / (1 << i)) * (1 << 15) / TB_DOUBLE_PI);
        //tb_printf(",\t0x%x\t// %lf\n", atan2i, atan(1. / (1 << i)) * 180 / TB_DOUBLE_PI);
#else
        //atan2i = tb_double_to_fixed16(atan(1. / (1 << i))) * 0x28be;
        //tb_printf(",\t0x%x\t// %lf\n", atan2i, atan(1. / (1 << i)) * 180 / TB_DOUBLE_PI);
#endif

        if (z >= 0) 
        {
            x -= yi;
            y += xi;
            z -= atan2i;
        }
        else 
        {
            x += yi;
            y -= xi;
            z += atan2i;
        }

    } while (++i < 16);

    *x0 = x;
    *y0 = y;
}

// |angle| < 90 degrees
static tb_fixed16_t tb_fixed16_cordic_vector_atan2(tb_fixed16_t y0, tb_fixed16_t x0)
{
    tb_int_t i = 0;
    tb_fixed16_t atan2i = 0;
    tb_fixed16_t z = 0;
    tb_fixed16_t x = x0;
    tb_fixed16_t y = y0;
    tb_fixed16_t xi = 0;
    tb_fixed16_t yi = 0;
    tb_fixed16_t const* patan2i = tb_fixed16_cordic_atan2i_table;

    do 
    {
        xi = x >> i;
        yi = y >> i;

        atan2i = *patan2i++;

        if (y < 0) 
        {
            x -= yi;
            y += xi;
            z -= atan2i;
        }
        else 
        {
            x += yi;
            y -= xi;
            z += atan2i;
        }

    } while (++i < 16);

    return z / 0x28be;
}

// |angle| < 90 degrees
static tb_fixed16_t tb_fixed16_cordic_vector_asin(tb_fixed16_t m)
{
    tb_int_t i = 0;
    tb_fixed16_t atan2i = 0;
    tb_fixed16_t z = 0;
    tb_fixed16_t x = 0x18bde0bb;    // k = 0.607252935
    tb_fixed16_t y = 0;
    tb_fixed16_t xi = 0;
    tb_fixed16_t yi = 0;
    tb_fixed16_t const* patan2i = tb_fixed16_cordic_atan2i_table;

    do 
    {
        xi = x >> i;
        yi = y >> i;

        atan2i = *patan2i++;

        if (y < m) 
        {
            x -= yi;
            y += xi;
            z -= atan2i;
        }
        else 
        {
            x += yi;
            y -= xi;
            z += atan2i;
        }

    } while (++i < 16);

    return z / 0x28be;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_fixed16_t tb_fixed16_invert_int32(tb_fixed16_t x)
{
    // is one?
    if (x == TB_FIXED16_ONE) return TB_FIXED16_ONE;

    // get sign
    tb_int32_t s = tb_int32_get_sign(x);

    // abs(x)
    x = tb_fixed16_abs(x);

    // is infinity?
    if (x <= 2) return tb_int32_set_sign(TB_FIXED16_MAX, s);

    // normalize
    tb_int32_t cl0 = (tb_int32_t)tb_bits_cl0_u32_be(x);
    x = x << cl0 >> 16;
 
    // compute 1 / x approximation (0.5 <= x < 1.0) 
    // (2.90625 (~2.914) - 2 * x) >> 1
    tb_uint32_t r = 0x17400 - x;      

    // newton-raphson iteration:
    // x = r * (2 - x * r) = ((r / 2) * (1 - x * r / 2)) * 4
    r = ((0x10000 - ((x * r) >> 16)) * r) >> 15;
    r = ((0x10000 - ((x * r) >> 16)) * r) >> (30 - cl0);

    return tb_int32_set_sign(r, s);
}

tb_void_t tb_fixed16_sincos_int32(tb_fixed16_t x, tb_fixed16_t* s, tb_fixed16_t* c)
{
    // (x0, y0) = (k, 0), k = 0.607252935 => fixed30
    tb_fixed30_t    cos = 0x26dd3b6a;
    tb_fixed30_t    sin = 0;

    /* scale to 65536 degrees from x radians: x * 65536 / (2 * pi)
     *
     * 90:  0x40000000
     * 180: 0x80000000
     * 270: 0xc0000000
     */
    tb_fixed16_t    ang = x * 0x28be; 

    /* quadrant
     *
     * 1: 00 ...
     * 2: 01 ...
     * 3: 10 ...
     * 4: 11 ...
     *
     * quadrant++
     *
     * 1: 01 ...
     * 2: 10 ...
     * 3: 11 ...
     * 4: 00 ...
     *
     */
    tb_int_t        quadrant = ang >> 30;
    quadrant++;
    
    /* quadrant == 2, 3, |angle| < 90
     *
     * 100 => -100 + 180 => 80
     * -200 => 200 + 180 => -20
     */
    if (quadrant & 0x2) ang = -ang + 0x80000000;

    // rotation
    tb_fixed16_cordic_rotation(&cos, &sin, ang);
    
    // result
    if (s) 
    {
        // return sin
        *s = tb_fixed30_to_fixed16(sin);
    }
    if (c) 
    {   
        // quadrant == 2, 3
        if (quadrant & 0x2) cos = -cos;

        // return cos
        *c = tb_fixed30_to_fixed16(cos);
    }
}
// slope angle: [-180, 180]
// the precision will be pool if x, y is too small
tb_fixed16_t tb_fixed16_atan2_int32(tb_fixed16_t y, tb_fixed16_t x)
{
    if (!(x | y)) return 0;

    // abs
    tb_int32_t xs = tb_int32_get_sign(x);
    x = tb_fixed30_abs(x);

    // quadrant: 1, 4
    tb_fixed16_t z = tb_fixed16_cordic_vector_atan2(y, x);

    // for quadrant: 2, 3
    if (xs) 
    {
        tb_int32_t zs = tb_int32_get_sign(z);
        if (y == 0) zs = 0;

        tb_fixed16_t pi = tb_int32_set_sign(TB_FIXED16_PI, zs);
        z = pi - z;
    }
    return z;
}
tb_fixed16_t tb_fixed16_asin_int32(tb_fixed16_t x)
{
    // abs
    tb_int32_t s = tb_int32_get_sign(x);
    x = tb_fixed16_abs(x);

    if (x >= TB_FIXED16_ONE) return tb_int32_set_sign(TB_FIXED16_PI >> 1, s);

    tb_fixed16_t z = tb_fixed16_cordic_vector_asin(x * 0x28be);
    return tb_int32_set_sign(z, ~s);
}

// |angle| < 90
// the precision will be pool if x is too large.
tb_fixed16_t tb_fixed16_atan_int32(tb_fixed16_t x)
{
    if (!x) return 0;
    return tb_fixed16_cordic_vector_atan2(x, TB_FIXED16_ONE);
}

tb_fixed16_t tb_fixed16_exp_int32(tb_fixed16_t x)
{
    tb_trace_noimpl();
    return 0;
}
