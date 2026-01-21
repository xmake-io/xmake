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
 * @file        width.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* utf8.width(char)
 * utf8.width(str)
 * utf8.width(codepoint)
 */
tb_int_t xm_utf8_width(lua_State* lua) {
    if (lua_isnumber(lua, 1)) {
        xm_utf8_int_t val = (xm_utf8_int_t)lua_tointeger(lua, 1);
        lua_pushinteger(lua, xm_utf8_charwidth(val));
    } else {
        size_t len = 0;
        tb_char_t const* s = luaL_checklstring(lua, 1, &len);
        lua_pushinteger(lua, xm_utf8_strwidth(s, len));
    }
    return 1;
}
