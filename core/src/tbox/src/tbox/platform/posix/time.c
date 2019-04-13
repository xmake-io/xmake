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
 * @file        time.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../time.h"
#include <unistd.h>
#include <time.h>
#include <stdio.h>
#include <sys/time.h>
#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) \
        && !defined(TB_CONFIG_MICRO_ENABLE)
#   include "../../coroutine/coroutine.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_void_t tb_usleep(tb_size_t us)
{
    usleep(us);
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
    tb_usleep(ms * 1000);
}

tb_void_t tb_sleep(tb_size_t s)
{
    tb_msleep(s * 1000);
}
tb_hong_t tb_mclock()
{
    tb_timeval_t tv = {0};
    if (!tb_gettimeofday(&tv, tb_null)) return -1;
    return ((tb_hong_t)tv.tv_sec * 1000 + tv.tv_usec / 1000);
}
tb_hong_t tb_uclock()
{
    tb_timeval_t tv = {0};
    if (!tb_gettimeofday(&tv, tb_null)) return -1;
    return ((tb_hong_t)tv.tv_sec * 1000000 + tv.tv_usec);
}
tb_bool_t tb_gettimeofday(tb_timeval_t* tv, tb_timezone_t* tz)
{
    // gettimeofday
    struct timeval ttv = {0};
    struct timezone ttz = {0};
    if (gettimeofday(&ttv, &ttz)) return tb_false;

    // tv
    if (tv) 
    {
        tv->tv_sec = (tb_time_t)ttv.tv_sec;
        tv->tv_usec = (tb_suseconds_t)ttv.tv_usec;
    }

    // tz
    if (tz) 
    {
        tz->tz_minuteswest = ttz.tz_minuteswest;
        tz->tz_dsttime = ttz.tz_dsttime;
    }

    // ok
    return tb_true;
}
