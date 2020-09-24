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
 * @file        filelock_trylock.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "filelock_trylock"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* try to lock file
 *
 * exclusive lock:  io.filelock_trylock("/xxxx/filelock")
 * shared lock:     io.filelock_trylock("/xxxx/filelock", {shared = true})
 */
tb_int_t xm_io_filelock_trylock(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get option argument
    tb_bool_t is_shared = tb_false;
    if (lua_istable(lua, 2))
    {
        // is shared lock?
        lua_pushstring(lua, "shared");
        lua_gettable(lua, 2);
        is_shared = (tb_bool_t)lua_toboolean(lua, -1);
        lua_pop(lua, 1);
    }

    // check lock?
    if (!xm_lua_ispointer(lua, 1))
        return 0;

    // get lock
    tb_filelock_ref_t lock = (tb_filelock_ref_t)xm_lua_topointer(lua, 1);
    tb_check_return_val(lock, 0);

    // try to lock it
    tb_bool_t ok = tb_filelock_enter_try(lock, is_shared? TB_FILELOCK_MODE_SH : TB_FILELOCK_MODE_EX);
    lua_pushboolean(lua, ok);
    return 1;
}
