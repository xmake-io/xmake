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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
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
    size_t           path_size = 0;
    tb_char_t const* path = luaL_checklstring(lua, 1, &path_size);
    tb_check_return_val(path, 0);

    // get the option argument, e.g. {normalize = true}
    tb_bool_t normalize = tb_false;
    if (lua_istable(lua, 2))
    {
        lua_pushstring(lua, "normalize");
        lua_gettable(lua, 2);
        if (lua_toboolean(lua, -1))
            normalize = tb_true;
        lua_pop(lua, 1);
    }

    // do path:translate()
    tb_char_t data[TB_PATH_MAXN];
    tb_size_t size = tb_path_translate_to(path, (tb_size_t)path_size, data, sizeof(data), normalize);
    if (size) lua_pushlstring(lua, data, (size_t)size);
    else lua_pushnil(lua);
    return 1;
}
