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
static tb_uint32_t tb_isqrti64_impl(tb_uint64_t x)
{
    // compute it fastly for uint32  
    if (!(x >> 32)) return tb_isqrti((tb_uint32_t)x);
    // compute it for uint64
    else
    {
        // done
        tb_uint64_t t;
        tb_uint64_t n = 0;
        tb_uint64_t b = 0x80000000;
        tb_uint32_t s = 31; 
        do 
        { 
            if (x >= (t = (((n << 1) + b) << s--))) 
            { 
                n += b; 
                x -= t; 
            } 
        } 
        while (b >>= 1); 

        // check
        tb_assert(!(n >> 32));

        // ok
        return (tb_uint32_t)n;
    }
}
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
static __tb_inline__ tb_uint32_t tb_isqrti64_impl_using_sqrt(tb_uint64_t x)
{
    return (!(x >> 32))? (tb_uint32_t)tb_sqrtf((tb_float_t)x) : (tb_uint32_t)tb_sqrt((tb_double_t)x);
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_uint32_t tb_isqrti64(tb_uint64_t x)
{
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT

    // using the sqrt function?
    static tb_long_t s_using_sqrt = -1;

    // analyze the profile
    if (s_using_sqrt < 0)
    {
        // analyze isqrti64
        tb_hong_t                   t1 = tb_uclock();
        __tb_volatile__ tb_size_t   n1 = 100;
        __tb_volatile__ tb_uint32_t v1; tb_used(&v1);
        while (n1--) 
        {
            v1 = tb_isqrti64_impl((1 << 4) + 3);
            v1 = tb_isqrti64_impl((1 << 12) + 3);
            v1 = tb_isqrti64_impl((1 << 20) + 3);
            v1 = tb_isqrti64_impl((1 << 28) + 3);
            v1 = tb_isqrti64_impl((1ULL << 36) + 3);
            v1 = tb_isqrti64_impl((1ULL << 42) + 3);
            v1 = tb_isqrti64_impl((1ULL << 50) + 3);
            v1 = tb_isqrti64_impl((1ULL << 58) + 3);
            v1 = tb_isqrti64_impl((1ULL << 60) + 3);
        }
        t1 = tb_uclock() - t1;

        // analyze sqrt
        tb_hong_t                   t2 = tb_uclock();
        __tb_volatile__ tb_size_t   n2 = 100;
        __tb_volatile__ tb_uint32_t v2; tb_used(&v2);
        while (n2--) 
        {
            v2 = tb_isqrti64_impl_using_sqrt((1 << 4) + 3);
            v2 = tb_isqrti64_impl_using_sqrt((1 << 12) + 3);
            v2 = tb_isqrti64_impl_using_sqrt((1 << 20) + 3);
            v2 = tb_isqrti64_impl_using_sqrt((1 << 28) + 3);
            v2 = tb_isqrti64_impl_using_sqrt((1ULL << 36) + 3);
            v2 = tb_isqrti64_impl_using_sqrt((1ULL << 42) + 3);
            v2 = tb_isqrti64_impl_using_sqrt((1ULL << 50) + 3);
            v2 = tb_isqrti64_impl_using_sqrt((1ULL << 58) + 3);
            v2 = tb_isqrti64_impl_using_sqrt((1ULL << 60) + 3);
        }
        t2 = tb_uclock() - t2;

        // using sqrt?
        s_using_sqrt = t2 < t1? 1 : 0;
    }
    
    // done
    return s_using_sqrt > 0? tb_isqrti64_impl_using_sqrt(x) : tb_isqrti64_impl(x);
#else
    return tb_isqrti64_impl(x);
#endif
}
