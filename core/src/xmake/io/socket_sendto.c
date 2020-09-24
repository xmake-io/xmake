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
 * @file        socket_sendto.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "socket_sendto"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// io.socket_sendto(sock, data, addr, port)
tb_int_t xm_io_socket_sendto(lua_State* lua)
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

    // get address
    tb_char_t const* addr = lua_tostring(lua, 3);
    tb_uint16_t      port = (tb_uint16_t)luaL_checknumber(lua, 4);
    if (!addr || !port)
    {
        lua_pushinteger(lua, -1);
        lua_pushliteral(lua, "invalid address!");
        return 2;
    }

    // get address family
    tb_size_t family = (tb_size_t)luaL_checknumber(lua, 5);

    // init ip address
    tb_ipaddr_t ipaddr;
    tb_ipaddr_set(&ipaddr, addr, port, (tb_uint8_t)family);

    // send data
    tb_long_t real = tb_socket_usend(sock, &ipaddr, data, size);
    lua_pushinteger(lua, (tb_int_t)real);
    return 1;
}
