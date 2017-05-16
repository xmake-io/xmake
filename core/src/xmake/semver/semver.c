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

void lua_pushsemver(lua_State *lua, const semver_t semver)
{
    semver_id_t const *id;
    tb_uchar_t i = 0;

    lua_createtable(lua, 0, 5);

    lua_pushinteger(lua, semver.major);
    lua_setfield(lua, -2, "major");

    lua_pushinteger(lua, semver.minor);
    lua_setfield(lua, -2, "minor");

    lua_pushinteger(lua, semver.patch);
    lua_setfield(lua, -2, "patch");

    lua_pushstring(lua, "prerelease");
    lua_newtable(lua);
    id = &semver.prerelease;
    while (id && id->len) {
        if (id->numeric) {
            lua_pushinteger(lua, id->num);
        } else {
            lua_pushlstring(lua, id->raw, id->len);
        }
        id = id->next;
        lua_rawseti(lua, -2, ++i);
    }
    lua_settable(lua, -3);

    i = 0;
    lua_pushstring(lua, "build");
    lua_newtable(lua);
    id = &semver.build;
    while (id && id->len) {
        if (id->numeric) {
            lua_pushinteger(lua, id->num);
        } else {
            lua_pushlstring(lua, id->raw, id->len);
        }
        id = id->next;
        lua_rawseti(lua, -2, ++i);
    }
    lua_settable(lua, -3);
}
