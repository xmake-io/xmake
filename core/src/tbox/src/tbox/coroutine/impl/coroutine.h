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
 * @file        coroutine.h
 * @ingroup     coroutine
 *
 */
#ifndef TB_COROUTINE_IMPL_COROUTINE_H
#define TB_COROUTINE_IMPL_COROUTINE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// get scheduler
#define tb_coroutine_scheduler(coroutine)           ((coroutine)->scheduler)

// is original?
#define tb_coroutine_is_original(coroutine)         ((coroutine)->scheduler == (tb_co_scheduler_ref_t)(coroutine))

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the coroutine function type
typedef struct __tb_coroutine_rs_func_t
{
    // the function 
    tb_coroutine_func_t             func;

    // the user private data as the argument of function
    tb_cpointer_t                   priv;

}tb_coroutine_rs_func_t;

// the coroutine wait type
typedef struct __tb_coroutine_rs_wait_t
{
    /* the timer task pointer for ltimer or timer
     *
     * for ltimer:  task
     * for timer:   task & 0x1
     */
    tb_cpointer_t                   task;

    // the socket
    tb_socket_ref_t                 sock;

    // the waiting events
    tb_uint16_t                     events          : 6;

    // the cached events
    tb_uint16_t                     events_cache    : 6;

    // is waiting?
    tb_uint16_t                     waiting         : 1;

}tb_coroutine_rs_wait_t;

// the coroutine type
typedef struct __tb_coroutine_t
{
    /* the list entry for ready, suspend and dead lists
     *
     * be placed in the head for optimization
     */
    tb_list_entry_t                 entry;

    // the scheduler
    tb_co_scheduler_ref_t           scheduler;

    // the context 
    tb_context_ref_t                context;

    // the stack base (top)
    tb_byte_t*                      stackbase;

    // the stack size
    tb_size_t                       stacksize;

    // the passed user private data between priv = resume(priv) and priv = suspend(priv)
    tb_cpointer_t                   rs_priv;

    // the passed private data between resume() and suspend()
    union 
    {
        // the function
        tb_coroutine_rs_func_t      func;

        // the arguments for wait()
        tb_coroutine_rs_wait_t      wait;

        // the list entry
        tb_list_entry_t             entry;

        // the single entry
        tb_single_list_entry_t      single_entry;

    }                               rs;

    // the guard
    tb_uint16_t                     guard;

}tb_coroutine_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* init coroutine 
 *
 * @param scheduler     the scheduler
 * @param func          the coroutine function
 * @param priv          the passed user private data as the argument of function
 * @param stacksize     the stack size, uses the default stack size if be zero
 *
 * @return              the coroutine 
 */
tb_coroutine_t*         tb_coroutine_init(tb_co_scheduler_ref_t scheduler, tb_coroutine_func_t func, tb_cpointer_t priv, tb_size_t stacksize);

/* reinit the given coroutine 
 *
 * @param coroutine     the coroutine
 * @param func          the coroutine function
 * @param priv          the passed user private data as the argument of function
 * @param stacksize     the stack size, uses the default stack size if be zero
 *
 * @return              the coroutine
 */
tb_coroutine_t*         tb_coroutine_reinit(tb_coroutine_t* coroutine, tb_coroutine_func_t func, tb_cpointer_t priv, tb_size_t stacksize);

/* exit coroutine
 *
 * @param coroutine     the coroutine
 */
tb_void_t               tb_coroutine_exit(tb_coroutine_t* coroutine);

#ifdef __tb_debug__
/* check coroutine
 *
 * @param coroutine     the coroutine
 */
tb_void_t               tb_coroutine_check(tb_coroutine_t* coroutine);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
