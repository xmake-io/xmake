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
 * @file        filelock.h
 *
 */
#ifndef XM_IO_FILE_LOCK_H
#define XM_IO_FILE_LOCK_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define xm_io_filelock_udata "XM_IO_FILE_LOCK*"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the file lock type
typedef struct __xm_io_filelock_t
{
    // the lock reference
    tb_filelock_ref_t   lock_ref;

    // is opened
    tb_bool_t           is_opened;

    // the lock name
    tb_char_t           name[64];

    // the lock path
    tb_char_t const*    path;

} xm_io_filelock_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
static __tb_inline__ xm_io_filelock_t* xm_io_new_filelock(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, tb_null);

    // new file lock
    xm_io_filelock_t* lock = (xm_io_filelock_t*)lua_newuserdata(lua, sizeof(xm_io_filelock_t));
    tb_assert_and_check_return_val(lock, tb_null);

    // init file lock
    tb_memset(lock, 0, sizeof(xm_io_filelock_t));

    // bind io._filelock metatable
    luaL_getmetatable(lua, xm_io_filelock_udata);
    lua_setmetatable(lua, -2);
    return lock;
}

static __tb_inline__ xm_io_filelock_t* xm_io_get_filelock(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, tb_null);

    // get file lock
    xm_io_filelock_t* lock = (xm_io_filelock_t*)luaL_checkudata(lua, 1, xm_io_filelock_udata);
    tb_assert(lock);
    return lock;
}

#endif
