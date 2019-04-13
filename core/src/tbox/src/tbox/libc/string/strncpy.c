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
 * @file        strncpy.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"
#ifndef TB_CONFIG_LIBC_HAVE_STRNCPY
#   if defined(TB_ARCH_x86)
#       include "impl/x86/strncpy.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/strncpy.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/strncpy.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_STRNCPY)
static tb_char_t* tb_strncpy_impl(tb_char_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    // copy it
    return strncpy(s1, s2, n);
}
#elif !defined(TB_LIBC_STRING_IMPL_STRNCPY)
static tb_char_t* tb_strncpy_impl(tb_char_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, s1);

    // no size or same? 
    tb_check_return_val(n && s1 != s2, s1);

    // copy it
    tb_char_t* s = s1;
    while (n) 
    {
        if ((*s = *s2)) s2++;
        ++s;
        --n;
    }
    return s1;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_char_t* tb_strncpy(tb_char_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow dst? 
        tb_strlen(s2);

        // strncpy overflow? 
        tb_size_t n1 = tb_pool_data_size(s1);
        if (n1 && n + 1 > n1)
        {
            tb_trace_i("[strncpy]: [overflow]: [%p, %lu] => [%p, %lu]", s2, n, s1, n1);
            tb_backtrace_dump("[strncpy]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s2, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_strncpy_impl(s1, s2, n);
}
