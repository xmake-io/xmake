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
 * @file        scheduler.h
 * @ingroup     coroutine
 *
 */
#ifndef TB_COROUTINE_STACKLESS_SCHEDULER_H
#define TB_COROUTINE_STACKLESS_SCHEDULER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the self scheduler
#define tb_lo_scheduler_self()          tb_lo_coroutine_scheduler_(co__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init scheduler 
 *
 * @return              the scheduler 
 */
tb_lo_scheduler_ref_t   tb_lo_scheduler_init(tb_noarg_t);

/*! exit scheduler
 *
 * @param scheduler     the scheduler
 */
tb_void_t               tb_lo_scheduler_exit(tb_lo_scheduler_ref_t scheduler);

/* kill the scheduler 
 *
 * @param scheduler     the scheduler
 */
tb_void_t               tb_lo_scheduler_kill(tb_lo_scheduler_ref_t scheduler);

/*! run the scheduler loop
 *
 * @param scheduler     the scheduler
 * @param exclusive     enable exclusive mode, we need ensure only one loop() be called at the same time, 
 *                      but it will be faster using thr global scheduler instead of TLS storage
 */
tb_void_t               tb_lo_scheduler_loop(tb_lo_scheduler_ref_t scheduler, tb_bool_t exclusive);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
