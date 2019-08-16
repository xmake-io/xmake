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

// p = process.open(command, {outpath = "", errpath = ""}) 
tb_int_t xm_process_open(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get command
    size_t              command_size = 0;
    tb_char_t const*    command = luaL_checklstring(lua, 1, &command_size);
    tb_check_return_val(command, 0);

    // init attributes
    tb_process_attr_t attr = {0};

    // get option arguments
    tb_char_t const* outpath = tb_null;
    tb_char_t const* errpath = tb_null;
    if (lua_istable(lua, 2)) 
    { 
        // get outpath
        lua_pushstring(lua, "outpath");
        lua_gettable(lua, 2);
        outpath = lua_tostring(lua, -1);
        lua_pop(lua, 1);

        // get errpath
        lua_pushstring(lua, "errpath");
        lua_gettable(lua, 2);
        errpath = lua_tostring(lua, -1);
        lua_pop(lua, 1);
    }
    else
    {
        // @deprecated compatible with process.open(cmd, outpath, errpath)
        outpath = lua_tostring(lua, 2);
        errpath = lua_tostring(lua, 3);
    }

    // redirect stdout?
    if (outpath)
    {
        // redirect stdout to file
        attr.outpath = outpath;
        attr.outmode = TB_FILE_MODE_RW | TB_FILE_MODE_TRUNC | TB_FILE_MODE_CREAT;
        attr.outtype = TB_PROCESS_REDIRECT_TYPE_FILEPATH;
    }

    // redirect stderr?
    if (errpath)
    {
        // redirect stderr to file
        attr.errpath = errpath;
        attr.errmode = TB_FILE_MODE_RW | TB_FILE_MODE_TRUNC | TB_FILE_MODE_CREAT;
        attr.errtype = TB_PROCESS_REDIRECT_TYPE_FILEPATH;
    }

    // init process
    tb_process_ref_t process = (tb_process_ref_t)tb_process_init_cmd(command, &attr);
    if (process) lua_pushlightuserdata(lua, (tb_pointer_t)process);
    else lua_pushnil(lua);
    return 1;
}
