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
 * @file        open.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "process.open"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// p = process.open(command) 
tb_int_t xm_process_open(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the command
    size_t              command_size = 0;
    tb_char_t const*    command = luaL_checklstring(lua, 1, &command_size);
    tb_char_t const*    outfile = lua_tostring(lua, 2);
    tb_char_t const*    errfile = lua_tostring(lua, 3);
    tb_check_return_val(command, 0);

    // init attributes
    tb_process_attr_t attr = {0};

    // redirect stdout?
    if (outfile)
    {
        // redirect stdout to file
        attr.outfile = outfile;
        attr.outmode = TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_APPEND;

        // remove the outfile first
        if (tb_file_info(outfile, tb_null))
            tb_file_remove(outfile);
    }

    // redirect stderr?
    if (errfile)
    {
        // redirect stderr to file
        attr.errfile = errfile;
        attr.errmode = TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_APPEND;

        // remove the errfile first
        if (tb_file_info(errfile, tb_null))
            tb_file_remove(errfile);
    }

    // init process
    tb_process_ref_t process = tb_process_init_cmd(command, &attr);

    // save the process reference
    lua_pushlightuserdata(lua, process);

    // ok
    return 1;
}
