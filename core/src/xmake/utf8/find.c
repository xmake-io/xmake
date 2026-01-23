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
 * private implementation
 */

static tb_int_t xm_utf8_find_impl_plain(lua_State* lua, tb_char_t const* s, size_t len, tb_char_t const* sub, size_t sublen, lua_Integer init) {
    tb_long_t char_end = 0;
    tb_long_t char_start = xm_utf8_find_impl(s, len, sub, sublen, (tb_long_t)init, &char_end);
    if (char_start > 0) {
        lua_pushinteger(lua, char_start);
        lua_pushinteger(lua, char_end);
        return 2;
    }
    lua_pushnil(lua);
    return 1;
}

static tb_int_t xm_utf8_find_impl_pattern(lua_State* lua, tb_char_t const* s, size_t len, lua_Integer init) {
    int base = lua_gettop(lua);
    tb_long_t byte_init = 1;
    if (init > 0) {
        if (init > 1) {
            byte_init = xm_utf8_offset_impl(s, len, (tb_long_t)init, 1);
            if (byte_init <= 0) {
                lua_pushnil(lua);
                return 1;
            }
        }
    } else if (init < 0) {
        byte_init = xm_utf8_offset_impl(s, len, (tb_long_t)init, len + 1);
        if (byte_init <= 0) {
            lua_pushnil(lua);
            return 1;
        }
    }
    
    lua_getglobal(lua, "string");
    lua_getfield(lua, -1, "find");
    lua_pushvalue(lua, 1); // s
    lua_pushvalue(lua, 2); // pattern
    lua_pushinteger(lua, byte_init); // init (byte)
    lua_pushboolean(lua, 0); // plain
    
    lua_call(lua, 4, LUA_MULTRET);
    
    // Stack: [args, string_table, results...]
    int nres = lua_gettop(lua) - (base + 1);
    if (nres <= 0 || lua_isnil(lua, base + 2)) {
         lua_pushnil(lua);
         lua_remove(lua, base + 1);
         return 1;
    }
    
    lua_Integer b_start = lua_tointeger(lua, base + 2);
    lua_Integer b_end = lua_tointeger(lua, base + 3);
    
    tb_long_t char_start = 1;
    if (b_start > 1) {
        tb_long_t count = xm_utf8_len_impl(s, len, 1, (tb_long_t)b_start - 1, tb_true, tb_null);
        if (count < 0) { 
            lua_pushnil(lua); 
            lua_remove(lua, base + 1);
            return 1; 
        }
        char_start = count + 1;
    }
    
    tb_long_t match_char_len = 0;
    if (b_end >= b_start) {
        match_char_len = xm_utf8_len_impl(s, len, (tb_long_t)b_start, (tb_long_t)b_end, tb_true, tb_null);
        if (match_char_len < 0) { 
            lua_pushnil(lua); 
            lua_remove(lua, base + 1);
            return 1; 
        }
    }
    
    lua_pushinteger(lua, char_start);
    lua_replace(lua, base + 2);
    lua_pushinteger(lua, char_start + match_char_len - 1);
    lua_replace(lua, base + 3);
    
    lua_remove(lua, base + 1);
    
    return nres;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* utf8.find(s, target [, init [, plain]])
 */
tb_int_t xm_utf8_find(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    size_t sublen;
    tb_char_t const* sub = luaL_checklstring(lua, 2, &sublen);
    lua_Integer init = luaL_optinteger(lua, 3, 1);
    tb_int_t plain = lua_toboolean(lua, 4);
    
    if (plain) {
        return xm_utf8_find_impl_plain(lua, s, len, sub, sublen, init);
    } else {
        return xm_utf8_find_impl_pattern(lua, s, len, init);
    }
}
