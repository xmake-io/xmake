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
 * @file        char.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

static void xm_utf8_char_push(lua_State *lua, tb_int_t arg) {
    lua_Unsigned code = (lua_Unsigned)luaL_checkinteger(lua, arg);
    luaL_argcheck(lua, code <= XM_UTF8_MAXUTF, arg, "value out of range");
    
    tb_char_t buf[8];
    tb_size_t n = xm_utf8_encode(buf, (xm_utf8_int_t)code);
    if (n > 0) {
        lua_pushlstring(lua, buf, n);
    } else {
        luaL_error(lua, "value out of range");
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* utfchar(n1, n2, ...)  -> char(n1)..char(n2)...
 */
tb_int_t xm_utf8_char(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    tb_int_t n = lua_gettop(lua);  // number of arguments
    if (n == 1) { // optimize common case of single char
        xm_utf8_char_push(lua, 1);
    } else {
        tb_int_t i;
        luaL_Buffer b;
        luaL_buffinit(lua, &b);
        for (i = 1; i <= n; i++) {
            xm_utf8_char_push(lua, i);
            luaL_addvalue(&b);
        }
        luaL_pushresult(&b);
    }
    return 1;
}
