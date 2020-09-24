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
 * @file        pipe_open.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "pipe_open"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/*
 * io.pipe_open(name, mode, buffsize)
 */
tb_int_t xm_io_pipe_open(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get pipe name and mode
    tb_char_t const* name = luaL_checkstring(lua, 1);
    tb_char_t const* modestr = luaL_optstring(lua, 2, "r");
    tb_assert_and_check_return_val(name && modestr, 0);

    // get file mode value
    tb_size_t mode = TB_FILE_MODE_RO;
    if (modestr[0] == 'w') mode = TB_FILE_MODE_WO;

    // get buffer size
    tb_size_t buffsize = (tb_size_t)luaL_checknumber(lua, 3);

    // open pipe file
    tb_pipe_file_ref_t pipefile = tb_pipe_file_init(name, mode, buffsize);
    if (pipefile) xm_lua_pushpointer(lua, (tb_pointer_t)pipefile);
    else lua_pushnil(lua);
    return 1;
}
