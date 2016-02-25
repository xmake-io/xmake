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
 * Copyright (C) 2015 - 2016, ruki All rights reserved.
 *
 * @author      ruki
 * @file        startswith.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "startswith"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_string_startswith(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the string and prefix
    size_t              prefix_size = 0;
    tb_char_t const*    string = luaL_checkstring(lua, 1);
    tb_char_t const*    prefix = luaL_checklstring(lua, 2, &prefix_size);
    tb_check_return_val(string && prefix, 0);

    // done string:startswith(prefix) 
    lua_pushboolean(lua, !tb_strncmp(string, prefix, (tb_size_t)prefix_size));

    // ok
    return 1;
}
