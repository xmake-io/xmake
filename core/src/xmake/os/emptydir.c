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
 * @file        emptydir.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "emptydir"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_os_emptydir_walk(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_bool_t* is_emptydir = (tb_bool_t*)priv;
    tb_assert_and_check_return_val(path && info && is_emptydir, tb_false);

    // is emptydir?
    if (info->type == TB_FILE_TYPE_DIRECTORY || info->type == TB_FILE_TYPE_FILE)
    {
        // not emptydir 
        *is_emptydir = tb_false;

        // break
        return tb_false;
    }

    // continue 
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_emptydir(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the directory
    tb_char_t const* dir = luaL_checkstring(lua, 1);
    tb_check_return_val(dir, 0);

    // done os.emptydir(dir) 
    tb_bool_t is_emptydir = tb_true;
    tb_directory_walk(dir, tb_false, tb_true, xm_os_emptydir_walk, &is_emptydir);

    // is emptydir?
    lua_pushboolean(lua, is_emptydir);

    // ok
    return 1;
}
