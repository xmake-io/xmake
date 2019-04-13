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
 * @file        strlen.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"
#ifndef TB_CONFIG_LIBC_HAVE_STRLEN
#   if defined(TB_ARCH_x86)
#       include "impl/x86/strlen.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/strlen.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/strlen.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_STRLEN)
static tb_size_t tb_strlen_impl(tb_char_t const* s)
{
    tb_assert_and_check_return_val(s, 0);
    return strlen(s);
}
#elif !defined(TB_LIBC_STRING_IMPL_STRLEN)
static tb_size_t tb_strlen_impl(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    __tb_register__ tb_char_t const* p = s;
#ifdef __tb_small__
    while (*p) p++;
    return (p - s);
#else
    while (1) 
    {
        if (!p[0]) return (p - s + 0);
        if (!p[1]) return (p - s + 1);
        if (!p[2]) return (p - s + 2);
        if (!p[3]) return (p - s + 3);
        p += 4;
    }
    return 0;
#endif
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_size_t tb_strlen(tb_char_t const* s)
{
    // check
#ifdef __tb_debug__
    {
        // overflow? 
        tb_size_t size = tb_pool_data_size(s);
        if (size)
        {
            // no '\0'?
            tb_size_t real = tb_strnlen(s, size);
            if (s[real])
            {
                tb_trace_i("[strlen]: [overflow]: [%p, %lu]", s, size);
                tb_backtrace_dump("[strlen]: [overflow]: ", tb_null, 10);
                tb_pool_data_dump(s, tb_true, "\t[malloc]: [from]: ");
                tb_abort();
            }
        }
    }
#endif

    // done
    return tb_strlen_impl(s);
}

