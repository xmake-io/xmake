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
 * @author      TitanSnow
 * @file        readline.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "readline"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

#ifdef XM_CONFIG_API_HAVE_READLINE

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// readline wrapper
tb_int_t xm_readline_readline(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the prompt
    tb_char_t const* prompt = luaL_optstring(lua, 1, tb_null);

    // call readline
    tb_char_t* line = readline(prompt);
    if (line)
    {
        // return line
        lua_pushstring(lua, line);

        // free it
        tb_free(line);
    }
    else lua_pushnil(lua);

    // ok
    return 1;
}

#endif
