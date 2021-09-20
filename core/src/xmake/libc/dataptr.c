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
 * @file        dataptr.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "dataptr"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_libc_dataptr(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    if (xm_lua_ispointer(lua, 1))
    {
        tb_pointer_t data = (tb_pointer_t)xm_lua_topointer(lua, 1);
        xm_lua_pushpointer(lua, data);
        return 1;
    }
    else if (lua_isstring(lua, 1))
    {
        tb_char_t const* cstr = luaL_checkstring(lua, 1);
        xm_lua_pushpointer(lua, (tb_pointer_t)cstr);
        return 1;
    }
    xm_libc_return_error(lua, "libc.dataptr(invalid data)!");
}

