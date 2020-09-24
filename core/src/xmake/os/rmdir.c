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
 * @file        rmdir.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "rmdir"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_os_rmdir_empty(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_bool_t* is_emptydir = (tb_bool_t*)priv;
    tb_assert_and_check_return_val(path && info && is_emptydir, tb_false);

    // is emptydir?
    if (info->type == TB_FILE_TYPE_DIRECTORY || info->type == TB_FILE_TYPE_FILE)
    {
        // not emptydir
        *is_emptydir = tb_false;

        // break
        return tb_false;
    }

    // continue
    return tb_true;
}
static tb_bool_t xm_os_rmdir_remove(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(path, tb_false);

    // is directory?
    if (info->type == TB_FILE_TYPE_DIRECTORY)
    {
        // is emptydir?
        tb_bool_t is_emptydir = tb_true;
        tb_directory_walk(path, tb_false, tb_true, xm_os_rmdir_empty, &is_emptydir);

        // trace
        tb_trace_d("path: %s, emptydir: %u", path, is_emptydir);

        // remove empty directory
        if (is_emptydir) tb_directory_remove(path);
    }

    // continue
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_rmdir(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the path
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_check_return_val(path, 0);

    // only remove empty directory?
    tb_bool_t rmempty = lua_toboolean(lua, 2);
    if (rmempty)
    {
        // remove all empty directories
        tb_directory_walk(path, tb_true, tb_false, xm_os_rmdir_remove, tb_null);

        // remove empty root directory
        tb_bool_t is_emptydir = tb_true;
        tb_directory_walk(path, tb_false, tb_true, xm_os_rmdir_empty, &is_emptydir);
        if (is_emptydir) tb_directory_remove(path);

        // trace
        tb_trace_d("path: %s, emptydir: %u", path, is_emptydir);

        // ok?
        lua_pushboolean(lua, !tb_file_info(path, tb_null));
    }
    else
    {
        // done os.rmdir(path)
        lua_pushboolean(lua, tb_directory_remove(path));
    }

    // ok
    return 1;
}
