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
 * @file        isqrti.c
 * @ingroup     libm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "math.h"
#include "../utils/utils.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_uint32_t tb_isqrti_impl(tb_uint32_t x)
{
#if 0
    // lookup + newton 
    static tb_uint32_t table[256] = 
    { 
        0,    16,  22,  27,  32,  35,  39,  42,  45,  48,  50,  53,  55,  57
    ,   59,   61,  64,  65,  67,  69,  71,  73,  75,  76,  78,  80,  81,  83
    ,   84,   86,  87,  89,  90,  91,  93,  94,  96,  97,  98,  99, 101, 102
    ,   103, 104, 106, 107, 108, 109, 110, 112, 113, 114, 115, 116, 117, 118
    ,   119, 120, 121, 122, 123, 124, 125, 126, 128, 128, 129, 130, 131, 132
    ,   133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 144, 145
    ,   146, 147, 148, 149, 150, 150, 151, 152, 153, 154, 155, 155, 156, 157
    ,   158, 159, 160, 160, 161, 162, 163, 163, 164, 165, 166, 167, 167, 168
    ,   169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 178
    ,   179, 180, 181, 181, 182, 183, 183, 184, 185, 185, 186, 187, 187, 188
    ,   189, 189, 190, 191, 192, 192, 193, 193, 194, 195, 195, 196, 197, 197
    ,   198, 199, 199, 200, 201, 201, 202, 203, 203, 204, 204, 205, 206, 206
    ,   207, 208, 208, 209, 209, 210, 211, 211, 212, 212, 213, 214, 214, 215
    ,   215, 216, 217, 217, 218, 218, 219, 219, 220, 221, 221, 222, 222, 223
    ,   224, 224, 225, 225, 226, 226, 227, 227, 228, 229, 229, 230, 230, 231
    ,   231, 232, 232, 233, 234, 234, 235, 235, 236, 236, 237, 237, 238, 238
    ,   239, 240, 240, 241, 241, 242, 242, 243, 243, 244, 244, 245, 245, 246
    ,   246, 247, 247, 248, 248, 249, 249, 250, 250, 251, 251, 252, 252, 253
    ,   253, 254, 254, 255 
    }; 

    tb_uint32_t xn; 
    if (x >= 0x7ffea810) return 0xb504; 
    if (x >= 0x10000) 
    { 
        if (x >= 0x1000000)
        { 
            // lookup table
            if (x >= 0x10000000)
            { 
                if (x >= 0x40000000) xn = table[x >> 24] << 8; 
                else xn = table[x >> 22] << 7;
            } 
            else 
            { 
                if (x >= 0x4000000) xn = table[x >> 20] << 6;  
                else xn = table[x >> 18] << 5;  
            } 

            // newton
            xn = (xn + 1 + (x / xn)) >> 1; 
            xn = (xn + 1 + (x / xn)) >> 1; 
            return (((xn * xn) > x)? --xn : xn); 

        }
        else 
        { 
            if (x >= 0x100000) 
            { 
                if (x >= 0x400000) xn = table[x >> 16] << 4; 
                else xn = table[x >> 14] << 3; 
            } 
            else 
            { 
                if (x >= 0x40000) xn = table[x >> 12] << 2; 
                else xn = table[x >> 10] << 1;
            } 

            xn = (xn + 1 + (x / xn)) >> 1; 
            return (((xn * xn) > x)? --xn : xn); 
        } 
    }
    else 
    { 
        if (x >= 0x100) 
        { 
            if (x >= 0x1000) 
            { 
                if (x >= 0x4000) xn = (table[x >> 8]) + 1; 
                else xn = (table[x >> 6] >> 1) + 1;
            } 
            else 
            { 
                if (x >= 0x400) xn = (table[x >> 4] >> 2) + 1; 
                else xn = (table[x >> 2] >> 3) + 1; 
            } 
            return ((xn * xn) > x)? --xn : xn; 
        } 
        else 
        { 
            return (table[x] >> 4);
        } 
    } 
    return ((tb_uint32_t)-1);
#elif 1
    static tb_uint8_t const table[256] =
    {
        0,      16,     23,     28,     32,     36,     40,     43,     46,     48,     51,     54,     56,     58,     60,     62,     64,     66,     68,     70,     72,     74,     76,     77,     79,     80,     82,     84,     85,     87,     88,     90
    ,   91,     92,     94,     95,     96,     98,     99,     100,    102,    103,    104,    105,    107,    108,    109,    110,    111,    112,    114,    115,    116,    117,    118,    119,    120,    121,    122,    123,    124,    125,    126,    127 
    ,   128,    129,    130,    131,    132,    133,    134,    135,    136,    137,    138,    139,    140,    141,    142,    143,    144,    144,    145,    146,    147,    148,    149,    150,    151,    151,    152,    153,    154,    155,    156,    156 
    ,   157,    158,    159,    160,    160,    161,    162,    163,    164,    164,    165,    166,    167,    168,    168,    169,    170,    171,    171,    172,    173,    174,    174,    175,    176,    176,    177,    178,    179,    179,    180,    181
    ,   182,    182,    183,    184,    184,    185,    186,    186,    187,    188,    188,    189,    190,    190,    191,    192,    192,    193,    194,    194,    195,    196,    196,    197,    198,    198,    199,    200,    200,    201,    202,    202
    ,   203,    204,    204,    205,    205,    206,    207,    207,    208,    208,    209,    210,    210,    211,    212,    212,    213,    213,    214,    215,    215,    216,    216,    217,    218,    218,    219,    219,    220,    220,    221,    222
    ,   222,    223,    223,    224,    224,    225,    226,    226,    227,    227,    228,    228,    229,    230,    230,    231,    231,    232,    232,    233,    233,    234,    235,    235,    236,    236,    237,    237,    238,    238,    239,    239
    ,   240,    240,    241,    242,    242,    243,    243,    244,    244,    245,    245,    246,    246,    247,    247,    248,    248,    249,    249,    250,    250,    251,    251,    252,    252,    253,    253,    254,    254,    255,    255,    255
    };

    tb_uint32_t b = 0;
    if (x < 255) return (table[x + 1] - 1) >> 4;
    else if (x < (1 << 12)) b = table[x >> 4] >> 2;
    else if (x < (1 << 14)) b = table[x >> 6] >> 1;
    else if (x < (1 << 16)) b = table[x >> 8];
    else 
    {
        tb_uint32_t s = tb_ilog2i(x >> 16) >> 1;
        tb_uint32_t c = x >> (s + 2);
        b = table[c >> (s + 8)];
        b = tb_idivi8(c, (tb_uint8_t)b) + (b << s);
    }
    return (b - (x < b * b));
#elif 0
    // lookup bits
    tb_uint32_t t;
    tb_uint32_t n = 0;
    tb_uint32_t b = 0x8000;
    tb_uint32_t s = 15; 
    do 
    { 
        if (x >= (t = (((n << 1) + b) << s--))) 
        { 
            n += b; 
            x -= t; 
        } 
    } 
    while (b >>= 1); 
    return n;
#else
    // lookup bits
    tb_uint32_t i = 0;
    tb_uint32_t r = 0;
    tb_uint32_t n = 0;
    tb_uint32_t d = 0;
    for (i = 0; i < 16; i++)
    {
        n <<= 1;
        r = ((r << 2) + (x >> 30));
        x <<= 2;
        d = (n << 1) + 1;
        if (d <= r)
        {
            r -= d;
            n++;
        }
    }
    return n;
#endif
}
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
static __tb_inline__ tb_uint32_t tb_isqrti_impl_using_sqrt(tb_uint32_t x)
{
    return (tb_uint32_t)tb_sqrtf((tb_float_t)x);
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_uint32_t tb_isqrti(tb_uint32_t x)
{
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT

    // using the sqrt function?
    static tb_long_t s_using_sqrt = -1;

    // analyze the profile
    if (s_using_sqrt < 0)
    {
        // analyze isqrti
        tb_hong_t                   t1 = tb_uclock();
        __tb_volatile__ tb_size_t   n1 = 200;
        __tb_volatile__ tb_uint32_t v1; tb_used(&v1);
        while (n1--) 
        {
            v1 = tb_isqrti_impl((1 << 4) + 3);
            v1 = tb_isqrti_impl((1 << 12) + 3);
            v1 = tb_isqrti_impl((1 << 20) + 3);
            v1 = tb_isqrti_impl((1 << 28) + 3);
        }
        t1 = tb_uclock() - t1;

        // analyze sqrt
        tb_hong_t                   t2 = tb_uclock();
        __tb_volatile__ tb_size_t   n2 = 200;
        __tb_volatile__ tb_uint32_t v2; tb_used(&v2);
        while (n2--) 
        {
            v2 = tb_isqrti_impl_using_sqrt((1 << 4) + 3);
            v2 = tb_isqrti_impl_using_sqrt((1 << 12) + 3);
            v2 = tb_isqrti_impl_using_sqrt((1 << 20) + 3);
            v2 = tb_isqrti_impl_using_sqrt((1 << 28) + 3);
        }
        t2 = tb_uclock() - t2;

        // using sqrt?
        s_using_sqrt = t2 < t1? 1 : 0;
    }
    
    // done
    return s_using_sqrt > 0? tb_isqrti_impl_using_sqrt(x) : tb_isqrti_impl(x);
#else
    return tb_isqrti_impl(x);
#endif
}
