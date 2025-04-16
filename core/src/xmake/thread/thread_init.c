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
 * @file        thread_init.c
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
 * private implementation
 */
static tb_int_t xm_thread_func(tb_cpointer_t priv)
{
    tb_trace_i("thread ..");
    return 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_init(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get thread name
    tb_char_t const* name = luaL_checkstring(lua, 1);

    // get stack size
    tb_size_t stacksize = (tb_size_t)luaL_checkinteger(lua, 4);

    // init thread
    tb_thread_ref_t thread = tb_thread_init(name, xm_thread_func, tb_null, stacksize);
    if (thread) xm_lua_pushpointer(lua, (tb_pointer_t)thread);
    else lua_pushnil(lua);
    return 1;
}
