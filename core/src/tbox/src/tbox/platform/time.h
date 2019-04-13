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
 * @file        time.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_TIME_H
#define TB_PLATFORM_TIME_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! usleep
 *
 * @param us    the microsecond time
 */
tb_void_t       tb_usleep(tb_size_t us);

/*! msleep
 *
 * @param ms    the millisecond time
 */
tb_void_t       tb_msleep(tb_size_t ms);

/*! sleep
 *
 * @param s     the second time
 */
tb_void_t       tb_sleep(tb_size_t s);

/*! clock, ms
 *
 * @return      the mclock
 */
tb_hong_t       tb_mclock(tb_noarg_t);

/*! uclock, us
 *
 * @return      the uclock
 */
tb_hong_t       tb_uclock(tb_noarg_t);

/*! get the time from 1970-01-01 00:00:00:000
 *
 * @param tv    the timeval
 * @param tz    the timezone
 *
 * @return      tb_true or tb_false
 */
tb_bool_t       tb_gettimeofday(tb_timeval_t* tv, tb_timezone_t* tz);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
