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
 * @file        gmtime.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "time.h"
#ifdef TB_CONFIG_LIBC_HAVE_GMTIME
#   include <time.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */

tb_bool_t tb_gmtime(tb_time_t time, tb_tm_t* tm)
{
#ifdef TB_CONFIG_LIBC_HAVE_GMTIME
    // gmtime
    time_t t = (time_t)time;
    struct tm* ptm = gmtime(&t);
    if (ptm && tm)
    {
        tm->second = ptm->tm_sec;
        tm->minute = ptm->tm_min;
        tm->hour = ptm->tm_hour;
        tm->mday = ptm->tm_mday;
        tm->month = ptm->tm_mon + 1;
        tm->year = ptm->tm_year + 1900;
        tm->week = ptm->tm_wday;
        tm->yday = ptm->tm_yday;
        tm->isdst = ptm->tm_isdst;
    }

    // ok?
    return ptm? tb_true : tb_false;
#else
    tb_trace_noimpl();
    return tb_false;
#endif
}

