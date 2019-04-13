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
 * @file        wcsstr.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifdef TB_CONFIG_LIBC_HAVE_WCSSTR
#   include <wchar.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */

#ifdef TB_CONFIG_LIBC_HAVE_WCSSTR
tb_wchar_t* tb_wcsstr(tb_wchar_t const* s1, tb_wchar_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);
    return (tb_wchar_t*)wcsstr(s1, s2);
}
#else
tb_wchar_t* tb_wcsstr(tb_wchar_t const* s1, tb_wchar_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    __tb_register__ tb_wchar_t const* s = s1;
    __tb_register__ tb_wchar_t const* p = s2;

    do 
    {
        if (!*p) return (tb_wchar_t *)s1;
        if (*p == *s) 
        {
            ++p;
            ++s;
        } 
        else 
        {
            p = s2;
            if (!*s) return tb_null;
            s = ++s1;
        }

    } while (1);

    return tb_null;
}
#endif
