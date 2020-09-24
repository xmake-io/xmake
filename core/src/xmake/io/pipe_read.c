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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        pipe_read.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "pipe_read"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// real, data_or_errors = io.pipe_read(pipefile, size)
tb_int_t xm_io_pipe_read(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // check pipe file
    if (!xm_lua_ispointer(lua, 1))
    {
        lua_pushinteger(lua, -1);
        lua_pushliteral(lua, "invalid pipe file!");
        return 2;
    }

    // get pipe file
    tb_pipe_file_ref_t pipefile = (tb_pipe_file_ref_t)xm_lua_topointer(lua, 1);
    tb_check_return_val(pipefile, 0);

    // get data
    tb_byte_t* data = tb_null;
    if (lua_isnumber(lua, 2))
        data = (tb_byte_t*)(tb_size_t)(tb_long_t)lua_tonumber(lua, 2);
    if (!data)
    {
        lua_pushinteger(lua, -1);
        lua_pushfstring(lua, "invalid data(%p)!", data);
        return 2;
    }

    // get size
    tb_long_t size = 0;
    if (lua_isnumber(lua, 3)) size = (tb_long_t)lua_tonumber(lua, 3);
    if (size <= 0)
    {
        lua_pushinteger(lua, -1);
        lua_pushfstring(lua, "invalid size(%ld)!", size);
        return 2;
    }

    // read data
    tb_long_t real = tb_pipe_file_read(pipefile, data, size);
    lua_pushinteger(lua, (tb_int_t)real);
    return 1;
}
