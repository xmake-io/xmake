/*!The Automatic Cross-platform Build Tool
 * 
 * XMake is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * XMake is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with XMake; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2015 - 2016, ruki All rights reserved.
 *
 * @author      ruki
 * @file        waitlist.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "process.waitlist"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* count, list = process.waitlist(proclist, timeout)
 *
 * count:
 *
 * the finished count: > 0
 * timeout: 0
 * failed: -1
 *
 * for _, procinfo in ipairs(list) do
 *     print("index: ", procinfo[1])
 *     print("status: ", procinfo[2])
 *     print("process: ", procinfo[3])
 * end
 */
tb_int_t xm_process_waitlist(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is table?
    if (!lua_istable(lua, 1)) 
    { 
        // error
        lua_pushfstring(lua, "invalid argument type(%s) for process.waitlist", luaL_typename(lua, 1));
        lua_error(lua);
        return 0;
    }

    // get the processes count
    tb_long_t count = lua_objlen(lua, 1);
    if (count <= 0 || count > 64)
    {
        // error
        lua_pushfstring(lua, "invalid process count(%ld) for process.waitlist", count);
        lua_error(lua);
        return 0;
    }

    // get the processes
    tb_size_t           i = 0;
    tb_process_ref_t    processes[64 + 1];
    for (i = 0; i < count; i++)
    {
        // get proclist[i]
        lua_pushinteger(lua, i + 1);
        lua_gettable(lua, 1);

        // is userdata?
        if (lua_isuserdata(lua, -1))
        {
            // save this process
            processes[i] = lua_touserdata(lua, -1);
            if (!processes[i])
            {
                // error
                lua_pushfstring(lua, "process[%ld] is null for process.waitlist", i);
                lua_error(lua);
            }
        }
        else
        {
            // error
            lua_pushfstring(lua, "invalid process[%ld] type(%s) for process.waitlist", i, luaL_typename(lua, -1));
            lua_error(lua);
        }

        // pop it
        lua_pop(lua, 1);
    }

    // end
    processes[count] = tb_null;

    // get the timeout
    tb_long_t timeout = (tb_long_t)luaL_checkinteger(lua, 2);

    // wait it
    tb_process_waitinfo_t infolist[64];
    tb_long_t infosize = tb_process_waitlist(processes, infolist, tb_arrayn(infolist), timeout);

    // save process info count
    lua_pushinteger(lua, infosize);
    if (infosize >= 0)
    {
        // save process info list
        lua_newtable(lua);
        for (i = 0; i < infosize; i++)
        {
            // save one process info
            lua_newtable(lua);
            lua_pushinteger(lua, infolist[i].index + 1);
            lua_rawseti(lua, -2, 1);
            lua_pushinteger(lua, infolist[i].status);
            lua_rawseti(lua, -2, 2);
            lua_pushlightuserdata(lua, infolist[i].process);
            lua_rawseti(lua, -2, 3);

            lua_rawseti(lua, -2, i + 1);
        }
    }
    else lua_pushnil(lua);

    // ok
    return 2;
}
