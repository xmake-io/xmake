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
 * @author      uael
 * @file        semver.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "semver"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t lua_pushsemver(lua_State *lua, semver_t const* semver)
{
    // check
    tb_assert(lua && semver);

    // return a semver table
    lua_createtable(lua, 0, 7);

    lua_pushstring(lua, semver->raw);
    lua_setfield(lua, -2, "raw");

    lua_pushlstring(lua, semver->raw, semver->len);
    lua_setfield(lua, -2, "version");

    lua_pushinteger(lua, semver->major);
    lua_setfield(lua, -2, "major");

    lua_pushinteger(lua, semver->minor);
    lua_setfield(lua, -2, "minor");

    lua_pushinteger(lua, semver->patch);
    lua_setfield(lua, -2, "patch");

    // push prelease table
    lua_pushstring(lua, "prerelease");
    lua_newtable(lua);

    tb_uchar_t i = 0;
    semver_id_t const* id = &semver->prerelease;
    while (id && id->len)
    {
        if (id->numeric) lua_pushinteger(lua, id->num);
        else lua_pushlstring(lua, id->raw, id->len);
        id = id->next;
        lua_rawseti(lua, -2, ++i);
    }
    lua_settable(lua, -3);

    // push the build table
    i = 0;
    lua_pushstring(lua, "build");
    lua_newtable(lua);
    id = &semver->build;
    while (id && id->len)
    {
        if (id->numeric) lua_pushinteger(lua, id->num);
        else lua_pushlstring(lua, id->raw, id->len);
        id = id->next;
        lua_rawseti(lua, -2, ++i);
    }
    lua_settable(lua, -3);
}
