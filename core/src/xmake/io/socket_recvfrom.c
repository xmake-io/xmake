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
 * @file        socket_recvfrom.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "socket_recvfrom"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// real, data_or_errors, addr, port = io.socket_recvfrom(sock, size)
tb_int_t xm_io_socket_recvfrom(lua_State* lua)
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

    // get socket
    tb_socket_ref_t sock = (tb_socket_ref_t)xm_lua_topointer(lua, 1);
    tb_check_return_val(sock, 0);

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

    // recv data
    tb_ipaddr_t ipaddr;
    tb_ipaddr_clear(&ipaddr);
    tb_int_t    retn = 1;
    tb_long_t   real = tb_socket_urecv(sock, &ipaddr, data, size);
    lua_pushinteger(lua, (tb_int_t)real);
    if (real > 0)
    {
        retn = 2;
        lua_pushnil(lua);
        if (!tb_ipaddr_is_empty(&ipaddr))
        {
            tb_char_t buffer[256];
            tb_char_t const* ipstr = tb_ipaddr_ip_cstr(&ipaddr, buffer, sizeof(buffer));
            if (ipstr)
            {
                lua_pushstring(lua, ipstr);
                lua_pushinteger(lua, (tb_int_t)tb_ipaddr_port(&ipaddr));
                retn = 4;
            }
        }
    }
    return retn;
}
