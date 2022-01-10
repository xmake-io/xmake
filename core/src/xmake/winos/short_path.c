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
 * @file        short_path.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "short_path"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* get windows short path from long path
 *
 * local short_path, errors = winos.short_path(long_path)
 */
tb_int_t xm_winos_short_path(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the arguments
    tb_char_t const* long_path = luaL_checkstring(lua, 1);
    tb_check_return_val(long_path, 0);

    // convert long path to wide characters
    tb_wchar_t long_path_w[TB_PATH_MAXN];
    if (tb_atow(long_path_w, long_path, TB_PATH_MAXN) == (tb_size_t)-1)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "invalid long path: %s", long_path);
        return 2;
    }

    // get short path
    tb_wchar_t short_path_w[TB_PATH_MAXN];
    if (GetShortPathNameW(long_path_w, short_path_w, TB_PATH_MAXN) == 0)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "cannot get short path from: %s", long_path);
        return 2;
    }

    // return result
    tb_char_t* short_path_a = (tb_char_t*)long_path_w;
    tb_size_t  short_path_n = tb_wtoa(short_path_a, short_path_w, TB_PATH_MAXN);
    if (short_path_n == (tb_size_t)-1)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "invalid short path from %s!", long_path);
        return 2;
    }
    lua_pushlstring(lua, short_path_a, short_path_n);
    return 1;
}
