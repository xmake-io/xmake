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
 * @file        wcschr.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifdef TB_CONFIG_LIBC_HAVE_WCSCHR
#   include <string.h>
#endif
/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */

#ifdef TB_CONFIG_LIBC_HAVE_WCSCHR
tb_wchar_t* tb_wcschr(tb_wchar_t const* s, tb_wchar_t c)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);
    return wcschr(s1, c);
}
#else
tb_wchar_t* tb_wcschr(tb_wchar_t const* s, tb_wchar_t c)
{
    tb_assert_and_check_return_val(s, tb_null);

    while (*s)
    {
        if (*s == c) return (tb_wchar_t* )s;
        s++;

    }
    return tb_null;
}
#endif

