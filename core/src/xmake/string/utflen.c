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
 * @file        utflen.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "utflen"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_string_utflen(lua_State* lua) {
    size_t size = 0;
    tb_char_t const* str = luaL_checklstring(lua, 1, &size);
    
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

    lua_pushinteger(lua, (tb_int_t)count);
    return 1;
}
