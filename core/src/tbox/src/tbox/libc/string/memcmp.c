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
 * @file        memcmp.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"
#ifndef TB_CONFIG_LIBC_HAVE_MEMCMP
#   if defined(TB_ARCH_x86)
#       include "impl/x86/memcmp.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/memcmp.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/memcmp.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_MEMCMP)
static tb_long_t tb_memcmp_impl(tb_cpointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);

    // done
    return memcmp(s1, s2, n);
}
#elif !defined(TB_LIBC_STRING_IMPL_MEMCMP)
static tb_long_t tb_memcmp_impl(tb_cpointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);

    // equal or empty?
    if (s1 == s2 || !n) return 0;

    // done
    tb_long_t r = 0;
    tb_byte_t const* p1 = (tb_byte_t const *)s1;
    tb_byte_t const* p2 = (tb_byte_t const *)s2;
    while (n-- && ((r = ((tb_long_t)(*p1++)) - *p2++) == 0)) ;
    return r;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_long_t tb_memcmp_(tb_cpointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    // done
    return tb_memcmp_impl(s1, s2, n);
}
tb_long_t tb_memcmp(tb_cpointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow?
        tb_size_t n1 = tb_pool_data_size(s1);
        if (n1 && n > n1)
        {
            tb_trace_i("[memcmp]: [overflow]: [%p, %lu] ?= [%p, %lu]", s2, n, s1, n1);
            tb_backtrace_dump("[memcmp]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s1, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }

        // overflow?
        tb_size_t n2 = tb_pool_data_size(s2);
        if (n2 && n > n2)
        {
            tb_trace_i("[memcmp]: [overflow]: [%p, %lu(%lu)] ?= [%p, %lu]", s2, n, n2, s1, n1);
            tb_backtrace_dump("[memcmp]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s2, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_memcmp_impl(s1, s2, n);
}
