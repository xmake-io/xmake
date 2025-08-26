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
 * @file        thread_mutex_unlock.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "thread_mutex"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_mutex_unlock(lua_State* lua)
{
    tb_assert_and_check_return_val(lua, 0);

    if (!xm_lua_ispointer(lua, 1))
        return 0;

    xm_thread_mutex_t* thread_mutex = (xm_thread_mutex_t*)xm_lua_topointer(lua, 1);
    tb_check_return_val(thread_mutex && thread_mutex->handle, 0);

    lua_pushboolean(lua, tb_mutex_leave(thread_mutex->handle));
    return 1;
}

