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
 * @file        scheduler.h
 * @ingroup     scheduler
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "scheduler"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "scheduler.h"
#include "../impl/impl.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the dead cache maximum count
#if defined(TB_CONFIG_MICRO_ENABLE)
#   define TB_SCHEDULER_DEAD_CACHE_MAXN     (8)
#elif defined(__tb_small__)
#   define TB_SCHEDULER_DEAD_CACHE_MAXN     (64)
#else
#   define TB_SCHEDULER_DEAD_CACHE_MAXN     (256)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

#if !defined(TB_CONFIG_MICRO_ENABLE) && !defined(__tb_thread_local__)
// the self scheduler local 
static tb_thread_local_t                        g_scheduler_self = TB_THREAD_LOCAL_INIT;
#endif

// the global scheduler for the exclusive mode
#ifdef __tb_thread_local__
static __tb_thread_local__ tb_lo_scheduler_t*   g_scheduler_self_ex = tb_null;
#else
static tb_lo_scheduler_t*                       g_scheduler_self_ex = tb_null;
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t tb_lo_scheduler_free(tb_list_entry_head_ref_t coroutines)
{
    // check
    tb_assert(coroutines);

    // free all coroutines
    while (tb_list_entry_size(coroutines))
    {
        // get the next entry from head
        tb_list_entry_ref_t entry = tb_list_entry_head(coroutines);
        tb_assert(entry);

        // remove it from the ready coroutines
        tb_list_entry_remove_head(coroutines);

        // exit this coroutine
        tb_lo_coroutine_exit((tb_lo_coroutine_t*)tb_list_entry(coroutines, entry));
    }
}
static tb_void_t tb_lo_scheduler_make_ready(tb_lo_scheduler_t* scheduler, tb_lo_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && coroutine);

    // mark ready state
    tb_lo_core_state_set(coroutine, TB_STATE_READY);

    // insert this coroutine to ready coroutines 
    if (scheduler->running)
    { 
        // .. -> coroutine(inserted) -> running -> ..
        tb_list_entry_insert_prev(&scheduler->coroutines_ready, &scheduler->running->entry, &coroutine->entry);
    }
    else
    {
        // .. last -> coroutine(inserted)
        tb_list_entry_insert_tail(&scheduler->coroutines_ready, &coroutine->entry);
    }
}
static tb_void_t tb_lo_scheduler_make_dead(tb_lo_scheduler_t* scheduler, tb_lo_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && coroutine);
    tb_assert(tb_lo_core_state(coroutine) == TB_STATE_END);

    // trace
    tb_trace_d("finish coroutine(%p)", coroutine);

    // free the user private data first
    if (coroutine->free) coroutine->free(coroutine->priv);

    // remove this coroutine from the ready coroutines
    tb_list_entry_remove(&scheduler->coroutines_ready, &coroutine->entry);

    // append this coroutine to dead coroutines
    tb_list_entry_insert_tail(&scheduler->coroutines_dead, &coroutine->entry);
}
static tb_void_t tb_lo_scheduler_make_suspend(tb_lo_scheduler_t* scheduler, tb_lo_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && coroutine);
    tb_assert(tb_lo_core_state(coroutine) == TB_STATE_SUSPEND);

    // trace
    tb_trace_d("suspend coroutine(%p)", coroutine);

    // remove this coroutine from the ready coroutines
    tb_list_entry_remove(&scheduler->coroutines_ready, &coroutine->entry);

    // append this coroutine to suspend coroutines
    tb_list_entry_insert_tail(&scheduler->coroutines_suspend, &coroutine->entry);
}
static __tb_inline__ tb_lo_coroutine_t* tb_lo_scheduler_next_ready(tb_lo_scheduler_t* scheduler)
{
    // check
    tb_assert(scheduler && tb_list_entry_size(&scheduler->coroutines_ready));

    // get the next entry 
    tb_list_entry_ref_t entry_next = scheduler->running? tb_list_entry_next(&scheduler->running->entry) : tb_list_entry_head(&scheduler->coroutines_ready);
    tb_assert(entry_next);

    // is list header? skip it and get the first entry
    if (entry_next == (tb_list_entry_ref_t)&scheduler->coroutines_ready)
        entry_next = tb_list_entry_next(entry_next);

    // get the next ready coroutine
    return (tb_lo_coroutine_t*)tb_list_entry(&scheduler->coroutines_ready, entry_next);
}
static tb_void_t tb_lo_scheduler_switch(tb_lo_scheduler_t* scheduler, tb_lo_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && coroutine && coroutine->func);
    tb_assert(tb_lo_core_state(coroutine) == TB_STATE_READY);

    // trace
    tb_trace_d("switch to coroutine(%p) from coroutine(%p)", coroutine, scheduler->running);

    // mark the given coroutine as running
    scheduler->running = coroutine;

    // call the coroutine function
    coroutine->func((tb_lo_coroutine_ref_t)coroutine, coroutine->priv);
}
tb_bool_t tb_lo_scheduler_start(tb_lo_scheduler_t* scheduler, tb_lo_coroutine_func_t func, tb_cpointer_t priv, tb_lo_coroutine_free_t free)
{
    // check
    tb_assert(func);

    // done
    tb_bool_t           ok = tb_false;
    tb_lo_coroutine_t*  coroutine = tb_null;
    do
    {
        // trace
        tb_trace_d("start ..");

        // get the current scheduler
        if (!scheduler) scheduler = (tb_lo_scheduler_t*)tb_lo_scheduler_self_();
        tb_assert_and_check_break(scheduler);

        // have been stopped? do not continue to start new coroutines
        tb_check_break(!scheduler->stopped);

        // reuses dead coroutines in init function
        if (tb_list_entry_size(&scheduler->coroutines_dead))
        {
            // get the next entry from head
            tb_list_entry_ref_t entry = tb_list_entry_head(&scheduler->coroutines_dead);
            tb_assert_and_check_break(entry);

            // remove it from the ready coroutines
            tb_list_entry_remove_head(&scheduler->coroutines_dead);

            // get the dead coroutine
            coroutine = (tb_lo_coroutine_t*)tb_list_entry(&scheduler->coroutines_dead, entry);

            // reinit this coroutine
            tb_lo_coroutine_reinit(coroutine, func, priv, free);
        }

        // init coroutine
        if (!coroutine) coroutine = tb_lo_coroutine_init((tb_lo_scheduler_ref_t)scheduler, func, priv, free);
        tb_assert_and_check_break(coroutine);

        // ready coroutine
        tb_lo_scheduler_make_ready(scheduler, coroutine);

        // the dead coroutines is too much? free some coroutines
        while (tb_list_entry_size(&scheduler->coroutines_dead) > TB_SCHEDULER_DEAD_CACHE_MAXN)
        {
            // get the next entry from head
            tb_list_entry_ref_t entry = tb_list_entry_head(&scheduler->coroutines_dead);
            tb_assert(entry);

            // remove it from the ready coroutines
            tb_list_entry_remove_head(&scheduler->coroutines_dead);

            // exit this coroutine
            tb_lo_coroutine_exit((tb_lo_coroutine_t*)tb_list_entry(&scheduler->coroutines_dead, entry));
        }

        // ok
        ok = tb_true;

    } while (0);

    // trace
    tb_trace_d("start %s", ok? "ok" : "no");

    // ok?
    return ok;
}
tb_void_t tb_lo_scheduler_resume(tb_lo_scheduler_t* scheduler, tb_lo_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && coroutine);
    tb_assert(tb_lo_core_state(coroutine) == TB_STATE_SUSPEND);

    // remove it from the suspend coroutines
    tb_list_entry_remove(&scheduler->coroutines_suspend, &coroutine->entry);

    // make it as ready
    tb_lo_scheduler_make_ready(scheduler, coroutine);
}
tb_lo_scheduler_ref_t tb_lo_scheduler_self_()
{ 
    // get self scheduler on the current thread
#if defined(TB_CONFIG_MICRO_ENABLE) || defined(__tb_thread_local__)
    return (tb_lo_scheduler_ref_t)g_scheduler_self_ex;
#else
    return (tb_lo_scheduler_ref_t)(g_scheduler_self_ex? g_scheduler_self_ex : tb_thread_local_get(&g_scheduler_self));
#endif
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * public implementation
 */
tb_lo_scheduler_ref_t tb_lo_scheduler_init()
{
    // done
    tb_bool_t           ok = tb_false;
    tb_lo_scheduler_t*  scheduler = tb_null;
    do
    {
        // make scheduler
        scheduler = tb_malloc0_type(tb_lo_scheduler_t);
        tb_assert_and_check_break(scheduler);

        // init dead coroutines
        tb_list_entry_init(&scheduler->coroutines_dead, tb_lo_coroutine_t, entry, tb_null);

        // init ready coroutines
        tb_list_entry_init(&scheduler->coroutines_ready, tb_lo_coroutine_t, entry, tb_null);

        // init suspend coroutines
        tb_list_entry_init(&scheduler->coroutines_suspend, tb_lo_coroutine_t, entry, tb_null);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (scheduler) tb_lo_scheduler_exit((tb_lo_scheduler_ref_t)scheduler);
        scheduler = tb_null;
    }

    // ok?
    return (tb_lo_scheduler_ref_t)scheduler;
}
tb_void_t tb_lo_scheduler_exit(tb_lo_scheduler_ref_t self)
{
    // check
    tb_lo_scheduler_t* scheduler = (tb_lo_scheduler_t*)self;
    tb_assert_and_check_return(scheduler);

    // must be stopped
    tb_assert(scheduler->stopped);
    
    // exit io scheduler first 
    if (scheduler->scheduler_io) tb_lo_scheduler_io_exit(scheduler->scheduler_io);
    scheduler->scheduler_io = tb_null;

    // check coroutines
    tb_assert(!tb_list_entry_size(&scheduler->coroutines_ready));
    tb_assert(!tb_list_entry_size(&scheduler->coroutines_suspend));

    // free all dead coroutines 
    tb_lo_scheduler_free(&scheduler->coroutines_dead);

    // free all ready coroutines 
    tb_lo_scheduler_free(&scheduler->coroutines_ready);

    // free all suspend coroutines 
    tb_lo_scheduler_free(&scheduler->coroutines_suspend);

    // exit dead coroutines
    tb_list_entry_exit(&scheduler->coroutines_dead);

    // exit ready coroutines
    tb_list_entry_exit(&scheduler->coroutines_ready);

    // exit suspend coroutines
    tb_list_entry_exit(&scheduler->coroutines_suspend);

    // exit the scheduler
    tb_free(scheduler);
}
tb_void_t tb_lo_scheduler_kill(tb_lo_scheduler_ref_t self)
{
    // check
    tb_lo_scheduler_t* scheduler = (tb_lo_scheduler_t*)self;
    tb_assert_and_check_return(scheduler);

    // stop it
    scheduler->stopped = tb_true;
}
tb_void_t tb_lo_scheduler_loop(tb_lo_scheduler_ref_t self, tb_bool_t exclusive)
{
    // check
    tb_lo_scheduler_t* scheduler = (tb_lo_scheduler_t*)self;
    tb_assert_and_check_return(scheduler);

#ifdef __tb_thread_local__
    g_scheduler_self_ex = scheduler;
#else
    // is exclusive mode?
    if (exclusive) g_scheduler_self_ex = scheduler;
#   ifndef TB_CONFIG_MICRO_ENABLE
    else
    {
        // init self scheduler local
        if (!tb_thread_local_init(&g_scheduler_self, tb_null)) return ;
     
        // update and overide the current scheduler
        tb_thread_local_set(&g_scheduler_self, self);
    }
#   else
    else
    {
        // trace
        tb_trace_e("non-exclusive is not suspported in micro mode!");
    }
#   endif
#endif

    // schedule all ready coroutines
    while (tb_list_entry_size(&scheduler->coroutines_ready) && !scheduler->stopped) 
    {
        // trace
        tb_trace_d("[loop]: ready %lu", tb_list_entry_size(&scheduler->coroutines_ready));

        // get the next ready coroutine
        tb_lo_coroutine_t* coroutine_next = tb_lo_scheduler_next_ready(scheduler);
        tb_assert(coroutine_next);

        // process the running coroutine
        if (scheduler->running)
        {
            // get the state of running coroutine
            tb_size_t state = tb_lo_core_state(scheduler->running);

            // mark this coroutine as dead if the running coroutine(root level) have been finished
            if (state == TB_STATE_END)
                tb_lo_scheduler_make_dead(scheduler, scheduler->running);
            // suspend the running coroutine 
            else if (state == TB_STATE_SUSPEND)
                tb_lo_scheduler_make_suspend(scheduler, scheduler->running);
        }
            
        // switch to it if the next coroutine (may be running coroutine) is ready
        if (tb_lo_core_state(coroutine_next) == TB_STATE_READY)
            tb_lo_scheduler_switch(scheduler, coroutine_next);
    }

    // stop it
    scheduler->stopped = tb_true;
 
#ifdef __tb_thread_local__
    g_scheduler_self_ex = tb_null;
#else
    // is exclusive mode?
    if (exclusive) g_scheduler_self_ex = tb_null;
#   ifndef TB_CONFIG_MICRO_ENABLE
    else
    {
        // clear the current scheduler
        tb_thread_local_set(&g_scheduler_self, tb_null);
    }
#   endif
#endif
}

