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
 * @file        ilog2i.c
 * @ingroup     libm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "math.h"
#include "../utils/bits.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_uint32_t tb_ilog2i(tb_uint32_t x)
{
#if 0
    static tb_uint32_t table[32] = 
    {
        1           // 0
    ,   2           // 1
    ,   4           // 2
    ,   8           // 3
    ,   16          // 4
    ,   32          // 5
    ,   64          // 6
    ,   128         // 7
    ,   256         // 8
    ,   512         // 9
    ,   1024        // 10
    ,   2048        // 11
    ,   4096        // 12
    ,   8192        // 13
    ,   16384       // 14
    ,   32768       // 15
    ,   65536       // 16
    ,   131072      // 17
    ,   262144      // 18
    ,   524288      // 19
    ,   1048576     // 20
    ,   2097152     // 21
    ,   4194304     // 22
    ,   8388608     // 23
    ,   16777216    // 24
    ,   33554432    // 25
    ,   67108864    // 26
    ,   134217728   // 27
    ,   268435456   // 28
    ,   536870912   // 29
    ,   1073741824  // 30
    ,   2147483648  // 31
    };

    tb_int_t l = 0;
    tb_int_t m = 15;
    tb_int_t r = 32;
    while ((r - l) > 1)
    {
        tb_uint32_t v = table[m];
        if (x < v) r = m;
        else l = m;
        m = (l + r) >> 1;
    }
    return m;
#elif 0
    static tb_uint8_t const table[256]=
    {
        0, 0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
    ,   5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
    ,   6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6
    ,   6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6
    ,   7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
    ,   7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
    ,   7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
    ,   7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
    };

    tb_size_t n = 0;
    if (x & 0xffff0000)
    {
        x >>= 16;
        n += 16;
    }

    if (x & 0xff00) 
    {
        x >>= 8;
        n += 8;
    }
    n += table[x];

    return n;
#else
    return (tb_uint32_t)(31 - tb_bits_cl0_u32_be(x | 1));
#endif
}
