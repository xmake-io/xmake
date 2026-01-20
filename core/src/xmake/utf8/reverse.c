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
 * @file        reverse.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* utf8.reverse(s)
 */
tb_int_t xm_utf8_reverse(lua_State *lua) {
    size_t len;
    tb_char_t const* s = luaL_checklstring(lua, 1, &len);
    if (len == 0) {
        lua_pushliteral(lua, "");
        return 1;
    }

    // do reverse
    if (len < 1024) {
        tb_char_t buf[1024 + 1];
        xm_utf8_reverse_impl(s, len, buf);
        lua_pushlstring(lua, buf, len);
    } else {
        tb_char_t* buf = (tb_char_t*)tb_malloc_bytes(len + 1);
        if (buf) {
            xm_utf8_reverse_impl(s, len, buf);
            lua_pushlstring(lua, buf, len);
            tb_free(buf);
        } else {
            lua_pushnil(lua);
        }
    }
    return 1;
}
