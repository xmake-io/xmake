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
 * @file        lastof.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "string_lastof"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../utf8/utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* lastof string (only support plain text)
 *
 * @param str             the string
 * @param substr          the substring
 */
tb_int_t xm_string_lastof(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get string
    size_t nstr = 0;
    tb_char_t const *cstr = luaL_checklstring(lua, 1, &nstr);

    // get substring
    size_t nsubstr = 0;
    tb_char_t const *csubstr = luaL_checklstring(lua, 2, &nsubstr);

    // lastof it
    tb_long_t char_pos = xm_utf8_lastof_impl(cstr, nstr, csubstr, nsubstr);
    if (char_pos > 0) {
        lua_pushinteger(lua, char_pos);
    } else {
        lua_pushnil(lua);
    }
    return 1;
}
