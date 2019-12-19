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
 * @file        history_list.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "history_list"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef XM_CONFIG_API_HAVE_READLINE

// history_list wrapper
tb_int_t xm_readline_history_list(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // history list
    lua_newtable(lua);

#ifdef TB_CONFIG_OS_MACOSX
    for (tb_int_t i = 1; i <= history_length; ++i)
    {
        lua_newtable(lua);

        // field line
        lua_pushstring(lua, "line");
        lua_pushstring(lua, history_get(i)->line);
        lua_settable(lua, -3);

        // set back
        lua_rawseti(lua, -2, i);
    }
#else
    tb_int_t i = 1;
    for (HIST_ENTRY **p = history_list(); *p; ++p, ++i)
    {
        lua_newtable(lua);

        // field line
        lua_pushstring(lua, "line");
        lua_pushstring(lua, (*p)->line);
        lua_settable(lua, -3);

        // set back
        lua_rawseti(lua, -2, i);
    }
#endif

    // ok
    return 1;
}

#endif
