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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        base64.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "base64"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_base64_decode(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the string
    size_t size = 0;
    tb_char_t const* cstr = luaL_checklstring(lua, 1, &size);
    tb_check_return_val(cstr && size, 0);

    // decode it
    tb_byte_t buff[8192];
    if (size < sizeof(buff))
    {
        tb_size_t real = tb_base64_decode(cstr, size, buff, sizeof(buff));
        if (real > 0)
        {
            lua_pushlstring(lua, (tb_char_t const*)buff, (tb_int_t)real);
            return 1;
        }
    }
    lua_pushnil(lua);
    lua_pushstring(lua, "buffer is too small");
    return 2;
}
