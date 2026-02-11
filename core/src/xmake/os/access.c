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
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        access.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "access"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_access(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get the path
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_char_t const* mode_str = luaL_checkstring(lua, 2);
    tb_check_return_val(path && mode_str, 0);

    // parse mode
    tb_size_t mode = 0;
    while (*mode_str) {
        switch (*mode_str) {
        case 'r': mode |= TB_FILE_MODE_RO; break;
        case 'w': mode |= TB_FILE_MODE_WO; break;
        case 'x': mode |= TB_FILE_MODE_EXEC; break;
        default: break;
        }
        mode_str++;
    }

    tb_trace_i("access: %s, mode: %d -> %d", path, mode, tb_file_access(path, mode));

    // os.access(path, mode)
    lua_pushboolean(lua, tb_file_access(path, mode));
    return 1;
}
