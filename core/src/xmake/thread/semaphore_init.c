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
 * @file        semaphore_init.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "thread_semaphore"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_semaphore_init(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    tb_bool_t              ok               = tb_false;
    xm_thread_semaphore_t *thread_semaphore = tb_null;
    do {
        tb_long_t value = (tb_long_t)luaL_checknumber(lua, 1);

        thread_semaphore = tb_malloc0_type(xm_thread_semaphore_t);
        tb_assert_and_check_break(thread_semaphore);

        thread_semaphore->refn   = 1;
        thread_semaphore->handle = tb_semaphore_init(value);
        tb_assert_and_check_break(thread_semaphore->handle);

        xm_lua_pushpointer(lua, (tb_pointer_t)thread_semaphore);
        ok = tb_true;

    } while (0);

    if (!ok) {
        if (thread_semaphore) {
            if (thread_semaphore->handle) {
                tb_semaphore_exit(thread_semaphore->handle);
                thread_semaphore->handle = tb_null;
            }
            tb_free(thread_semaphore);
        }
        lua_pushnil(lua);
    }
    return 1;
}
