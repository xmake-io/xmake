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
 * @file        cpfile.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "cpfile"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_cpfile(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the source and destination
    tb_char_t const* src = luaL_checkstring(lua, 1);
    tb_char_t const* dst = luaL_checkstring(lua, 2);
    tb_check_return_val(src && dst, 0);

    // init copy flags
    tb_size_t flags = TB_FILE_COPY_NONE;
    tb_bool_t is_symlink = lua_toboolean(lua, 3);
    if (is_symlink)
        flags |= TB_FILE_COPY_LINK;

    tb_bool_t is_writeable = lua_toboolean(lua, 4);
    if (is_writeable)
        flags |= TB_FILE_COPY_WRITEABLE;

    // do copy
    lua_pushboolean(lua, tb_file_copy(src, dst, flags));
    return 1;
}
