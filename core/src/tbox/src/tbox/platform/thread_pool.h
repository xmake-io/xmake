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
 * @file        thread_pool.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_THREAD_POOL_H
#define TB_PLATFORM_THREAD_POOL_H

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

/// the thread pool worker private data maximum count
#ifdef __tb_small__
#   define TB_THREAD_POOL_WORKER_PRIV_MAXN      (16)
#else
#   define TB_THREAD_POOL_WORKER_PRIV_MAXN      (32)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the thread pool ref type
typedef __tb_typeref__(thread_pool);

/// the thread pool task ref type
typedef __tb_typeref__(thread_pool_task);

/// the thread pool worker ref type
typedef __tb_typeref__(thread_pool_worker);

/// the thread pool priv exit func type
typedef tb_void_t                       (*tb_thread_pool_priv_exit_func_t)(tb_thread_pool_worker_ref_t worker, tb_cpointer_t priv);

/// the thread pool task done func type
typedef tb_void_t                       (*tb_thread_pool_task_done_func_t)(tb_thread_pool_worker_ref_t worker, tb_cpointer_t priv);

/// the thread pool task exit func type
typedef tb_void_t                       (*tb_thread_pool_task_exit_func_t)(tb_thread_pool_worker_ref_t worker, tb_cpointer_t priv);

/// the thread pool task type
typedef struct __tb_thread_pool_task_t
{
    /// the task name
    tb_char_t const*                    name;

    /// the task done func
    tb_thread_pool_task_done_func_t     done;

    /// the task exit func for freeing the private data
    tb_thread_pool_task_exit_func_t     exit;

    /// the task private data
    tb_cpointer_t                       priv;

    /// is urgent task?
    tb_bool_t                           urgent;

}tb_thread_pool_task_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the thread pool instance
 *
 * @return                  the thread pool 
 */
tb_thread_pool_ref_t        tb_thread_pool(tb_noarg_t);

/*! init thread pool
 *
 * @param worker_maxn       the thread worker max count, using the default count
 * @param stack             the thread stack, using the default stack size if be zero 
 *
 * @return                  the thread pool 
 */
tb_thread_pool_ref_t        tb_thread_pool_init(tb_size_t worker_maxn, tb_size_t stack);

/*! exit thread pool
 *
 * @param pool              the thread pool 
 *
 * @return                  tb_true or tb_false
 */
tb_bool_t                   tb_thread_pool_exit(tb_thread_pool_ref_t pool);

/*! kill thread pool, all workers and waiting tasks 
 *
 * @param pool              the thread pool 
 */
tb_void_t                   tb_thread_pool_kill(tb_thread_pool_ref_t pool);

/*! the current worker count
 *
 * @param pool              the thread pool 
 *
 * @return                  the current worker count
 */
tb_size_t                   tb_thread_pool_worker_size(tb_thread_pool_ref_t pool);

/*! set the worker private data
 *
 * @param worker            the thread pool worker
 * @param index             the private data index
 * @param exit              the private data exit func
 * @param priv              the private data
 */
tb_void_t                   tb_thread_pool_worker_setp(tb_thread_pool_worker_ref_t worker, tb_size_t index, tb_thread_pool_priv_exit_func_t exit, tb_cpointer_t priv);

/*! get the worker private data
 *
 * @param worker            the thread pool worker
 * @param index             the private data index
 *
 * @return                  the private data
 */
tb_cpointer_t               tb_thread_pool_worker_getp(tb_thread_pool_worker_ref_t worker, tb_size_t index);

/*! the current waiting task count
 *
 * @param pool              the thread pool 
 *
 * @return                  the current task count
 */
tb_size_t                   tb_thread_pool_task_size(tb_thread_pool_ref_t pool);

/*! post one task
 *
 * @param pool              the thread pool 
 * @param name              the task name, optional
 * @param done              the task done func
 * @param exit              the task exit func, optional
 * @param priv              the task private data
 * @param urgent            is urgent task?
 *
 * @return                  tb_true or tb_false
 */
tb_bool_t                   tb_thread_pool_task_post(tb_thread_pool_ref_t pool, tb_char_t const* name, tb_thread_pool_task_done_func_t done, tb_thread_pool_task_exit_func_t exit, tb_cpointer_t priv, tb_bool_t urgent);

/*! post task list
 *
 * @param pool              the thread pool 
 * @param list              the task list
 * @param size              the task count
 *
 * @return                  the real posted task count
 */
tb_size_t                   tb_thread_pool_task_post_list(tb_thread_pool_ref_t pool, tb_thread_pool_task_t const* list, tb_size_t size);

/*! init one task
 *
 * @param pool              the thread pool 
 * @param name              the task name, optional
 * @param done              the task done func
 * @param exit              the task exit func, optional
 * @param priv              the task private data
 * @param urgent            is urgent task?
 *
 * @return                  the thread pool task
 */
tb_thread_pool_task_ref_t   tb_thread_pool_task_init(tb_thread_pool_ref_t pool, tb_char_t const* name, tb_thread_pool_task_done_func_t done, tb_thread_pool_task_exit_func_t exit, tb_cpointer_t priv, tb_bool_t urgent);

/*! kill the waiting task
 *
 * @param pool              the thread pool 
 * @param task              the task handle
 */
tb_void_t                   tb_thread_pool_task_kill(tb_thread_pool_ref_t pool, tb_thread_pool_task_ref_t task);

/*! kill all waiting tasks
 *
 * @param pool              the thread pool 
 */
tb_void_t                   tb_thread_pool_task_kill_all(tb_thread_pool_ref_t pool);

/*! wait one task 
 *
 * @param pool              the thread pool 
 * @param task              the thread pool task 
 * @param timeout           the timeout
 *
 * @return                  ok: 1, timeout: 0, error: -1
 */
tb_long_t                   tb_thread_pool_task_wait(tb_thread_pool_ref_t pool, tb_thread_pool_task_ref_t task, tb_long_t timeout);

/*! wait all waiting tasks
 *
 * @param pool              the thread pool 
 * @param timeout           the timeout
 *
 * @return                  ok: 1, timeout: 0, error: -1
 */
tb_long_t                   tb_thread_pool_task_wait_all(tb_thread_pool_ref_t pool, tb_long_t timeout);

/*! exit the task
 *
 * @param pool              the thread pool 
 * @param task              the thread pool task 
 */
tb_void_t                   tb_thread_pool_task_exit(tb_thread_pool_ref_t pool, tb_thread_pool_task_ref_t task);

#ifdef __tb_debug__
/*! dump the thread pool
 *
 * @param pool              the thread pool 
 */
tb_void_t                   tb_thread_pool_dump(tb_thread_pool_ref_t pool);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
