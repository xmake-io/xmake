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

/* utf8.lastof(s, substr)
 */
tb_int_t xm_utf8_lastof(lua_State *lua) {
    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    size_t sublen;
    tb_char_t const* sub = luaL_checklstring(lua, 2, &sublen);

    if (sublen == 0) {
        lua_pushnil(lua);
        return 1;
    }

    tb_char_t const* p = s;
    tb_char_t const* last = tb_null;
    
    while (1) {
        p = tb_strstr(p, sub);
        if (!p) break;
        last = p;
        p += 1; 
    }

    if (last) {
        tb_long_t count = xm_utf8_len_impl(s, len, 1, last - s, tb_true, tb_null);
        if (count < 0) {
             lua_pushnil(lua);
             return 1;
        }
        lua_pushinteger(lua, count + 1);
    } else {
        lua_pushnil(lua);
    }
    return 1;
}
