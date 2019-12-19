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
 * @file        logical_drives.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "logical_drives"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// get the logical drives
tb_int_t xm_winos_logical_drives(lua_State* lua)
{
    // init table
    lua_newtable(lua);

    // get logical drives
    tb_bool_t  ok = tb_false;
    tb_char_t* data = tb_null;
    do
    {
        // get buffer size
        DWORD size = GetLogicalDriveStringsA(0, tb_null);
        tb_assert_and_check_break(size);

        // make data buffer
        data = (tb_char_t*)tb_malloc0(size + 1);
        tb_assert_and_check_break(data);

        // get logical drives
        size = GetLogicalDriveStringsA(size, data);
        tb_assert_and_check_break(size);

        // parse logical drives
        tb_size_t i = 1;
        tb_char_t const* p = data;
        while (*p)
        {
            // save drive
            lua_pushinteger(lua, i++);
            lua_pushstring(lua, p);
            lua_settable(lua, -3);

            // next drive
            p += tb_strlen(p) + 1;
        }

        // ok
        ok = tb_true;

    } while (0);

    // exit data
    if (data) tb_free(data);
    data = tb_null;

    // ok
    return 1;
}
