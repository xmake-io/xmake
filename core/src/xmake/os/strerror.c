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
 * @author      ruki
 * @file        strerror.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "strerror"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if !defined(TB_CONFIG_OS_WINDOWS) || defined(TB_COMPILER_LIKE_UNIX)
#   include <errno.h>
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_strerror(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get syserror state
    tb_size_t syserror = tb_syserror_state();
    if (syserror != TB_STATE_SYSERROR_UNKNOWN_ERROR)
    {
        tb_char_t const* strerr = "Unknown";
        switch (syserror)
        {
        case TB_STATE_SYSERROR_NOT_PERM:
            strerr = "Permission denied";
            break;
        case TB_STATE_SYSERROR_NOT_FILEDIR:
            strerr = "No such file or directory";
            break;
        default:
            break;
        }
        lua_pushstring(lua, strerr);
    }
    else
    {
#if defined(TB_CONFIG_OS_WINDOWS) && !defined(TB_COMPILER_LIKE_UNIX)
        lua_pushstring(lua, "Unknown");
#else
        lua_pushstring(lua, strerror(errno));
#endif
    }
    return 1;
}
