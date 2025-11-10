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
 * @file        sharedata_exit.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "thread_sharedata"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_sharedata_exit(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    xm_thread_sharedata_t *thread_sharedata = xm_thread_sharedata_get(lua, 1);
    tb_assert_and_check_return_val(thread_sharedata, 0);

    if (tb_atomic_fetch_and_sub(&thread_sharedata->refn, 1) == 1) {
        tb_buffer_exit(&thread_sharedata->buffer);
        tb_free(thread_sharedata);
    }
    lua_pushboolean(lua, tb_true);
    return 1;
}
