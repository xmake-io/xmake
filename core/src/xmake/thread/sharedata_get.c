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
 * @file        thread_sharedata_get.c
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
tb_int_t xm_thread_sharedata_get_(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    xm_thread_sharedata_t *thread_sharedata = xm_thread_sharedata_get(lua, 1);
    tb_assert_and_check_return_val(thread_sharedata, 0);

    tb_bool_t ok = tb_false;
    switch (thread_sharedata->value.kind) {
    case XM_THREAD_VALUE_STR:
        if (tb_buffer_size(&thread_sharedata->buffer) > 0) {
            lua_pushlstring(lua,
                            (tb_char_t *)tb_buffer_data(&thread_sharedata->buffer),
                            tb_buffer_size(&thread_sharedata->buffer));
        } else {
            lua_pushliteral(lua, "");
        }
        ok = tb_true;
        break;
    case XM_THREAD_VALUE_INT:
        lua_pushinteger(lua, thread_sharedata->value.u.integer);
        ok = tb_true;
        break;
    case XM_THREAD_VALUE_NUM:
        lua_pushnumber(lua, thread_sharedata->value.u.number);
        ok = tb_true;
        break;
    case XM_THREAD_VALUE_BOOL:
        lua_pushboolean(lua, thread_sharedata->value.u.boolean);
        ok = tb_true;
        break;
    case XM_THREAD_VALUE_NIL:
        lua_pushnil(lua);
        ok = tb_true;
        break;
    default:
        break;
    }

    if (!ok) {
        lua_pushnil(lua);
        lua_pushliteral(lua, "invalid thread sharedata thread_sharedata");
        return 2;
    }

    return 1;
}
