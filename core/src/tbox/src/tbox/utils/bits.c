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
 * @file        bits.c
 * @ingroup     utils
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "bits.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_uint32_t tb_bits_get_ubits32(tb_byte_t const* p, tb_size_t b, tb_size_t n)
{
    // check
    tb_assert(p && n <= 32);

    // no bits?
    tb_check_return_val(n, 0);

    // done
    p += b >> 3; b &= 0x07;
    if (!b && n == 1) return tb_bits_get_u1(p);
    else if (!b && n == 8) return tb_bits_get_u8(p);
    else if (!b && n == 16) return tb_bits_get_u16_be(p);
    else if (!b && n == 24) return tb_bits_get_u24_be(p);
    else if (!b && n == 32) return tb_bits_get_u32_be(p);
    else
    {
#if defined(tb_bits_get_ubits32_impl)
        return tb_bits_get_ubits32_impl(p, b, n);
#elif defined(__tb_small__)
        tb_uint32_t x = 0;
        tb_size_t   i = b; 
        tb_int_t    j = 24;

        b += n;
        while (b > 7) 
        {
            x |= *p++ << (i + j);
            j -= 8;
            b -= 8;
        }
        if (b > 0) x |= j < 0? (*p >> (8 - i)) : *p << (i + j);
        return (n < 32)? (x >> (32 - n)) : x;
#else   
        tb_uint32_t x = 0;
        tb_size_t   i = b; b += n;

        if (b > 32)
        {
            x |= p[0] << (i + 24);
            x |= p[1] << (i + 16);
            x |= p[2] << (i + 8);
            x |= p[3] << (i + 0);
            x |= p[4] >> (8 - i);
        }
        else if (b > 24)
        {
#if 1
            x |= p[0] << (i + 24);
            x |= p[1] << (i + 16);
            x |= p[2] << (i + 8);
            x |= p[3] << (i + 0);
#else
            x = tb_bits_get_u32_be(p);
            x <<= i;
#endif
        }
        else if (b > 16)
        {
            x |= p[0] << (i + 24);
            x |= p[1] << (i + 16);
            x |= p[2] << (i + 8);
        }
        else if (b > 8)
        {
            x |= p[0] << (i + 24);
            x |= p[1] << (i + 16);
        }
        else x |= p[0] << (i + 24);
        return (n < 32)? (x >> (32 - n)) : x;
#endif
    }
}
tb_sint32_t tb_bits_get_sbits32(tb_byte_t const* p, tb_size_t b, tb_size_t n)
{
    // check
    tb_assert(p && n <= 32);

    // no bits?
    tb_check_return_val(n, 0);

    // done
    p += b >> 3; b &= 0x07;
    if (n < 32)
    {
        tb_sint32_t s = -(tb_sint32_t)tb_bits_get_ubits32(p, b, 1);
        return ((s << (n - 1)) | tb_bits_get_ubits32(p, b + 1, n - 1));
    }
    else return tb_bits_get_ubits32(p, b, n);
}
tb_void_t tb_bits_set_ubits32(tb_byte_t* p, tb_size_t b, tb_uint32_t x, tb_size_t n)
{
    // check
    tb_assert(p && n <= 32);

    // no bits?
    tb_check_return(n);

    // done
    p += b >> 3; b &= 0x07;
    if (!b && n == 1) tb_bits_set_u1(p, x);
    else if (!b && n == 8) tb_bits_set_u8(p, x);
    else if (!b && n == 16) tb_bits_set_u16_be(p, x);
    else if (!b && n == 24) tb_bits_set_u24_be(p, x);
    else if (!b && n == 32) tb_bits_set_u32_be(p, x);
    else
    {
#ifdef __tb_small__
        if (n < 32) x <<= (32 - n);
        while (n--) 
        {
            *p &= ~(0x1 << (7 - b));
            *p |= ((x >> 31) << (7 - b));

            x <<= 1;
            if (++b > 7) 
            {
                b = 0;
                p++;
            }
        }
#else
        tb_uint32_t m = 0xffffffff;
        tb_size_t   i = b; b += n;

        if (n < 32) 
        {
            x <<= (32 - n);
            m <<= (32 - n);
        }
        if (b > 32)
        {
            p[0] &= ~(m >> (24 + i));
            p[0] |= (x >> (24 + i));
            p[1] = (x >> (16 + i));
            p[2] = (x >> (8 + i));  
            p[3] = (x >> i);
            p[4] = (x << (8 - i));
        }
        else if (b > 24)
        {
            if (i)
            {
                p[0] &= ~(m >> (24 + i));
                p[0] |= (x >> (24 + i));
                p[1] = (x >> (16 + i));
                p[2] = (x >> (8 + i));  
                p[3] = (x >> i);
            }
            else
            {   
                p[0] = x >> 24;
                p[1] = x >> 16;
                p[2] = x >> 8;
                p[3] = x;
            }
        }
        else if (b > 16)
        {
            if (i)
            {
                p[0] &= ~(m >> (24 + i));
                p[0] |= (x >> (24 + i));
                p[1] = (x >> (16 + i));
                p[2] = (x >> (8 + i));
            }
            else
            {   
                p[0] = x >> 24;
                p[1] = x >> 16;
                p[2] = x >> 8;
            }
        }
        else if (b > 8)
        {
            if (i)
            {
                p[0] &= ~(m >> (24 + i));
                p[0] |= (x >> (24 + i));
                p[1] = (x >> (16 + i));
            }
            else
            {   
                p[0] = x >> 24;
                p[1] = x >> 16;
            }
        }
        else 
        {
            if (i)
            {
                p[0] &= ~(m >> (24 + i));
                p[0] |= (x >> (24 + i));    
            }
            else p[0] = x >> 24;
        }
#endif
    }
}
tb_void_t tb_bits_set_sbits32(tb_byte_t* p, tb_size_t b, tb_sint32_t x, tb_size_t n)
{
    // check
    tb_assert(p && n <= 32);

    // no bits?
    tb_check_return(n);

    // done
    p += b >> 3; b &= 0x07;
    if (n < 32)
    {
        tb_bits_set_ubits32(p, b, (((tb_uint32_t)x) >> 31) & 0x01, 1);
        tb_bits_set_ubits32(p, b + 1, (((tb_uint32_t)x) & 0x7fffffff), n - 1);
    }
    else tb_bits_set_ubits32(p, b, x, n);
}
tb_uint64_t tb_bits_get_ubits64(tb_byte_t const* p, tb_size_t b, tb_size_t n)
{
    // check
    tb_assert(p && n <= 64);

    // need 32bits only?
    if (n <= 32) return (tb_uint64_t)tb_bits_get_ubits32(p, b, n);

    // skip bytes
    p += b >> 3; b &= 0x07;

    // done
    if (!b && n == 64) return tb_bits_get_u64_be(p);
    else
    {
        tb_uint64_t x = 0;
        tb_size_t   i = b; 
        tb_int_t    j = 56;

        b += n;
        while (b > 7) 
        {
            x |= ((tb_uint64_t)*p++) << (i + j);
            j -= 8;
            b -= 8;
        }
        if (b > 0) x |= j < 0? (*p >> (8 - i)) : ((tb_uint64_t)*p) << (i + j);
        return (n < 64)? (x >> (64 - n)) : x;
    }
}
tb_sint64_t tb_bits_get_sbits64(tb_byte_t const* p, tb_size_t b, tb_size_t n)
{
    // check
    tb_assert(p && n <= 64);

    // need 32bits only?
    if (n <= 32) return tb_bits_get_sbits32(p, b, n);

    // skip bytes
    p += b >> 3; b &= 0x07;

    // done
    if (n < 64)
    {
        tb_sint64_t s = -(tb_sint64_t)tb_bits_get_ubits64(p, b, 1);
        return ((s << (n - 1)) | tb_bits_get_ubits64(p, b + 1, n - 1));
    }
    else return tb_bits_get_ubits64(p, b, n);
}

