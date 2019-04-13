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
#include "impl/impl.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the self scheduler local 
#ifndef __tb_thread_local__
static tb_thread_local_t                        g_scheduler_self = TB_THREAD_LOCAL_INIT;
#endif

// the global scheduler for the exclusive mode
#ifdef __tb_thread_local__
static __tb_thread_local__ tb_co_scheduler_t*   g_scheduler_self_ex = tb_null;
#else
static tb_co_scheduler_t*                       g_scheduler_self_ex = tb_null;
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t tb_co_scheduler_free(tb_list_entry_head_ref_t coroutines)
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
        tb_coroutine_exit((tb_coroutine_t*)tb_list_entry0(entry));
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_co_scheduler_ref_t tb_co_scheduler_init()
{
    // done
    tb_bool_t           ok = tb_false;
    tb_co_scheduler_t*  scheduler = tb_null;
    do
    {
        // make scheduler
        scheduler = tb_malloc0_type(tb_co_scheduler_t);
        tb_assert_and_check_break(scheduler);

        // init dead coroutines
        tb_list_entry_init(&scheduler->coroutines_dead, tb_coroutine_t, entry, tb_null);

        // init ready coroutines
        tb_list_entry_init(&scheduler->coroutines_ready, tb_coroutine_t, entry, tb_null);

        // init suspend coroutines
        tb_list_entry_init(&scheduler->coroutines_suspend, tb_coroutine_t, entry, tb_null);

        // init original coroutine
        scheduler->original.scheduler = (tb_co_scheduler_ref_t)scheduler;

        // init running
        scheduler->running = &scheduler->original;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (scheduler) tb_co_scheduler_exit((tb_co_scheduler_ref_t)scheduler);
        scheduler = tb_null;
    }

    // ok?
    return (tb_co_scheduler_ref_t)scheduler;
}
tb_void_t tb_co_scheduler_exit(tb_co_scheduler_ref_t self)
{
    // check
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)self;
    tb_assert_and_check_return(scheduler);

    // must be stopped
    tb_assert(scheduler->stopped);

    // exit io scheduler first
    if (scheduler->scheduler_io) tb_co_scheduler_io_exit(scheduler->scheduler_io);
    scheduler->scheduler_io = tb_null;

    // clear running
    scheduler->running = tb_null;

    // check coroutines
    tb_assert(!tb_list_entry_size(&scheduler->coroutines_ready));
    tb_assert(!tb_list_entry_size(&scheduler->coroutines_suspend));

    // free all dead coroutines 
    tb_co_scheduler_free(&scheduler->coroutines_dead);

    // free all ready coroutines 
    tb_co_scheduler_free(&scheduler->coroutines_ready);

    // free all suspend coroutines 
    tb_co_scheduler_free(&scheduler->coroutines_suspend);

    // exit dead coroutines
    tb_list_entry_exit(&scheduler->coroutines_dead);

    // exit ready coroutines
    tb_list_entry_exit(&scheduler->coroutines_ready);

    // exit suspend coroutines
    tb_list_entry_exit(&scheduler->coroutines_suspend);

    // exit the scheduler
    tb_free(scheduler);
}
tb_void_t tb_co_scheduler_kill(tb_co_scheduler_ref_t self)
{
    // check
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)self;
    tb_assert_and_check_return(scheduler);

    // stop it
    scheduler->stopped = tb_true;

    // kill the io scheduler
    if (scheduler->scheduler_io) tb_co_scheduler_io_kill(scheduler->scheduler_io);
}
tb_void_t tb_co_scheduler_loop(tb_co_scheduler_ref_t self, tb_bool_t exclusive)
{
    // check
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)self;
    tb_assert_and_check_return(scheduler);

#ifdef __tb_thread_local__
    g_scheduler_self_ex = scheduler;
#else
    // is exclusive mode?
    if (exclusive) g_scheduler_self_ex = scheduler;
    else
    {
        // init self scheduler local
        if (!tb_thread_local_init(&g_scheduler_self, tb_null)) return ;
     
        // update and overide the current scheduler
        tb_thread_local_set(&g_scheduler_self, self);
    }
#endif

    // schedule all ready coroutines
    while (tb_list_entry_size(&scheduler->coroutines_ready)) 
    {
        // check
        tb_assert(tb_coroutine_is_original(scheduler->running));

        // get the next entry from head
        tb_list_entry_ref_t entry = tb_list_entry_head(&scheduler->coroutines_ready);
        tb_assert(entry);

        // switch to the next coroutine 
        tb_co_scheduler_switch(scheduler, (tb_coroutine_t*)tb_list_entry0(entry));

        // trace
        tb_trace_d("[loop]: ready %lu", tb_list_entry_size(&scheduler->coroutines_ready));
    }

    // stop it
    scheduler->stopped = tb_true;
 
#ifdef __tb_thread_local__
    g_scheduler_self_ex = tb_null;
#else
    // is exclusive mode?
    if (exclusive) g_scheduler_self_ex = tb_null;
    else
    {
        // clear the current scheduler
        tb_thread_local_set(&g_scheduler_self, tb_null);
    }
#endif
}
tb_co_scheduler_ref_t tb_co_scheduler_self()
{ 
    // get self scheduler on the current thread
#ifdef __tb_thread_local__
    return (tb_co_scheduler_ref_t)g_scheduler_self_ex;
#else
    return (tb_co_scheduler_ref_t)(g_scheduler_self_ex? g_scheduler_self_ex : tb_thread_local_get(&g_scheduler_self));
#endif
}
