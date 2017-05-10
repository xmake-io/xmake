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
 * @file        get_history_state.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "get_history_state"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

#ifdef XM_CONFIG_API_HAVE_READLINE

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// get_history_state wrapper
tb_int_t xm_readline_get_history_state(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // HISTORY_STATE table
    lua_newtable(lua);
    HISTORY_STATE *hs = history_get_history_state();
    // field offset
    lua_pushstring(lua, "offset");
    lua_pushinteger(lua, hs -> offset);
    lua_settable(lua, -3);
    // field length
    lua_pushstring(lua, "length");
    lua_pushinteger(lua, hs -> length);
    lua_settable(lua, -3);
    // field size
    lua_pushstring(lua, "size");
    lua_pushinteger(lua, hs -> size);
    lua_settable(lua, -3);
    // field flags
    lua_pushstring(lua, "flags");
    lua_pushinteger(lua, hs -> flags);
    lua_settable(lua, -3);
    // field entries
    lua_pushstring(lua, "entries");
    lua_newtable(lua);
    for (HIST_ENTRY **p = hs -> entries; *p; ++p)
    {
        lua_newtable(lua);
        // field line
        lua_pushstring(lua, "line");
        lua_pushstring(lua, (*p) -> line);
        lua_settable(lua, -3);
        // field timestamp
        lua_pushstring(lua, "timestamp");
        lua_pushstring(lua, (*p) -> timestamp);
        lua_settable(lua, -3);

        // set back
        lua_rawseti(lua, -2, p - hs -> entries + 1);
    }
    lua_settable(lua, -3);

    // ok
    return 1;
}

#endif
