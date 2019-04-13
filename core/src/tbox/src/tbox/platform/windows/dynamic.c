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
 * @file        dynamic.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../dynamic.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_dynamic_ref_t tb_dynamic_init(tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(name, tb_null);

    // atow
    tb_wchar_t temp[TB_PATH_MAXN];
    if (tb_atow(temp, name, TB_PATH_MAXN) == -1) return tb_null;

    // load
    return (tb_dynamic_ref_t)LoadLibraryExW(temp, tb_null, LOAD_WITH_ALTERED_SEARCH_PATH);
}
tb_void_t tb_dynamic_exit(tb_dynamic_ref_t dynamic)
{
    // check
    tb_assert_and_check_return(dynamic);

    // exit it
    FreeLibrary((HMODULE)dynamic);
}
tb_pointer_t tb_dynamic_func(tb_dynamic_ref_t dynamic, tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(dynamic && name, tb_null);

    // get func
    return (tb_pointer_t)GetProcAddress((HMODULE)dynamic, name);
}
tb_pointer_t tb_dynamic_pvar(tb_dynamic_ref_t dynamic, tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(dynamic && name, tb_null);

    // get variable address
    return (tb_pointer_t)GetProcAddress((HMODULE)dynamic, name);
}
