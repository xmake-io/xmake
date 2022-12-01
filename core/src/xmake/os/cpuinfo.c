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
#elif defined(TB_CONFIG_OS_WINDOWS)
#   include <windows.h>
#elif defined(TB_CONFIG_OS_LINUX)
#   include <stdio.h>
#elif defined(TB_CONFIG_OS_BSD)
#   include <stdio.h>
#   include <string.h>
#   include <sys/types.h>
#   include <sys/sysctl.h>
#   include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#if defined(TB_CONFIG_OS_WINDOWS)
static tb_uint64_t xm_os_cpuinfo_subtract_times(FILETIME const* one, FILETIME const* two)
{
    LARGE_INTEGER a, b;
    a.LowPart  = one->dwLowDateTime;
    a.HighPart = one->dwHighDateTime;

    b.LowPart  = two->dwLowDateTime;
    b.HighPart = two->dwHighDateTime;

    return (tb_uint64_t)(a.QuadPart - b.QuadPart);
}
#endif

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
#elif defined(TB_CONFIG_OS_WINDOWS)
    // kernel include idle_time
    tb_float_t usagerate = 0;
    FILETIME idle, kernel, user;
    if (GetSystemTimes(&idle, &kernel, &user))
    {
        static FILETIME idle_prev = {0};
        static FILETIME kernel_prev = {0};
        static FILETIME user_prev = {0};

        if (idle_prev.dwLowDateTime != 0 && idle_prev.dwHighDateTime != 0)
        {
            tb_uint64_t idle_diff = xm_os_cpuinfo_subtract_times(&idle, &idle_prev);
            tb_uint64_t kernel_diff = xm_os_cpuinfo_subtract_times(&kernel, &kernel_prev);
            tb_uint64_t user_diff = xm_os_cpuinfo_subtract_times(&user, &user_prev);

            // kernel_time - idle_time = kernel_time, because kernel include idle_time
            tb_uint64_t sys_total = kernel_diff + user_diff;
            tb_uint64_t kernel_total = kernel_diff - idle_diff;

            // sometimes kernel_time > idle_time
            if (sys_total > 0)
                usagerate = (tb_float_t)((tb_double_t)(kernel_total + user_diff) / sys_total);
        }

        idle_prev = idle;
        kernel_prev = kernel;
        user_prev = user;
    }
    return usagerate;
#elif defined(TB_CONFIG_OS_LINUX)
    tb_float_t usagerate = 0;
    if (tb_file_info("/proc/stat", tb_null))
    {
        tb_bool_t ok = tb_false;
        FILE* fp = fopen("/proc/stat", "r");
        if (fp)
        {
            tb_char_t line[8192];
            static tb_int64_t total_prev = 0;
            static tb_int64_t active_prev = 0;
            while (!feof(fp))
            {
                /* cpu  548760 0 867417 102226682 12430 0 9089 0 0 0
                 * cpu0 136863 0 218110 25632388 2706 0 2328 0 0 0
                 * cpu1 148383 0 213941 25627686 3925 0 2129 0 0 0
                 *
                 * The meanings of the columns are as follows, from left to right:
                 *
                 * user: normal processes executing in user mode
                 * nice: niced processes executing in user mode
                 * system: processes executing in kernel mode
                 * idle: twiddling thumbs
                 * iowait: waiting for I/O to complete
                 * irq: servicing interrupts
                 * softirq: servicing softirqs
                 * steal
                 * guest
                 * guest_nice
                 */
                if (fgets(line, sizeof(line), fp) && !tb_strncmp(line, "cpu ", 4))
                {
                    long long user, nice, sys, idle, iowait, irq, softirq, steal, guest, guest_nice;
                    if (10 == sscanf(line, "cpu  %lld %lld %lld %lld %lld %lld %lld %lld %lld %lld",
                            &user, &nice, &sys, &idle, &iowait, &irq, &softirq, &steal, &guest, &guest_nice))
                    {
                        tb_int64_t active = (tb_int64_t)(user + nice + sys + irq + softirq + steal + guest + guest_nice);
                        tb_int64_t total = (tb_int64_t)(user + nice + sys + idle + iowait + irq + softirq + steal + guest + guest_nice);
                        if (total_prev > 0 && active_prev > 0)
                        {
                            tb_int64_t total_diff = total - total_prev;
                            tb_int64_t active_diff = active - active_prev;
                            if (total_diff > 0)
                                usagerate = (tb_float_t)((tb_double_t)active_diff / total_diff);
                        }
                        total_prev = total;
                        active_prev = active;
                    }
                    break;
                }
            }
            fclose(fp);
        }
    }
    return usagerate;
#elif defined(TB_CONFIG_OS_BSD) && !defined(__OpenBSD__)
#   define CP_USER   0
#   define CP_NICE   1
#   define CP_SYS    2
#   define CP_INTR   3
#   define CP_IDLE   4
#   define CPUSTATES 5

    static tb_int64_t total_prev = 0;
    static tb_int64_t active_prev = 0;

    tb_float_t usagerate = 0;
    long states[CPUSTATES] = {0};
    size_t states_size = sizeof(states);
    if (sysctlbyname("kern.cp_time", &states, &states_size, tb_null, 0) == 0)
    {
        tb_long_t user = states[CP_USER];
        tb_long_t nice = states[CP_NICE];
        tb_long_t sys = states[CP_SYS];
        tb_long_t intr = states[CP_INTR];
        tb_long_t idle = states[CP_IDLE];

        tb_int64_t active = user + nice + sys + intr;
        tb_int64_t total = user + nice + sys + idle + intr;
        if (total_prev > 0 && active_prev > 0)
        {
            tb_int64_t total_diff = total - total_prev;
            tb_int64_t active_diff = active - active_prev;
            if (total_diff > 0)
                usagerate = (tb_float_t)((tb_double_t)active_diff / total_diff);
        }
        total_prev = total;
        active_prev = active;
    }
    return usagerate;
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
    if (usagerate >= 0)
    {
        lua_pushstring(lua, "usagerate");
        lua_pushnumber(lua, usagerate);
        lua_settable(lua, -3);
    }
    return 1;
}
