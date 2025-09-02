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
 * @file        sharedata_init.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "thread_sharedata"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_sharedata_init(lua_State* lua)
{
    tb_assert_and_check_return_val(lua, 0);

    tb_bool_t ok = tb_false;
    xm_thread_sharedata_t* thread_sharedata = tb_null;
    do
    {
        thread_sharedata = tb_malloc0_type(xm_thread_sharedata_t);
        tb_assert_and_check_break(thread_sharedata);

        thread_sharedata->refn = 1;
        thread_sharedata->value.kind = XM_THREAD_VALUE_NIL;
        tb_buffer_init(&thread_sharedata->buffer);

        xm_lua_pushpointer(lua, (tb_pointer_t)thread_sharedata);
        ok = tb_true;

    } while (0);

    if (!ok)
    {
        if (thread_sharedata)
        {
            tb_buffer_exit(&thread_sharedata->buffer);
            tb_free(thread_sharedata);
        }
        lua_pushnil(lua);
    }
    return 1;
}
