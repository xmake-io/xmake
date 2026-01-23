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
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        offset.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* offset(s, n, [i])  -> index where n-th character counting from
 *   position 'i' starts; 0 means character at 'i'.
 */
tb_int_t xm_utf8_offset(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    lua_Integer n  = luaL_checkinteger(lua, 2);
    lua_Integer posi = (n >= 0) ? 1 : len + 1;
    posi = xm_utf8_posrelat((tb_long_t)luaL_optinteger(lua, 3, posi), len);

    tb_long_t result = xm_utf8_offset_impl(s, len, (tb_long_t)n, (tb_long_t)posi);
    if (result == -1) {
        return luaL_argerror(lua, 3, "position out of bounds");
    }
    if (result == -2) {
        return luaL_error(lua, "initial position is a continuation byte");
    }
    if (result == 0) {
        lua_pushnil(lua);
        return 1;
    }
    lua_pushinteger(lua, result);
    return 1;
}
