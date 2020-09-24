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
 * @file        compare.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "compare"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// semver.compare("v1.0.1-beta", "1.2") > 0?
tb_int_t xm_semver_compare(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the version1 string
    tb_char_t const* version1_str = luaL_checkstring(lua, 1);
    tb_check_return_val(version1_str, 0);

    // get the version2 string
    tb_char_t const* version2_str = luaL_checkstring(lua, 2);
    tb_check_return_val(version2_str, 0);

    // try to parse version1 string
    semver_t semver1 = {0};
    if (semver_tryn(&semver1, version1_str, tb_strlen(version1_str)))
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "unable to parse semver '%s'", version1_str);
        return 2;
    }


    // try to parse version2 string
    semver_t semver2 = {0};
    if (semver_tryn(&semver2, version2_str, tb_strlen(version2_str)))
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "unable to parse semver '%s'", version2_str);
        return 2;
    }

    // do compare
    lua_pushinteger(lua, semver_pcmp(&semver1, &semver2));

    // end
    semver_dtor(&semver1);
    semver_dtor(&semver2);
    return 1;
}
