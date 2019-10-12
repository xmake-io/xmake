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
 * @file        socket_open.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "socket_open"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/*
 * io.socket_open(socktype, family)
 */
tb_int_t xm_io_socket_open(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get socket type 
    tb_char_t const* socktype = luaL_checkstring(lua, 1);
    tb_assert_and_check_return_val(socktype, 0);

    // get address family 
    tb_char_t const* family = luaL_checkstring(lua, 2);
    tb_assert_and_check_return_val(family, 0);

    // map socket type
    tb_size_t t = TB_SOCKET_TYPE_NONE;
    if (!tb_strcmp(socktype, "tcp"))
        t = TB_SOCKET_TYPE_TCP;
    else if (!tb_strcmp(socktype, "udp"))
        t = TB_SOCKET_TYPE_UDP;
    else if (!tb_strcmp(socktype, "icmp"))
        t = TB_SOCKET_TYPE_ICMP;
    else
    {
        lua_pushnil(lua);
        lua_pushliteral(lua, "invalid socket type!");
        return 2;
    }

    // map address family
    tb_size_t f = TB_IPADDR_FAMILY_NONE;
    if (!tb_strcmp(family, "ipv4"))
        f = TB_IPADDR_FAMILY_IPV4;
    else if (!tb_strcmp(family, "ipv6"))
        f = TB_IPADDR_FAMILY_IPV6;
    else
    {
        lua_pushnil(lua);
        lua_pushliteral(lua, "invalid address family!");
        return 2;
    }

    // init socket
    tb_socket_ref_t sock = tb_socket_init(t, f);
    if (sock) lua_pushlightuserdata(lua, (tb_pointer_t)sock);
    else lua_pushnil(lua);
    return 1;
}
