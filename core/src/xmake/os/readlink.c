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
 * @file        readlink.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "readlink"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifndef TB_CONFIG_OS_WINDOWS
#   include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_readlink(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the path
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_check_return_val(path, 0);

    // is link?
#if defined(TB_CONFIG_OS_WINDOWS)
    lua_pushnil(lua);
#else
    tb_char_t srcpath[TB_PATH_MAXN];
    tb_long_t size = readlink(path, srcpath, TB_PATH_MAXN);
    if (size == TB_PATH_MAXN)
    {
        tb_size_t  maxn = TB_PATH_MAXN * 2;
        tb_char_t* data = (tb_char_t*)tb_malloc(maxn);
        if (data)
        {
            tb_long_t size = readlink(path, data, maxn);
            if (size > 0 && size < maxn)
            {
                data[size] = '\0';
                lua_pushstring(lua, data);
            }
            else lua_pushnil(lua);
            tb_free(data);
        }
    }
    else if (size >= 0 && size < TB_PATH_MAXN)
    {
        srcpath[size] = '\0';
        lua_pushstring(lua, srcpath);
    }
    else lua_pushnil(lua);
#endif

    // ok
    return 1;
}
