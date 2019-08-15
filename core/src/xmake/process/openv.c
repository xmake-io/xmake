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

// p = process.openv(shellname, argv, outpath, errpath, envs) 
tb_int_t xm_process_openv(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // check argv
    if (!lua_istable(lua, 2))
    {
        // error
        lua_pushfstring(lua, "invalid argv type(%s) for process.openv", luaL_typename(lua, 2));
        lua_error(lua);
        return 0;
    }

    // get the output and error file
    tb_char_t const* shellname  = lua_tostring(lua, 1);
    tb_char_t const* outpath    = lua_tostring(lua, 3);
    tb_char_t const* errpath    = lua_tostring(lua, 4);
    tb_check_return_val(shellname, 0);

    // get environments
    tb_char_t const* envs[256] = {0};
    tb_size_t envn = 0;
    if (lua_istable(lua, 5))
    {
        // get environment variables count
        envn = (tb_size_t)lua_objlen(lua, 5);

        // get all passed environment variables
        tb_size_t i;
        for (i = 0; i < envn; i++)
        {
            // get envs[i]
            lua_pushinteger(lua, i + 1);
            lua_gettable(lua, 5);

            // is string?
            if (lua_isstring(lua, -1))
            {
                // add this environment value
                if (i + 1 < tb_arrayn(envs)) 
                    envs[i] = lua_tostring(lua, -1);
                else
                {
                    // error
                    lua_pushfstring(lua, "envs is too large(%lu > %d) for process.openv", envn, tb_arrayn(envs) - 1);
                    lua_error(lua);
                }
            }
            else
            {
                // error
                lua_pushfstring(lua, "invalid envs[%ld] type(%s) for process.openv", i, luaL_typename(lua, -1));
                lua_error(lua);
            }

            // pop it
            lua_pop(lua, 1);
        }
    }

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

    // set the new environments
    if (envn > 0) attr.envp = envs;

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
    tb_process_ref_t process = (tb_process_ref_t)tb_process_init(shellname, argv, &attr);
    if (process) lua_pushlightuserdata(lua, (tb_pointer_t)process);
    else lua_pushnil(lua);

    // exit argv
    if (argv) tb_free(argv);
    argv = tb_null;

    // ok
    return 1;
}
