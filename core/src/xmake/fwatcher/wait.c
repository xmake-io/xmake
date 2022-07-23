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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        wait.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "fwatcher.wait"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// fwatcher.wait(p)
tb_int_t xm_fwatcher_wait(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is pointer?
    if (!xm_lua_ispointer(lua, 1))
        return 0;

    // get the fwatcher
    tb_fwatcher_ref_t fwatcher = (tb_fwatcher_ref_t)xm_lua_topointer(lua, 1);
    tb_check_return_val(fwatcher, 0);

    // get the timeout
    tb_long_t timeout = (tb_long_t)luaL_checkinteger(lua, 2);

    // wait fwatcher event
    tb_fwatcher_event_t event;
    tb_long_t ok = tb_fwatcher_wait(fwatcher, &event, timeout);

    // save result
    lua_pushinteger(lua, ok);
    if (ok > 0)
    {
        lua_newtable(lua);
        lua_pushstring(lua, "path");
        lua_pushstring(lua, event.filepath);
        lua_settable(lua, -3);

        lua_pushstring(lua, "type");
        lua_pushinteger(lua, event.event);
        lua_settable(lua, -3);
        return 2;
    }
    return 1;
}
