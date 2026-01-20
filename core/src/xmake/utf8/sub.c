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
 * @file        sub.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* utf8.sub(s, i [, j])
 */
tb_int_t xm_utf8_sub(lua_State *lua) {
    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    lua_Integer i = luaL_checkinteger(lua, 2);
    lua_Integer j = luaL_optinteger(lua, 3, -1);

    // map i (char index) to byte offset
    tb_long_t start_byte = 0;
    if (i > 0) {
        start_byte = xm_utf8_offset_impl(s, len, i, 1);
    } else if (i < 0) {
        start_byte = xm_utf8_offset_impl(s, len, i, len + 1);
    } else {
        start_byte = 1;
    }

    if (start_byte == -1) {
        if (i > 0) {
            lua_pushliteral(lua, "");
            return 1;
        } else {
            start_byte = 1;
        }
    } else if (start_byte == 0) {
        if (i < 0) {
            start_byte = 1;
        } else {
            lua_pushliteral(lua, "");
            return 1;
        }
    }

    // map j (char index) to byte offset (end)
    tb_long_t end_byte = 0;
    if (j >= 0) {
        end_byte = xm_utf8_offset_impl(s, len, j + 1, 1);
    } else {
        end_byte = xm_utf8_offset_impl(s, len, j + 1, len + 1);
    }

    if (end_byte == -1) {
        if (j >= 0) end_byte = len + 1;
        else end_byte = 1;
    } else if (end_byte == 0) {
         if (j >= 0) end_byte = len + 1;
         else end_byte = 1;
    }

    if (end_byte <= start_byte) {
        lua_pushliteral(lua, "");
        return 1;
    }

    lua_pushlstring(lua, s + start_byte - 1, end_byte - start_byte);
    return 1;
}
