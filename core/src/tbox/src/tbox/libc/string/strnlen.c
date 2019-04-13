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
 * @file        strnlen.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"
#ifndef TB_CONFIG_LIBC_HAVE_STRNLEN
#   if defined(TB_ARCH_x86)
#       include "impl/x86/strnlen.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/strnlen.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/strnlen.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_STRNLEN)
static tb_size_t tb_strnlen_impl(tb_char_t const* s, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, 0);

#ifdef TB_CONFIG_OS_ANDROID
    /* fix the bug for android
     *
     * return -1 if n == (tb_uint32_t)-1
     */
    return strnlen(s, (tb_uint16_t)n);
#else
    return strnlen(s, n);
#endif
}
#elif !defined(TB_LIBC_STRING_IMPL_STRNLEN)
static tb_size_t tb_strnlen_impl(tb_char_t const* s, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, 0);
    if (!n) return 0;

    __tb_register__ tb_char_t const* p = s;

#ifdef __tb_small__
    while (n-- && *p) ++p;
    return p - s;
#else
    tb_size_t l = n & 0x3; n = (n - l) >> 2;
    while (n--)
    {
        if (!p[0]) return (p - s + 0);
        if (!p[1]) return (p - s + 1);
        if (!p[2]) return (p - s + 2);
        if (!p[3]) return (p - s + 3);
        p += 4;
    }

    while (l-- && *p) ++p;
    return p - s;
#endif
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_size_t tb_strnlen(tb_char_t const* s, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow? 
        tb_size_t size = tb_pool_data_size(s);
        if (size)
        {
            // no '\0'?
            tb_size_t real = tb_strnlen_impl(s, size);
            if (s[real])
            {
                tb_trace_i("[strnlen]: [overflow]: [%p, %lu]", s, size);
                tb_backtrace_dump("[strnlen]: [overflow]: ", tb_null, 10);
                tb_pool_data_dump(s, tb_true, "\t[malloc]: [from]: ");
                tb_abort();
            }
        }
    }
#endif

    // done
    return tb_strnlen_impl(s, n);
}
