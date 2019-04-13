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
 * @file        wcscpy.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifdef TB_CONFIG_LIBC_HAVE_WCSCPY
#   include <wchar.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */

#ifdef TB_CONFIG_LIBC_HAVE_WCSCPY
tb_wchar_t* tb_wcscpy(tb_wchar_t* s1, tb_wchar_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);
    return wcscpy(s1, s2);
}
#else
tb_wchar_t* tb_wcscpy(tb_wchar_t* s1, tb_wchar_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    __tb_register__ tb_wchar_t* s = s1;
    if (s1 == s2) return s;

#if 1
    tb_memcpy(s1, s2, (tb_wcslen(s2) + 1) * sizeof(tb_wchar_t));
#elif defined(__tb_small__)
    while ((*s++ = *s2++)) ;
#else
    while (1) 
    {
        if (!(s1[0] = s2[0])) break;
        if (!(s1[1] = s2[1])) break;
        if (!(s1[2] = s2[2])) break;
        if (!(s1[3] = s2[3])) break;
        s1 += 4;
        s2 += 4;
    }
#endif

    return s;
}
#endif
