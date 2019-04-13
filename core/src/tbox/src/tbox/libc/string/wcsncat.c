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
 * @file        wcsncat.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifdef TB_CONFIG_LIBC_HAVE_WCSNCAT
#   include <wchar.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
#ifdef TB_CONFIG_LIBC_HAVE_WCSNCAT
tb_wchar_t* tb_wcsncat(tb_wchar_t* s1, tb_wchar_t const* s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);
    return wcsncat(s1, s2, n);
}
#else
tb_wchar_t* tb_wcsncat(tb_wchar_t* s1, tb_wchar_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    // done
    __tb_register__ tb_wchar_t* s = s1;
    while (*s) s++; --s;
    while (n-- && !(*s++ = *s2++));
    return s1;
}
#endif
