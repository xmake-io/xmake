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
 * @file        cache_time.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_CACHE_TIME_H
#define TB_PLATFORM_CACHE_TIME_H

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

/*! the cached time, like tb_time
 *
 * lower accuracy and faster
 *
 * @return          the now time, s
 */
tb_time_t           tb_cache_time(tb_noarg_t);

/*! spak cached time 
 *
 * update the cached time for the external loop thread
 *
 * @return          the now ms-clock
 */
tb_hong_t           tb_cache_time_spak(tb_noarg_t);

/*! the cached ms-clock
 *
 * lower accuracy and faster
 *
 * @return          the now ms-clock
 */
tb_hong_t           tb_cache_time_mclock(tb_noarg_t);

/*! the cached s-clock
 *
 * lower accuracy and faster
 *
 * @return          the now s-clock
 */
tb_hong_t           tb_cache_time_clock(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
