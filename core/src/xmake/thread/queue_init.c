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
 * @file        queue_init.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "thread_queue"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_thread_value_free(tb_element_ref_t element, tb_pointer_t buff) {
    xm_thread_value_t *item = (xm_thread_value_t *)buff;
    if (item) {
        if (item->kind == XM_THREAD_VALUE_STR) {
            if (item->u.string) {
                tb_free((tb_pointer_t)item->u.string);
            }
            item->u.string = tb_null;
        }
        item->size = 0;
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_queue_init(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    tb_bool_t          ok           = tb_false;
    xm_thread_queue_t *thread_queue = tb_null;
    do {
        thread_queue = tb_malloc0_type(xm_thread_queue_t);
        tb_assert_and_check_break(thread_queue);

        thread_queue->refn   = 1;
        thread_queue->handle = tb_queue_init(0,
                                             tb_element_mem(sizeof(xm_thread_value_t), xm_thread_value_free, tb_null));
        tb_assert_and_check_break(thread_queue->handle);

        xm_lua_pushpointer(lua, (tb_pointer_t)thread_queue);
        ok = tb_true;

    } while (0);

    if (!ok) {
        if (thread_queue) {
            if (thread_queue->handle) {
                tb_queue_exit(thread_queue->handle);
                thread_queue->handle = tb_null;
            }
            tb_free(thread_queue);
        }
        lua_pushnil(lua);
    }
    return 1;
}
