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
 * @file        gmmktime.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "time.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */

tb_time_t tb_gmmktime(tb_tm_t const* tm)
{
    // check
    tb_assert_and_check_return_val(tm, -1);

    // done
    tb_long_t y = tm->year;
    tb_long_t m = tm->month;
    tb_long_t d = tm->mday;

    if (m < 3) 
    {
        m += 12;
        y--;
    }

    tb_time_t time = 86400 * (d + (153 * m - 457) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 719469);
    time += 3600 * tm->hour;
    time += 60 * tm->minute;
    time += tm->second;

    // time
    return time;
}

