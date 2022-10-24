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
 * @file        meminfo.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "meminfo"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_CONFIG_OS_MACOSX)
#   include <mach/mach.h>
#   include <mach/machine.h>
#   include <mach/vm_statistics.h>
#   include <mach-o/dyld.h>
#   include <mach-o/nlist.h>
#elif defined(TB_CONFIG_OS_LINUX)
#   include <stdio.h>
#   include <sys/sysinfo.h>
#elif defined(TB_CONFIG_OS_WINDOWS)
#   include <windows.h>
#elif defined(TB_CONFIG_OS_BSD)
#   include <sys/types.h>
#   include <sys/sysctl.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#ifdef TB_CONFIG_OS_LINUX
static tb_int64_t xm_os_meminfo_get_value(tb_char_t const* buffer, tb_char_t const* name)
{
    tb_char_t const* p = tb_strstr(buffer, name);
    return p? tb_stoi64(p + tb_strlen(name)) : 0;
}
#endif

// get the used memory size (MB)
static tb_bool_t xm_os_meminfo_stats(tb_int_t* ptotalsize, tb_int_t* pavailsize)
{
#if defined(TB_CONFIG_OS_MACOSX)
    vm_statistics64_data_t vmstat;
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info_t) &vmstat, &count) == KERN_SUCCESS)
    {
        tb_int_t pagesize = (tb_int_t)tb_page_size();
        tb_int64_t totalsize = (tb_int64_t)(vmstat.inactive_count + vmstat.free_count + vmstat.active_count + vmstat.wire_count + vmstat.compressor_page_count) * pagesize;
        /*
         * NB: speculative pages are already accounted for in "free_count",
         * so "speculative_count" is the number of "free" pages that are
         * used to hold data that was read speculatively from disk but
         * haven't actually been used by anyone so far.
         *
         */
        tb_int64_t availsize = (tb_int64_t)(vmstat.inactive_count + vmstat.free_count - vmstat.speculative_count) * pagesize;
        *ptotalsize = (tb_int_t)(totalsize / (1024 * 1024));
        *pavailsize = (tb_int_t)(availsize / (1024 * 1024));
        return tb_true;
    }
#elif defined(TB_CONFIG_OS_LINUX)
    /* we get meminfo from /proc/meminfo
     *
     * @see https://github.com/rfjakob/earlyoom/blob/cba1d599e4a7484c45ac017aa7702ff879f15846/meminfo.c#L52
     */
    if (tb_file_info("/proc/meminfo", tb_null))
    {
        tb_bool_t ok = tb_false;
        FILE* fp = fopen("/proc/meminfo", "r");
        if (fp)
        {
            // 8192 should be enough for the foreseeable future.
            tb_char_t buffer[8192];
            size_t len = fread(buffer, 1, sizeof(buffer) - 1, fp);
            if (!ferror(fp) && len)
            {
                tb_int64_t totalsize = xm_os_meminfo_get_value(buffer, "MemTotal:");
                tb_int64_t availsize = xm_os_meminfo_get_value(buffer, "MemAvailable:");
                if (availsize <= 0)
                {
                    tb_int64_t cachesize  = xm_os_meminfo_get_value(buffer, "Cached:");
                    tb_int64_t freesize   = xm_os_meminfo_get_value(buffer, "MemFree:");
                    tb_int64_t buffersize = xm_os_meminfo_get_value(buffer, "Buffers:");
                    tb_int64_t shmemsize  = xm_os_meminfo_get_value(buffer, "Shmem:");
                    if (cachesize >= 0 && freesize >= 0 && buffersize >= 0 && shmemsize >= 0)
                        availsize = freesize + buffersize + cachesize - shmemsize;
                }
                if (totalsize > 0 && availsize >= 0)
                {
                    *ptotalsize = (tb_int_t)(totalsize / 1024);
                    *pavailsize = (tb_int_t)(availsize / 1024);
                    ok = tb_true;
                }
            }
            fclose(fp);
        }
        return ok;
    }
    else
    {
        struct sysinfo info = {0};
        if (sysinfo(&info) == 0)
        {
            *ptotalsize = (tb_int_t)(info.totalram / (1024 * 1024));
            *pavailsize = (tb_int_t)((info.freeram + info.bufferram/* + cache size */) / (1024 * 1024));
            return tb_true;
        }
    }
#elif defined(TB_CONFIG_OS_WINDOWS)
    MEMORYSTATUSEX statex;
    statex.dwLength = sizeof(statex);
    if (GlobalMemoryStatusEx(&statex))
    {
        *ptotalsize = (tb_int_t)(statex.ullTotalPhys / (1024 * 1024));
        *pavailsize = (tb_int_t)(statex.ullAvailPhys / (1024 * 1024));
        return tb_true;
    }
#elif defined(TB_CONFIG_OS_BSD) && !defined(__OpenBSD__)
    unsigned long totalsize;
    size_t size = sizeof(totalsize);
    if (sysctlbyname("hw.physmem", &totalsize, &size, tb_null, 0) != 0)
        return tb_false;

    // http://web.mit.edu/freebsd/head/usr.bin/systat/vmstat.c
    tb_uint32_t v_free_count;
    size = sizeof(v_free_count);
    if (sysctlbyname("vm.stats.vm.v_free_count", &v_free_count, &size, tb_null, 0) != 0)
        return tb_false;

    tb_uint32_t v_inactive_count;
    size = sizeof(v_inactive_count);
    if (sysctlbyname("vm.stats.vm.v_inactive_count", &v_inactive_count, &size, tb_null, 0) != 0)
        return tb_false;

    *ptotalsize = (tb_int_t)(totalsize / (1024 * 1024));
    *pavailsize = (tb_int_t)(((tb_int64_t)(v_free_count + v_inactive_count) * tb_page_size()) / (1024 * 1024));
    return tb_true;
#endif
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_meminfo(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // init table
    lua_newtable(lua);

    // get the pagesize (bytes)
    tb_int_t pagesize = (tb_int_t)tb_page_size();
    lua_pushstring(lua, "pagesize");
    lua_pushinteger(lua, pagesize);
    lua_settable(lua, -3);

    // get the memory size (MB)
    tb_int_t availsize = 0;
    tb_int_t totalsize = 0;
    if (xm_os_meminfo_stats(&totalsize, &availsize))
    {
        lua_pushstring(lua, "totalsize");
        lua_pushinteger(lua, totalsize);
        lua_settable(lua, -3);

        lua_pushstring(lua, "availsize");
        lua_pushinteger(lua, availsize);
        lua_settable(lua, -3);
    }

    return 1;
}
