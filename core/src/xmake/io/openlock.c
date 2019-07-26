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
 * @file        openlock.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "openlock"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "filelock.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/*
 * io.openlock(path)
 */
tb_int_t xm_io_openlock(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get file path 
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_assert_and_check_return_val(path, 0);

    // init file lock
    tb_filelock_ref_t lock = tb_filelock_init_from_path(path, tb_file_info(path, tb_null)? TB_FILE_MODE_RO : TB_FILE_MODE_RW | TB_FILE_MODE_CREAT);
    if (lock)
    {
        // init file lock
        xm_io_filelock_t* xmlock = xm_io_new_filelock(lua);
        xmlock->lock_ref  = lock;
        xmlock->is_opened = tb_true;
        xmlock->nlocked   = 0;

        // save lock path
        tb_size_t pathlen = tb_strlen(path);
        xmlock->path = tb_malloc_cstr(pathlen + 1);
        if (xmlock->path) 
        {
            tb_strncpy((tb_char_t*)xmlock->path, path, pathlen);
            ((tb_char_t*)xmlock->path)[pathlen] = '\0';
        }

        // save lock name
        tb_size_t name_maxn = tb_arrayn(xmlock->name);
        tb_strlcpy(xmlock->name, "lock: ", name_maxn);
        if (pathlen < name_maxn - tb_arrayn("lock: "))
            tb_strcat(xmlock->name, path);
        else
        {
            tb_strcat(xmlock->name, "...");
            tb_strcat(xmlock->name, path + (pathlen - name_maxn + tb_arrayn("lock: ") + tb_arrayn("...")));
        }
        return 1;
    }
    else 
    {
        lua_pushnil(lua);
        lua_pushliteral(lua, "cannot open file lock!");
        return 2;
    }
}
