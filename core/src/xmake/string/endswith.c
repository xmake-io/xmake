/*!The Automatic Cross-platform Build Tool
 * 
 * XMake is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * XMake is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with XMake; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        endswith.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "endswith"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_string_endswith(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the string and suffix
    size_t              string_size = 0;
    size_t              suffix_size = 0;
    tb_char_t const*    string = luaL_checklstring(lua, 1, &string_size);
    tb_char_t const*    suffix = luaL_checklstring(lua, 2, &suffix_size);
    tb_check_return_val(string && suffix, 0);

    // done string:endswith(suffix) 
    if (string_size >= suffix_size)
        lua_pushboolean(lua, !tb_strcmp(string + string_size - suffix_size, suffix));

    // ok
    return 1;
}
