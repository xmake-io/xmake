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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
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
#include "../io/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* p = process.open(command,
 * {outpath = "", errpath = "", outfile = "",
 *  errfile = "", outpipe = "", errpipe = "",
 *  infile = "", inpipe = "", inpipe = "",
 *  envs = {"PATH=xxx", "XXX=yyy"}})
 */
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
    tb_size_t          envn = 0;
    tb_char_t const*   envs[1024] = {0};
    tb_char_t const*   inpath  = tb_null;
    tb_char_t const*   outpath = tb_null;
    tb_char_t const*   errpath = tb_null;
    xm_io_file_t*      infile  = tb_null;
    xm_io_file_t*      outfile = tb_null;
    xm_io_file_t*      errfile = tb_null;
    tb_pipe_file_ref_t inpipe  = tb_null;
    tb_pipe_file_ref_t outpipe = tb_null;
    tb_pipe_file_ref_t errpipe = tb_null;
    if (lua_istable(lua, 2))
    {
        // is detached?
        lua_pushstring(lua, "detach");
        lua_gettable(lua, 2);
        if (lua_toboolean(lua, -1))
            attr.flags |= TB_PROCESS_FLAG_DETACH;
        lua_pop(lua, 1);

        // get curdir
        lua_pushstring(lua, "curdir");
        lua_gettable(lua, 3);
        attr.curdir = lua_tostring(lua, -1);
        lua_pop(lua, 1);

        // get inpath
        lua_pushstring(lua, "inpath");
        lua_gettable(lua, 2);
        inpath = lua_tostring(lua, -1);
        lua_pop(lua, 1);

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

        // get infile
        if (!inpath)
        {
            lua_pushstring(lua, "infile");
            lua_gettable(lua, 3);
            infile = (xm_io_file_t*)lua_touserdata(lua, -1);
            lua_pop(lua, 1);
        }

        // get outfile
        if (!outpath)
        {
            lua_pushstring(lua, "outfile");
            lua_gettable(lua, 3);
            outfile = (xm_io_file_t*)lua_touserdata(lua, -1);
            lua_pop(lua, 1);
        }

        // get errfile
        if (!errpath)
        {
            lua_pushstring(lua, "errfile");
            lua_gettable(lua, 3);
            errfile = (xm_io_file_t*)lua_touserdata(lua, -1);
            lua_pop(lua, 1);
        }

        // get inpipe
        if (!inpath && !infile)
        {
            lua_pushstring(lua, "inpipe");
            lua_gettable(lua, 3);
            inpipe = (tb_pipe_file_ref_t)lua_touserdata(lua, -1);
            lua_pop(lua, 1);
        }

        // get outpipe
        if (!outpath && !outfile)
        {
            lua_pushstring(lua, "outpipe");
            lua_gettable(lua, 3);
            outpipe = (tb_pipe_file_ref_t)lua_touserdata(lua, -1);
            lua_pop(lua, 1);
        }

        // get errpipe
        if (!errpath && !errfile)
        {
            lua_pushstring(lua, "errpipe");
            lua_gettable(lua, 3);
            errpipe = (tb_pipe_file_ref_t)lua_touserdata(lua, -1);
            lua_pop(lua, 1);
        }

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
                        lua_pushfstring(lua, "envs is too large(%d > %d) for process.openv", (tb_int_t)envn, tb_arrayn(envs) - 1);
                        lua_error(lua);
                    }
                }
                else
                {
                    // error
                    lua_pushfstring(lua, "invalid envs[%d] type(%s) for process.openv", (tb_int_t)i, luaL_typename(lua, -1));
                    lua_error(lua);
                }

                // pop it
                lua_pop(lua, 1);
            }
        }
        lua_pop(lua, 1);
    }

    // redirect stdin?
    if (inpath)
    {
        // redirect stdin to file
        attr.in.path = inpath;
        attr.inmode  = TB_FILE_MODE_RO;
        attr.intype  = TB_PROCESS_REDIRECT_TYPE_FILEPATH;
    }
    else if (infile && xm_io_file_is_file(infile))
    {
        tb_file_ref_t rawfile = tb_null;
        if (tb_stream_ctrl(infile->stream, TB_STREAM_CTRL_FILE_GET_FILE, &rawfile) && rawfile)
        {
            attr.in.file = rawfile;
            attr.intype  = TB_PROCESS_REDIRECT_TYPE_FILE;
        }
    }
    else if (inpipe)
    {
        attr.in.pipe = inpipe;
        attr.intype  = TB_PROCESS_REDIRECT_TYPE_PIPE;
    }


    // redirect stdout?
    if (outpath)
    {
        // redirect stdout to file
        attr.out.path = outpath;
        attr.outmode  = TB_FILE_MODE_RW | TB_FILE_MODE_TRUNC | TB_FILE_MODE_CREAT;
        attr.outtype  = TB_PROCESS_REDIRECT_TYPE_FILEPATH;
    }
    else if (outfile && xm_io_file_is_file(outfile))
    {
        tb_file_ref_t rawfile = tb_null;
        if (tb_stream_ctrl(outfile->stream, TB_STREAM_CTRL_FILE_GET_FILE, &rawfile) && rawfile)
        {
            attr.out.file = rawfile;
            attr.outtype  = TB_PROCESS_REDIRECT_TYPE_FILE;
        }
    }
    else if (outpipe)
    {
        attr.out.pipe = outpipe;
        attr.outtype  = TB_PROCESS_REDIRECT_TYPE_PIPE;
    }

    // redirect stderr?
    if (errpath)
    {
        // redirect stderr to file
        attr.err.path = errpath;
        attr.errmode  = TB_FILE_MODE_RW | TB_FILE_MODE_TRUNC | TB_FILE_MODE_CREAT;
        attr.errtype  = TB_PROCESS_REDIRECT_TYPE_FILEPATH;
    }
    else if (errfile && xm_io_file_is_file(errfile))
    {
        tb_file_ref_t rawfile = tb_null;
        if (tb_stream_ctrl(errfile->stream, TB_STREAM_CTRL_FILE_GET_FILE, &rawfile) && rawfile)
        {
            attr.err.file = rawfile;
            attr.errtype  = TB_PROCESS_REDIRECT_TYPE_FILE;
        }
    }
    else if (errpipe)
    {
        attr.err.pipe = errpipe;
        attr.errtype  = TB_PROCESS_REDIRECT_TYPE_PIPE;
    }

    // set the new environments
    if (envn > 0) attr.envp = envs;

    // init process
    tb_process_ref_t process = (tb_process_ref_t)tb_process_init_cmd(command, &attr);
    if (process) xm_lua_pushpointer(lua, (tb_pointer_t)process);
    else lua_pushnil(lua);
    return 1;
}
