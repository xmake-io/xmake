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
#   include <sys/sysctl.h>
#   include <mach/mach.h>
#   include <mach/machine.h>
#   include <mach-o/dyld.h>
#   include <mach-o/nlist.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

// get the used memory size (MB)
static tb_bool_t xm_os_meminfo_vmstats(tb_int_t* vm_totalsize, tb_int_t* vm_availsize)
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
        *vm_totalsize = (tb_int_t)(totalsize / (1024 * 1024));
        *vm_availsize = (tb_int_t)(availsize / (1024 * 1024));
        return tb_true;
    }
#endif
    return tb_false;
}

// get the total physical memory size (MB)
static tb_int_t xm_os_meminfo_physmem()
{
#if defined(TB_CONFIG_OS_MACOSX)
    tb_int_t mib[] = { CTL_HW, HW_MEMSIZE };
    tb_int64_t value = 0;
    size_t length = sizeof(value);
    if (sysctl(mib, 2, &value, &length, tb_null, 0) == 0)
        return (tb_int_t)(value / (1024 * 1024));
#endif
    return 0;
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

    // get the pagesize
    tb_int_t pagesize = (tb_int_t)tb_page_size();
    lua_pushstring(lua, "pagesize");
    lua_pushinteger(lua, pagesize);
    lua_settable(lua, -3);

    // get the total memory size
    tb_int_t physmem = xm_os_meminfo_physmem();
    lua_pushstring(lua, "physmem");
    lua_pushinteger(lua, physmem);
    lua_settable(lua, -3);

    // get the vm memory info
    tb_int_t vm_availsize = 0;
    tb_int_t vm_totalsize = 0;
    if (xm_os_meminfo_vmstats(&vm_totalsize, &vm_availsize))
    {
        lua_pushstring(lua, "vm_totalsize");
        lua_pushinteger(lua, vm_totalsize);
        lua_settable(lua, -3);

        lua_pushstring(lua, "vm_availsize");
        lua_pushinteger(lua, vm_availsize);
        lua_settable(lua, -3);
    }

    return 1;
}
