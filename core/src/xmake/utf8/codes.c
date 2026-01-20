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
 * @file        codes.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

static tb_int_t xm_utf8_codes_iter(lua_State *lua, tb_bool_t strict) {
    tb_assert_and_check_return_val(lua, 0);

    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    lua_Unsigned n = (lua_Unsigned)lua_tointeger(lua, 2);
    if (n < len) {
        while (n < len && xm_utf8_iscontp(s + n)) {
            n++;  // go to next character
        }
    }
    if (n >= len) { // (also handles original 'n' being negative)
        return 0;  // no more codepoints
    } else {
        xm_utf8_int_t code;
        tb_char_t const* next = xm_utf8_decode(s + n, &code, strict);
        if (next == NULL || xm_utf8_iscontp(next)) {
            return luaL_error(lua, XM_UTF8_MSGInvalid);
        }
        lua_pushinteger(lua, n + 1);
        lua_pushinteger(lua, code);
        return 2;
    }
}

static int xm_utf8_codes_iter_strict(lua_State *lua) {
    return xm_utf8_codes_iter(lua, tb_true);
}

static int xm_utf8_codes_iter_lax(lua_State *lua) {
    return xm_utf8_codes_iter(lua, tb_false);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_int_t xm_utf8_codes(lua_State *lua) {
    tb_bool_t lax = lua_toboolean(lua, 2);
    tb_char_t const* s = luaL_checkstring(lua, 1);
    luaL_argcheck(lua, !xm_utf8_iscontp(s), 1, XM_UTF8_MSGInvalid);
    lua_pushcfunction(lua, lax ? xm_utf8_codes_iter_lax : xm_utf8_codes_iter_strict);
    lua_pushvalue(lua, 1);
    lua_pushinteger(lua, 0);
    return 3;
}
