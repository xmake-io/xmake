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
 * @file        thread_queue_pop.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "thread_queue"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_queue_pop(lua_State* lua)
{
    tb_assert_and_check_return_val(lua, 0);

    xm_thread_queue_t* thread_queue = xm_thread_queue_get(lua, 1);
    tb_assert_and_check_return_val(thread_queue && thread_queue->handle, 0);

    if (tb_queue_null(thread_queue->handle))
    {
        lua_pushnil(lua);
        lua_pushliteral(lua, "the thread queue is empty");
        return 2;
    }

    xm_thread_value_t* item = (xm_thread_value_t*)tb_queue_get(thread_queue->handle);
    tb_assert_and_check_return_val(item, 0);

    tb_bool_t ok = tb_false;
    switch (item->kind)
    {
    case XM_THREAD_VALUE_STR:
        if (item->size)
            lua_pushlstring(lua, item->u.string, item->size);
        else lua_pushliteral(lua, "");
        ok = tb_true;
        break;
    case XM_THREAD_VALUE_INT:
        lua_pushinteger(lua, item->u.integer);
        ok = tb_true;
        break;
    case XM_THREAD_VALUE_NUM:
        lua_pushnumber(lua, item->u.number);
        ok = tb_true;
        break;
    case XM_THREAD_VALUE_BOOL:
        lua_pushboolean(lua, item->u.boolean);
        ok = tb_true;
        break;
    case XM_THREAD_VALUE_NIL:
        lua_pushnil(lua);
        ok = tb_true;
        break;
    default:
        break;
    }

    if (!ok)
    {
        lua_pushnil(lua);
        lua_pushliteral(lua, "invalid thread queue item");
        return 2;
    }

    tb_queue_pop(thread_queue->handle);
    return 1;
}

