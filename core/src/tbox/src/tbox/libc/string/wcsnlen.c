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
 * @file        wcsnlen.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifdef TB_CONFIG_LIBC_HAVE_WCSNLEN
#   include <wchar.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
#ifdef TB_CONFIG_LIBC_HAVE_WCSNLEN
tb_size_t tb_wcsnlen(tb_wchar_t const* s, tb_size_t n)
{
    tb_assert_and_check_return_val(s, 0);
    return wcsnlen(s, n);
}
#else
tb_size_t tb_wcsnlen(tb_wchar_t const* s, tb_size_t n)
{
    tb_assert_and_check_return_val(s, 0);
    if (!n) return 0;

    __tb_register__ tb_wchar_t const* p = s;

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
