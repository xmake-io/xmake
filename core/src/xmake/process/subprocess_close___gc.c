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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        subprocess_close___gc.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "subprocess_close___gc"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

static tb_int_t xm_subprocess_close_impl(lua_State* lua, tb_bool_t allow_closed_subprocess)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // close subprocess
    xm_subprocess_t* subprocess = xm_subprocess_get(lua);
    if (!subprocess->is_opened)
    {
        if (allow_closed_subprocess)
        {
            lua_pushboolean(lua, tb_true);
            xm_subprocess_return_success();
        }
        else xm_subprocess_return_error_closed(lua);
    }

    // check
    tb_assert(subprocess->process);

    // close process
    tb_process_exit(subprocess->process);
    subprocess->process   = tb_null;
    subprocess->is_opened = tb_false;

    // mark this subprocess as closed
    tb_strlcpy(subprocess->name, "subprocess: (closed subprocess)", tb_arrayn(subprocess->name));

    // close ok
    lua_pushboolean(lua, tb_true);
    xm_subprocess_return_success();
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*
 * subprocess:close()
 */
tb_int_t xm_process_subprocess_close(lua_State* lua)
{
    return xm_subprocess_close_impl(lua, tb_false);
}

/*
 * subprocess:close()
 */
tb_int_t xm_process_subprocess___gc(lua_State* lua)
{
    return xm_subprocess_close_impl(lua, tb_true);
}
