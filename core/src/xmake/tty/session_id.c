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
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        session_id.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "session_id"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_WINDOWS
#include <windows.h>
#else
#include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// tty.session_id()
tb_int_t xm_tty_session_id(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

#ifdef TB_CONFIG_OS_WINDOWS
    HWND hwnd = GetConsoleWindow();
    if (hwnd) {
        // use hex string of hwnd as session id
        lua_pushfstring(lua, "%p", hwnd);
        return 1;
    }
#else
    // we use the tty name as session id
    tb_char_t const* name = ttyname(STDIN_FILENO);
    if (name) {
        lua_pushstring(lua, name);
        return 1;
    }
#endif

    // failed
    lua_pushnil(lua);
    return 1;
}
