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
 * @file        wcsdup.c
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

tb_wchar_t* tb_wcsdup(tb_wchar_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // done
    __tb_register__ tb_size_t       n = tb_wcslen(s);
    __tb_register__ tb_wchar_t*     p = (tb_wchar_t*)tb_malloc((n + 1) * sizeof(tb_wchar_t));
    if (p)
    {
        tb_memcpy(p, s, n * sizeof(tb_wchar_t));
        p[n] = L'\0';
    }

    return p;
}
