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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        poller_remove.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "poller_remove"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "poller.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// io.poller_remove(obj:otype(), obj)
tb_int_t xm_io_poller_remove(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is pointer?
    if (!xm_lua_ispointer(lua, 2))
    {
        lua_pushboolean(lua, tb_false);
        lua_pushfstring(lua, "invalid poller object!");
        return 2;
    }

    // get otype
    tb_uint8_t otype = (tb_uint8_t)luaL_checknumber(lua, 1);

    // get cdata
    tb_pointer_t cdata = (tb_pointer_t)xm_lua_topointer(lua, 2);
    tb_check_return_val(cdata, 0);

    // remove events from poller
    tb_poller_object_t object;
    object.type    = otype;
    object.ref.ptr = cdata;
    lua_pushboolean(lua, tb_poller_remove(xm_io_poller(), &object));
    return 1;
}

