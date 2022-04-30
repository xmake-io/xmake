/*!A cross-platform build utility based on Lua
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this sock except in compliance with the License.
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
 * @sock        socket_peeraddr.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "socket_peeraddr"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// socket to fd
#define xm_io_sock2fd(sock)            (lua_Number)tb_sock2fd(sock)

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* io.socket_peeraddr(sock)
 */
tb_int_t xm_io_socket_peeraddr(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is pointer?
    if (!xm_lua_ispointer(lua, 1))
        xm_io_return_error(lua, "get peer address for invalid sock!");

    // get socket
    tb_socket_ref_t sock = (tb_socket_ref_t)xm_lua_topointer(lua, 1);
    tb_check_return_val(sock, 0);

    // get peer address
    tb_ipaddr_t addr;
    tb_char_t data[256];
    tb_char_t const* cstr = tb_null;
    if (tb_socket_peer(sock, &addr) && (cstr = tb_ipaddr_cstr(&addr, data, sizeof(data))))
        lua_pushstring(lua, cstr);
    else lua_pushnil(lua);
    return 1;
}
