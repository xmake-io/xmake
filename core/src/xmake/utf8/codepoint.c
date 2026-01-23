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
 * @file        codepoint.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_utf8_codepoint_cb(xm_utf8_int_t code, tb_cpointer_t udata) {
    lua_State* lua = (lua_State*)udata;
    tb_assert_and_check_return_val(lua, tb_false);

    lua_pushinteger(lua, code);
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* codepoint(s, [i, [j [, lax]]]) -> returns codepoints for all
 * characters that start in the range [i,j]
 */
tb_int_t xm_utf8_codepoint(lua_State *lua) {
    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    lua_Integer posi = xm_utf8_posrelat((tb_long_t)luaL_optinteger(lua, 2, 1), len);
    lua_Integer pose = xm_utf8_posrelat((tb_long_t)luaL_optinteger(lua, 3, posi), len);
    tb_bool_t lax = lua_toboolean(lua, 4);

    luaL_argcheck(lua, posi >= 1, 2, "out of bounds");
    luaL_argcheck(lua, pose <= (lua_Integer)len, 3, "out of bounds");

    if (posi > pose) {
        return 0;  // empty interval; return no values
    }
    if (pose - posi >= INT_MAX) { // (lua_Integer -> int) overflow?
        return luaL_error(lua, "string slice too long");
    }
    
    tb_int_t n = (tb_int_t)(pose - posi) + 1;
    luaL_checkstack(lua, n, "string slice too long");

    int nresults = lua_gettop(lua);
    if (!xm_utf8_codepoint_impl(s, len, (tb_long_t)posi, (tb_long_t)pose, !lax, xm_utf8_codepoint_cb, lua)) {
        return luaL_error(lua, XM_UTF8_MSGInvalid);
    }
    
    return lua_gettop(lua) - nresults;
}
