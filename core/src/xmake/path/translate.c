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
 * @file        translate.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "translate"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_path_translate(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the path
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_check_return_val(path, 0);

    // copy path
    tb_char_t data[TB_PATH_MAXN];
    tb_strlcpy(data, path, sizeof(data));

    // do path:translate()
    tb_size_t size = tb_path_translate(data, 0, sizeof(data) - 1);
    if (size) lua_pushlstring(lua, data, (size_t)size);
    else lua_pushnil(lua);
    return 1;
}
