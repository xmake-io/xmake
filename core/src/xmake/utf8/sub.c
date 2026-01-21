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
 * @file        sub.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* utf8.sub(s, i [, j])
 */
tb_int_t xm_utf8_sub(lua_State *lua) {
    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    lua_Integer i = luaL_checkinteger(lua, 2);
    lua_Integer j = luaL_optinteger(lua, 3, -1);

    tb_size_t sublen = 0;
    tb_char_t const* sub = xm_utf8_sub_impl(s, len, (tb_long_t)i, (tb_long_t)j, &sublen);
    if (sub) {
        lua_pushlstring(lua, sub, sublen);
    } else {
        lua_pushliteral(lua, "");
    }
    return 1;
}
