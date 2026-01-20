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
 * @file        lastof.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* utf8.lastof(s, pattern, plain)
 */
tb_int_t xm_utf8_lastof(lua_State *lua) {
    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    size_t sublen;
    tb_char_t const* sub = luaL_checklstring(lua, 2, &sublen);
    tb_int_t plain = lua_toboolean(lua, 3);
    tb_long_t byte_pos = 0;

    if (plain) {
        byte_pos = xm_utf8_lastof_impl(s, len, sub, sublen);
    } else {
        lua_getglobal(lua, "string");
        lua_getfield(lua, -1, "lastof");
        lua_pushvalue(lua, 1); // s
        lua_pushvalue(lua, 2); // pattern
        lua_pushboolean(lua, 0); // plain = false
        lua_call(lua, 3, 1);
        if (!lua_isnil(lua, -1)) {
            byte_pos = (tb_long_t)lua_tointeger(lua, -1);
        }
    }

    if (byte_pos > 0) {
        tb_long_t char_pos = xm_utf8_charpos(s, len, byte_pos);
        if (char_pos > 0) {
            lua_pushinteger(lua, char_pos);
            return 1;
        }
    }

    lua_pushnil(lua);
    return 1;
}
