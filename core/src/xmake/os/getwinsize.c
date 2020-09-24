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
 * @file        getwinsize.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "getwinsize"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_CONFIG_OS_WINDOWS) && !defined(TB_COMPILER_LIKE_UNIX)
#   include <windows.h>
#else
#   include <sys/ioctl.h>
#   include <errno.h>  // for errno
#   include <unistd.h> // for STDOUT_FILENO
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// get console window size
tb_int_t xm_os_getwinsize(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // init default window size (we will not consider winsize limit if cannot get it)
    tb_int_t w = TB_MAXS16, h = TB_MAXS16;

    // get winsize
#if defined(TB_CONFIG_OS_WINDOWS) && !defined(TB_COMPILER_LIKE_UNIX)
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi))
    {
        w = (tb_int_t)csbi.dwSize.X;
        h = (tb_int_t)csbi.dwSize.Y;
    }
#else
    struct winsize size;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) == 0)
    {
        w = (tb_int_t)size.ws_col;
        h = (tb_int_t)size.ws_row;
    }
#endif

    /* local winsize = os.getwinsize()
     *
     * return
     * {
     *      width = -1 or ..
     * ,    height = -1 or ..
     * }
     */
    lua_newtable(lua);
    lua_pushstring(lua, "width");
    lua_pushinteger(lua, w);
    lua_settable(lua, -3);
    lua_pushstring(lua, "height");
    lua_pushinteger(lua, h);
    lua_settable(lua, -3);

    // ok
    return 1;
}
