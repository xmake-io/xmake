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
 * @file        pipe_write.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "pipe_write"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// io.pipe_write(pipefile, data, start, last)
tb_int_t xm_io_pipe_write(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // check pipe
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
    tb_size_t        size = 0;
    tb_byte_t const* data = tb_null;
    if (lua_istable(lua, 2))
    {
        // get data address
        lua_pushstring(lua, "data");
        lua_gettable(lua, 2);
        data = (tb_byte_t const*)(tb_size_t)(tb_long_t)lua_tonumber(lua, -1);
        lua_pop(lua, 1);

        // get data size
        lua_pushstring(lua, "size");
        lua_gettable(lua, 2);
        size = (tb_size_t)lua_tonumber(lua, -1);
        lua_pop(lua, 1);
    }
    else
    {
        size_t datasize = 0;
        data = (tb_byte_t const*)luaL_checklstring(lua, 2, &datasize);
        size = (tb_size_t)datasize;
    }
    if (!data || !size)
    {
        lua_pushinteger(lua, -1);
        lua_pushfstring(lua, "invalid data(%p) and size(%zu)!", data, size);
        return 2;
    }

    // get start
    tb_long_t start = 1;
    if (lua_isnumber(lua, 3)) start = (tb_long_t)lua_tonumber(lua, 3);
    if (start < 1 || start > size)
    {
        lua_pushinteger(lua, -1);
        lua_pushfstring(lua, "invalid start position(%ld)!", start);
        return 2;
    }

    // get last
    tb_long_t last = (tb_long_t)size;
    if (lua_isnumber(lua, 4)) last = (tb_long_t)lua_tonumber(lua, 4);
    if (last < start - 1 || last > size + start - 1)
    {
        lua_pushinteger(lua, -1);
        lua_pushfstring(lua, "invalid last position(%ld)!", last);
        return 2;
    }

    // write data
    tb_long_t real = tb_pipe_file_write(pipefile, data + start - 1, last - start + 1);
    lua_pushinteger(lua, (tb_int_t)real);
    return 1;
}
