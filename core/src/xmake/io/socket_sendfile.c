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
 * @file        socket_sendfile.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "socket_sendfile"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// io.socket_sendfile(sock, file, start, last)
tb_int_t xm_io_socket_sendfile(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // check socket
    if (!xm_lua_ispointer(lua, 1))
    {
        lua_pushinteger(lua, -1);
        lua_pushliteral(lua, "invalid socket!");
        return 2;
    }

    // check file
    if (!lua_isuserdata(lua, 2))
    {
        lua_pushinteger(lua, -1);
        lua_pushliteral(lua, "invalid file!");
        return 2;
    }

    // get socket
    tb_socket_ref_t sock = (tb_socket_ref_t)xm_lua_topointer(lua, 1);
    tb_check_return_val(sock, 0);

    // get file
    xm_io_file_t* file = (xm_io_file_t*)lua_touserdata(lua, 2);
    tb_check_return_val(file, 0);

    // does not support stdfile
    if (!xm_io_file_is_file(file) || !file->stream)
    {
        lua_pushinteger(lua, -1);
        lua_pushliteral(lua, "invalid file type!");
        return 2;
    }

    // get file reference
    tb_file_ref_t rawfile = tb_null;
    if (!tb_stream_ctrl(file->stream, TB_STREAM_CTRL_FILE_GET_FILE, &rawfile) || !rawfile)
    {
        lua_pushinteger(lua, -1);
        lua_pushliteral(lua, "cannot get file reference!");
        return 2;
    }

    // get file size
    tb_hize_t filesize = tb_file_size(rawfile);
    if (!filesize)
    {
        lua_pushinteger(lua, -1);
        lua_pushliteral(lua, "cannot send empty file!");
        return 2;
    }

    // get start
    tb_long_t start = 1;
    if (lua_isnumber(lua, 3)) start = (tb_long_t)lua_tonumber(lua, 3);
    if (start < 1 || start > filesize)
    {
        lua_pushinteger(lua, -1);
        lua_pushfstring(lua, "invalid start position(%ld)!", start);
        return 2;
    }

    // get last
    tb_long_t last = (tb_long_t)filesize;
    if (lua_isnumber(lua, 4)) last = (tb_long_t)lua_tonumber(lua, 4);
    if (last < start - 1 || last > filesize + start - 1)
    {
        lua_pushinteger(lua, -1);
        lua_pushfstring(lua, "invalid last position(%ld)!", last);
        return 2;
    }

    // send file data
    tb_long_t real = (tb_long_t)tb_socket_sendf(sock, rawfile, start - 1, last - start + 1);
    lua_pushinteger(lua, (tb_int_t)real);
    return 1;
}
