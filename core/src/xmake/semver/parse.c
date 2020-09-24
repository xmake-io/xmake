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
 * @file        parse.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "parse"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* version = semver.parse("v1.0.1-beta")
 *
 *
    {
        patch = 1
    ,   raw = v1.0.1-beta
    ,   version = v1.0.1-beta
    ,   major = 1
    ,   build =
        {
        }

    ,   minor = 0
    ,   prerelease =
        {
            beta
        }
    }
 *
 */
tb_int_t xm_semver_parse(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the version string
    tb_char_t const* version_str = luaL_checkstring(lua, 1);
    tb_check_return_val(version_str, 0);

    // try to parse version string
    semver_t semver = {0};
    if (semver_tryn(&semver, version_str, tb_strlen(version_str)))
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "unable to parse semver '%s'", version_str);
        return 2;
    }

    // ok
    lua_pushsemver(lua, &semver);
    semver_dtor(&semver);
    return 1;
}
