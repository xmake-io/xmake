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
 * @file        cpfile.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "cpfile"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_cpfile(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the source and destination 
    tb_char_t const* src = luaL_checkstring(lua, 1);
    tb_char_t const* dst = luaL_checkstring(lua, 2);
    tb_check_return_val(src && dst, 0);

    // done os.cpfile(src, dst) 
    lua_pushboolean(lua, tb_file_copy(src, dst));

    // ok
    return 1;
}
