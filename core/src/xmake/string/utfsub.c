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
 * @file        utfsub.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "utfsub"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

// get offset of the given utf8 char index
static tb_size_t xm_utf_offset(tb_char_t const* str, tb_size_t size, tb_long_t index) {
    if (index < 0) {
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
tb_int_t xm_string_utfsub(lua_State* lua) {
    size_t size = 0;
    tb_char_t const* str = luaL_checklstring(lua, 1, &size);
    tb_long_t start_idx = luaL_checkinteger(lua, 2);
    tb_long_t end_idx = luaL_optinteger(lua, 3, -1);

    tb_size_t start_offset = xm_utf_offset(str, size, start_idx);
    tb_size_t end_offset;
    if (end_idx == -1) {
        end_offset = size;
    } else {
        end_offset = xm_utf_offset(str, size, end_idx + 1);
    }
    
    if (start_offset >= size || start_offset >= end_offset) {
        lua_pushstring(lua, "");
        return 1;
    }
    
    lua_pushlstring(lua, str + start_offset, end_offset - start_offset);
    return 1;
}
