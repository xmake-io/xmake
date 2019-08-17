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

// p = process.open(command, {outpath = "", errpath = "", envs = {"PATH=xxx", "XXX=yyy"}}) 
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
    tb_size_t        envn = 0;
    tb_char_t const* envs[256] = {0};
    tb_char_t const* outpath = tb_null;
    tb_char_t const* errpath = tb_null;
    tb_bool_t        vs_unicode_output = tb_false;
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

        // enable vs_unicode_output?
        lua_pushstring(lua, "vs_unicode_output");
        lua_gettable(lua, 2);
        vs_unicode_output = lua_toboolean(lua, -1);
        lua_pop(lua, 1);
    }

    // enable vs_unicode_output? @see https://github.com/xmake-io/xmake/issues/528
    if (vs_unicode_output)
    {
        xm_subprocess_t* subprocess = tb_malloc0_type(xm_subprocess_t);
        if (subprocess)
        {
            // init vs_unicode_output
            tb_string_init(&subprocess->vs_unicode_output);

            // redirect stdout?
            if (outpath)
            {
                // redirect stdout to file
                subprocess->outfile = tb_file_init(outpath, TB_FILE_MODE_RW | TB_FILE_MODE_TRUNC | TB_FILE_MODE_CREAT);
                subprocess->outtype = TB_PROCESS_REDIRECT_TYPE_FILE;
                attr.outfile = subprocess->outfile;
                attr.outtype = subprocess->outtype;

#ifdef TB_CONFIG_OS_WINDOWS
                /* add environment value of vs_unicode_output
                 *
                 * @note we have to set it at the beginning, because opt.envs might also have this value.
                 */
                if (envn + 1 < tb_arrayn(envs)) 
                    envs[envn++] = tb_string_cstrfcpy(&subprocess->vs_unicode_output, "VS_UNICODE_OUTPUT=%zu", (tb_size_t)subprocess->outfile);
#endif
            }

            // redirect stderr?
            if (errpath)
            {
                // redirect stderr to file
                subprocess->errfile = tb_file_init(errpath, TB_FILE_MODE_RW | TB_FILE_MODE_TRUNC | TB_FILE_MODE_CREAT);
                subprocess->errtype = TB_PROCESS_REDIRECT_TYPE_FILE;
                attr.errfile = subprocess->errfile;
                attr.errtype = subprocess->errtype;
            }
            attr.priv = subprocess;
        }
    }
    else
    {
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
    }

    // append other environments after setting VS_UNICODE_OUTPUT 
    if (lua_istable(lua, 2)) 
    { 
        // get environments
        lua_pushstring(lua, "envs");
        lua_gettable(lua, 2);
        if (lua_istable(lua, -1))
        {
            // get environment variables count
            tb_size_t count = (tb_size_t)lua_objlen(lua, -1);

            // get all passed environment variables
            tb_size_t i;
            for (i = 0; i < count; i++)
            {
                // get envs[i]
                lua_pushinteger(lua, i + 1);
                lua_gettable(lua, -2);

                // is string?
                if (lua_isstring(lua, -1))
                {
                    // add this environment value
                    if (envn + 1 < tb_arrayn(envs)) 
                        envs[envn++] = lua_tostring(lua, -1);
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
        lua_pop(lua, 1);
    }


    // set the new environments
    if (envn > 0) attr.envp = envs;

    // init process
    tb_process_ref_t process = (tb_process_ref_t)tb_process_init_cmd(command, &attr);
    if (process) lua_pushlightuserdata(lua, (tb_pointer_t)process);
    else lua_pushnil(lua);
    return 1;
}
