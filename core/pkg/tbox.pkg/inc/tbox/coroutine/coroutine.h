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
