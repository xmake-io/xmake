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
 * @file        thread_sharedata_set.c
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
tb_int_t xm_thread_sharedata_set(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    xm_thread_sharedata_t *thread_sharedata = xm_thread_sharedata_get(lua, 1);
    tb_assert_and_check_return_val(thread_sharedata, 0);

    if (lua_isstring(lua, 2)) {
        size_t           data_size = 0;
        tb_char_t const *data      = luaL_checklstring(lua, 2, &data_size);
        tb_assert_and_check_return_val(data, 0);

        thread_sharedata->value.kind = (tb_uint32_t)XM_THREAD_VALUE_STR;
        if (data_size) {
            tb_buffer_memncpy(&thread_sharedata->buffer, (tb_byte_t const *)data, data_size);
        }
        else {
            tb_buffer_clear(&thread_sharedata->buffer);
        }
    } else if (xm_lua_isinteger(lua, 2)) {
        thread_sharedata->value.kind      = (tb_uint32_t)XM_THREAD_VALUE_INT;
        thread_sharedata->value.u.integer = lua_tointeger(lua, 2);
    } else if (lua_isnumber(lua, 2)) {
        thread_sharedata->value.kind     = (tb_uint32_t)XM_THREAD_VALUE_NUM;
        thread_sharedata->value.u.number = lua_tonumber(lua, 2);
    } else if (lua_isboolean(lua, 2)) {
        thread_sharedata->value.kind      = (tb_uint32_t)XM_THREAD_VALUE_BOOL;
        thread_sharedata->value.u.boolean = lua_toboolean(lua, 2);
    } else if (lua_isnil(lua, 2)) {
        thread_sharedata->value.kind = (tb_uint32_t)XM_THREAD_VALUE_NIL;
    } else {
        lua_pushboolean(lua, tb_false);
        lua_pushliteral(lua, "unsupported thread sharedata item");
        return 2;
    }

    lua_pushboolean(lua, tb_true);
    return 1;
}
