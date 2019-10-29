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

// real, data, errors = io.socket_recv(sock, size, prev_data)
tb_int_t xm_io_socket_recv(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // check socket
    if (!lua_isuserdata(lua, 1)) 
    {
        lua_pushnumber(lua, -1);
        lua_pushnil(lua);
        lua_pushliteral(lua, "invalid socket!");
        return 2;
    }

    // get socket
    tb_socket_ref_t sock = (tb_socket_ref_t)lua_touserdata(lua, 1);
    tb_check_return_val(sock, 0);

    // get data and size
    tb_byte_t data[8192];
    tb_long_t size = 0;
    if (lua_isnumber(lua, 2)) size = (tb_long_t)lua_tonumber(lua, 2);
    if (size < 0)
    {
        lua_pushnumber(lua, -1);
        lua_pushnil(lua);
        lua_pushfstring(lua, "invalid size(%ld)!", size);
        return 2;
    }
    if (size > sizeof(data)) 
        size = sizeof(data);

    // get the previous data and size first
    size_t prev_size = 0;
    tb_char_t const* prev_data = luaL_optlstring(lua, 3, "", &prev_size);

    // recv data
    tb_long_t real = tb_socket_recv(sock, data, size);
    lua_pushnumber(lua, (tb_int_t)real);
    if (real > 0)
    {
        // init result
        luaL_Buffer result;
        luaL_buffinit(lua, &result);

        // prepend the previous data
        if (prev_data && prev_size) luaL_addlstring(&result, prev_data, prev_size);
        luaL_addlstring(&result, (tb_char_t const*)data, real);

        // save result
        luaL_pushresult(&result);
        return 2;
    }
    else if (prev_data && prev_size)
    {
        lua_pushlstring(lua, prev_data, prev_size);
        return 2;
    }
    return 1;
}
