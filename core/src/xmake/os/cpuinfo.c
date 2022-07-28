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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
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
#if defined(TB_CONFIG_OS_MACOSX)
#   include <sys/sysctl.h>
#   include <sys/types.h>
#   include <mach/mach.h>
#   include <mach/processor_info.h>
#   include <mach/mach_host.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_float_t xm_os_cpuinfo_usagerate()
{
#if defined(TB_CONFIG_OS_MACOSX)
    tb_float_t usagerate = 0;
    natural_t cpu_count = 0;
    processor_info_array_t cpuinfo;
    mach_msg_type_number_t cpuinfo_count;
    static tb_hong_t s_time = 0;
    if (tb_mclock() - s_time > 1000 && host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpu_count, &cpuinfo, &cpuinfo_count) == KERN_SUCCESS)
    {
        static processor_info_array_t s_cpuinfo_prev = tb_null;
        static mach_msg_type_number_t s_cpuinfo_count_prev = 0;
        for (tb_int_t i = 0; i < cpu_count; ++i)
        {
            tb_int_t use, total;
            if (s_cpuinfo_prev)
            {
                use = (cpuinfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - s_cpuinfo_prev[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                      + (cpuinfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - s_cpuinfo_prev[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                      + (cpuinfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - s_cpuinfo_prev[(CPU_STATE_MAX * i) + CPU_STATE_NICE]);
                total = use + (cpuinfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - s_cpuinfo_prev[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            }
            else
            {
                use = cpuinfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + cpuinfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + cpuinfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                total = use + cpuinfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }
            usagerate += total > 0? ((tb_float_t)use / (tb_float_t)total) : 0;
        }
        if (s_cpuinfo_prev)
            vm_deallocate(mach_task_self(), (vm_address_t)s_cpuinfo_prev, sizeof(integer_t) * s_cpuinfo_count_prev);
        s_time = tb_mclock();
        s_cpuinfo_prev = cpuinfo;
        s_cpuinfo_count_prev = cpuinfo_count;
    }
    return cpu_count > 0? usagerate / cpu_count : 0;
#else
    return 0;
#endif
}

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

    // get cpu usage rate
    tb_float_t usagerate = xm_os_cpuinfo_usagerate();
    if (usagerate > 0)
    {
        lua_pushstring(lua, "usagerate");
        lua_pushnumber(lua, usagerate);
        lua_settable(lua, -3);
    }
    return 1;
}
