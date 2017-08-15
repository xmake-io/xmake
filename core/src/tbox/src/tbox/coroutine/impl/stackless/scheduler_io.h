/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        scheduler_io.h
 * @ingroup     coroutine
 *
 */
#ifndef TB_COROUTINE_IMPL_STACKLESS_SCHEDULER_IO_H
#define TB_COROUTINE_IMPL_STACKLESS_SCHEDULER_IO_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "scheduler.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the io scheduler type
typedef struct __tb_lo_scheduler_io_t
{
    // is stopped?
    tb_bool_t           stop;

    // the scheduler 
    tb_lo_scheduler_t*  scheduler;

    // the poller
    tb_poller_ref_t     poller;

#ifndef TB_CONFIG_MICRO_ENABLE
    // the timer
    tb_timer_ref_t      timer;

    // the low-precision timer (faster)
    tb_ltimer_ref_t     ltimer;
#endif

}tb_lo_scheduler_io_t, *tb_lo_scheduler_io_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* init io scheduler 
 *
 * @return                  the io scheduler 
 */
tb_lo_scheduler_io_ref_t    tb_lo_scheduler_io_init(tb_lo_scheduler_t* scheduler);

/* exit io scheduler 
 *
 * @param scheduler_io      the io scheduler
 */
tb_void_t                   tb_lo_scheduler_io_exit(tb_lo_scheduler_io_ref_t scheduler_io);

/* kill the current io scheduler 
 *
 * @param scheduler_io      the io scheduler
 */
tb_void_t                   tb_lo_scheduler_io_kill(tb_lo_scheduler_io_ref_t scheduler_io);

/* sleep the current coroutine
 *
 * @param scheduler_io      the io scheduler
 * @param interval          the interval (ms), infinity: -1
 */
tb_void_t                   tb_lo_scheduler_io_sleep(tb_lo_scheduler_io_ref_t scheduler_io, tb_long_t interval);

/* wait io events 
 *
 * @param scheduler_io      the io scheduler
 * @param sock              the socket
 * @param events            the waited events
 * @param timeout           the timeout, infinity: -1
 *
 * @return                  suspend coroutine if be tb_true
 */
tb_bool_t                   tb_lo_scheduler_io_wait(tb_lo_scheduler_io_ref_t scheduler_io, tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout);

/*! cancel io events for the given socket 
 *
 * @param scheduler_io      the io scheduler
 * @param sock              the socket
 *
 * return                   tb_true or tb_false
 */
tb_bool_t                   tb_lo_scheduler_io_cancel(tb_lo_scheduler_io_ref_t scheduler_io, tb_socket_ref_t sock);

/* get the current io scheduler
 *
 * @return                  the io scheduler
 */
tb_lo_scheduler_io_ref_t    tb_lo_scheduler_io_self(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
