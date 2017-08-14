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
 * @file        select.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "select"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include <stdlib.h>
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// satisfies wrapper
tb_int_t xm_semver_select(lua_State* lua)
{
    semver_t semver = {0};
    semvers_t matches = {0};
    semver_range_t range = {0};
    lua_Integer i;
    size_t range_len = 0, source_len;
    tb_char_t const* source_str;
    tb_char_t const* source;
    tb_bool_t is_range;

    lua_settop(lua, 4);

    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the version string
    tb_char_t const* range_str = luaL_checkstring(lua, 1);
    tb_check_return_val(range_str, 0);
    range_len = tb_strlen(range_str);

    is_range = semver_rangen(&range, range_str, range_len) == 0;
    if (is_range) {
        source = "versions";
        luaL_checktype(lua, 2, LUA_TTABLE);
        for (i = lua_objlen(lua, 2); i > 0; --i) {
            lua_pushinteger(lua, i);
            lua_gettable(lua, 2);

            source_str = luaL_checkstring(lua, -1);
            tb_check_return_val(source_str, 0);

            if (semver_tryn(&semver, source_str, tb_strlen(source_str)) == 0) {
                if (semver_range_match(semver, range)) {
                    semvers_push(matches, semver);
                } else {
                    semver_dtor(&semver);
                }
            }
        }
        if (matches.length) {
            goto match;
        }
        semvers_clear(matches);
        source = "tags";
        luaL_checktype(lua, 3, LUA_TTABLE);
        for (i = lua_objlen(lua, 3); i > 0; --i) {
            lua_pushinteger(lua, i);
            lua_gettable(lua, 3);

            source_str = luaL_checkstring(lua, -1);
            tb_check_return_val(source_str, 0);

            if (semver_tryn(&semver, source_str, tb_strlen(source_str)) == 0) {
                if (semver_range_match(semver, range)) {
                    semvers_push(matches, semver);
                } else {
                    semver_dtor(&semver);
                }
            }
        }
        if (matches.length) {
            goto match;
        }
        semvers_dtor(matches);
        semver_range_dtor(&range);
    }

    source = "branches";
    luaL_checktype(lua, 4, LUA_TTABLE);
    for (i = lua_objlen(lua, 4); i > 0; --i) {
        lua_pushinteger(lua, i);
        lua_gettable(lua, 4);

        source_str = luaL_checkstring(lua, -1);
        tb_check_return_val(source_str, 0);
        source_len = tb_strlen(source_str);

        if (source_len == range_len && tb_memcmp(source_str, range_str, source_len) == 0) {
            lua_createtable(lua, 0, 2);

            lua_pushlstring(lua, source_str, source_len);
            lua_setfield(lua, -2, "version");

            lua_pushstring(lua, source);
            lua_setfield(lua, -2, "source");

            return 1;
        }
    }

    if (!is_range)  {
        lua_pushnil(lua);
        lua_pushfstring(lua, "Unable to parse semver range '%s'", range_str);

        return 2;
    }
    lua_pushnil(lua);
    lua_pushfstring(lua, "Unable to select version for range '%s'", range_str);

    return 2;
    match:
    semvers_sort(matches);
    semver = semvers_pop(matches);
    lua_createtable(lua, 0, 2);

    lua_pushstring(lua, semver.raw);
    lua_setfield(lua, -2, "version");

    lua_pushstring(lua, source);
    lua_setfield(lua, -2, "source");

    semvers_dtor(matches);
    semver_dtor(&semver);
    semver_range_dtor(&range);

    return 1;
}
