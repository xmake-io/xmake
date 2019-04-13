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
 * @file        memset.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../utils/utils.h"
#include "../../memory/impl/prefix.h"
#ifndef TB_CONFIG_LIBC_HAVE_MEMSET
#   if defined(TB_ARCH_x86)
#       include "impl/x86/memset.c"
#   elif defined(TB_ARCH_x64)
#       include "impl/x86/memset.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/memset.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/memset.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_MEMSET)
static tb_pointer_t tb_memset_impl(tb_pointer_t s, tb_byte_t c, tb_size_t n)
{
    tb_assert_and_check_return_val(s, tb_null);
    return memset(s, c, n);
}
#elif !defined(TB_LIBC_STRING_IMPL_MEMSET_U8)
static tb_pointer_t tb_memset_impl(tb_pointer_t s, tb_byte_t c, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // no size?
    tb_check_return_val(n, s);

    // init
    __tb_register__ tb_byte_t* p = (tb_byte_t*)s;

    // done
#ifdef __tb_small__
    while (n--) *p++ = c;
#else
    tb_size_t l = n & 0x3; n = (n - l) >> 2;
    while (n--)
    {
        p[0] = c;
        p[1] = c;
        p[2] = c;
        p[3] = c;
        p += 4;
    }

    while (l--) *p++ = c;
#endif
    return s;
}
#endif

#if !defined(TB_LIBC_STRING_IMPL_MEMSET_U16) && !defined(TB_CONFIG_MICRO_ENABLE)
static tb_pointer_t tb_memset_u16_impl(tb_pointer_t s, tb_uint16_t c, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // no size?
    tb_check_return_val(n, s);

    // must be aligned by 2-bytes 
    tb_assert(!(((tb_size_t)s) & 0x1));

    // init
    __tb_register__ tb_uint16_t* p = (tb_uint16_t*)s;

    // done
#ifdef __tb_small__
    while (n--) *p++ = c;
#else
    tb_size_t l = n & 0x3; n = (n - l) >> 2;
    while (n--)
    {
        p[0] = c;
        p[1] = c;
        p[2] = c;
        p[3] = c;
        p += 4;
    }

    while (l--) *p++ = c;
#endif

    // ok?
    return s;
}
#endif

#if !defined(TB_LIBC_STRING_IMPL_MEMSET_U24) && !defined(TB_CONFIG_MICRO_ENABLE)
static tb_pointer_t tb_memset_u24_impl(tb_pointer_t s, tb_uint32_t c, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // no size?
    tb_check_return_val(n, s);

    // init
    __tb_register__ tb_byte_t* p = (tb_byte_t*)s;
    __tb_register__ tb_byte_t* e = p + (n * 3);

    // done
#ifdef __tb_small__
    for (; p < e; p += 3) tb_bits_set_u24_ne(p, c);
#else
    tb_size_t l = n & 0x3; n -= l;
    while (p < e)
    {
        tb_bits_set_u24_ne(p + 0, c);
        tb_bits_set_u24_ne(p + 3, c);
        tb_bits_set_u24_ne(p + 6, c);
        tb_bits_set_u24_ne(p + 9, c);
        p += 12;
    }

    while (l--)
    {
        tb_bits_set_u24_ne(p, c);
        p += 3;
    }
#endif

    // ok?
    return s;
}
#endif

#if !defined(TB_LIBC_STRING_IMPL_MEMSET_U32) && !defined(TB_CONFIG_MICRO_ENABLE)
static tb_pointer_t tb_memset_u32_impl(tb_pointer_t s, tb_uint32_t c, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // no size?
    tb_check_return_val(n, s);

    // must be aligned by 4-bytes 
    tb_assert(!(((tb_size_t)s) & 0x3));

    // init 
    __tb_register__ tb_uint32_t* p = (tb_uint32_t*)s;

    // done
#ifdef __tb_small__
    while (n--) *p++ = c;
#else
    tb_size_t l = n & 0x3; n = (n - l) >> 2;
    while (n--)
    {
        p[0] = c;
        p[1] = c;
        p[2] = c;
        p[3] = c;
        p += 4;
    }

    while (l--) *p++ = c;
#endif

    // ok?
    return s;
}
#endif

#if !defined(TB_LIBC_STRING_IMPL_MEMSET_U64) && !defined(TB_CONFIG_MICRO_ENABLE)
static tb_pointer_t tb_memset_u64_impl(tb_pointer_t s, tb_uint64_t c, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // no size?
    tb_check_return_val(n, s);

    // must be aligned by 8-bytes 
    tb_assert(!(((tb_size_t)s) & 0x7));

    // init
    __tb_register__ tb_uint64_t* p = (tb_uint64_t*)s;

    // done
#ifdef __tb_small__
    while (n--) *p++ = c;
#else
    tb_size_t l = n & 0x3; n = (n - l) >> 2;
    while (n--)
    {
        p[0] = c;
        p[1] = c;
        p[2] = c;
        p[3] = c;
        p += 4;
    }

    while (l--) *p++ = c;
#endif

    // ok?
    return s;
}
#endif
/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_pointer_t tb_memset_(tb_pointer_t s, tb_byte_t c, tb_size_t n)
{
    // done
    return tb_memset_impl(s, c, n);
}
tb_pointer_t tb_memset(tb_pointer_t s, tb_byte_t c, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow?
        tb_size_t size = tb_pool_data_size(s);
        if (size && n > size)
        {
            tb_trace_i("[memset]: [overflow]: [%#x x %lu] => [%p, %lu]", c, n, s, size);
            tb_backtrace_dump("[memset]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_memset_impl(s, c, n);
}
#ifndef TB_CONFIG_MICRO_ENABLE
tb_pointer_t tb_memset_u16(tb_pointer_t s, tb_uint16_t c, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow?
        tb_size_t size = tb_pool_data_size(s);
        if (size && (n << 1) > size)
        {
            tb_trace_i("[memset_u16]: [overflow]: [%#x x %lu x 2] => [%p, %lu]", c, n, s, size);
            tb_backtrace_dump("[memset_u16]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_memset_u16_impl(s, c, n);
}
tb_pointer_t tb_memset_u24(tb_pointer_t s, tb_uint32_t c, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow?
        tb_size_t size = tb_pool_data_size(s);
        if (size && (n * 3) > size)
        {
            tb_trace_i("[memset_u24]: [overflow]: [%#x x %lu x 3] => [%p, %lu]", c, n, s, size);
            tb_pool_data_dump(s, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_memset_u24_impl(s, c, n);
}
tb_pointer_t tb_memset_u32(tb_pointer_t s, tb_uint32_t c, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow?
        tb_size_t size = tb_pool_data_size(s);
        if (size && (n << 2) > size)
        {
            tb_trace_i("[memset_u32]: [overflow]: [%#x x %lu x 4] => [%p, %lu]", c, n, s, size);
            tb_backtrace_dump("[memset_u32]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_memset_u32_impl(s, c, n);
}
tb_pointer_t tb_memset_u64(tb_pointer_t s, tb_uint64_t c, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow?
        tb_size_t size = tb_pool_data_size(s);
        if (size && (n << 3) > size)
        {
            tb_trace_i("[memset_u64]: [overflow]: [%#llx x %lu x 4] => [%p, %lu]", c, n, s, size);
            tb_backtrace_dump("[memset_u64]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_memset_u64_impl(s, c, n);
}
#endif
