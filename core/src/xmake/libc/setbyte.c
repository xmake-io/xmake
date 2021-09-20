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
 * @file        setbyte.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "setbyte"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_libc_setbyte(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get data
    tb_pointer_t data = tb_null;
    if (lua_isnumber(lua, 1))
        data = (tb_pointer_t)(tb_size_t)lua_tointeger(lua, 1);
    else if (lua_isstring(lua, 1))
        data = (tb_pointer_t)luaL_checkstring(lua, 1);
    else xm_libc_return_error(lua, "libc.setbyte(invalid data)!");

    // get offset
    tb_int_t offset = 0;
    if (lua_isnumber(lua, 2))
        offset = (tb_int_t)lua_tointeger(lua, 2);
    else xm_libc_return_error(lua, "libc.setbyte(invalid offset)!");

    // set byte
    if (lua_isnumber(lua, 3))
        ((tb_byte_t*)data)[offset] = (tb_byte_t)lua_tointeger(lua, 3);
    else xm_libc_return_error(lua, "libc.setbyte(invalid value)!");
    return 0;
}


