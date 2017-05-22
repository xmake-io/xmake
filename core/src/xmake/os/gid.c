/*!The Make-like Build Utility based on Lua
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Copyright (C) 2015 - 2017, TBOOX Open Source Group.
 *
 * @author      TitanSnow
 * @file        gid.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "gid"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifndef TB_CONFIG_OS_WINDOWS
#   include <unistd.h>
#   include <errno.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// get gid & egid
tb_int_t xm_os_gid(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_int_t gidset = -1, egidset = -1;

    tb_int_t argc = lua_gettop(lua);

    if (argc == 1)
    {
        if (lua_istable(lua, 1))
        {
            // os.gid({["gid"] = gid, ["egid"] = egid})
            lua_getfield(lua, 1, "gid");
            lua_getfield(lua, 1, "egid");
            if (!lua_isnil(lua, -1))
            {
                if (!lua_isnumber(lua, -1))
                {
                    lua_pushfstring(lua, "invalid field type(%s) in `egid` for os.gid", luaL_typename(lua, -1));
                    lua_error(lua);
                    return 0;
                }
                egidset = (tb_int_t)lua_tonumber(lua, -1);
            }
            lua_pop(lua, 1);
            if (!lua_isnil(lua, -1))
            {
                if (!lua_isnumber(lua, -1))
                {
                    lua_pushfstring(lua, "invalid field type(%s) in `gid` for os.gid", luaL_typename(lua, -1));
                    lua_error(lua);
                    return 0;
                }
                gidset = (tb_int_t)lua_tonumber(lua, -1);
            }
            lua_pop(lua, 1);
        } else if (lua_isnumber(lua, 1))
        {
            // os.gid(egid)
            egidset = (tb_int_t)lua_tonumber(lua, 1);
        } else
        {
            lua_pushfstring(lua, "invalid argument type(%s) for os.gid", luaL_typename(lua, 1));
            lua_error(lua);
            return 0;
        }
    } else if (argc == 2)
    {
        // os.gid(gid, egid)
        if (!lua_isnil(lua, 1))
        {
            if (!lua_isnumber(lua, 1))
            {
                lua_pushfstring(lua, "invalid argument type(%s) for os.gid", luaL_typename(lua, 1));
                lua_error(lua);
                return 0;
            }
            gidset = (tb_int_t)lua_tonumber(lua, 1);
        }
        if (!lua_isnil(lua, 2))
        {
            if (!lua_isnumber(lua, 2))
            {
                lua_pushfstring(lua, "invalid argument type(%s) for os.gid", luaL_typename(lua, 2));
                lua_error(lua);
                return 0;
            }
            egidset = (tb_int_t)lua_tonumber(lua, 2);
        }
    } else if (argc != 0)
    {
        lua_pushstring(lua, "invalid argument count for os.gid");
        lua_error(lua);
        return 0;
    }

    // store return value
    lua_newtable(lua);

    // set gid & egid
    if (gidset != -1)
    {
        lua_pushstring(lua, "setgid_errno");
        lua_pushinteger(lua, setgid(gidset) != 0 ? errno : 0);
        lua_settable(lua, -3);
    }
    if (egidset != -1)
    {
        lua_pushstring(lua, "setegid_errno");
        lua_pushinteger(lua, setegid(egidset) != 0 ? errno : 0);
        lua_settable(lua, -3);
    }

    // get gid & egid
    gid_t gid = getgid(), egid = getegid();

    // push
    lua_pushstring(lua, "gid");
    lua_pushinteger(lua, gid);
    lua_settable(lua, -3);
    lua_pushstring(lua, "egid");
    lua_pushinteger(lua, egid);
    lua_settable(lua, -3);

    // ok
    return 1;
}

#endif
