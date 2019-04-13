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
 * @file        scheduler.c
 * @ingroup     coroutine
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
#include "coroutine.h"
#include "scheduler_io.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the dead cache maximum count
#ifdef __tb_small__
#   define TB_SCHEDULER_DEAD_CACHE_MAXN     (64)
#else
#   define TB_SCHEDULER_DEAD_CACHE_MAXN     (256)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t tb_co_scheduler_make_dead(tb_co_scheduler_t* scheduler, tb_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && coroutine);

    // cannot be original coroutine
    tb_assert(!tb_coroutine_is_original(coroutine));

    // remove this coroutine from the ready coroutines
    tb_list_entry_remove(&scheduler->coroutines_ready, (tb_list_entry_ref_t)coroutine);

    // append this coroutine to dead coroutines
    tb_list_entry_insert_tail(&scheduler->coroutines_dead, (tb_list_entry_ref_t)coroutine);
}
static tb_void_t tb_co_scheduler_make_ready(tb_co_scheduler_t* scheduler, tb_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && coroutine);

    // insert this coroutine to ready coroutines 
    if (__tb_unlikely__(tb_coroutine_is_original(scheduler->running)))
    {
        // .. last -> coroutine(inserted)
        tb_list_entry_insert_tail(&scheduler->coroutines_ready, (tb_list_entry_ref_t)coroutine);
    }
    else
    {
        // .. -> coroutine(inserted) -> running -> ..
        tb_list_entry_insert_prev(&scheduler->coroutines_ready, (tb_list_entry_ref_t)scheduler->running, (tb_list_entry_ref_t)coroutine);
    }
}
static tb_void_t tb_co_scheduler_make_suspend(tb_co_scheduler_t* scheduler, tb_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && coroutine);

    // cannot be original coroutine
    tb_assert(!tb_coroutine_is_original(coroutine));

    // remove this coroutine from the ready coroutines
    tb_list_entry_remove(&scheduler->coroutines_ready, (tb_list_entry_ref_t)coroutine);

    // append this coroutine to suspend coroutines
    tb_list_entry_insert_tail(&scheduler->coroutines_suspend, (tb_list_entry_ref_t)coroutine);
}
static __tb_inline__ tb_coroutine_t* tb_co_scheduler_next_ready(tb_co_scheduler_t* scheduler)
{
    // check
    tb_assert(scheduler && scheduler->running && tb_list_entry_size(&scheduler->coroutines_ready));

    // get the next entry 
    tb_list_entry_ref_t entry_next = tb_list_entry_next((tb_list_entry_ref_t)scheduler->running);
    tb_assert(entry_next);

    // is list header? skip it and get the first entry
    if (entry_next == (tb_list_entry_ref_t)&scheduler->coroutines_ready)
        entry_next = tb_list_entry_next(entry_next);

    // get the next ready coroutine
    return (tb_coroutine_t*)tb_list_entry0(entry_next);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_co_scheduler_start(tb_co_scheduler_t* scheduler, tb_coroutine_func_t func, tb_cpointer_t priv, tb_size_t stacksize)
{
    // check
    tb_assert(func);

    // done
    tb_bool_t       ok = tb_false;
    tb_coroutine_t* coroutine = tb_null;
    do
    {
        // trace
        tb_trace_d("start ..");

        // uses the current scheduler if be null
        if (!scheduler) scheduler = (tb_co_scheduler_t*)tb_co_scheduler_self();
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
            tb_coroutine_t* coroutine_dead = (tb_coroutine_t*)tb_list_entry0(entry);

            // reinit this coroutine
            coroutine = tb_coroutine_reinit(coroutine_dead, func, priv, stacksize);

            // failed? exit this coroutine
            if (!coroutine) tb_coroutine_exit(coroutine_dead);
        }

        // init coroutine
        if (!coroutine) coroutine = tb_coroutine_init((tb_co_scheduler_ref_t)scheduler, func, priv, stacksize);
        tb_assert_and_check_break(coroutine);

        // ready coroutine
        tb_co_scheduler_make_ready(scheduler, coroutine);

        // the dead coroutines is too much? free some coroutines
        while (tb_list_entry_size(&scheduler->coroutines_dead) > TB_SCHEDULER_DEAD_CACHE_MAXN)
        {
            // get the next entry from head
            tb_list_entry_ref_t entry = tb_list_entry_head(&scheduler->coroutines_dead);
            tb_assert(entry);

            // remove it from the ready coroutines
            tb_list_entry_remove_head(&scheduler->coroutines_dead);

            // exit this coroutine
            tb_coroutine_exit((tb_coroutine_t*)tb_list_entry0(entry));
        }

        // ok
        ok = tb_true;

    } while (0);

    // trace
    tb_trace_d("start %s", ok? "ok" : "no");

    // ok?
    return ok;
}
tb_bool_t tb_co_scheduler_yield(tb_co_scheduler_t* scheduler)
{
    // check
    tb_assert(scheduler && scheduler->running);
    tb_assert(scheduler->running == (tb_coroutine_t*)tb_coroutine_self());

    // trace
    tb_trace_d("yield coroutine(%p)", scheduler->running);

#ifdef __tb_debug__
    // check it
    tb_coroutine_check(scheduler->running);
#endif

    // get the next ready coroutine
    tb_coroutine_t* coroutine_next = tb_co_scheduler_next_ready(scheduler);
    if (coroutine_next != scheduler->running)
    {
        // switch to the next coroutine
        tb_co_scheduler_switch(scheduler, coroutine_next);

        // ok
        return tb_true;
    }
    // no more coroutine (only running)?
    else
    {
        // trace
        tb_trace_d("continue to run current coroutine(%p)", tb_coroutine_self());

        // check
        tb_assert((tb_list_entry_ref_t)scheduler->running == tb_list_entry_head(&scheduler->coroutines_ready));
    }

    // return it directly and continue to run this coroutine
    return tb_false;
}
tb_pointer_t tb_co_scheduler_resume(tb_co_scheduler_t* scheduler, tb_coroutine_t* coroutine, tb_cpointer_t priv)
{
    // check
    tb_assert(scheduler && coroutine);

    // trace
    tb_trace_d("resume coroutine(%p)", coroutine);

    // remove it from the suspend coroutines
    tb_list_entry_remove(&scheduler->coroutines_suspend, (tb_list_entry_ref_t)coroutine);

    // get the passed private data from suspend(priv)
    tb_pointer_t retval = (tb_pointer_t)coroutine->rs_priv;

    // pass the user private data to suspend()
    coroutine->rs_priv = priv;

    // make it as ready
    tb_co_scheduler_make_ready(scheduler, coroutine);

    // return it
    return retval;
}
tb_pointer_t tb_co_scheduler_suspend(tb_co_scheduler_t* scheduler, tb_cpointer_t priv)
{
    // check
    tb_assert(scheduler && scheduler->running);
    tb_assert(scheduler->running == (tb_coroutine_t*)tb_coroutine_self());

    // have been stopped? return it directly
    tb_check_return_val(!scheduler->stopped, tb_null);

    // trace
    tb_trace_d("suspend coroutine(%p)", scheduler->running);

#ifdef __tb_debug__
    // check it
    tb_coroutine_check(scheduler->running);
#endif

    // pass the private data to resume() first
    scheduler->running->rs_priv = priv;

    // get the next ready coroutine first
    tb_coroutine_t* coroutine_next = tb_co_scheduler_next_ready(scheduler);

    // make the running coroutine as suspend
    tb_co_scheduler_make_suspend(scheduler, scheduler->running);

    // switch to next coroutine 
    if (coroutine_next != scheduler->running) tb_co_scheduler_switch(scheduler, coroutine_next);
    // no more coroutine?
    else
    {
        // trace
        tb_trace_d("switch to original coroutine");

        // switch to the original coroutine 
        tb_co_scheduler_switch(scheduler, &scheduler->original);
    }

    // check
    tb_assert(scheduler->running);

    // return the user private data from resume(priv)
    return (tb_pointer_t)scheduler->running->rs_priv;
}
tb_void_t tb_co_scheduler_finish(tb_co_scheduler_t* scheduler)
{
    // check
    tb_assert(scheduler && scheduler->running);
    tb_assert(scheduler->running == (tb_coroutine_t*)tb_coroutine_self());

    // trace
    tb_trace_d("finish coroutine(%p)", scheduler->running);

#ifdef __tb_debug__
    // check it
    tb_coroutine_check(scheduler->running);
#endif

    // get the next ready coroutine first
    tb_coroutine_t* coroutine_next = tb_co_scheduler_next_ready(scheduler);

    // make the running coroutine as dead
    tb_co_scheduler_make_dead(scheduler, scheduler->running);

    // switch to next coroutine 
    if (coroutine_next != scheduler->running) tb_co_scheduler_switch(scheduler, coroutine_next);
    // no more coroutine?
    else
    {
        // trace
        tb_trace_d("switch to original coroutine");

        // switch to the original coroutine 
        tb_co_scheduler_switch(scheduler, &scheduler->original);
    }
}
tb_pointer_t tb_co_scheduler_sleep(tb_co_scheduler_t* scheduler, tb_long_t interval)
{
    // check
    tb_assert(scheduler && scheduler->running);
    tb_assert(scheduler->running == (tb_coroutine_t*)tb_coroutine_self());

    // have been stopped? return it directly
    tb_check_return_val(!scheduler->stopped, tb_null);

    // need io scheduler
    if (!tb_co_scheduler_io_need(scheduler)) return tb_null;

    // sleep it
    return tb_co_scheduler_io_sleep(scheduler->scheduler_io, interval);
}
tb_void_t tb_co_scheduler_switch(tb_co_scheduler_t* scheduler, tb_coroutine_t* coroutine)
{
    // check
    tb_assert(scheduler && scheduler->running);
    tb_assert(coroutine && coroutine->context);

    // the current running coroutine
    tb_coroutine_t* running = scheduler->running;

    // mark the given coroutine as running
    scheduler->running = coroutine;

    // trace
    tb_trace_d("switch to coroutine(%p) from coroutine(%p)", coroutine, running);

    // jump to the given coroutine
    tb_context_from_t from = tb_context_jump(coroutine->context, running);

    // the from-coroutine 
    tb_coroutine_t* coroutine_from = (tb_coroutine_t*)from.priv;
    tb_assert(coroutine_from && from.context);

#ifdef __tb_debug__
    // check it
    tb_coroutine_check(coroutine_from);
#endif

    // update the context
    coroutine_from->context = from.context;
}
tb_long_t tb_co_scheduler_wait(tb_co_scheduler_t* scheduler, tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout)
{
    // check
    tb_assert(scheduler && scheduler->running);
    tb_assert(scheduler->running == (tb_coroutine_t*)tb_coroutine_self());

    // have been stopped? return it directly
    tb_check_return_val(!scheduler->stopped, -1);

    // need io scheduler
    if (!tb_co_scheduler_io_need(scheduler)) return -1;

    // sleep it
    return tb_co_scheduler_io_wait(scheduler->scheduler_io, sock, events, timeout);
}

