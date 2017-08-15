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
 * @file        transfer_pool.c
 * @ingroup     stream
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "transfer_pool"
#define TB_TRACE_MODULE_DEBUG               (1)
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "transfer_pool.h"
#include "../stream.h"
#include "../../network/network.h"
#include "../../platform/platform.h"
#include "../../container/container.h"
#include "../../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the task pool type
typedef struct __tb_transfer_pool_impl_t
{
    // the aicp
    tb_aicp_ref_t                   aicp;

    // the task maxn
    tb_size_t                       maxn;

    // the lock 
    tb_spinlock_t                   lock;

    // the task pool
    tb_fixed_pool_ref_t             pool;

    // the idle task list
    tb_list_entry_head_t            idle;

    // the work task list
    tb_list_entry_head_t            work;

    /* the state
     *
     * TB_STATE_OK
     * TB_STATE_KILLING
     */
    tb_atomic_t                     state;

}tb_transfer_pool_impl_t;

// the task task type
typedef struct __tb_transfer_task_t
{
    // the transfer
    tb_async_transfer_ref_t         transfer;

    // the pool
    tb_transfer_pool_impl_t*        pool;

    // the func
    tb_async_transfer_done_func_t   func;

    // the priv
    tb_cpointer_t                   priv;

    // the entry
    tb_list_entry_t                 entry;

}tb_transfer_task_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_void_t tb_transfer_task_exit(tb_transfer_pool_impl_t* impl, tb_transfer_task_t* task)
{
    // check
    tb_assert_and_check_return(impl && impl->pool && task);

    // trace
    tb_trace_d("task[%p]: exit", task);

    // append task to the idle list
    tb_list_entry_insert_tail(&impl->idle, &task->entry);
}
static tb_transfer_task_t* tb_transfer_task_init(tb_transfer_pool_impl_t* impl, tb_async_transfer_done_func_t done, tb_async_transfer_ctrl_func_t ctrl, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(impl, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_transfer_task_t* task = tb_null;
    do
    {
        // init task pool
        if (!impl->pool) impl->pool = tb_fixed_pool_init(tb_null, (impl->maxn >> 4) + 16, sizeof(tb_transfer_task_t), tb_null, tb_null, tb_null);
        tb_assert_and_check_break(impl->pool);

        // init task from the idle list first
        if (tb_list_entry_size(&impl->idle))
        {
            // get the head entry
            tb_list_entry_ref_t entry = tb_list_entry_head(&impl->idle);
            tb_assert_and_check_break(entry);

            // the task
            task = (tb_transfer_task_t*)tb_list_entry(&impl->idle, entry);
            tb_assert_and_check_break(task);

            // remove the last task
            tb_list_entry_remove(&impl->idle, entry);

            // check
            tb_assert_and_check_break(task->transfer);
        }
        // init task from the task pool
        else
        {
            // make task
            task = (tb_transfer_task_t*)tb_fixed_pool_malloc0(impl->pool);
            tb_assert_and_check_break(task);

            // init transfer
            task->transfer = tb_async_transfer_init(impl->aicp, tb_true);
            tb_assert_and_check_break(task->transfer);
        }

        // init ctrl
        if (ctrl && !tb_async_transfer_ctrl(task->transfer, ctrl, priv)) break;

        // init task
        task->func = done;
        task->priv = priv;
        task->pool = impl;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (task) tb_transfer_task_exit(impl, task);
        task = tb_null;
    }

    // ok?
    return task;
}
static tb_bool_t tb_transfer_task_done(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_hize_t save, tb_size_t rate, tb_cpointer_t priv)
{
    // the task
    tb_transfer_task_t* task = (tb_transfer_task_t*)priv;
    tb_assert_and_check_return_val(task && task->transfer, tb_false);

    // the pool
    tb_transfer_pool_impl_t* impl = (tb_transfer_pool_impl_t*)task->pool;
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("task[%p]: done: %llu bytes, rate: %lu bytes/s, state: %s", task, save, rate, tb_state_cstr(state));

    // done func
    tb_bool_t ok = task->func? task->func(state, offset, size, save, rate, task->priv) : tb_true; 

    // failed, killed or closed?
    if (state != TB_STATE_OK && state != TB_STATE_PAUSED)
    {
        // enter
        tb_spinlock_enter(&impl->lock);

        // remove task from the work list
        tb_list_entry_remove(&impl->work, &task->entry);
    
        // exit task
        tb_transfer_task_exit(impl, task);
        task = tb_null;

        // leave
        tb_spinlock_leave(&impl->lock);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_transfer_pool_work_kill(tb_iterator_ref_t iterator, tb_pointer_t item, tb_cpointer_t priv)
{
    // the task 
    tb_transfer_task_t* task = (tb_transfer_task_t*)item;
    tb_check_return_val(task, tb_false);

    // check
    tb_assert_and_check_return_val(task->transfer, tb_false);

    // kill it
    tb_async_transfer_kill(task->transfer);

    // ok
    return tb_true;
}
#ifdef __tb_debug__
static tb_bool_t tb_transfer_pool_work_wait(tb_iterator_ref_t iterator, tb_pointer_t item, tb_cpointer_t priv)
{
    // check
    tb_transfer_task_t* task = (tb_transfer_task_t*)item;
    tb_assert_and_check_return_val(task, tb_false);

    // trace
    tb_trace_d("wait: task: %p: ..", task);

    // ok
    return tb_true;
}
#endif
static tb_bool_t tb_transfer_pool_walk_exit(tb_pointer_t item, tb_cpointer_t priv)
{
    // check
    tb_transfer_task_t* task = (tb_transfer_task_t*)item;
    tb_assert_and_check_return_val(task, tb_false);

    // exit transfer
    if (task->transfer) tb_async_transfer_exit(task->transfer);
    task->transfer = tb_null;

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * instance implementation
 */
static tb_handle_t tb_transfer_pool_instance_init(tb_cpointer_t* ppriv)
{
    // init it
    return (tb_handle_t)tb_transfer_pool_init(tb_null);
}
static tb_void_t tb_transfer_pool_instance_exit(tb_handle_t pool, tb_cpointer_t priv)
{
    tb_transfer_pool_exit((tb_transfer_pool_ref_t)pool);
}
static tb_void_t tb_transfer_pool_instance_kill(tb_handle_t pool, tb_cpointer_t priv)
{
    tb_transfer_pool_kill((tb_transfer_pool_ref_t)pool);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_transfer_pool_ref_t tb_transfer_pool()
{
    return (tb_transfer_pool_ref_t)tb_singleton_instance(TB_SINGLETON_TYPE_TRANSFER_POOL, tb_transfer_pool_instance_init, tb_transfer_pool_instance_exit, tb_transfer_pool_instance_kill, tb_null);
}
tb_transfer_pool_ref_t tb_transfer_pool_init(tb_aicp_ref_t aicp)
{
    // done
    tb_bool_t                   ok = tb_false;
    tb_transfer_pool_impl_t*    impl = tb_null;
    do
    {
        // using the default aicp if be null
        if (!aicp) aicp = tb_aicp();
        tb_assert_and_check_break(aicp);

        // make impl
        impl = tb_malloc0_type(tb_transfer_pool_impl_t);
        tb_assert_and_check_break(impl);

        // init lock
        if (!tb_spinlock_init(&impl->lock)) break;

        // init pool
        impl->aicp      = aicp;
        impl->maxn      = tb_aicp_maxn(aicp);
        impl->state     = TB_STATE_OK;
        tb_assert_and_check_break(impl->maxn);

        // init idle task list
        tb_list_entry_init(&impl->idle, tb_transfer_task_t, entry, tb_null);

        // init work task list
        tb_list_entry_init(&impl->work, tb_transfer_task_t, entry, tb_null);

        // register lock profiler
#ifdef TB_LOCK_PROFILER_ENABLE
        tb_lock_profiler_register(tb_lock_profiler(), (tb_pointer_t)&impl->lock, TB_TRACE_MODULE_NAME);
#endif

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok) 
    {
        // exit it
        if (impl) tb_transfer_pool_exit((tb_transfer_pool_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_transfer_pool_ref_t)impl;
}
tb_void_t tb_transfer_pool_kill(tb_transfer_pool_ref_t pool)
{
    // check
    tb_transfer_pool_impl_t* impl = (tb_transfer_pool_impl_t*)pool;
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("kill: ..");

    // kill it
    if (TB_STATE_OK == tb_atomic_fetch_and_set(&impl->state, TB_STATE_KILLING))
        tb_transfer_pool_kill_all(pool);
}
tb_void_t tb_transfer_pool_kill_all(tb_transfer_pool_ref_t pool)
{
    // check
    tb_transfer_pool_impl_t* impl = (tb_transfer_pool_impl_t*)pool;
    tb_assert_and_check_return(impl);

    // check 
    tb_check_return(TB_STATE_OK == tb_atomic_get(&impl->state));

    // enter
    tb_spinlock_enter(&impl->lock);

    // trace
    tb_trace_d("kill_all: %lu, ..", tb_list_entry_size(&impl->work));

    // kill it
    tb_walk_all(tb_list_entry_itor(&impl->work), tb_transfer_pool_work_kill, tb_null);

    // leave
    tb_spinlock_leave(&impl->lock);
}
tb_long_t tb_transfer_pool_wait_all(tb_transfer_pool_ref_t pool, tb_long_t timeout)
{
    // check
    tb_transfer_pool_impl_t* impl = (tb_transfer_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl, -1);

    // wait it
    tb_size_t size = 0;
    tb_hong_t time = tb_cache_time_spak();
    while ((timeout < 0 || tb_cache_time_spak() < time + timeout))
    {
        // enter
        tb_spinlock_enter(&impl->lock);

        // the size
        tb_size_t size = tb_list_entry_size(&impl->work);

        // trace
        tb_trace_d("wait: %lu: ..", size);

        // trace work
#ifdef __tb_debug__
        if (size) tb_walk_all(tb_list_entry_itor(&impl->work), tb_transfer_pool_work_wait, tb_null);
#endif

        // leave
        tb_spinlock_leave(&impl->lock);

        // ok?
        tb_check_break(size);

        // wait some time
        tb_msleep(200);
    }

    // ok?
    return !size? 1 : 0;
}
tb_bool_t tb_transfer_pool_exit(tb_transfer_pool_ref_t pool)
{
    // check
    tb_transfer_pool_impl_t* impl = (tb_transfer_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("exit: ..");

    // kill it first
    tb_transfer_pool_kill(pool);

    // wait all
    if (tb_transfer_pool_wait_all(pool, 5000) <= 0)
    {
        // trace
        tb_trace_e("exit: wait failed!");
        return tb_false;
    }

    // enter
    tb_spinlock_enter(&impl->lock);

    // check
    tb_assert(!tb_list_entry_size(&impl->work));

    // exit the work list
    tb_list_entry_exit(&impl->work);

    // exit the idle list
    tb_list_entry_exit(&impl->idle);

    // exit pool
    if (impl->pool) 
    {
        // exit all task
        tb_fixed_pool_walk(impl->pool, tb_transfer_pool_walk_exit, tb_null);

        // exit it
        tb_fixed_pool_exit(impl->pool);
        impl->pool = tb_null;
    }

    // leave
    tb_spinlock_leave(&impl->lock);

    // exit lock
    tb_spinlock_exit(&impl->lock);

    // exit it
    tb_free(pool);

    // trace
    tb_trace_d("exit: ok");
    
    // ok
    return tb_true;
}
tb_size_t tb_transfer_pool_maxn(tb_transfer_pool_ref_t pool)
{
    // check
    tb_transfer_pool_impl_t* impl = (tb_transfer_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl, 0);

    // the maxn
    return impl->maxn;
}
tb_size_t tb_transfer_pool_size(tb_transfer_pool_ref_t pool)
{
    // check
    tb_transfer_pool_impl_t* impl = (tb_transfer_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl, 0);

    // enter
    tb_spinlock_enter(&impl->lock);

    // the size
    tb_size_t size = tb_list_entry_size(&impl->work);

    // leave
    tb_spinlock_leave(&impl->lock);

    // ok?
    return size;
}
tb_bool_t tb_transfer_pool_done(tb_transfer_pool_ref_t pool, tb_char_t const* iurl, tb_char_t const* ourl, tb_hize_t offset, tb_size_t rate, tb_async_transfer_done_func_t done, tb_async_transfer_ctrl_func_t ctrl, tb_cpointer_t priv)
{
    // check
    tb_transfer_pool_impl_t* impl = (tb_transfer_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl && impl->aicp && iurl && ourl, tb_false);
    
    // enter
    tb_spinlock_enter(&impl->lock);

    // done
    tb_bool_t               ok = tb_false;
    tb_transfer_task_t*     task = tb_null;
    do
    {
        // check 
        tb_check_break(TB_STATE_OK == tb_atomic_get(&impl->state));

        // too many tasks?
        if (tb_list_entry_size(&impl->work) >= impl->maxn)
        {
            // trace
            tb_trace_e("too many tasks, done task: %s => %s failed!", iurl, ourl);
            break;
        }

        // init task
        task = tb_transfer_task_init(impl, done, ctrl, priv);
        tb_assert_and_check_break(task && task->transfer);

        // init transfer stream
        if (!tb_async_transfer_init_istream_from_url(task->transfer, iurl)) break;
        if (!tb_async_transfer_init_ostream_from_url(task->transfer, ourl)) break;

        // init transfer rate
        tb_async_transfer_limitrate(task->transfer, rate);

        // check
        tb_assert_and_check_break(impl->pool);

        // append to the work list
        tb_list_entry_insert_tail(&impl->work, &task->entry);

        // ok
        ok = tb_true;

    } while (0);

    // trace
    tb_trace_d("done: task: %p, %s => %s, work: %lu, idle: %lu, state: %s", task, iurl, ourl, tb_list_entry_size(&impl->work), tb_list_entry_size(&impl->idle), ok? "ok" : "no");

    // failed?
    if (!ok) 
    {
        // exit it
        if (task) tb_transfer_task_exit(impl, task);
        task = tb_null;
    }

    // leave
    tb_spinlock_leave(&impl->lock);

    // ok? done it
    if (ok && task && task->transfer)
    {
        // done
        if (!tb_async_transfer_open_done(task->transfer, 0, tb_transfer_task_done, task))
        {
            // enter
            tb_spinlock_enter(&impl->lock);

            // remove task from the work list
            tb_list_entry_remove(&impl->work, &task->entry);

            // exit task
            tb_transfer_task_exit(impl, task);

            // leave
            tb_spinlock_leave(&impl->lock);

            // failed
            ok = tb_false;
        }
    }

    // ok?
    return ok;
}
