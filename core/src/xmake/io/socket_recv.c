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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        socket_recv.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "socket_recv"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// io.socket_recv(file, data, start, last)
tb_int_t xm_io_socket_recv(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is user data?
    if (!lua_isuserdata(lua, 1)) 
        return 0;

    // get socket
    tb_socket_ref_t sock = (tb_socket_ref_t)lua_touserdata(lua, 1);
    tb_check_return_val(sock, 0);

    // get data
    size_t datasize = 0;
    tb_char_t const* data = luaL_checklstring(lua, 2, &datasize);
    tb_assert_and_check_return_val(data, 0);

    // get start
    tb_size_t start = 1;
    if (lua_isnumber(lua, 3)) start = lua_tonumber(lua, 3);

    // get last
    tb_size_t last = (tb_size_t)datasize;
    if (lua_isnumber(lua, 4)) last = lua_tonumber(lua, 4);

    // recv data
    tb_long_t real = tb_socket_recv(sock, (tb_byte_t const*)data + start - 1, last - start + 1);
    lua_pushnumber(lua, (tb_int_t)real);
    return 1;
}
