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
 * @file        getenvs.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "getenvs"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_CONFIG_OS_WINDOWS) && !defined(TB_COMPILER_LIKE_UNIX)
#   include <windows.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the separator
#if defined(TB_CONFIG_OS_WINDOWS) && !defined(TB_COMPILER_LIKE_UNIX)
#   define XM_OS_ENV_SEP                    ';'
#else
#   define XM_OS_ENV_SEP                    ':'
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the user environment
#if !defined(TB_CONFIG_OS_WINDOWS) || defined(TB_COMPILER_LIKE_UNIX)
extern tb_char_t** environ;
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_getenvs(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // init table
    lua_newtable(lua);

#if defined(TB_CONFIG_OS_WINDOWS) && !defined(TB_COMPILER_LIKE_UNIX)
    tb_wchar_t const* p = (tb_wchar_t const*)GetEnvironmentStringsW();
    if (p)
    {
        tb_int_t    i = 1;
        tb_char_t*  data = tb_null;
        tb_size_t   maxn = 0;
        tb_char_t   line[TB_PATH_MAXN];
        tb_size_t   n = 0;
        while (*p)
        {
            n = tb_wcslen(p);
            if (n + 1 <  tb_arrayn(line))
            {
                if (tb_wtoa(line, p, tb_arrayn(line)) >= 0)
                {
                    lua_pushstring(lua, line);
                    lua_rawseti(lua, -2, i++);
                }
            }
            else
            {
                if (!data)
                {
                    maxn = n + 1;
                    data = (tb_char_t*)tb_malloc(maxn);
                }
                else if (n >= maxn)
                {
                    maxn = n + TB_PATH_MAXN + 1;
                    data = (tb_char_t*)tb_ralloc(data, maxn);
                }
                tb_assert_and_check_break(data);

                if (tb_wtoa(data, p, maxn) >= 0)
                {
                    lua_pushstring(lua, data);
                    lua_rawseti(lua, -2, i++);
                }
            }
            p += n + 1;
        }
        if (data && data != line) tb_free(data);
        data = tb_null;
    }
#else
    tb_char_t const** p = (tb_char_t const**)environ;
    if (p)
    {
        tb_int_t  i = 1;
        tb_size_t n = 0;
        while (*p)
        {
            n = tb_strlen(*p);
            if (n)
            {
                lua_pushstring(lua, *p);
                lua_rawseti(lua, -2, i++);
            }
            p++;
        }
    }
#endif

    // ok
    return 1;
}
