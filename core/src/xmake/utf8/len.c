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
 * @file        len.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/*
** utf8len(s [, i [, j [, lax]]]) --> number of characters that
** start in the range [i,j], or nil + current position if 's' is not
** well formed in that interval
*/
tb_int_t xm_utf8_len(lua_State *lua) {
    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    lua_Integer posi = xm_utf8_posrelat(luaL_optinteger(lua, 2, 1), len);
    lua_Integer posj = xm_utf8_posrelat(luaL_optinteger(lua, 3, -1), len);
    tb_bool_t lax = lua_toboolean(lua, 4);
    luaL_argcheck(lua, 1 <= posi && --posi <= (lua_Integer)len, 2, "initial position out of bounds");
    luaL_argcheck(lua, --posj < (lua_Integer)len, 3, "final position out of bounds");

    tb_size_t errpos = 0;
    tb_long_t n = xm_utf8_len_impl(s, len, posi + 1, posj + 1, !lax, &errpos);
    if (n < 0) {
        lua_pushnil(lua);
        lua_pushinteger(lua, errpos);
        return 2;
    }
    lua_pushinteger(lua, n);
    return 1;
}
