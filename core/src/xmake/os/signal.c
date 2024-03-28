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
 * @file        signal.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "signal"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_CONFIG_OS_MACOSX) || defined(TB_CONFIG_OS_IOS)
#   include <unistd.h>
#   include <signal.h>
#elif defined(TB_CONFIG_OS_LINUX) || defined(TB_CONFIG_OS_BSD) || defined(TB_CONFIG_OS_ANDROID) || defined(TB_CONFIG_OS_HAIKU)
#   include <unistd.h>
#   include <signal.h>
#endif
#ifdef TB_CONFIG_OS_BSD
#   include <sys/types.h>
#   include <sys/sysctl.h>
#   include <signal.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
typedef enum __xm_os_signal_e {
    XM_OS_SIGINT = 1
}xm_os_signal_e;

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
static lua_State* g_lua = tb_null;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_os_signal_handler_impl(tb_int_t signo)
{
    // do callback(signo)
    lua_State* lua = g_lua;
    if (lua)
    {
        tb_char_t name[64] = {0};
        tb_snprintf(name, sizeof(name), "_SIGNAL_HANDLER_%d", signo);
        lua_getglobal(lua, name);
        lua_pushinteger(lua, signo);
        lua_call(lua, 1, 0);
    }
}

#if defined(TB_CONFIG_OS_WINDOWS)
static BOOL WINAPI xm_os_signal_handler(DWORD ctrl_type)
{
    if (ctrl_type == CTRL_C_EVENT)
        xm_os_signal_handler_impl(XM_OS_SIGINT);
    return TRUE;
}
#elif defined(SIGINT)
static tb_void_t xm_os_signal_handler(tb_int_t signo_native)
{
    tb_int_t signo = -1;
    switch (signo_native)
    {
    case SIGINT:
        signo = XM_OS_SIGINT;
        break;
    default:
        break;
    }
    if (signo >= 0)
        xm_os_signal_handler_impl(signo);
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_signal(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);
    g_lua = lua;

    // check signal handler
    if (!lua_isfunction(lua, 2))
        return 0;

    // save signal handler
    tb_int_t signo = (tb_int_t)luaL_checkinteger(lua, 1);
    tb_char_t name[64] = {0};
    tb_snprintf(name, sizeof(name), "_SIGNAL_HANDLER_%d", signo);
    lua_pushvalue(lua, 2);
    lua_setglobal(lua, name);

#if defined(TB_CONFIG_OS_WINDOWS)
    if (signo == XM_OS_SIGINT)
        SetConsoleCtrlHandler(xm_os_signal_handler, TRUE);
#elif defined(SIGINT) // for checking signal
    tb_int_t signo_native = -1;
    switch (signo)
    {
    case XM_OS_SIGINT:
#ifdef SIGINT
        signo_native = SIGINT;
#endif
        break;
    default:
        break;
    }
    if (signo_native >= 0)
        signal(signo_native, xm_os_signal_handler);
#endif
    return 0;
}
