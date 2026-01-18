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
 * @file        upper.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* string.upper
 *
 * @param str       the string
 *
 * @code
 *      local result = (str)
 * @endcode
 */
tb_int_t xm_string_upper(lua_State *lua) {
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get string
    size_t           size = 0;
    tb_char_t const* cstr = luaL_checklstring(lua, 1, &size);
    tb_check_return_val(cstr, 0);

    // empty?
    if (!size) {
        lua_pushstring(lua, "");
        return 1;
    }

    // copy string to buffer
    tb_char_t* buffer = tb_malloc_bytes(size + 1);
    if (buffer) {
        tb_memcpy(buffer, cstr, size);
        buffer[size] = '\0';

        // to upper
        tb_long_t real_size = tb_charset_utf8_toupper(buffer, size);
        
        // push result
        if (real_size >= 0) {
            lua_pushlstring(lua, buffer, real_size);
        } else {
            lua_pushlstring(lua, cstr, size);
        }
        tb_free(buffer);
    } else {
        lua_pushnil(lua);
    }
    return 1;
}
