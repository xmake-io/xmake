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
 * @file        filelock_close___gc.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "filelock_close___gc"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "filelock.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

static tb_int_t xm_io_filelock_close_impl(lua_State* lua, tb_bool_t allow_closed_lock)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // close lock
    xm_io_filelock_t* lock = xm_io_get_filelock(lua);
    if (!lock->is_opened)
    {
        if (allow_closed_lock)
        {
            lua_pushboolean(lua, tb_true);
            xm_io_filelock_return_success();
        }
        else xm_io_filelock_return_error_closed(lua);
    }

    // check
    tb_assert(lock->lock_ref);

    // close lock
    tb_filelock_exit(lock->lock_ref);
    lock->lock_ref  = tb_null;
    lock->is_opened = tb_false;
    lock->is_locked = tb_false;

    // free lock path
    if (lock->path)
    {
        tb_free(lock->path);
        lock->path = tb_null;
    }

    // mark this lock as closed
    tb_strlcpy(lock->name, "lock: (closed lock)", tb_arrayn(lock->name));

    // close ok
    lua_pushboolean(lua, tb_true);
    xm_io_filelock_return_success();
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*
 * lock:close()
 */
tb_int_t xm_io_filelock_close(lua_State* lua)
{
    return xm_io_filelock_close_impl(lua, tb_false);
}

/*
 * lock:close()
 */
tb_int_t xm_io_filelock___gc(lua_State* lua)
{
    return xm_io_filelock_close_impl(lua, tb_true);
}
