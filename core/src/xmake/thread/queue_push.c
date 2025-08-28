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
 * @file        thread_queue_lock.c
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
tb_int_t xm_thread_queue_push(lua_State* lua)
{
    tb_assert_and_check_return_val(lua, 0);

    xm_thread_queue_t* thread_queue = xm_thread_queue_get(lua, 1);
    tb_assert_and_check_return_val(thread_queue && thread_queue->handle, 0);

    if (tb_queue_full(thread_queue->handle))
    {
        lua_pushboolean(lua, tb_false);
        lua_pushliteral(lua, "the thread queue is full");
        return 2;
    }

    xm_thread_queue_item_t item;
    if (lua_isstring(lua, 2))
    {
        size_t data_size = 0;
        tb_char_t const* data = luaL_checklstring(lua, 2, &data_size);
        tb_assert_and_check_return_val(data, 0);

        item.kind = (tb_uint32_t)XM_THREAD_QUEUE_ITEM_STR;
        item.size = (tb_uint32_t)data_size;
        if (data_size)
        {
            item.u.string = tb_malloc_cstr(data_size);
            tb_assert_and_check_return_val(item.u.string, 0);
            tb_memcpy(item.u.string, data, data_size);
        }
    }
    else if (lua_isinteger(lua, 2))
    {
        item.kind = (tb_uint32_t)XM_THREAD_QUEUE_ITEM_INT;
        item.u.integer = lua_tointeger(lua, 2);
    }
    else if (lua_isnumber(lua, 2))
    {
        item.kind = (tb_uint32_t)XM_THREAD_QUEUE_ITEM_NUM;
        item.u.number = lua_tonumber(lua, 2);
    }
    else if (lua_isboolean(lua, 2))
    {
        item.kind = (tb_uint32_t)XM_THREAD_QUEUE_ITEM_BOOL;
        item.u.boolean = lua_toboolean(lua, 2);
    }
    else if (lua_isnil(lua, 2))
    {
        item.kind = (tb_uint32_t)XM_THREAD_QUEUE_ITEM_NIL;
    }
    else
    {
        lua_pushboolean(lua, tb_false);
        lua_pushliteral(lua, "unsupported thread queue item");
        return 2;
    }

    tb_queue_put(thread_queue->handle, &item);
    lua_pushboolean(lua, tb_true);
    return 1;
}

