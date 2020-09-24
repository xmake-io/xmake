/*!A cross-platform build utility based on Lua
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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        endswith.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "endswith"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_string_endswith(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the string and suffix
    size_t              string_size = 0;
    size_t              suffix_size = 0;
    tb_char_t const*    string = luaL_checklstring(lua, 1, &string_size);
    tb_char_t const*    suffix = luaL_checklstring(lua, 2, &suffix_size);
    tb_check_return_val(string && suffix, 0);

    // string:endswith(suffix)?
    lua_pushboolean(lua, string_size >= suffix_size && !tb_strcmp(string + string_size - suffix_size, suffix));


    // ok
    return 1;
}
