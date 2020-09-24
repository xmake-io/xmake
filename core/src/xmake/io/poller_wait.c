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
 * @file        poller_wait.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "poller_wait"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "poller.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// we need only one global lua state/poller in main thread, so it is thread-safe.
static lua_State* g_lua = tb_null;
static tb_int_t   g_events_count = 0;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_io_poller_event(tb_poller_ref_t poller, tb_poller_object_ref_t object, tb_long_t events, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return(g_lua);

    // save object and events
    lua_newtable(g_lua);
    lua_pushinteger(g_lua, (tb_int_t)object->type);
    lua_rawseti(g_lua, -2, 1);
    if (priv) lua_pushstring(g_lua, (tb_char_t const*)priv);
    else lua_pushlightuserdata(g_lua, object->ref.ptr);
    lua_rawseti(g_lua, -2, 2);
    lua_pushinteger(g_lua, (tb_int_t)events);
    lua_rawseti(g_lua, -2, 3);
    lua_rawseti(g_lua, -2, ++g_events_count);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// local events, count = io.poller_wait(timeout)
tb_int_t xm_io_poller_wait(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get timeout
    tb_long_t timeout = (tb_long_t)luaL_checknumber(lua, 1);

    // pass lua and count to the events callback
    g_lua = lua;
    g_events_count = 0;

    // wait it
    lua_newtable(lua);
    tb_long_t count = tb_poller_wait(xm_io_poller(), xm_io_poller_event, timeout);
    if (count > 0)
    {
        lua_pushinteger(lua, (tb_int_t)count);
        return 2;
    }
    else if (!count)
    {
        // timeout
        lua_pop(lua, 1);
        lua_pushnil(lua);
        lua_pushinteger(lua, 0);
        return 2;
    }

    // failed
    lua_pop(lua, 1);
    lua_pushnil(lua);
    lua_pushinteger(lua, -1);
    return 2;
}

