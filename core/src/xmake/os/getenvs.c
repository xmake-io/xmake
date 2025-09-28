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
static tb_void_t xm_os_getenvs_trim(tb_char_t const** sstr, tb_char_t const** estr)
{
    // check
    tb_assert(sstr && estr && *sstr && *estr);

    tb_char_t const* p = *sstr;
    tb_char_t const* e = *estr;

    // trim left
    while (p < e && tb_isspace(*p))
        p++;

    // trim right
    while (e > p && tb_isspace(*(e - 1)))
        e--;

    // save trimmed string
    *sstr = p;
    *estr = e;
}

static tb_void_t xm_os_getenvs_process_line(lua_State* lua, tb_char_t const* line)
{
    // check
    tb_assert_and_check_return(lua && line);

    tb_size_t n = tb_strlen(line);
    tb_check_return(n > 0);

    // find '=' separator
    tb_char_t const* p = tb_strchr(line, '=');
    tb_check_return(p);

    // get key and value parts
    tb_char_t const* key_start = line;
    tb_char_t const* key_end = p;
    tb_char_t const* value_start = p + 1;
    tb_char_t const* value_end = line + n;

    // trim key
    xm_os_getenvs_trim(&key_start, &key_end);
    if (key_start >= key_end) return;

    // trim value
    xm_os_getenvs_trim(&value_start, &value_end);

    // get key and value lengths
    tb_size_t key_len = key_end - key_start;
    tb_size_t value_len = value_end > value_start ? value_end - value_start : 0;

    // handle Windows-specific PATH conversion
    tb_char_t const* final_key_start = key_start;
    tb_size_t final_key_len = key_len;
#if defined(TB_CONFIG_OS_WINDOWS) && !defined(TB_COMPILER_LIKE_UNIX)
    if (key_len == 4 && tb_strnicmp(key_start, "path", 4) == 0)
    {
        // use "PATH" instead of "path"
        static tb_char_t const PATH_UPPER[] = "PATH";
        final_key_start = PATH_UPPER;
        final_key_len = 4;
    }
#endif

    // set key-value pair in Lua table using pushlstring to avoid length limits
    lua_pushlstring(lua, final_key_start, final_key_len);
    lua_pushlstring(lua, value_start, value_len);
    lua_rawset(lua, -3);
}

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
                    xm_os_getenvs_process_line(lua, line);
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
                    xm_os_getenvs_process_line(lua, data);
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
        while (*p)
        {
            xm_os_getenvs_process_line(lua, *p);
            p++;
        }
    }
#endif

    // ok
    return 1;
}
