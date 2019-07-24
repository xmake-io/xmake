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
 * @file        filelock_unlock.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "filelock_unlock"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "filelock.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// filelock:unlock()
tb_int_t xm_io_filelock_unlock(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // this lock has been closed?
    xm_io_filelock_t* lock = xm_io_get_filelock(lua);
    if (!lock->is_opened) 
        xm_io_filelock_return_error_closed(lua);
    else 
    {
        // unlock it
        if (tb_filelock_leave(lock->lock_ref))
        {
            lua_pushboolean(lua, tb_true);
            xm_io_filelock_return_success();
        }
        else xm_io_filelock_return_error(lua, lock, "unlock failed!");
    }
}
