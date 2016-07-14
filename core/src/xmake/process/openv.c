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
 * @file        openv.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "process.openv"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// p = process.openv(shellname, argv, outfile, errfile) 
tb_int_t xm_process_openv(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // check table
    if (!lua_istable(lua, 2))
    {
        // error
        lua_pushfstring(lua, "invalid argv type(%s) for process.openv", luaL_typename(lua, 2));
        lua_error(lua);
        return 0;
    }

    // get the output and error file
    tb_char_t const* shellname  = lua_tostring(lua, 1);
    tb_char_t const* outfile    = lua_tostring(lua, 3);
    tb_char_t const* errfile    = lua_tostring(lua, 4);
    tb_check_return_val(shellname, 0);

    // get the arguments count
    tb_long_t argn = lua_objlen(lua, 2);
    tb_check_return_val(argn >= 0, 0);
    
    // get arguments
    tb_size_t           argi = 0;
    tb_char_t const**   argv = tb_nalloc0_type(1 + argn + 1, tb_char_t const*);
    tb_check_return_val(argv, 0);

    // fill arguments
    argv[0] = shellname;
    for (argi = 0; argi < argn; argi++)
    {
        // get argv[i]
        lua_pushinteger(lua, argi + 1);
        lua_gettable(lua, 2);

        // is string?
        if (lua_isstring(lua, -1))
        {
            // pass this argument
            argv[1 + argi] = lua_tostring(lua, -1);
        }
        else
        {
            // error
            lua_pushfstring(lua, "invalid argv[%ld] type(%s) for process.openv", argi, luaL_typename(lua, -1));
            lua_error(lua);
        }

        // pop it
        lua_pop(lua, 1);
    }

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
    tb_process_ref_t process = tb_process_init(shellname, argv, &attr);
    if (process) lua_pushlightuserdata(lua, process);
    else lua_pushnil(lua);

    // exit argv
    if (argv) tb_free(argv);
    argv = tb_null;

    // ok
    return 1;
}
