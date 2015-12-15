/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
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
