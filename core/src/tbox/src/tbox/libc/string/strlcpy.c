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
 * @file        strlcpy.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"
#ifndef TB_CONFIG_LIBC_HAVE_STRLCPY
#   if defined(TB_ARCH_x86)
#       include "impl/x86/strlcpy.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/strlcpy.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/strlcpy.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros 
 */

/* suppress warning as error for clang compiler temporarily:
 *
 * implicit declaration of function 'strlcpy' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
 *
 * TODO: need improve xmake to check this interface more correctly.
 */
#if defined(TB_CONFIG_LIBC_HAVE_STRLCPY) && defined(TB_COMPILER_IS_CLANG)
#   undef TB_CONFIG_LIBC_HAVE_STRLCPY
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_STRLCPY)
static tb_size_t tb_strlcpy_impl(tb_char_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);

    // copy it
    return strlcpy(s1, s2, n);
}
#elif !defined(TB_LIBC_STRING_IMPL_STRLCPY)
/* copy s2 to s1 of size n
 *
 * - at most n - 1 characters will be copied.
 * - always null terminates (unless n == 0).
 * 
 * returns strlen(s2); if retval >= n, truncation occurred.
 */
static tb_size_t tb_strlcpy_impl(tb_char_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);

    // init
    tb_char_t*          d = s1;
    tb_char_t const*    s = s2;
    tb_size_t           m = n;

    // copy as many bytes as will fit 
    if (m != 0 && --m != 0)
    {
        do 
        {
            if ((*d++ = *s++) == 0) break;

        } while (--m != 0);
    }

    // not enough room in dst, add null and traverse rest of src 
    if (m == 0)
    {
        if (n != 0) *d = '\0';      
        while (*s++) ;
    }

    // count does not include null
    return (s - s2 - 1);
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_size_t tb_strlcpy(tb_char_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
#ifdef __tb_debug__
    {
        // overflow dst? 
        tb_size_t n2 = tb_strlen(s2);

        // strlcpy overflow? 
        tb_size_t n1 = tb_pool_data_size(s1);
        if (n1 && tb_min(n2 + 1, n) > n1)
        {
            tb_trace_i("[strlcpy]: [overflow]: [%p, %lu] => [%p, %lu]", s2, tb_min(n2 + 1, n), s1, n1);
            tb_backtrace_dump("[strlcpy]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s2, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_strlcpy_impl(s1, s2, n);
}
