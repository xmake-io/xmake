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
 * @file        wcsichr.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */

tb_wchar_t* tb_wcsichr(tb_wchar_t const* s, tb_wchar_t c)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // init
    tb_wchar_t const*   p = s;
    tb_wchar_t          b = tb_tolower(c);

    // find
    while (*p)
    {
        if (tb_tolower(*p) == b) return (tb_wchar_t*)p;
        p++;

    }

    return tb_null;
}
