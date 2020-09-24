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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        pipe_connect.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "pipe_connect"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// io.pipe_connect(pipefile)
tb_int_t xm_io_pipe_connect(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // check pipe
    if (!xm_lua_ispointer(lua, 1))
    {
        lua_pushnumber(lua, -1);
        lua_pushliteral(lua, "invalid pipe!");
        return 2;
    }

    // get pipe file
    tb_pipe_file_ref_t pipefile = (tb_pipe_file_ref_t)xm_lua_topointer(lua, 1);
    tb_check_return_val(pipefile, 0);

    // connect pipe
    lua_pushnumber(lua, (tb_int_t)tb_pipe_file_connect(pipefile));
    return 1;
}

