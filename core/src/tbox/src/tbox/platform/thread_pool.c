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
 * @file        thread_pool.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "thread_pool"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "platform.h"
#include "../utils/utils.h"
#include "../memory/memory.h"
#include "../container/container.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the worker maxn
#ifdef __tb_small__
#   define TB_THREAD_POOL_WORKER_MAXN           (32)
#else
#   define TB_THREAD_POOL_WORKER_MAXN           (64)
#endif

// the jobs grow
#ifdef __tb_small__
#   define TB_THREAD_POOL_JOBS_POOL_GROW        (256)
#else
#   define TB_THREAD_POOL_JOBS_POOL_GROW        (512)
#endif

// the working jobs grow
#ifdef __tb_small__
#   define TB_THREAD_POOL_JOBS_WORKING_GROW     (32)
#else
#   define TB_THREAD_POOL_JOBS_WORKING_GROW     (64)
#endif

// the jobs waiting maxn
#ifdef __tb_small__
#   define TB_THREAD_POOL_JOBS_WAITING_MAXN     (1 << 16)
#else
#   define TB_THREAD_POOL_JOBS_WAITING_MAXN     (1 << 20)
#endif

// the pull jobs time maxn
#ifdef __tb_small__
#   define TB_THREAD_POOL_JOBS_PULL_TIME_MAXN   (10000)
#else
#   define TB_THREAD_POOL_JOBS_PULL_TIME_MAXN   (20000)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the thread pool job type
typedef struct __tb_thread_pool_job_t
{
    // the task
    tb_thread_pool_task_t               task;

    // the reference count, must be <= 2
    tb_atomic_t                         refn;

    /* the state
     *
     * TB_STATE_KILLED
     * TB_STATE_WAITING
     * TB_STATE_WORKING
     * TB_STATE_KILLING
     * TB_STATE_FINISHED
     */
    tb_atomic_t                         state;

    // the entry
    tb_list_entry_t                     entry;

}tb_thread_pool_job_t;

// the thread pool job stats type
typedef struct __tb_thread_pool_job_stats_t
{
    // the done count
    tb_size_t                           done_count;

    // the done total time
    tb_hize_t                           total_time;

}tb_thread_pool_job_stats_t;

// the thread pool worker priv type
typedef struct __tb_thread_pool_worker_priv_t
{
    // the exit func
    tb_thread_pool_priv_exit_func_t     exit;

    // the private data
    tb_cpointer_t                       priv;

}tb_thread_pool_worker_priv_t;

// the thread pool worker type
typedef struct __tb_thread_pool_worker_t
{
    // the worker id
    tb_size_t                           id;

    // the thread pool 
    tb_thread_pool_ref_t                pool;

    // the loop
    tb_thread_ref_t                     loop;

    // the jobs
    tb_vector_ref_t                     jobs;

    // the pull time
    tb_size_t                           pull;

    // the stats
    tb_hash_map_ref_t                   stats;

    // is stoped?
    tb_atomic_t                         bstoped;

    // the private data 
    tb_thread_pool_worker_priv_t        priv[TB_THREAD_POOL_WORKER_PRIV_MAXN];

}tb_thread_pool_worker_t;

// the thread pool type
typedef struct __tb_thread_pool_impl_t
{
    // the thread stack size
    tb_size_t                           stack;

    // the worker maxn
    tb_size_t                           worker_maxn;

    // the lock
    tb_spinlock_t                       lock;

    // the jobs pool
    tb_fixed_pool_ref_t                 jobs_pool;

    // the urgent jobs
    tb_list_entry_head_t                jobs_urgent;
    
    // the waiting jobs
    tb_list_entry_head_t                jobs_waiting;
    
    // the pending jobs
    tb_list_entry_head_t                jobs_pending;

    // is stoped
    tb_bool_t                           bstoped;

    // the semaphore
    tb_semaphore_ref_t                  semaphore;
    
    // the worker size
    tb_size_t                           worker_size;

    // the worker list
    tb_thread_pool_worker_t             worker_list[TB_THREAD_POOL_WORKER_MAXN];

}tb_thread_pool_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * instance implementation
 */
static tb_handle_t tb_thread_pool_instance_init(tb_cpointer_t* ppriv)
{
    // init it
    return tb_thread_pool_init(0, 0);
}
static tb_void_t tb_thread_pool_instance_exit(tb_handle_t pool, tb_cpointer_t priv)
{
    // exit it
    tb_thread_pool_exit((tb_thread_pool_ref_t)pool);
}
static tb_void_t tb_thread_pool_instance_kill(tb_handle_t pool, tb_cpointer_t priv)
{
    // dump it
#ifdef __tb_debug__
    tb_thread_pool_dump((tb_thread_pool_ref_t)pool);
#endif

    // kill it
    tb_thread_pool_kill((tb_thread_pool_ref_t)pool);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * worker implementation
 */
static tb_bool_t tb_thread_pool_worker_walk_pull(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value, tb_bool_t* is_break)
{
    // the worker pull
    tb_thread_pool_worker_t* worker = (tb_thread_pool_worker_t*)value;
    tb_assert(worker && worker->jobs && worker->stats && is_break);

    // full?
    if (worker->pull >= TB_THREAD_POOL_JOBS_PULL_TIME_MAXN)
    {
        // break it
        *is_break = tb_true;
        return tb_false;
    }

    // the job
    tb_thread_pool_job_t* job = (tb_thread_pool_job_t*)item;
    tb_assert(job);

    // the pool
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)worker->pool;
    tb_assert(impl);

    // append the job to the pending jobs
    tb_list_entry_insert_tail(&impl->jobs_pending, &job->entry);  

    // append the job to the working jobs
    tb_vector_insert_tail(worker->jobs, job);   

    // computate the job average time 
    tb_size_t average_time = 200;
    if (tb_hash_map_size(worker->stats))
    {
        tb_thread_pool_job_stats_t* stats = (tb_thread_pool_job_stats_t*)tb_hash_map_get(worker->stats, job->task.done);
        if (stats && stats->done_count) average_time = (tb_size_t)(stats->total_time / stats->done_count);
    }

    // update the pull time
    worker->pull += average_time;

    // trace
    tb_trace_d("worker[%lu]: pull: task[%p:%s] from %s", worker->id, job->task.done, job->task.name, iterator == tb_list_entry_itor(&impl->jobs_waiting)? "waiting" : "urgent");

    // remove the job from the waiting or urgent jobs
    return tb_true;
}
static tb_bool_t tb_thread_pool_worker_walk_pull_and_clean(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // the worker pull
    tb_thread_pool_worker_t* worker = (tb_thread_pool_worker_t*)value;
    tb_assert(worker && worker->jobs && worker->stats);

    // the job
    tb_thread_pool_job_t* job = (tb_thread_pool_job_t*)item;
    tb_assert(job);

    // the job state
    tb_size_t state = tb_atomic_get(&job->state);

    // waiting and non-full? pull it
    tb_bool_t ok = tb_false;
    if (state == TB_STATE_WAITING && worker->pull < TB_THREAD_POOL_JOBS_PULL_TIME_MAXN)
    {
        // append the job to the working jobs
        tb_vector_insert_tail(worker->jobs, job);   

        // computate the job average time 
        tb_size_t average_time = 200;
        if (tb_hash_map_size(worker->stats))
        {
            tb_thread_pool_job_stats_t* stats = (tb_thread_pool_job_stats_t*)tb_hash_map_get(worker->stats, job->task.done);
            if (stats && stats->done_count) average_time = (tb_size_t)(stats->total_time / stats->done_count);
        }

        // update the pull time
        worker->pull += average_time;

        // trace
        tb_trace_d("worker[%lu]: pull: task[%p:%s] from pending", worker->id, job->task.done, job->task.name);
    }
    // finished or killed? remove it
    else if (state == TB_STATE_FINISHED || state == TB_STATE_KILLED)
    {
        // trace
        tb_trace_d("worker[%lu]: remove: task[%p:%s] from pending", worker->id, job->task.done, job->task.name);

        // exit the job
        if (job->task.exit) job->task.exit((tb_thread_pool_worker_ref_t)worker, job->task.priv);

        // remove it from the waiting or urgent jobs
        ok = tb_true;

        // refn--
        if (job->refn > 1) job->refn--;
        // remove it from pool directly
        else 
        {
            // the pool
            tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)worker->pool;
            tb_assert(impl);

            // remove it from the jobs pool
            tb_fixed_pool_free(impl->jobs_pool, job);
        }
    }

    // remove it?
    return ok;
}
static tb_bool_t tb_thread_pool_worker_walk_clean(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // the worker pull
    tb_thread_pool_worker_t* worker = (tb_thread_pool_worker_t*)value;
    tb_assert(worker && worker->jobs);

    // the job
    tb_thread_pool_job_t* job = (tb_thread_pool_job_t*)item;
    tb_assert(job);

    // the job state
    tb_size_t state = tb_atomic_get(&job->state);

    // finished or killed? remove it
    tb_bool_t ok = tb_false;
    if (state == TB_STATE_FINISHED || state == TB_STATE_KILLED)
    {
        // trace
        tb_trace_d("worker[%lu]: remove: task[%p:%s] from pending", worker->id, job->task.done, job->task.name);

        // exit the job
        if (job->task.exit) job->task.exit((tb_thread_pool_worker_ref_t)worker, job->task.priv);

        // remove it from the pending jobs
        ok = tb_true;

        // refn--
        if (job->refn > 1) job->refn--;
        // remove it from pool directly
        else 
        {
            // the pool
            tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)worker->pool;
            tb_assert(impl);

            // remove it from the jobs pool
            tb_fixed_pool_free(impl->jobs_pool, job);
        }
    }

    // remove it?
    return ok;
}
static tb_void_t tb_thread_pool_worker_post(tb_thread_pool_impl_t* impl, tb_size_t post)
{
    // check
    tb_assert_and_check_return(impl && impl->semaphore);

    // the semaphore value
    tb_long_t value = tb_semaphore_value(impl->semaphore);

    // post wait
    if (value >= 0 && (tb_size_t)value < post) 
        tb_semaphore_post(impl->semaphore, post - value);
}
static tb_int_t tb_thread_pool_worker_loop(tb_cpointer_t priv)
{
    // the worker
    tb_thread_pool_worker_t* worker = (tb_thread_pool_worker_t*)priv;

    // trace
    tb_trace_d("worker[%lu]: init", worker? worker->id : -1);

    // done
    do
    {
        // check
        tb_assert_and_check_break(worker && !worker->jobs && !worker->stats);

        // the pool
        tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)worker->pool;
        tb_assert_and_check_break(impl && impl->semaphore);

        // wait some time for leaving the lock
        tb_msleep((worker->id + 1) * 20);

        // init jobs
        worker->jobs = tb_vector_init(TB_THREAD_POOL_JOBS_WORKING_GROW, tb_element_ptr(tb_null, tb_null));
        tb_assert_and_check_break(worker->jobs);

        // init stats
        worker->stats = tb_hash_map_init(TB_HASH_MAP_BUCKET_SIZE_MICRO, tb_element_ptr(tb_null, tb_null), tb_element_mem(sizeof(tb_thread_pool_job_stats_t), tb_null, tb_null));
        tb_assert_and_check_break(worker->stats);
        
        // loop
        while (1)
        {
            // pull jobs if be idle
            if (!tb_vector_size(worker->jobs))
            {
                // enter 
                tb_spinlock_enter(&impl->lock);

                // init the pull time
                worker->pull = 0;

                // pull from the urgent jobs
                if (tb_list_entry_size(&impl->jobs_urgent))
                {
                    // trace
                    tb_trace_d("worker[%lu]: try pulling from urgent: %lu", worker->id, tb_list_entry_size(&impl->jobs_urgent));

                    // pull it
                    tb_remove_if_until(tb_list_entry_itor(&impl->jobs_urgent), tb_thread_pool_worker_walk_pull, worker);
                }

                // pull from the waiting jobs
                if (tb_list_entry_size(&impl->jobs_waiting))
                {
                    // trace
                    tb_trace_d("worker[%lu]: try pulling from waiting: %lu", worker->id, tb_list_entry_size(&impl->jobs_waiting));

                    // pull it
                    tb_remove_if_until(tb_list_entry_itor(&impl->jobs_waiting), tb_thread_pool_worker_walk_pull, worker);
                }

                // pull from the pending jobs and clean some finished and killed jobs
                if (tb_list_entry_size(&impl->jobs_pending))
                {
                    // trace
                    tb_trace_d("worker[%lu]: try pulling from pending: %lu", worker->id, tb_list_entry_size(&impl->jobs_pending));

                    // no jobs? try to pull from the pending jobs
                    if (!tb_vector_size(worker->jobs))
                        tb_remove_if(tb_list_entry_itor(&impl->jobs_pending), tb_thread_pool_worker_walk_pull_and_clean, worker);
                    // clean some finished and killed jobs
                    else tb_remove_if(tb_list_entry_itor(&impl->jobs_pending), tb_thread_pool_worker_walk_clean, worker);
                }

                // leave 
                tb_spinlock_leave(&impl->lock);

                // idle? wait it
                if (!tb_vector_size(worker->jobs))
                {
                    // killed?
                    tb_check_break(!tb_atomic_get(&worker->bstoped));

                    // trace
                    tb_trace_d("worker[%lu]: wait: ..", worker->id);

                    // wait some time
                    tb_long_t wait = tb_semaphore_wait(impl->semaphore, -1);
                    tb_assert_and_check_break(wait > 0);

                    // trace
                    tb_trace_d("worker[%lu]: wait: ok", worker->id);

                    // continue it
                    continue;
                }
                else
                {
#ifdef TB_TRACE_DEBUG
                    // update the jobs urgent size
                    tb_size_t jobs_urgent_size = tb_list_entry_size(&impl->jobs_urgent);

                    // update the jobs waiting size
                    tb_size_t jobs_waiting_size = tb_list_entry_size(&impl->jobs_waiting);

                    // update the jobs pending size
                    tb_size_t jobs_pending_size = tb_list_entry_size(&impl->jobs_pending);

                    // trace
                    tb_trace_d("worker[%lu]: pull: jobs: %lu, time: %lu ms, waiting: %lu, pending: %lu, urgent: %lu", worker->id, tb_vector_size(worker->jobs), worker->pull, jobs_waiting_size, jobs_pending_size, jobs_urgent_size);
#endif
                }
            }

            // done jobs
            tb_for_all (tb_thread_pool_job_t*, job, worker->jobs)
            {
                // check
                tb_assert_and_check_continue(job && job->task.done);

                // the job state
                tb_size_t state = tb_atomic_fetch_and_pset(&job->state, TB_STATE_WAITING, TB_STATE_WORKING);
                
                // the job is waiting? work it
                if (state == TB_STATE_WAITING)
                {
                    // trace
                    tb_trace_d("worker[%lu]: done: task[%p:%s]: ..", worker->id, job->task.done, job->task.name);

                    // init the time
                    tb_hong_t time = tb_cache_time_spak();

                    // done the job
                    job->task.done((tb_thread_pool_worker_ref_t)worker, job->task.priv);

                    // computate the time
                    time = tb_cache_time_spak() - time;

                    // exists? update time and count
                    tb_size_t               itor;
                    tb_hash_map_item_ref_t  item = tb_null;
                    if (    ((itor = tb_hash_map_find(worker->stats, job->task.done)) != tb_iterator_tail(worker->stats))
                        &&  (item = (tb_hash_map_item_ref_t)tb_iterator_item(worker->stats, itor)))
                    {
                        // the stats
                        tb_thread_pool_job_stats_t* stats = (tb_thread_pool_job_stats_t*)item->data;
                        tb_assert_and_check_break(stats);

                        // update the done count
                        stats->done_count++;

                        // update the total time 
                        stats->total_time += time;
                    }
                    
                    // no item? add it
                    if (!item) 
                    {
                        // init stats
                        tb_thread_pool_job_stats_t stats = {0};
                        stats.done_count = 1;
                        stats.total_time = time;

                        // add stats
                        tb_hash_map_insert(worker->stats, job->task.done, &stats);
                    }

#ifdef TB_TRACE_DEBUG
                    tb_size_t done_count = 0;
                    tb_hize_t total_time = 0;
                    tb_thread_pool_job_stats_t* stats = (tb_thread_pool_job_stats_t*)tb_hash_map_get(worker->stats, job->task.done);
                    if (stats)
                    {
                        done_count = stats->done_count;
                        total_time = stats->total_time;
                    }

                    // trace
                    tb_trace_d("worker[%lu]: done: task[%p:%s]: time: %lld ms, average: %lld ms, count: %lu", worker->id, job->task.done, job->task.name, time, (total_time / (tb_hize_t)done_count), done_count);
#endif

                    // update the job state
                    tb_atomic_set(&job->state, TB_STATE_FINISHED);
                }
                // the job is killing? work it
                else if (state == TB_STATE_KILLING)
                {
                    // update the job state
                    tb_atomic_set(&job->state, TB_STATE_KILLED);
                }
            }

            // clear jobs
            tb_vector_clear(worker->jobs);
        }

    } while (0);

    // exit worker
    if (worker)
    {
        // trace
        tb_trace_d("worker[%lu]: exit", worker->id);

        // stoped
        tb_atomic_set(&worker->bstoped, 1);

        // exit all private data
        tb_size_t i = 0;
        tb_size_t n = tb_arrayn(worker->priv);
        for (i = 0; i < n; i++)
        {
            // the private data
            tb_thread_pool_worker_priv_t* priv = &worker->priv[n - i - 1];

            // exit it
            if (priv->exit) priv->exit((tb_thread_pool_worker_ref_t)worker, priv->priv);

            // clear it
            priv->exit = tb_null;
            priv->priv = tb_null;
        }

        // exit stats
        if (worker->stats) tb_hash_map_exit(worker->stats);
        worker->stats = tb_null;

        // exit jobs
        if (worker->jobs) tb_vector_exit(worker->jobs);
        worker->jobs = tb_null;
    }

    // exit
    return 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * jobs implementation
 */
static tb_bool_t tb_thread_pool_jobs_walk_kill_all(tb_pointer_t item, tb_cpointer_t priv)
{
    // check
    tb_thread_pool_job_t* job = (tb_thread_pool_job_t*)item;
    tb_assert_and_check_return_val(job, tb_false);

    // trace
    tb_trace_d("task[%p:%s]: kill: ..", job->task.done, job->task.name);

    // kill it if be waiting
    tb_atomic_pset(&job->state, TB_STATE_WAITING, TB_STATE_KILLING);

    // ok
    return tb_true;
}
#ifdef __tb_debug__
static tb_bool_t tb_thread_pool_jobs_walk_dump_all(tb_pointer_t item, tb_cpointer_t priv)
{
    // check
    tb_thread_pool_job_t* job = (tb_thread_pool_job_t*)item;
    tb_assert_and_check_return_val(job, tb_false);

    // the state string
    static tb_char_t const* s_state_cstr[] = 
    {
        "waiting"
    ,   "working"
    ,   "killed"
    ,   "finished"
    };
    tb_assert_and_check_return_val(job->state < tb_arrayn(s_state_cstr), tb_false);

    // trace
    tb_trace_d("    task[%p:%s]: refn: %lu, state: %s", job->task.done, job->task.name, job->refn, s_state_cstr[job->state]);

    // ok
    return tb_true;
}
#endif
static tb_thread_pool_job_t* tb_thread_pool_jobs_post_task(tb_thread_pool_impl_t* impl, tb_thread_pool_task_t const* task, tb_size_t* post_size)
{
    // check
    tb_assert_and_check_return_val(impl && task && task->done && post_size, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_thread_pool_job_t*   job = tb_null;
    do
    {
        // check
        tb_assert_and_check_break(tb_list_entry_size(&impl->jobs_waiting) + tb_list_entry_size(&impl->jobs_urgent) + 1 < TB_THREAD_POOL_JOBS_WAITING_MAXN);

        // make job
        job = (tb_thread_pool_job_t*)tb_fixed_pool_malloc0(impl->jobs_pool);
        tb_assert_and_check_break(job);

        // init job
        job->refn   = 1;
        job->state  = TB_STATE_WAITING;
        job->task   = *task;

        // non-urgent job? 
        if (!task->urgent)
        {
            // post to the waiting jobs
            tb_list_entry_insert_tail(&impl->jobs_waiting, &job->entry);
        }
        else
        {
            // post to the urgent jobs
            tb_list_entry_insert_tail(&impl->jobs_urgent, &job->entry);
        }

        // the waiting jobs count
        tb_size_t jobs_waiting_count = tb_list_entry_size(&impl->jobs_waiting) + tb_list_entry_size(&impl->jobs_urgent);
        tb_assert_and_check_break(jobs_waiting_count);

        // update the post size
        if (*post_size < impl->worker_size) (*post_size)++;

        // trace
        tb_trace_d("task[%p:%s]: post: %lu: ..", task->done, task->name, *post_size);

        // init them if the workers have been not inited
        if (impl->worker_size < jobs_waiting_count)
        {
            tb_size_t i = impl->worker_size;
            tb_size_t n = tb_min(jobs_waiting_count, impl->worker_maxn);
            for (; i < n; i++)
            {
                // the worker 
                tb_thread_pool_worker_t* worker = &impl->worker_list[i];

                // clear worker
                tb_memset(worker, 0, sizeof(tb_thread_pool_worker_t));

                // init worker
                worker->id          = i;
                worker->pool        = (tb_thread_pool_ref_t)impl;
                worker->loop        = tb_thread_init(__tb_lstring__("thread_pool"), tb_thread_pool_worker_loop, worker, impl->stack);
                tb_assert_and_check_continue(worker->loop);
            }

            // update the worker size
            impl->worker_size = i;
        }

        // ok
        ok = tb_true;
    
    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        tb_fixed_pool_free(impl->jobs_pool, job);
        job = tb_null;
    }

    // ok?
    return job;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_thread_pool_ref_t tb_thread_pool()
{
    return (tb_thread_pool_ref_t)tb_singleton_instance(TB_SINGLETON_TYPE_THREAD_POOL, tb_thread_pool_instance_init, tb_thread_pool_instance_exit, tb_thread_pool_instance_kill, tb_null);
}
tb_thread_pool_ref_t tb_thread_pool_init(tb_size_t worker_maxn, tb_size_t stack)
{
    // done
    tb_bool_t               ok = tb_false;
    tb_thread_pool_impl_t*  impl = tb_null;
    do
    {
        // make pool
        impl = tb_malloc0_type(tb_thread_pool_impl_t);
        tb_assert_and_check_break(impl);

        // init lock
        if (!tb_spinlock_init(&impl->lock)) break;

        // computate the default worker maxn if be zero
        if (!worker_maxn) worker_maxn = tb_processor_count() << 2;
        tb_assert_and_check_break(worker_maxn);

        // init thread stack
        impl->stack         = stack;

        // init workers
        impl->worker_size   = 0;
        impl->worker_maxn   = worker_maxn;

        // init jobs pool
        impl->jobs_pool     = tb_fixed_pool_init(tb_null, TB_THREAD_POOL_JOBS_POOL_GROW, sizeof(tb_thread_pool_job_t), tb_null, tb_null, tb_null);
        tb_assert_and_check_break(impl->jobs_pool);

        // init jobs urgent
        tb_list_entry_init(&impl->jobs_urgent, tb_thread_pool_job_t, entry, tb_null);

        // init jobs waiting
        tb_list_entry_init(&impl->jobs_waiting, tb_thread_pool_job_t, entry, tb_null);

        // init jobs pending
        tb_list_entry_init(&impl->jobs_pending, tb_thread_pool_job_t, entry, tb_null);

        // init semaphore
        impl->semaphore = tb_semaphore_init(0);
        tb_assert_and_check_break(impl->semaphore);

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
        if (impl) tb_thread_pool_exit((tb_thread_pool_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_thread_pool_ref_t)impl;
}
tb_bool_t tb_thread_pool_exit(tb_thread_pool_ref_t pool)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("exit: ..");

    // kill it first
    tb_thread_pool_kill(pool);

    // wait all
    if (tb_thread_pool_task_wait_all(pool, 5000) <= 0)
    {
        // trace
        tb_trace_e("exit: wait failed!");
        return tb_false;
    }

    /* exit all workers
     * need not lock it because the worker size will not be increase d
     */
    tb_size_t i = 0;
    tb_size_t n = impl->worker_size;
    for (i = 0; i < n; i++) 
    {
        // the worker
        tb_thread_pool_worker_t* worker = &impl->worker_list[i];

        // exit loop
        if (worker->loop)
        {
            // wait it
            tb_long_t wait = 0;
            if ((wait = tb_thread_wait(worker->loop, 5000, tb_null)) <= 0)
            {
                // trace
                tb_trace_e("worker[%lu]: wait failed: %ld!", i, wait);
            }

            // exit it
            tb_thread_exit(worker->loop);
            worker->loop = tb_null;
        }
    }
    impl->worker_size = 0;

    // enter
    tb_spinlock_enter(&impl->lock);

    // exit pending jobs
    tb_list_entry_exit(&impl->jobs_pending);

    // exit waiting jobs
    tb_list_entry_exit(&impl->jobs_waiting);

    // exit urgent jobs
    tb_list_entry_exit(&impl->jobs_urgent);

    // exit jobs pool
    if (impl->jobs_pool) tb_fixed_pool_exit(impl->jobs_pool);
    impl->jobs_pool = tb_null;

    // leave
    tb_spinlock_leave(&impl->lock);

    // exit lock
    tb_spinlock_exit(&impl->lock);

    // exit semaphore
    if (impl->semaphore) tb_semaphore_exit(impl->semaphore);
    impl->semaphore = tb_null;

    // exit it
    tb_free(impl);

    // trace
    tb_trace_d("exit: ok");

    // ok
    return tb_true;
}
tb_void_t tb_thread_pool_kill(tb_thread_pool_ref_t pool)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return(impl);

    // enter
    tb_spinlock_enter(&impl->lock);

    // kill it
    tb_size_t post = 0;
    if (!impl->bstoped)
    {
        // trace
        tb_trace_d("kill: ..");

        // stoped
        impl->bstoped = tb_true;
        
        // kill all workers
        tb_size_t i = 0;
        tb_size_t n = impl->worker_size;
        for (i = 0; i < n; i++) tb_atomic_set(&impl->worker_list[i].bstoped, 1);

        // kill all jobs
        if (impl->jobs_pool) tb_fixed_pool_walk(impl->jobs_pool, tb_thread_pool_jobs_walk_kill_all, tb_null);

        // post it
        post = impl->worker_size;
    }

    // leave
    tb_spinlock_leave(&impl->lock);

    // post the workers
    if (post) tb_thread_pool_worker_post(impl, post);
}
tb_size_t tb_thread_pool_worker_size(tb_thread_pool_ref_t pool)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl, 0);

    // enter
    tb_spinlock_enter(&impl->lock);

    // the worker size
    tb_size_t worker_size = impl->worker_size;

    // leave
    tb_spinlock_leave(&impl->lock);

    // ok?
    return worker_size;
}
tb_void_t tb_thread_pool_worker_setp(tb_thread_pool_worker_ref_t worker, tb_size_t index, tb_thread_pool_priv_exit_func_t exit, tb_cpointer_t priv)
{
    // check
    tb_thread_pool_worker_t* worker_impl = (tb_thread_pool_worker_t*)worker;
    tb_assert_and_check_return(worker_impl && index < tb_arrayn(worker_impl->priv));

    // set the private data
    worker_impl->priv[index].exit = exit;
    worker_impl->priv[index].priv = priv;
}
tb_cpointer_t tb_thread_pool_worker_getp(tb_thread_pool_worker_ref_t worker, tb_size_t index)
{
    // check
    tb_thread_pool_worker_t* worker_impl = (tb_thread_pool_worker_t*)worker;
    tb_assert_and_check_return_val(worker_impl && index < tb_arrayn(worker_impl->priv), tb_null);

    // get the private data
    return worker_impl->priv[index].priv;
}
tb_size_t tb_thread_pool_task_size(tb_thread_pool_ref_t pool)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl, 0);

    // enter
    tb_spinlock_enter(&impl->lock);

    // the task size
    tb_size_t task_size = impl->jobs_pool? tb_fixed_pool_size(impl->jobs_pool) : 0;

    // leave
    tb_spinlock_leave(&impl->lock);

    // ok?
    return task_size;
}
tb_bool_t tb_thread_pool_task_post(tb_thread_pool_ref_t pool, tb_char_t const* name, tb_thread_pool_task_done_func_t done, tb_thread_pool_task_exit_func_t exit, tb_cpointer_t priv, tb_bool_t urgent)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl && done, tb_false);

    // init the post size
    tb_size_t post_size = 0;

    // enter
    tb_spinlock_enter(&impl->lock);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // stoped?
        tb_check_break(!impl->bstoped);

        // init task
        tb_thread_pool_task_t task = {0};
        task.name       = name;
        task.done       = done;
        task.exit       = exit;
        task.priv       = priv;
        task.urgent     = urgent;

        // post task
        tb_thread_pool_job_t* job = tb_thread_pool_jobs_post_task(impl, &task, &post_size);
        tb_assert_and_check_break(job);

        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&impl->lock);

    // post the workers
    if (ok && post_size) tb_thread_pool_worker_post(impl, post_size);

    // ok?
    return ok;
}
tb_size_t tb_thread_pool_task_post_list(tb_thread_pool_ref_t pool, tb_thread_pool_task_t const* list, tb_size_t size)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl && list, 0);

    // init the post size
    tb_size_t post_size = 0;

    // enter
    tb_spinlock_enter(&impl->lock);

    // done
    tb_size_t ok = 0;
    if (!impl->bstoped)
    {
        for (ok = 0; ok < size; ok++)
        {
            // post task
            tb_thread_pool_job_t* job = tb_thread_pool_jobs_post_task(impl, &list[ok], &post_size);
            tb_assert_and_check_break(job);
        }
    }

    // leave
    tb_spinlock_leave(&impl->lock);

    // post the workers
    if (ok && post_size) tb_thread_pool_worker_post(impl, post_size);

    // ok?
    return ok;
}
tb_thread_pool_task_ref_t tb_thread_pool_task_init(tb_thread_pool_ref_t pool, tb_char_t const* name, tb_thread_pool_task_done_func_t done, tb_thread_pool_task_exit_func_t exit, tb_cpointer_t priv, tb_bool_t urgent)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl && done, tb_null);

    // init the post size
    tb_size_t post_size = 0;

    // enter
    tb_spinlock_enter(&impl->lock);

    // done
    tb_bool_t               ok = tb_false;
    tb_thread_pool_job_t*   job = tb_null;
    do
    {
        // stoped?
        tb_check_break(!impl->bstoped);

        // init task
        tb_thread_pool_task_t task = {0};
        task.name       = name;
        task.done       = done;
        task.exit       = exit;
        task.priv       = priv;
        task.urgent     = urgent;

        // post task
        job = tb_thread_pool_jobs_post_task(impl, &task, &post_size);
        tb_assert_and_check_break(job);

        // refn++
        job->refn++;

        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&impl->lock);

    // post the workers
    if (ok && post_size) tb_thread_pool_worker_post(impl, post_size);
    // failed?
    else if (!ok) job = tb_null;

    // ok?
    return (tb_thread_pool_task_ref_t)job;
}
tb_void_t tb_thread_pool_task_kill(tb_thread_pool_ref_t pool, tb_thread_pool_task_ref_t task)
{
    // check
    tb_thread_pool_job_t* job = (tb_thread_pool_job_t*)task;
    tb_assert_and_check_return(pool && job);

    // trace
    tb_trace_d("task[%p:%s]: kill: state: %s: ..", job->task.done, job->task.name, tb_state_cstr(tb_atomic_get(&job->state)));

    // kill it if be waiting
    tb_atomic_pset(&job->state, TB_STATE_WAITING, TB_STATE_KILLING);
}
tb_void_t tb_thread_pool_task_kill_all(tb_thread_pool_ref_t pool)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return(impl);

    // enter
    tb_spinlock_enter(&impl->lock);

    // kill all jobs
    if (!impl->bstoped && impl->jobs_pool) 
        tb_fixed_pool_walk(impl->jobs_pool, tb_thread_pool_jobs_walk_kill_all, tb_null);

    // leave
    tb_spinlock_leave(&impl->lock);
}
tb_long_t tb_thread_pool_task_wait(tb_thread_pool_ref_t pool, tb_thread_pool_task_ref_t task, tb_long_t timeout)
{
    // check
    tb_thread_pool_job_t* job = (tb_thread_pool_job_t*)task;
    tb_assert_and_check_return_val(pool && job, -1);

    // wait it
    tb_hong_t time = tb_cache_time_spak();
    tb_size_t state = TB_STATE_WAITING;
    while ( ((state = tb_atomic_get(&job->state)) != TB_STATE_FINISHED) 
        &&  state != TB_STATE_KILLED
        &&  (timeout < 0 || tb_cache_time_spak() < time + timeout))
    {
        // trace
        tb_trace_d("task[%p:%s]: wait: state: %s: ..", job->task.done, job->task.name, tb_state_cstr(state));

        // wait some time
        tb_msleep(200);
    }

    // ok?
    return (state == TB_STATE_FINISHED || state == TB_STATE_KILLED)? 1 : 0;
}
tb_long_t tb_thread_pool_task_wait_all(tb_thread_pool_ref_t pool, tb_long_t timeout)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return_val(impl, -1);

    // wait it
    tb_size_t size = 0;
    tb_hong_t time = tb_cache_time_spak();
    while ((timeout < 0 || tb_cache_time_spak() < time + timeout))
    {
        // enter
        tb_spinlock_enter(&impl->lock);

        // the jobs count
        size = impl->jobs_pool? tb_fixed_pool_size(impl->jobs_pool) : 0;

        // trace
        tb_trace_d("wait: jobs: %lu, waiting: %lu, pending: %lu, urgent: %lu: .."
                    , size
                    , tb_list_entry_size(&impl->jobs_waiting)
                    , tb_list_entry_size(&impl->jobs_pending) 
                    , tb_list_entry_size(&impl->jobs_urgent));

#if 0
        tb_for_all_if (tb_thread_pool_job_t*, job, tb_list_entry_itor(&impl->jobs_pending), job)
        {
            tb_trace_d("wait: job: %s from pending", tb_state_cstr(tb_atomic_get(&job->state)));
        }
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
tb_void_t tb_thread_pool_task_exit(tb_thread_pool_ref_t pool, tb_thread_pool_task_ref_t task)
{
    // check
    tb_thread_pool_impl_t*  impl = (tb_thread_pool_impl_t*)pool;
    tb_thread_pool_job_t*   job = (tb_thread_pool_job_t*)task;
    tb_assert_and_check_return(impl && job);

    // kill it first
    tb_thread_pool_task_kill(pool, task);

    // enter
    tb_spinlock_enter(&impl->lock);

    // refn--
    if (job->refn > 1) job->refn--;
    // remove it from pool directly
    else tb_fixed_pool_free(impl->jobs_pool, job);

    // leave
    tb_spinlock_leave(&impl->lock);
}
#ifdef __tb_debug__
tb_void_t tb_thread_pool_dump(tb_thread_pool_ref_t pool)
{
    // check
    tb_thread_pool_impl_t* impl = (tb_thread_pool_impl_t*)pool;
    tb_assert_and_check_return(impl);

    // enter
    tb_spinlock_enter(&impl->lock);

    // dump workers
    if (impl->worker_size)
    {
        // trace
        tb_trace_i("");
        tb_trace_i("workers: size: %lu, maxn: %lu", impl->worker_size, impl->worker_maxn);

        // walk
        tb_size_t i = 0;
        for (i = 0; i < impl->worker_size; i++)
        {
            // the worker
            tb_thread_pool_worker_t* worker = &impl->worker_list[i];
            tb_assert_and_check_break(worker);

            // dump worker
            tb_trace_i("    worker: id: %lu, stoped: %ld", worker->id, (tb_long_t)tb_atomic_get(&worker->bstoped));
        }

        // trace
        tb_trace_i("");

        // dump all jobs
        if (impl->jobs_pool) 
        {
            // trace
            tb_trace_i("jobs: size: %lu", tb_fixed_pool_size(impl->jobs_pool));

            // dump jobs
            tb_fixed_pool_walk(impl->jobs_pool, tb_thread_pool_jobs_walk_dump_all, tb_null);
        }
    }

    // leave
    tb_spinlock_leave(&impl->lock);
}
#endif
