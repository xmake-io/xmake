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
 * @file        memmov.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"
#ifndef TB_CONFIG_LIBC_HAVE_MEMMOVE
#   if defined(TB_ARCH_x86)
#       include "impl/x86/memmov.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/memmov.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/memmov.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */

#if defined(TB_CONFIG_LIBC_HAVE_MEMMOVE)
static tb_pointer_t tb_memmov_impl(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);
    return memmove(s1, s2, n);
}
#elif !defined(TB_LIBC_STRING_IMPL_MEMMOV)
static tb_pointer_t tb_memmov_impl(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    __tb_register__ tb_byte_t*          s = (tb_byte_t*)s1;
    __tb_register__ tb_byte_t const*    p = (tb_byte_t const*)s2;

    if (p >= s) 
    {
        while (n) 
        {
            *s++ = *p++;
            --n;
        }
    } 
    else 
    {
        while (n) 
        {
            --n;
            s[n] = p[n];
        }
    }

    return s1;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_pointer_t tb_memmov_(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    // done
    return tb_memmov_impl(s1, s2, n);
}

tb_pointer_t tb_memmov(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow dst?
        tb_size_t n1 = tb_pool_data_size(s1);
        if (n1 && n > n1)
        {
            tb_trace_i("[memmov]: [overflow]: [%p, %lu] => [%p, %lu]", s2, n, s1, n1);
            tb_backtrace_dump("[memmov]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s1, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }

        // overflow src?
        tb_size_t n2 = tb_pool_data_size(s2);
        if (n2 && n > n2)
        {
            tb_trace_i("[memmov]: [overflow]: [%p, %lu] => [%p, %lu]", s2, n, s1, n1);
            tb_backtrace_dump("[memmov]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s2, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_memmov_impl(s1, s2, n);
}

