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
 * @author      ruki
 * @file        term_mode.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "term_mode"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_WINDOWS
#   include <windows.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* local oldmode = tty.term_mode(stdtype)
 * local oldmode = tty.term_mode(stdtype, newmode)
 */
tb_int_t xm_tty_term_mode(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

#ifdef TB_CONFIG_OS_WINDOWS

    // get std type, (stdin: 1, stdout: 2, stderr: 3)
    tb_int_t stdtype = (tb_int_t)luaL_checkinteger(lua, 1);

    // get and set terminal mode
    DWORD mode = 0;
    HANDLE console_handle = INVALID_HANDLE_VALUE;
    switch (stdtype)
    {
    case 1: console_handle = GetStdHandle(STD_INPUT_HANDLE); break;
    case 2: console_handle = GetStdHandle(STD_OUTPUT_HANDLE); break;
    case 3: console_handle = GetStdHandle(STD_ERROR_HANDLE); break;
    }
    GetConsoleMode(console_handle, &mode);
    if (lua_isnumber(lua, 2))
    {
        tb_int_t newmode = (tb_int_t)lua_tointeger(lua, 2);
        if (console_handle != INVALID_HANDLE_VALUE)
            SetConsoleMode(console_handle, (DWORD)newmode);
    }
#else
    tb_int_t mode = 0;
#endif
    lua_pushinteger(lua, (tb_int_t)mode);
    return 1;
}
