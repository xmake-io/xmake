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
 * implementation
 */

tb_int_t xm_string_utfsub(lua_State* lua) {
    size_t size = 0;
    tb_char_t const* str = luaL_checklstring(lua, 1, &size);
    tb_long_t start_idx = (tb_long_t)luaL_checkinteger(lua, 2);
    tb_long_t end_idx = (tb_long_t)luaL_optinteger(lua, 3, -1);

    if (start_idx < 0 || (end_idx < 0 && end_idx != -1)) {
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
        
        if (start_idx < 0) start_idx = count + start_idx + 1;
        if (end_idx < 0 && end_idx != -1) end_idx = count + end_idx + 1;
    }

    if (start_idx < 1) start_idx = 1;
    
    tb_size_t start_offset = size;
    tb_size_t end_offset = size;
    
    tb_size_t current_char_idx = 1; // 1-based index
    tb_char_t const* p = str;
    tb_char_t const* e = str + size;

    while (p < e && (current_char_idx <= start_idx || (end_idx != -1 && current_char_idx <= end_idx))) {
        
        // Capture start offset
        if (current_char_idx == start_idx) {
            start_offset = p - str;
        }

        tb_size_t len = 1;
        tb_byte_t b = (tb_byte_t)*p;
        if (b >= 0xC0) {
            if (b >= 0xF0) len = 4;
            else if (b >= 0xE0) len = 3;
            else if (b >= 0xC0) len = 2;
        }
        if (p + len > e) len = 1;
        p += len;

        // Capture end offset
        if (end_idx != -1 && current_char_idx == end_idx) {
            end_offset = p - str;
        }
        
        current_char_idx++;
    }

    // Handle edge case: if start_idx is beyond string length
    if (current_char_idx <= start_idx) {
        start_offset = size;
    }

    if (start_offset >= size || start_offset >= end_offset) {
        lua_pushstring(lua, "");
    } else {
        lua_pushlstring(lua, str + start_offset, end_offset - start_offset);
    }
    
    return 1;
}
