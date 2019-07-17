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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        trim.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "trim"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* trim string 
 *
 * @param cstr     the c-string
 * @param mode     the trim mode, all: 0, left: -1, right: 1
 */
tb_int_t xm_string_trim(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the string and trim mode
    size_t           size = 0;
    tb_char_t const* cstr = luaL_checklstring(lua, 1, &size);
    ptrdiff_t        mode = luaL_optinteger(lua, 2, 0);
    tb_check_return_val(cstr, 0);

    // empty string?
    if (!size) lua_pushstring(lua, "");
    else
    {
        tb_char_t const* p = cstr;
        tb_char_t const* e = cstr + size;
    
        // trim left?
        if (mode <= 0) while (p < e && tb_isspace(*p)) p++;

        // trim right
        if (mode >= 0) 
        {
            e--;
            while (e >= cstr && tb_isspace(*e)) e--;
            e++;
        }

        // save trimed string
        if (e > p) lua_pushlstring(lua, p, e - p);
        else lua_pushstring(lua, "");
    }

    // ok
    return 1;
}
