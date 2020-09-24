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
 * @author      TitanSnow
 * @file        uid.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "uid"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifndef TB_CONFIG_OS_WINDOWS
#   include <unistd.h>
#   include <errno.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifndef TB_CONFIG_OS_WINDOWS

// get & set uid
tb_int_t xm_os_uid(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_int_t ruidset = -1;
    tb_int_t euidset = -1;
    tb_int_t argc = lua_gettop(lua);
    if (argc == 1)
    {
        if (lua_istable(lua, 1))
        {
            // os.uid({["ruid"] = ruid, ["euid"] = euid})
            lua_getfield(lua, 1, "ruid");
            lua_getfield(lua, 1, "euid");
            if (!lua_isnil(lua, -1))
            {
                if (!lua_isnumber(lua, -1))
                {
                    lua_pushfstring(lua, "invalid field type(%s) in `euid` for os.uid", luaL_typename(lua, -1));
                    lua_error(lua);
                    return 0;
                }
                euidset = (tb_int_t)lua_tonumber(lua, -1);
            }
            lua_pop(lua, 1);
            if (!lua_isnil(lua, -1))
            {
                if (!lua_isnumber(lua, -1))
                {
                    lua_pushfstring(lua, "invalid field type(%s) in `ruid` for os.uid", luaL_typename(lua, -1));
                    lua_error(lua);
                    return 0;
                }
                ruidset = (tb_int_t)lua_tonumber(lua, -1);
            }
            lua_pop(lua, 1);
        }
        else if (lua_isnumber(lua, 1))
        {
            // os.uid(uid)
            ruidset = euidset = (tb_int_t)lua_tonumber(lua, 1);
        }
        else
        {
            lua_pushfstring(lua, "invalid argument type(%s) for os.uid", luaL_typename(lua, 1));
            lua_error(lua);
            return 0;
        }
    }
    else if (argc == 2)
    {
        // os.uid(ruid, euid)
        if (!lua_isnil(lua, 1))
        {
            if (!lua_isnumber(lua, 1))
            {
                lua_pushfstring(lua, "invalid argument type(%s) for os.uid", luaL_typename(lua, 1));
                lua_error(lua);
                return 0;
            }
            ruidset = (tb_int_t)lua_tonumber(lua, 1);
        }
        if (!lua_isnil(lua, 2))
        {
            if (!lua_isnumber(lua, 2))
            {
                lua_pushfstring(lua, "invalid argument type(%s) for os.uid", luaL_typename(lua, 2));
                lua_error(lua);
                return 0;
            }
            euidset = (tb_int_t)lua_tonumber(lua, 2);
        }
    }
    else if (argc != 0)
    {
        lua_pushstring(lua, "invalid argument count for os.uid");
        lua_error(lua);
        return 0;
    }

    // store return value
    lua_newtable(lua);

    if (ruidset != -1 || euidset != -1)
    {
        // set ruid & euid
        lua_pushstring(lua, "errno");
        lua_pushinteger(lua, setreuid(ruidset, euidset) != 0 ? errno : 0);
        lua_settable(lua, -3);
    }

    // get uid & euid
    uid_t uid  = getuid();
    uid_t euid = geteuid();

    // push
    lua_pushstring(lua, "ruid");
    lua_pushinteger(lua, uid);
    lua_settable(lua, -3);
    lua_pushstring(lua, "euid");
    lua_pushinteger(lua, euid);
    lua_settable(lua, -3);

    // ok
    return 1;
}

#endif
