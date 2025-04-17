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
 * @file        thread_exit.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "thread"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_exit(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is pointer?
    if (!xm_lua_ispointer(lua, 1))
        return 0;

    // get thread
    xm_thread_t* thread = (xm_thread_t*)xm_lua_topointer(lua, 1);
    tb_check_return_val(thread, 0);

    // exit thread
    if (thread)
    {
        tb_string_exit(&thread->callback);
        tb_string_exit(&thread->argv);
        if (thread->handle)
        {
            tb_thread_exit(thread->handle);
            thread->handle = tb_null;
        }
        tb_free(thread);
    }
    lua_pushboolean(lua, tb_true);
    return 1;
}

