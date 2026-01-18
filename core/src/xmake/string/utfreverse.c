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
 * @file        utfreverse.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "utfreverse"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_string_utfreverse(lua_State* lua) {
    size_t size = 0;
    tb_char_t const* str = luaL_checklstring(lua, 1, &size);
    if (size == 0) {
        lua_pushstring(lua, "");
        return 1;
    }

    // allocate a temporary buffer using lua userdata to let garbage collector handle it
    tb_char_t* buffer = (tb_char_t*)lua_newuserdata(lua, size * sizeof(tb_char_t));
    if (!buffer) {
        return 0;
    }

    tb_char_t const* p = str;
    tb_char_t const* e = str + size;
    tb_char_t* q = buffer + size;
    
    while (p < e) {
        tb_size_t len = 1;
        tb_byte_t b = (tb_byte_t)*p;
        if (b >= 0xC0) {
            if (b >= 0xF0) len = 4;
            else if (b >= 0xE0) len = 3;
            else if (b >= 0xC0) len = 2;
        }
        if (p + len > e) len = 1;
        
        // copy char to buffer in reverse position
        q -= len;
        tb_memcpy(q, p, len);
        
        p += len;
    }
    
    lua_pushlstring(lua, buffer, size);
    return 1;
}
