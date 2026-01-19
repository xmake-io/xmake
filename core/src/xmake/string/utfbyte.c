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
 * @file        utfbyte.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "utfbyte"
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
tb_int_t xm_string_utfbyte(lua_State* lua) {
    size_t size = 0;
    tb_char_t const* str = luaL_checklstring(lua, 1, &size);
    tb_long_t start_idx = (tb_long_t)luaL_optinteger(lua, 2, 1);
    tb_long_t end_idx = (tb_long_t)luaL_optinteger(lua, 3, start_idx);

    // handle negative indices
    if (start_idx < 0 || end_idx < 0) {
        tb_size_t count = xm_utf_char_count(str, size);
        if (start_idx < 0) start_idx = count + start_idx + 1;
        if (end_idx < 0) end_idx = count + end_idx + 1;
    }

    if (start_idx < 1) start_idx = 1;
    if (end_idx < start_idx) return 0;

    // get start offset
    tb_size_t offset = xm_utf_offset(str, size, start_idx);
    if (offset >= size) return 0;

    tb_char_t const* p = str + offset;
    tb_char_t const* e = str + size;
    tb_long_t count = 0;
    
    // iterate and push code points
    tb_long_t idx = start_idx;
    while (p < e && idx <= end_idx) {
        tb_size_t len = 1;
        tb_byte_t b = (tb_byte_t)*p;
        tb_long_t code = b;
        
        if (b >= 0xC0) {
            if (b >= 0xF0) {
                len = 4;
                code = b & 0x07;
            } else if (b >= 0xE0) {
                len = 3;
                code = b & 0x0F;
            } else if (b >= 0xC0) {
                len = 2;
                code = b & 0x1F;
            }
        }
        
        if (p + len > e) {
            // unsafe/invalid, fallback to byte
            len = 1;
            code = b;
        } else if (len > 1) {
            // decode sequence
            tb_size_t i;
            for (i = 1; i < len; i++) {
                tb_byte_t cb = (tb_byte_t)p[i];
                if ((cb & 0xC0) != 0x80) {
                    // invalid continuation, fallback to first byte
                    len = 1;
                    code = b;
                    break;
                }
                code = (code << 6) | (cb & 0x3F);
            }
        }
        
        lua_pushinteger(lua, code);
        p += len;
        idx++;
        count++;
    }
    
    return (tb_int_t)count;
}
