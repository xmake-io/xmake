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
 * @file        utfchar.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "utfchar"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_string_utfchar(lua_State* lua) {
    tb_int_t n = lua_gettop(lua);
    if (n == 0) {
        lua_pushstring(lua, "");
        return 1;
    }

    luaL_Buffer b;
    luaL_buffinit(lua, &b);

    tb_int_t i;
    for (i = 1; i <= n; i++) {
        tb_long_t code = (tb_long_t)luaL_checkinteger(lua, i);
        tb_char_t buf[4];
        tb_size_t len = 0;

        if (code < 0) {
             return luaL_error(lua, "invalid utf8 code point: %ld", code);
        } else if (code <= 0x7F) {
            buf[0] = (tb_char_t)code;
            len = 1;
        } else if (code <= 0x7FF) {
            buf[0] = (tb_char_t)(0xC0 | (code >> 6));
            buf[1] = (tb_char_t)(0x80 | (code & 0x3F));
            len = 2;
        } else if (code <= 0xFFFF) {
            buf[0] = (tb_char_t)(0xE0 | (code >> 12));
            buf[1] = (tb_char_t)(0x80 | ((code >> 6) & 0x3F));
            buf[2] = (tb_char_t)(0x80 | (code & 0x3F));
            len = 3;
        } else if (code <= 0x10FFFF) {
            buf[0] = (tb_char_t)(0xF0 | (code >> 18));
            buf[1] = (tb_char_t)(0x80 | ((code >> 12) & 0x3F));
            buf[2] = (tb_char_t)(0x80 | ((code >> 6) & 0x3F));
            buf[3] = (tb_char_t)(0x80 | (code & 0x3F));
            len = 4;
        } else {
             return luaL_error(lua, "invalid utf8 code point: %ld", code);
        }
        
        luaL_addlstring(&b, buf, len);
    }
    
    luaL_pushresult(&b);
    return 1;
}
