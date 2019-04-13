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
 * @file        mktime.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "time.h"
#ifdef TB_CONFIG_LIBC_HAVE_MKTIME
#   include <time.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */

tb_time_t tb_mktime(tb_tm_t const* tm)
{
    // check
    tb_assert_and_check_return_val(tm, -1);

#ifdef TB_CONFIG_LIBC_HAVE_MKTIME
    // init
    struct tm t = {0};
    t.tm_sec    = (tb_int_t)tm->second;
    t.tm_min    = (tb_int_t)tm->minute;
    t.tm_hour   = (tb_int_t)tm->hour;
    t.tm_mday   = (tb_int_t)tm->mday;
    t.tm_mon    = (tb_int_t)tm->month - 1;
    t.tm_year   = (tb_int_t)(tm->year > 1900? tm->year - 1900 : tm->year);
    t.tm_wday   = (tb_int_t)tm->week;
    t.tm_yday   = (tb_int_t)tm->yday;
    t.tm_isdst  = (tb_int_t)tm->isdst;
    
    // mktime
    return (tb_time_t)mktime(&t);
#else
    // GMT+8 for beijing.china.
    tb_time_t time = tb_gmmktime(tm);
    return time >= 8 * 3600? time - 8 * 3600: -1;
#endif
}

