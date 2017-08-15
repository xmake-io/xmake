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
 * @file        scheduler_io.c
 * @ingroup     coroutine
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "scheduler_io"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "scheduler_io.h"
#include "coroutine.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the ltimer grow
#ifdef __tb_small__
#   define TB_SCHEDULER_IO_LTIMER_GROW      (64)
#else
#   define TB_SCHEDULER_IO_LTIMER_GROW      (4096)
#endif

// the timer grow
#define TB_SCHEDULER_IO_TIMER_GROW          (TB_SCHEDULER_IO_LTIMER_GROW >> 4)

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t tb_co_scheduler_io_resume(tb_co_scheduler_t* scheduler, tb_coroutine_t* coroutine, tb_cpointer_t priv)
{
    // exists the timer task? remove it
    tb_cpointer_t task = coroutine->rs.wait.task;
    if (task) 
    {
        // get io scheduler
        tb_co_scheduler_io_ref_t scheduler_io = tb_co_scheduler_io(scheduler);
        tb_assert(scheduler_io && scheduler_io->poller);

        // is high-precision timer?
        tb_size_t is_timer = (tb_size_t)(task) & 0x1;

        // check
        tb_assert((tb_size_t)task & (tb_size_t)~0x1);

        // remove the timer task
        if (__tb_unlikely__(is_timer)) tb_timer_task_exit(scheduler_io->timer, (tb_timer_task_ref_t)((tb_size_t)task & (tb_size_t)~0x1));
        else tb_ltimer_task_exit(scheduler_io->ltimer, (tb_ltimer_task_ref_t)task);
        coroutine->rs.wait.task = tb_null;
    }

    // clear waiting state
    coroutine->rs.wait.waiting = 0;

    // resume the coroutine
    tb_co_scheduler_resume(scheduler, coroutine, priv);
}
static tb_void_t tb_co_scheduler_io_timeout(tb_bool_t killed, tb_cpointer_t priv)
{
    // check
    tb_coroutine_t* coroutine = (tb_coroutine_t*)priv;
    tb_assert(coroutine);

    // get scheduler
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_coroutine_scheduler(coroutine);
    tb_assert(scheduler);

    // trace
    tb_trace_d("coroutine(%p): timer %s", coroutine, killed? "killed" : "timeout");

    // resume the coroutine 
    tb_co_scheduler_io_resume(scheduler, coroutine, tb_null);
}
static tb_void_t tb_co_scheduler_io_events(tb_poller_ref_t poller, tb_socket_ref_t sock, tb_size_t events, tb_cpointer_t priv)
{
    // check
    tb_coroutine_t* coroutine = (tb_coroutine_t*)priv;
    tb_assert(coroutine && poller && sock && priv);

    // get scheduler
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_coroutine_scheduler(coroutine);
    tb_assert(scheduler);

    // trace
    tb_trace_d("coroutine(%p): socket: %p, events %lu", coroutine, sock, events);

    // waiting now?
    if (coroutine->rs.wait.waiting)
    {
        // eof for edge trigger?
        if (events & TB_POLLER_EVENT_EOF)
        {
            // cache this eof as next recv/send event
            events &= ~TB_POLLER_EVENT_EOF;
            coroutine->rs.wait.events_cache |= coroutine->rs.wait.events;
        }

        // resume the coroutine and pass the events to suspend()
        tb_co_scheduler_io_resume(scheduler, coroutine, (tb_cpointer_t)events);
    }
    // cache this events
    else coroutine->rs.wait.events_cache = events;
}
static tb_bool_t tb_co_scheduler_io_timer_spak(tb_co_scheduler_io_ref_t scheduler_io)
{
    // check
    tb_assert(scheduler_io && scheduler_io->timer && scheduler_io->ltimer);

    // spak ctime
    tb_cache_time_spak();

    // spak timer
    if (!tb_timer_spak(scheduler_io->timer)) return tb_false;

    // spak ltimer
    if (!tb_ltimer_spak(scheduler_io->ltimer)) return tb_false;

    // pk
    return tb_true;
}
static tb_void_t tb_co_scheduler_io_loop(tb_cpointer_t priv)
{
    // check
    tb_co_scheduler_io_ref_t scheduler_io = (tb_co_scheduler_io_ref_t)priv;
    tb_assert_and_check_return(scheduler_io && scheduler_io->timer && scheduler_io->ltimer);

    // the scheduler
    tb_co_scheduler_t* scheduler = scheduler_io->scheduler;
    tb_assert_and_check_return(scheduler);

    // the poller
    tb_poller_ref_t poller = scheduler_io->poller;
    tb_assert_and_check_return(poller);

    // loop
    while (!scheduler->stopped)
    {
        // finish all other ready coroutines first
        while (tb_co_scheduler_yield(scheduler)) 
        {
            // spak timer
            if (!tb_co_scheduler_io_timer_spak(scheduler_io)) break;
        }

        // no more suspended coroutines? loop end
        tb_check_break(tb_co_scheduler_suspend_count(scheduler));

        // the delay
        tb_size_t delay = tb_timer_delay(scheduler_io->timer);

        // the ldelay
        tb_size_t ldelay = tb_ltimer_delay(scheduler_io->ltimer);

        // trace
        tb_trace_d("loop: wait %lu ms ..", tb_min(delay, ldelay));

        // no more ready coroutines? wait io events and timers
        if (tb_poller_wait(poller, tb_co_scheduler_io_events, tb_min(delay, ldelay)) < 0) break;

        // spak timer
        if (!tb_co_scheduler_io_timer_spak(scheduler_io)) break;
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_co_scheduler_io_ref_t tb_co_scheduler_io_init(tb_co_scheduler_t* scheduler)
{
    // done
    tb_bool_t                   ok = tb_false;
    tb_co_scheduler_io_ref_t    scheduler_io = tb_null;
    do
    {
        // init io scheduler
        scheduler_io = tb_malloc0_type(tb_co_scheduler_io_t);
        tb_assert_and_check_break(scheduler_io);

        // save scheduler
        scheduler_io->scheduler = (tb_co_scheduler_t*)scheduler;

        // init timer and using cache time
        scheduler_io->timer = tb_timer_init(TB_SCHEDULER_IO_TIMER_GROW, tb_true);
        tb_assert_and_check_break(scheduler_io->timer);

        // init ltimer and using cache time
        scheduler_io->ltimer = tb_ltimer_init(TB_SCHEDULER_IO_LTIMER_GROW, TB_LTIMER_TICK_S, tb_true);
        tb_assert_and_check_break(scheduler_io->ltimer);

        // init poller
        scheduler_io->poller = tb_poller_init(tb_null);
        tb_assert_and_check_break(scheduler_io->poller);

        // start the io loop coroutine
        if (!tb_co_scheduler_start(scheduler_io->scheduler, tb_co_scheduler_io_loop, scheduler_io, 0)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit io scheduler
        if (scheduler_io) tb_co_scheduler_io_exit(scheduler_io);
        scheduler_io = tb_null;
    }

    // ok?
    return scheduler_io;
}
tb_void_t tb_co_scheduler_io_exit(tb_co_scheduler_io_ref_t scheduler_io)
{
    // check
    tb_assert_and_check_return(scheduler_io);

    // exit poller
    if (scheduler_io->poller) tb_poller_exit(scheduler_io->poller);
    scheduler_io->poller = tb_null;

    // exit timer
    if (scheduler_io->timer) tb_timer_exit(scheduler_io->timer);
    scheduler_io->timer = tb_null;

    // exit ltimer
    if (scheduler_io->ltimer) tb_ltimer_exit(scheduler_io->ltimer);
    scheduler_io->ltimer = tb_null;

    // clear scheduler
    scheduler_io->scheduler = tb_null;

    // exit it
    tb_free(scheduler_io);
}
tb_void_t tb_co_scheduler_io_kill(tb_co_scheduler_io_ref_t scheduler_io)
{
    // check
    tb_assert_and_check_return(scheduler_io);

    // trace
    tb_trace_d("kill: ..");

    // kill timer
    if (scheduler_io->timer) tb_timer_kill(scheduler_io->timer);

    // kill ltimer
    if (scheduler_io->ltimer) tb_ltimer_kill(scheduler_io->ltimer);

    // kill poller
    if (scheduler_io->poller) tb_poller_kill(scheduler_io->poller);
}
tb_pointer_t tb_co_scheduler_io_sleep(tb_co_scheduler_io_ref_t scheduler_io, tb_long_t interval)
{
    // check
    tb_assert_and_check_return_val(scheduler_io && scheduler_io->poller && scheduler_io->scheduler, tb_null);

    // no sleep?
    tb_check_return_val(interval, tb_null);

    // get the current coroutine
    tb_coroutine_t* coroutine = tb_co_scheduler_running(scheduler_io->scheduler);
    tb_assert(coroutine);

    // trace
    tb_trace_d("coroutine(%p): sleep %ld ms ..", coroutine, interval);

    // infinity?
    if (interval > 0)
    {
        // high-precision interval?
        if (interval % 1000)
        {
            // post task to timer
            tb_timer_task_post(scheduler_io->timer, interval, tb_false, tb_co_scheduler_io_timeout, coroutine);
        }
        // low-precision interval?
        else
        {
            // post task to ltimer (faster)
            tb_ltimer_task_post(scheduler_io->ltimer, interval, tb_false, tb_co_scheduler_io_timeout, coroutine);
        }
    }

    // suspend it
    return tb_co_scheduler_suspend(scheduler_io->scheduler, tb_null);
}
tb_long_t tb_co_scheduler_io_wait(tb_co_scheduler_io_ref_t scheduler_io, tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout)
{
    // check
    tb_assert(scheduler_io && sock && scheduler_io->poller && scheduler_io->scheduler && events);

    // get the current coroutine
    tb_coroutine_t* coroutine = tb_co_scheduler_running(scheduler_io->scheduler);
    tb_assert(coroutine);

    // trace
    tb_trace_d("coroutine(%p): wait events(%lu) with %ld ms for socket(%p) ..", coroutine, events, timeout, sock);

    // enable edge-trigger mode if be supported
    if (tb_poller_support(scheduler_io->poller, TB_POLLER_EVENT_CLEAR))
        events |= TB_POLLER_EVENT_CLEAR;

    // exists this socket? only modify events 
    tb_socket_ref_t sock_prev = coroutine->rs.wait.sock;
    if (sock_prev == sock)
    {
        // return the cached events directly if the waiting events exists cache
        tb_size_t events_prev   = coroutine->rs.wait.events;
        tb_size_t events_cache  = coroutine->rs.wait.events_cache;
        if (events_cache && (events_prev & events))
        {
            // clear cache events
            coroutine->rs.wait.events_cache &= ~events;

            // return the cached events
            return events_cache & events;
        }

        // modify socket from poller for waiting events if the waiting events has been changed 
        if (events_prev != events && !tb_poller_modify(scheduler_io->poller, sock, events, coroutine))
        {
            // trace
            tb_trace_e("failed to modify sock(%p) to poller on coroutine(%p)!", sock, coroutine);

            // failed
            return -1;
        }
    }
    else
    {
        // remove the previous socket first if exists
        if (sock_prev && !tb_poller_remove(scheduler_io->poller, sock_prev))
        {
            // trace
            tb_trace_e("failed to remove sock(%p) to poller on coroutine(%p)!", sock_prev, coroutine);

            // failed
            return -1;
        }

        // insert socket to poller for waiting events
        if (!tb_poller_insert(scheduler_io->poller, sock, events, coroutine))
        {
            // trace
            tb_trace_e("failed to insert sock(%p) to poller on coroutine(%p)!", sock, coroutine);

            // failed
            return -1;
        }
    }

    // exists timeout?
    tb_cpointer_t   task = tb_null;
    tb_bool_t       is_ltimer = tb_false;
    if (timeout >= 0)
    {
        // high-precision interval?
        if (timeout % 1000)
        {
            // init task for timer
            task = tb_timer_task_init(scheduler_io->timer, timeout, tb_false, tb_co_scheduler_io_timeout, coroutine);
            tb_assert_and_check_return_val(task, tb_false);
        }
        // low-precision interval?
        else
        {
            // init task for ltimer (faster)
            task = tb_ltimer_task_init(scheduler_io->ltimer, timeout, tb_false, tb_co_scheduler_io_timeout, coroutine);
            tb_assert_and_check_return_val(task, tb_false);

            // mark as low-precision timer
            is_ltimer = tb_true;
        }
    }

    // check
    tb_assert(!((tb_size_t)(task) & 0x1));

    // save the timer task to coroutine
    coroutine->rs.wait.task = (is_ltimer || !task)? task : (tb_cpointer_t)((tb_size_t)(task) | 0x1);

    // save the socket to coroutine for the timer function
    coroutine->rs.wait.sock = sock;

    // save waiting events to coroutine
    coroutine->rs.wait.events        = (tb_uint16_t)events;
    coroutine->rs.wait.events_cache  = 0;

    // mark as waiting state
    coroutine->rs.wait.waiting       = 1;

    // suspend the current coroutine and return the waited result
    return (tb_long_t)tb_co_scheduler_suspend(scheduler_io->scheduler, tb_null);
}
tb_bool_t tb_co_scheduler_io_cancel(tb_co_scheduler_io_ref_t scheduler_io, tb_socket_ref_t sock)
{
    // check
    tb_assert(scheduler_io && sock && scheduler_io->poller && scheduler_io->scheduler);

    // get the current coroutine
    tb_coroutine_t* coroutine = tb_co_scheduler_running(scheduler_io->scheduler);
    tb_check_return_val(coroutine, tb_false);

    // trace
    tb_trace_d("coroutine(%p): cancel socket(%p) ..", coroutine, sock);

    // remove the this socket from poller
    if (coroutine->rs.wait.sock == sock)
    {
        // remove the previous socket first if exists
        if (!tb_poller_remove(scheduler_io->poller, sock))
        {
            // trace
            tb_trace_e("failed to remove sock(%p) to poller on coroutine(%p)!", sock, coroutine);

            // failed
            return tb_false;
        }

        // remove ok
        return tb_true;
    }

    // no this socket
    return tb_false;
}
tb_co_scheduler_io_ref_t tb_co_scheduler_io_self()
{
    // get the current scheduler
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_co_scheduler_self();
   
    // get the current io scheduler
    return scheduler? (tb_co_scheduler_io_ref_t)scheduler->scheduler_io : tb_null;
}
