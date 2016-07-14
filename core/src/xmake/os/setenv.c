/*!The Make-like Build Utility based on Lua
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
 * @file        setenv.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "setenv"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
// ok = os.setenv(name, value) 
tb_int_t xm_os_setenv(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the name and value 
    size_t              value_size = 0;
    tb_char_t const*    name = luaL_checkstring(lua, 1);
    tb_char_t const*    value = luaL_checklstring(lua, 2, &value_size);
    tb_check_return_val(name, 0);

    // set it
    lua_pushboolean(lua, value? tb_environment_set(name, value) : tb_false);

    // ok
    return 1;
}
