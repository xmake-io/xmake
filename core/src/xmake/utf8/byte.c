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
 * @file        byte.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_utf8_byte_cb(xm_utf8_int_t code, tb_cpointer_t udata) {
    lua_State* lua = (lua_State*)udata;
    tb_assert_and_check_return_val(lua, tb_false);

    luaL_checkstack(lua, 1, "too many results");
    lua_pushinteger(lua, code);
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* utf8.byte(s, i [, j])
 */
tb_int_t xm_utf8_byte(lua_State* lua) {
    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    lua_Integer i = luaL_optinteger(lua, 2, 1);
    lua_Integer j = luaL_optinteger(lua, 3, i);

    return (tb_int_t)xm_utf8_byte_impl(s, len, i, j, xm_utf8_byte_cb, lua);
}
