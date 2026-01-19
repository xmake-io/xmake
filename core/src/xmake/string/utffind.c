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
 * @author      luadebug, ruki
 * @file        utffind.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "utffind"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_size_t xm_utf_char_count(tb_char_t const* str, tb_size_t size) {
    tb_size_t count = 0;
    tb_char_t const* p = str;
    tb_char_t const* e = str + size;
    while (p < e) {
        tb_size_t len = 1;
        tb_byte_t b = (tb_byte_t)*p;
        if (b >= 0xC0) {
            if (b >= 0xF0) len = 4;
            else if (b >= 0xE0) len = 3;
            else if (b >= 0xC0) len = 2;
        }
        if (p + len > e) len = 1;
        p += len;
        count++;
    }
    return count;
}

static tb_size_t xm_utf_offset(tb_char_t const* str, tb_size_t size, tb_long_t index) {
    if (index < 0) {
        tb_size_t count = xm_utf_char_count(str, size);
        index = count + index + 1;
    }

    if (index <= 1) return 0;

    tb_size_t c = 0;
    tb_char_t const* p = str;
    tb_char_t const* e = str + size;
    while (p < e) {
        if (c == index - 1) return p - str;
        
        tb_size_t len = 1;
        tb_byte_t b = (tb_byte_t)*p;
        if (b >= 0xC0) {
            if (b >= 0xF0) len = 4;
            else if (b >= 0xE0) len = 3;
            else if (b >= 0xC0) len = 2;
        }
        if (p + len > e) len = 1;
        p += len;
        c++;
    }
    return size;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_string_utffind(lua_State* lua) {
    size_t str_size = 0;
    tb_char_t const* str = luaL_checklstring(lua, 1, &str_size);
    size_t sub_size = 0;
    tb_char_t const* substr = luaL_checklstring(lua, 2, &sub_size);
    tb_long_t init = (tb_long_t)luaL_optinteger(lua, 3, 1);

    if (str_size == 0 || sub_size == 0) {
        lua_pushnil(lua);
        return 1;
    }

    tb_size_t start_offset = xm_utf_offset(str, str_size, init);
    if (start_offset >= str_size) {
        lua_pushnil(lua);
        return 1;
    }

    // find substring
    tb_char_t const* p = tb_strstr(str + start_offset, substr);
    if (!p) {
        lua_pushnil(lua);
        return 1;
    }

    // count chars from beginning to found position to get absolute index
    tb_size_t found_offset_bytes = p - str;
    tb_long_t start_idx = xm_utf_char_count(str, found_offset_bytes) + 1;

    // calculate end char index
    tb_size_t sub_len_chars = xm_utf_char_count(substr, sub_size);
    tb_long_t end_idx = start_idx + sub_len_chars - 1;

    lua_pushinteger(lua, start_idx);
    lua_pushinteger(lua, end_idx);
    return 2;
}
