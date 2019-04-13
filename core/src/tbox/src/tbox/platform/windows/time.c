/*!The Treasure Box Library
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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        utils.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../time.h"
#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) \
        && !defined(TB_CONFIG_MICRO_ENABLE)
#   include "../../coroutine/coroutine.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_void_t tb_usleep(tb_size_t us)
{
    Sleep(1);
}
tb_void_t tb_msleep(tb_size_t ms)
{
#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) \
        && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to sleep in coroutine
    if (tb_coroutine_self())
    {
        // sleep it
        tb_coroutine_sleep(ms);
        return ;
    }
#endif

    // sleep it
    Sleep((DWORD)ms);
}
tb_void_t tb_sleep(tb_size_t s)
{
    tb_msleep(s * 1000);
}
tb_hong_t tb_mclock()
{
    return (tb_hong_t)GetTickCount();
}
tb_hong_t tb_uclock()
{
    LARGE_INTEGER f = {{0}};
    if (!QueryPerformanceFrequency(&f)) return 0;
    tb_assert_and_check_return_val(f.QuadPart, 0);

    LARGE_INTEGER t = {{0}};
    if (!QueryPerformanceCounter(&t)) return 0;
    tb_assert_and_check_return_val(t.QuadPart, 0);
    
    return (t.QuadPart * 1000000) / f.QuadPart;
}
tb_bool_t tb_gettimeofday(tb_timeval_t* tv, tb_timezone_t* tz)
{
    union 
    {
        tb_uint64_t ns100; //< time since 1 Jan 1601 in 100ns units
        FILETIME    ft;

    }now;

    if (tv)
    {
        GetSystemTimeAsFileTime(&now.ft);
        tv->tv_sec  = (tb_time_t)((now.ns100 - 116444736000000000ULL) / 10000000ULL);
        tv->tv_usec = (tb_suseconds_t)((now.ns100 / 10ULL) % 1000000ULL);
    }

    // tz is not implementated now.
    tb_assert_and_check_return_val(!tz, tb_false);

    // ok
    return tb_true;
}
