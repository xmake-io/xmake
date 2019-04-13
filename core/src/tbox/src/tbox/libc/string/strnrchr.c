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
 * @file        strnrchr.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
tb_char_t* tb_strnrchr(tb_char_t const* s, tb_size_t n, tb_char_t c)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);
    
    // done
    tb_char_t const* p = s + n - 1;
    while (p >= s && *p)
    {
        if (*p == c) return (tb_char_t*)p;
        p--;
    }
    return tb_null;
}
