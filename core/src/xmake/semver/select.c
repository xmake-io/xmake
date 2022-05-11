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
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_semver_select_from_versions_tags1(lua_State* lua, tb_int_t fromidx, semver_t* semver, semver_range_t const* range, semvers_t* matches)
{
    // clear matches
    semvers_pclear(matches);

    // select all matches
    lua_Integer i = 0;
    luaL_checktype(lua, fromidx, LUA_TTABLE);
    for (i = lua_objlen(lua, fromidx); i > 0; --i)
    {
        lua_pushinteger(lua, i);
        lua_gettable(lua, fromidx);

        tb_char_t const* source_str = luaL_checkstring(lua, -1);
        if (source_str && semver_tryn(semver, source_str, tb_strlen(source_str)) == 0)
        {
            if (semver_range_pmatch(semver, range)) semvers_ppush(matches, *semver);
            else semver_dtor(semver);
        }
        lua_pop(lua, 1);
    }

    // no matches?
    tb_check_return_val(matches->length, tb_false);

    // sort matches
    semvers_psort(matches);

    // get the newest version
    semver_t top = semvers_ppop(matches);
    lua_createtable(lua, 0, 2);

    // return results
    lua_pushstring(lua, top.raw);
    lua_setfield(lua, -2, "version");

    lua_pushstring(lua, fromidx == 2? "version" : "tag");
    lua_setfield(lua, -2, "source");

    // exit the popped semver
    semver_dtor(&top);

    // ok
    return tb_true;
}
static tb_bool_t xm_semver_select_from_versions_tags2(lua_State* lua, tb_int_t fromidx, semver_t* semver, tb_char_t const* version_str, tb_size_t version_len)
{
    lua_Integer i = 0;
    luaL_checktype(lua, fromidx, LUA_TTABLE);
    for (i = lua_objlen(lua, fromidx); i > 0; --i)
    {
        lua_pushinteger(lua, i);
        lua_gettable(lua, fromidx);

        tb_char_t const* source_str = luaL_checkstring(lua, -1);
        tb_size_t source_len = tb_strlen(source_str);
        lua_pop(lua, 1);
        if (source_len == version_len && tb_strncmp(source_str, version_str, version_len) == 0)
        {
            lua_createtable(lua, 0, 2);
            lua_pushlstring(lua, source_str, source_len);
            lua_setfield(lua, -2, "version");
            lua_pushstring(lua, fromidx == 2? "version" : "tag");
            lua_setfield(lua, -2, "source");
            return tb_true;
        }
    }
    return tb_false;
}
static tb_bool_t xm_semver_select_from_branches(lua_State* lua, tb_int_t fromidx, tb_char_t const* range_str, tb_size_t range_len)
{
    lua_Integer i = 0;
    luaL_checktype(lua, fromidx, LUA_TTABLE);
    for (i = lua_objlen(lua, fromidx); i > 0; --i)
    {
        lua_pushinteger(lua, i);
        lua_gettable(lua, fromidx);

        tb_char_t const* source_str = luaL_checkstring(lua, -1);
        tb_size_t source_len = tb_strlen(source_str);
        lua_pop(lua, 1);
        if (source_len == range_len && tb_memcmp(source_str, range_str, source_len) == 0)
        {
            lua_createtable(lua, 0, 2);
            lua_pushlstring(lua, source_str, source_len);
            lua_setfield(lua, -2, "version");
            lua_pushstring(lua, "branch");
            lua_setfield(lua, -2, "source");
            return tb_true;
        }
    }
    return tb_false;
}
static tb_bool_t xm_semver_select_latest_from_versions_tags(lua_State* lua, tb_int_t fromidx, semver_t* semver, semvers_t* matches)
{
    // clear matches
    semvers_pclear(matches);

    // push all versions to matches
    lua_Integer i = 0;
    luaL_checktype(lua, fromidx, LUA_TTABLE);
    for (i = lua_objlen(lua, fromidx); i > 0; --i)
    {
        lua_pushinteger(lua, i);
        lua_gettable(lua, fromidx);

        tb_char_t const* source_str = luaL_checkstring(lua, -1);
        if (source_str && semver_tryn(semver, source_str, tb_strlen(source_str)) == 0)
            semvers_ppush(matches, *semver);

        lua_pop(lua, 1);
    }
    tb_check_return_val(matches->length, tb_false);

    // sort matches
    semvers_psort(matches);

    // get the newest match
    semver_t top = semvers_ppop(matches);
    lua_createtable(lua, 0, 2);

    // return results
    lua_pushstring(lua, top.raw);
    lua_setfield(lua, -2, "version");

    lua_pushstring(lua, fromidx == 2? "version" : "tag");
    lua_setfield(lua, -2, "source");

    semver_dtor(&top);
    return tb_true;
}


/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* select version
 *
 * local versioninfo, errors = semver.select(">=1.5.0 <1.6", {"1.5.0", "1.5.1"}, {"v1.5.0", ..}, {"latest", "dev"})
 */
tb_int_t xm_semver_select(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // select version
    tb_bool_t ok               = tb_false;
    tb_bool_t is_range         = tb_false;
    tb_char_t const* range_str = tb_null;
    semver_t semver            = {0};
    semvers_t matches          = {0};
    semver_range_t range       = {0};
    do
    {
        // get the version range string
        range_str = luaL_checkstring(lua, 1);
        tb_check_break(range_str);

        // get the range string length
        tb_size_t range_len = tb_strlen(range_str);

        // parse the version range string
        is_range = semver_rangen(&range, range_str, range_len) == 0;
        if (is_range)
        {
            // attempt to select version from the versions list first
            if (xm_semver_select_from_versions_tags1(lua, 2, &semver, &range, &matches))
            {
                ok = tb_true;
                break;
            }

            // attempt to select version from the tags list
            if (xm_semver_select_from_versions_tags1(lua, 3, &semver, &range, &matches))
            {
                ok = tb_true;
                break;
            }
        }
        else
        {
            // attempt to select version from the versions list first
            if (xm_semver_select_from_versions_tags2(lua, 2, &semver, range_str, range_len))
            {
                ok = tb_true;
                break;
            }

            // attempt to select version from the tags list
            if (xm_semver_select_from_versions_tags2(lua, 3, &semver, range_str, range_len))
            {
                ok = tb_true;
                break;
            }
        }

        // attempt to select version from the branches
        if (xm_semver_select_from_branches(lua, 4, range_str, range_len))
        {
            ok = tb_true;
            break;
        }

        // select the latest version from the tags and versions if be latest
        if (!tb_strcmp(range_str, "latest"))
        {
            // attempt to select latest version from the versions list
            if (xm_semver_select_latest_from_versions_tags(lua, 2, &semver, &matches))
            {
                ok = tb_true;
                break;
            }

            // attempt to select latest version from the tags list
            if (xm_semver_select_latest_from_versions_tags(lua, 3, &semver, &matches))
            {
                ok = tb_true;
                break;
            }
        }

    } while (0);

    // exit matches
    semvers_dtor(matches);

    // exit range
    semver_range_dtor(&range);

    // failed?
    if (!ok)
    {
        if (!is_range)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "unable to parse semver range '%s'", range_str);
        }

        lua_pushnil(lua);
        lua_pushfstring(lua, "unable to select version for range '%s'", range_str);
        return 2;
    }

    // ok
    return 1;
}
