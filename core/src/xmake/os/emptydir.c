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
 * @file        emptydir.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "emptydir"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_os_emptydir_walk(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_bool_t* is_emptydir = (tb_bool_t*)priv;
    tb_assert_and_check_return_val(path && info && is_emptydir, tb_false);

    // is emptydir?
    if (info->type == TB_FILE_TYPE_FILE || info->type == TB_FILE_TYPE_DIRECTORY)
    {
        *is_emptydir = tb_false;
        return tb_false;
    }

    // continue
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_emptydir(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the directory
    tb_char_t const* dir = luaL_checkstring(lua, 1);
    tb_check_return_val(dir, 0);

    // done os.emptydir(dir)
    tb_bool_t is_emptydir = tb_true;
    tb_directory_walk(dir, tb_true, tb_true, xm_os_emptydir_walk, &is_emptydir);

    // is emptydir?
    lua_pushboolean(lua, is_emptydir);

    // ok
    return 1;
}
