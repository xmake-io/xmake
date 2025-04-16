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
 * Copyright (C) 2015-present, Xmake Open Source Community.
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
 * private implementation
 */
static tb_void_t xm_io_poller_event(tb_poller_ref_t poller, tb_poller_object_ref_t object, tb_long_t events, tb_cpointer_t priv)
{
    // check
    xm_poller_state_t* state = (xm_poller_state_t*)tb_poller_priv(poller);
    tb_assert_and_check_return(state && state->lua);

    // save object and events
    lua_State* lua = state->lua;
    lua_newtable(lua);
    lua_pushinteger(lua, (tb_int_t)object->type);
    lua_rawseti(lua, -2, 1);
    if (priv) lua_pushstring(lua, (tb_char_t const*)priv);
    else lua_pushlightuserdata(lua, object->ref.ptr);
    lua_rawseti(lua, -2, 2);
    if (object->type == TB_POLLER_OBJECT_FWATCHER)
    {
        lua_newtable(lua);
        tb_fwatcher_event_t* event = (tb_fwatcher_event_t*)events;
        if (event)
        {
            lua_pushstring(lua, "path");
            lua_pushstring(lua, event->filepath);
            lua_settable(lua, -3);

            lua_pushstring(lua, "type");
            lua_pushinteger(lua, event->event);
            lua_settable(lua, -3);
        }
    }
    else lua_pushinteger(lua, (tb_int_t)events);
    lua_rawseti(lua, -2, 3);
    lua_rawseti(lua, -2, ++state->events_count);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// local events, count = io.poller_wait(timeout)
tb_int_t xm_io_poller_wait(lua_State* lua)
{
    // check
    tb_poller_ref_t poller = xm_io_poller(lua);
    tb_assert_and_check_return_val(poller && lua, 0);

    // get timeout
    tb_long_t timeout = (tb_long_t)luaL_checknumber(lua, 1);

    // reset events count
    xm_poller_state_t* state = (xm_poller_state_t*)tb_poller_priv(poller);
    state->events_count = 0;

    // wait it
    lua_newtable(lua);
    tb_long_t count = tb_poller_wait(poller, xm_io_poller_event, timeout);
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

