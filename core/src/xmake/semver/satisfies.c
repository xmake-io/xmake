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
 * @file        satisfies.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "satisfies"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* satisfies the given version range?
 *
 * semver.satisfies('1.2.3', '1.x || >=2.5.0 || 5.0.0 - 7.2.3') => true
 */
tb_int_t xm_semver_satisfies(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the version string
    tb_char_t const* version_str = luaL_checkstring(lua, 1);
    tb_char_t const* range_str   = luaL_checkstring(lua, 2);
    tb_assert_and_check_return_val(version_str && range_str, 0);

    // parse the version range string
    semver_range_t range = {0};
    if (semver_rangen(&range, range_str, tb_strlen(range_str)))
    {
        // range is branch name? try to match it
        semver_t range_semver = {0};
        if (!tb_strcmp(version_str, range_str))
        {
            lua_pushboolean(lua, tb_true);
            return 1;
        }
        // range is a single version? try to compare it
        else if (!semver_tryn(&range_semver, range_str, tb_strlen(range_str)))
        {
            semver_t semver = {0};
            if (!semver_tryn(&semver, version_str, tb_strlen(version_str)))
            {
                lua_pushboolean(lua, semver_pcmp(&semver, &range_semver) == 0);
                semver_dtor(&semver);
                semver_dtor(&range_semver);
                return 1;
            }
            else
            {
                semver_dtor(&range_semver);
                lua_pushnil(lua);
                lua_pushfstring(lua, "unable to parse semver '%s'", version_str);
                return 2;
            }
        }
        else
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "unable to parse semver range '%s'", range_str);
            return 2;
        }
    }

    // try to parse the version string
    semver_t semver = {0};
    if (semver_tryn(&semver, version_str, tb_strlen(version_str)))
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "unable to parse semver '%s'", version_str);
        return 2;
    }

    // satisfies this range?
    lua_pushboolean(lua, semver_range_match(semver, range));
    semver_dtor(&semver);
    semver_range_dtor(&range);
    return 1;
}
