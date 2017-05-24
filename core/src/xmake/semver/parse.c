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

// parse wrapper
tb_int_t xm_semver_parse(lua_State* lua)
{
    semver_t semver = {0};

    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the version string
    tb_char_t const* str = luaL_checkstring(lua, 1);
    tb_check_return_val(str, 0);

    if (semvern(&semver, str, tb_strlen(str))) {
        lua_pushnil(lua);
        lua_pushfstring(lua, "Unable to parse semver '%s'", str);

        return 2;
    }

    lua_pushsemver(lua, semver);
    semver_dtor(&semver);

    // ok
    return 1;
}
