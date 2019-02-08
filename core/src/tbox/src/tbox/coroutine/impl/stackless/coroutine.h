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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        coroutine.h
 *
 */
#ifndef TB_COROUTINE_IMPL_STACKLESS_COROUTINE_H
#define TB_COROUTINE_IMPL_STACKLESS_COROUTINE_H

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

// the coroutine wait type
typedef struct __tb_lo_coroutine_rs_wait_t
{
#ifndef TB_CONFIG_MICRO_ENABLE
    /* the timer task pointer for ltimer or timer
     *
     * for ltimer:  task
     * for timer:   task & 0x1
     */
    tb_cpointer_t               task;
#endif

    // the socket
    tb_socket_ref_t             sock;

    // the waiting events
    tb_sint32_t                 events          : 6;

    // the cached events
    tb_sint32_t                 events_cache    : 6;

    // the events result (may be -1)
    tb_sint32_t                 events_result   : 6;

    // is waiting?
    tb_sint32_t                 waiting         : 1;

}tb_lo_coroutine_rs_wait_t;

/// the stackless coroutine type
typedef struct __tb_lo_coroutine_t
{
    // the coroutine core
    tb_lo_core_t                core;

    // the list entry
    tb_list_entry_t             entry;

    // the coroutine function
    tb_lo_coroutine_func_t      func;

    // the user private data of the coroutine function
    tb_cpointer_t               priv;

    // the user private data free function
    tb_lo_coroutine_free_t      free;

    // the scheduler
    tb_lo_scheduler_ref_t       scheduler;

    // the passed private data between resume() and suspend()
    union 
    {
        // the arguments for wait()
        tb_lo_coroutine_rs_wait_t   wait;

    }                               rs;

}tb_lo_coroutine_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* init coroutine 
 *
 * @param scheduler     the scheduler
 * @param func          the coroutine function
 * @param priv          the passed user private data as the argument of function
 * @param free          the user private data free function
 *
 * @return              the coroutine 
 */
tb_lo_coroutine_t*      tb_lo_coroutine_init(tb_lo_scheduler_ref_t scheduler, tb_lo_coroutine_func_t func, tb_cpointer_t priv, tb_lo_coroutine_free_t free);

/* reinit the given coroutine 
 *
 * @param coroutine     the coroutine
 * @param func          the coroutine function
 * @param priv          the passed user private data as the argument of function
 * @param free          the user private data free function
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_lo_coroutine_reinit(tb_lo_coroutine_t* coroutine, tb_lo_coroutine_func_t func, tb_cpointer_t priv, tb_lo_coroutine_free_t free);

/* exit coroutine
 *
 * @param coroutine     the coroutine
 */
tb_void_t               tb_lo_coroutine_exit(tb_lo_coroutine_t* coroutine);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
