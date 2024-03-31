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
    XM_OS_SIGINT = 2
}xm_os_signal_e;

typedef enum __xm_os_signal_handler_e {
    XM_OS_SIGFUN = 0,
    XM_OS_SIGDFL = 1,
    XM_OS_SIGIGN = 2,
}xm_os_signal_handler_e;

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
    tb_int_t handler = XM_OS_SIGFUN;

    // check signal handler
    if (lua_isnumber(lua, 2))
        handler = (tb_int_t) luaL_checkinteger(lua, 2);
    else if (!lua_isfunction(lua, 2))
        return 0;

    // save signal handler
    tb_int_t signo = (tb_int_t)luaL_checkinteger(lua, 1);
    if (handler == XM_OS_SIGFUN)
    {
        tb_char_t name[64] = {0};
        tb_snprintf(name, sizeof(name), "_SIGNAL_HANDLER_%d", signo);
        lua_pushvalue(lua, 2);
        lua_setglobal(lua, name);
    }

#if defined(TB_CONFIG_OS_WINDOWS)
    if (signo != XM_OS_SIGINT)
        return 0;

    switch (handler)
    {
        case XM_OS_SIGFUN:
            SetConsoleCtrlHandler(xm_os_signal_handler, TRUE);
            break;
        case XM_OS_SIGDFL:
            SetConsoleCtrlHandler(NULL, FALSE);
            break;
        case XM_OS_SIGIGN:
            SetConsoleCtrlHandler(NULL, TRUE);
            break;
        default:
            break;
    }
#elif defined(SIGINT)
    switch (signo)
    {
    case XM_OS_SIGINT:
        signo = SIGINT;
        break;
    default:
        return 0;
    }

    switch (handler)
    {
        case XM_OS_SIGFUN:
            signal(signo, xm_os_signal_handler);
            break;
        case XM_OS_SIGDFL:
            signal(signo, SIG_DFL);
            break;
        case XM_OS_SIGIGN:
            signal(signo, SIG_IGN);
            break;
        default:
            break;
    }
#endif
    return 0;
}
