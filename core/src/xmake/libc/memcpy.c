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
 * @file        memcpy.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "memcpy"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_libc_memcpy(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // do memcpy
    tb_pointer_t dst = (tb_pointer_t)(tb_size_t)luaL_checkinteger(lua, 1);
    tb_pointer_t src = (tb_pointer_t)(tb_size_t)luaL_checkinteger(lua, 2);
    tb_int_t size = (tb_int_t)lua_tointeger(lua, 3);
    if (dst && src && size > 0)
        tb_memcpy(dst, src, size);
    return 0;
}

