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
 * @file        strnicmp.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifdef TB_CONFIG_LIBC_HAVE_STRNCASECMP
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#ifdef TB_CONFIG_LIBC_HAVE_STRNCASECMP
static tb_long_t tb_strnicmp_impl(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);
#   ifdef TB_COMPILER_IS_MSVC
    return _strnicmp(s1, s2, n);
#   else
    return strncasecmp(s1, s2, n);
#   endif
}
#else
static tb_long_t tb_strnicmp_impl(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, 0);
    if (s1 == s2 || !n) return 0;

    tb_long_t r = 0;
    while (n && ((s1 == s2) || !(r = ((tb_long_t)(tb_tolower(*((tb_byte_t*)s1)))) - tb_tolower(*((tb_byte_t*)s2)))) && (--n, ++s2, *s1++));
    return r;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_long_t tb_strnicmp(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n)
{
    // done
    return tb_strnicmp_impl(s1, s2, n);
}
