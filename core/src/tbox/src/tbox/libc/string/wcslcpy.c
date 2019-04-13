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
 * @file        wcslcpy.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifdef TB_CONFIG_LIBC_HAVE_WCSLCPY
#   include <wchar.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
#ifdef TB_CONFIG_LIBC_HAVE_WCSLCPY
tb_size_t tb_wcslcpy(tb_wchar_t* s1, tb_wchar_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);
    return wcslcpy(s1, s2, n);
}
#else
tb_size_t tb_wcslcpy(tb_wchar_t* s1, tb_wchar_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);

    // no size or same? 
    tb_check_return_val(n && s1 != s2, tb_wcslen(s1));

    // copy
#if 0
    tb_wchar_t const* s = s2; --n;
    while (*s1 = *s2) 
    {
        if (n) 
        {
            --n;
            ++s1;
        }
        ++s2;
    }
    return s2 - s;
#else
    tb_size_t sn = tb_wcslen(s2);
    tb_memcpy(s1, s2, tb_min(sn + 1, n) * sizeof(tb_wchar_t));
    return tb_min(sn, n);
#endif
}
#endif
