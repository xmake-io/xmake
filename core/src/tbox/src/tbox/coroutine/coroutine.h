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
 * @file        coroutine.h
 * @defgroup    coroutine
 *
 */
#ifndef TB_COROUTINE_H
#define TB_COROUTINE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "lock.h"
#include "channel.h"
#include "semaphore.h"
#include "scheduler.h"
#include "stackless/stackless.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the coroutine ref type
typedef __tb_typeref__(coroutine);

/// the coroutine function type
typedef tb_void_t       (*tb_coroutine_func_t)(tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! start coroutine 
 *
 * @param scheduler     the scheduler, uses the current scheduler if be null
 * @param func          the coroutine function
 * @param priv          the passed user private data as the argument of function
 * @param stacksize     the stack size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_coroutine_start(tb_co_scheduler_ref_t scheduler, tb_coroutine_func_t func, tb_cpointer_t priv, tb_size_t stacksize);

/*! yield the current coroutine
 * 
 * @return              tb_true(yield ok) or tb_false(yield failed, no more coroutines)
 */
tb_bool_t               tb_coroutine_yield(tb_noarg_t);

/*! resume the given coroutine (suspended)
 *
 * @param coroutine     the suspended coroutine
 * @param priv          the user private data as the return value of suspend() or sleep()
 *
 * @return              the user private data from suspend(priv)
 */
tb_pointer_t            tb_coroutine_resume(tb_coroutine_ref_t coroutine, tb_cpointer_t priv);

/*! suspend the current coroutine
 *
 * @param priv          the user private data as the return value of resume() 
 *
 * @return              the user private data from resume(priv)
 */
tb_pointer_t            tb_coroutine_suspend(tb_cpointer_t priv);

/*! sleep some times (ms)
 *
 * @param interval      the interval (ms), infinity: -1
 *
 * @return              the user private data from resume(priv)
 */
tb_pointer_t            tb_coroutine_sleep(tb_long_t interval);

/*! wait io events 
 *
 * @param sock          the socket
 * @param events        the waited events, will remove this socket from io scheduler if be TB_SOCKET_EVENT_NONE
 * @param timeout       the timeout, infinity: -1
 *
 * @return              > 0: the events, 0: timeout, -1: failed
 */
tb_long_t               tb_coroutine_waitio(tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout);

/*! get the current coroutine
 *
 * @return              the current coroutine
 */
tb_coroutine_ref_t      tb_coroutine_self(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
