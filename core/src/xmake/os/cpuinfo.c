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
 * @file        cpuinfo.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "cpuinfo"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* local cpuinfo = os.cpuinfo()
 * {
 *      ncpu = 4,
 *      ...
 * }
 */
tb_int_t xm_os_cpuinfo(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // init table
    lua_newtable(lua);

    // get cpu number
    tb_int_t ncpu = (tb_int_t)tb_cpu_count();
    lua_pushstring(lua, "ncpu");
    lua_pushinteger(lua, ncpu > 0? ncpu : 1);
    lua_settable(lua, -3);

    return 1;
}
