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
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        scheduler.h
 * @ingroup     coroutine
 *
 */
#ifndef TB_COROUTINE_SCHEDULER_H
#define TB_COROUTINE_SCHEDULER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the coroutine scheduler ref type
typedef __tb_typeref__(co_scheduler);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init scheduler 
 *
 * @return              the scheduler 
 */
tb_co_scheduler_ref_t   tb_co_scheduler_init(tb_noarg_t);

/*! exit scheduler
 *
 * @param scheduler     the scheduler
 */
tb_void_t               tb_co_scheduler_exit(tb_co_scheduler_ref_t scheduler);

/* kill the scheduler 
 *
 * @param scheduler     the scheduler
 */
tb_void_t               tb_co_scheduler_kill(tb_co_scheduler_ref_t scheduler);

/*! run the scheduler loop
 *
 * @param scheduler     the scheduler
 * @param exclusive     enable exclusive mode, we need ensure only one loop() be called at the same time, 
 *                      but it will be faster using thr global scheduler instead of TLS storage
 */
tb_void_t               tb_co_scheduler_loop(tb_co_scheduler_ref_t schedule, tb_bool_t exclusive);

/*! get the scheduler of the current coroutine
 *
 * @return              the scheduler
 */
tb_co_scheduler_ref_t   tb_co_scheduler_self(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
