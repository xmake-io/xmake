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
 * @file        readline.c
 *
 */

#ifdef XM_CONFIG_API_HAVE_READLINE

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "readline"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// readline wrapper
tb_int_t xm_readline_readline(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the prompt
    tb_char_t const* prompt = tb_null;
    if (luaL_typename(lua, 1) != "nil")
        prompt = luaL_checkstring(lua, 1);

    // call readline
    tb_char_t const* line = readline(prompt);
    if (line)
        lua_pushstring(lua, line);
    else
        lua_pushnil(lua);

    // ok
    return 1;
}

#endif
