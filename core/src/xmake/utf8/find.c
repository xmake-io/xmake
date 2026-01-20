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
 * @file        find.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* utf8.find(s, target [, init])
 */
tb_int_t xm_utf8_find(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    size_t sublen;
    tb_char_t const* sub = luaL_checklstring(lua, 2, &sublen);
    lua_Integer init = luaL_optinteger(lua, 3, 1);

    if (init > (lua_Integer)len) {
        lua_pushnil(lua);
        return 1;
    }

    if (sublen == 0) {
        if (init <= 1) {
             lua_pushinteger(lua, 1);
             lua_pushinteger(lua, 0);
             return 2;
        } else {
             lua_pushinteger(lua, init);
             lua_pushinteger(lua, init - 1);
             return 2;
        }
    }

    tb_long_t start_byte = 0;
    if (init > 0) {
        start_byte = xm_utf8_offset_impl(s, len, init, 1);
    } else if (init < 0) {
        start_byte = xm_utf8_offset_impl(s, len, init, len + 1);
    } else {
        start_byte = 1; 
    }
    
    if (start_byte <= 0) { 
         lua_pushnil(lua);
         return 1;
    }
    
    tb_char_t const* p = tb_strstr(s + start_byte - 1, sub);
    if (!p) {
        lua_pushnil(lua);
        return 1;
    }
    
    tb_long_t found_byte_start = p - s + 1; 
    
    tb_long_t char_start = 0;
    if (found_byte_start > 1) {
        char_start = xm_utf8_len_impl(s, len, 1, found_byte_start - 1, tb_true, tb_null);
        if (char_start < 0) {
             lua_pushnil(lua); return 1;
        }
    }
    char_start += 1; 
    
    tb_long_t match_char_len = xm_utf8_len_impl(s, len, found_byte_start, found_byte_start + sublen - 1, tb_true, tb_null);
     if (match_char_len < 0) {
         lua_pushnil(lua); return 1;
    }
    
    lua_pushinteger(lua, char_start);
    lua_pushinteger(lua, char_start + match_char_len - 1);
    return 2;
}
