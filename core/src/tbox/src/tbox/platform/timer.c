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
 * @file        timer.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "timer"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "platform.h"
#include "../memory/memory.h"
#include "../container/container.h"
#include "../algorithm/algorithm.h"
#include "../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the timer task type
typedef struct __tb_timer_task_t
{
    // the func
    tb_timer_task_func_t        func;

    // the priv
    tb_cpointer_t               priv;

    // the when
    tb_hong_t                   when;

    // the period
    tb_uint32_t                 period  : 28;

    // is repeat?
    tb_uint32_t                 repeat  : 1;

    // is killed?
    tb_uint32_t                 killed  : 1;

    // the refn, <= 2
    tb_uint32_t                 refn    : 2;

}tb_timer_task_t;

/// the timer type
typedef struct __tb_timer_t
{
    // the grow
    tb_size_t                   grow;

    // is stoped?
    tb_atomic_t                 stop;

    // is worked?
    tb_atomic_t                 work;

    // cache time?
    tb_bool_t                   ctime;

    // the lock
    tb_spinlock_t               lock;

    // the pool
    tb_fixed_pool_ref_t         pool;

    // the heap
    tb_heap_ref_t               heap;

    // the event
    tb_event_ref_t              event;

}tb_timer_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_hong_t tb_timer_now(tb_timer_t* timer)
{
    // using the real time?
    if (!timer->ctime)
    {
        // get the time
        tb_timeval_t tv = {0};
        if (tb_gettimeofday(&tv, tb_null)) return ((tb_hong_t)tv.tv_sec * 1000 + tv.tv_usec / 1000);
    }

    // using cached time
    return tb_cache_time_mclock();
}
static tb_long_t tb_timer_comp_by_when(tb_element_ref_t element, tb_cpointer_t ldata, tb_cpointer_t rdata)
{
    // check
    tb_timer_task_t const* ltask = (tb_timer_task_t const*)ldata;
    tb_timer_task_t const* rtask = (tb_timer_task_t const*)rdata;
    tb_assert_and_check_return_val(ltask && rtask, -1);

    // comp
    return (ltask->when > rtask->when? 1 : (ltask->when < rtask->when? -1 : 0));
}
static tb_bool_t tb_timer_pred_by_task(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // is equal?
    return item == value;
}
static tb_int_t tb_timer_instance_loop(tb_cpointer_t priv)
{
    // timer
    tb_timer_ref_t timer = (tb_timer_ref_t)priv;

    // trace
    tb_trace_d("loop: init");

    // loop timer
    if (timer) tb_timer_loop(timer);
    
    // trace
    tb_trace_d("loop: exit");

    // exit
    return 0;
}
static tb_handle_t tb_timer_instance_init(tb_cpointer_t* ppriv)
{
    // check
    tb_assert_and_check_return_val(ppriv, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_timer_ref_t      timer = tb_null;
    do
    {
        // init timer
        timer = tb_timer_init(0, tb_true);
        tb_assert_and_check_break(timer);

        // init loop
        *ppriv = (tb_cpointer_t)tb_thread_init(tb_null, tb_timer_instance_loop, timer, 0);
        tb_assert_and_check_break(*ppriv);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit timer
        if (timer) tb_timer_exit(timer);
        timer = tb_null;
    }

    // ok?
    return (tb_handle_t)timer;
}
static tb_void_t tb_timer_instance_exit(tb_handle_t handle, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return(handle);

    // exit loop
    tb_thread_ref_t loop = (tb_thread_ref_t)priv;
    if (loop)
    {
        // wait it
        if (!tb_thread_wait(loop, 5000, tb_null)) return ;

        // exit it
        tb_thread_exit(loop);
    }

    // exit it
    tb_timer_exit((tb_timer_ref_t)handle);
}
static tb_void_t tb_timer_instance_kill(tb_handle_t handle, tb_cpointer_t priv)
{
    // kill it
    if (handle) tb_timer_kill((tb_timer_ref_t)handle);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_timer_ref_t tb_timer()
{
    return (tb_timer_ref_t)tb_singleton_instance(TB_SINGLETON_TYPE_TIMER, tb_timer_instance_init, tb_timer_instance_exit, tb_timer_instance_kill, tb_null);
}
tb_timer_ref_t tb_timer_init(tb_size_t grow, tb_bool_t ctime)
{
    // done
    tb_bool_t   ok = tb_false;
    tb_timer_t* timer = tb_null;
    do
    {
        // make timer
        timer = tb_malloc0_type(tb_timer_t);
        tb_assert_and_check_break(timer);

        // init element
        tb_element_t element = tb_element_ptr(tb_null, tb_null); element.comp = tb_timer_comp_by_when;

        // init timer
        timer->grow         = tb_max(grow, 16);
        timer->ctime        = ctime;

        // init lock
        if (!tb_spinlock_init(&timer->lock)) break;

        // init pool
        timer->pool         = tb_fixed_pool_init(tb_null, timer->grow, sizeof(tb_timer_task_t), tb_null, tb_null, tb_null);
        tb_assert_and_check_break(timer->pool);
        
        // init heap
        timer->heap         = tb_heap_init(timer->grow, element);
        tb_assert_and_check_break(timer->heap);

        // register lock profiler
#ifdef TB_LOCK_PROFILER_ENABLE
        tb_lock_profiler_register(tb_lock_profiler(), (tb_pointer_t)&timer->lock, TB_TRACE_MODULE_NAME);
#endif
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (timer) tb_timer_exit((tb_timer_ref_t)timer);
        timer = tb_null;
    }

    // ok?
    return (tb_timer_ref_t)timer;
}
tb_void_t tb_timer_exit(tb_timer_ref_t self)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return(timer);

    // kill it first
    tb_timer_kill(self);

    // wait loop exit
    tb_size_t tryn = 10;
    while (tb_atomic_get(&timer->work) && tryn--) tb_msleep(500);

    // warning
    if (!tryn && tb_atomic_get(&timer->work)) 
    {
        tb_trace_w("[timer]: the loop has been not exited now!");
    }

    // enter
    tb_spinlock_enter(&timer->lock);

    // exit heap
    if (timer->heap) tb_heap_exit(timer->heap);
    timer->heap = tb_null;

    // exit pool
    if (timer->pool) tb_fixed_pool_exit(timer->pool);
    timer->pool = tb_null;

    // exit event
    if (timer->event) tb_event_exit(timer->event);
    timer->event = tb_null;

    // leave
    tb_spinlock_leave(&timer->lock);

    // exit lock
    tb_spinlock_exit(&timer->lock);

    // exit it
    tb_free(timer);
}
tb_void_t tb_timer_kill(tb_timer_ref_t self)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return(timer);

    // stop it
    if (!tb_atomic_fetch_and_set(&timer->stop, 1))
    {
        // get event
        tb_spinlock_enter(&timer->lock);
        tb_event_ref_t event = timer->event;
        tb_spinlock_leave(&timer->lock);

        // post event
        if (event) tb_event_post(event);
    }
}
tb_void_t tb_timer_clear(tb_timer_ref_t self)
{
    tb_timer_t* timer = (tb_timer_t*)self;
    if (timer)
    {
        // enter
        tb_spinlock_enter(&timer->lock);

        // clear heap
        if (timer->heap) tb_heap_clear(timer->heap);

        // clear pool
        if (timer->pool) tb_fixed_pool_clear(timer->pool);

        // leave
        tb_spinlock_leave(&timer->lock);
    }
}
tb_hize_t tb_timer_top(tb_timer_ref_t self)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return_val(timer && timer->heap, -1);

    // stoped?
    tb_assert_and_check_return_val(!tb_atomic_get(&timer->stop), -1);

    // enter
    tb_spinlock_enter(&timer->lock);

    // done
    tb_hize_t when = -1; 
    if (tb_heap_size(timer->heap))
    {
        // the task
        tb_timer_task_t const* timer_task = (tb_timer_task_t const*)tb_heap_top(timer->heap);
        if (timer_task) when = timer_task->when;
    }

    // leave
    tb_spinlock_leave(&timer->lock);

    // ok?
    return when;
}
tb_size_t tb_timer_delay(tb_timer_ref_t self)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return_val(timer && timer->heap, -1);

    // stoped?
    tb_assert_and_check_return_val(!tb_atomic_get(&timer->stop), -1);

    // enter
    tb_spinlock_enter(&timer->lock);

    // done
    tb_size_t delay = -1; 
    if (tb_heap_size(timer->heap))
    {
        // the task
        tb_timer_task_t const* timer_task = (tb_timer_task_t const*)tb_heap_top(timer->heap);
        if (timer_task)
        {
            // the now
            tb_hong_t now = tb_timer_now(timer);

            // the delay
            delay = timer_task->when > now? (tb_size_t)(timer_task->when - now) : 0;
        }
    }

    // leave
    tb_spinlock_leave(&timer->lock);

    // ok?
    return delay;
}
tb_bool_t tb_timer_spak(tb_timer_ref_t self)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return_val(timer && timer->pool && timer->heap, tb_false);

    // stoped?
    tb_check_return_val(!tb_atomic_get(&timer->stop), tb_false);

    // enter
    tb_spinlock_enter(&timer->lock);

    // done
    tb_bool_t               ok = tb_false;
    tb_timer_task_func_t    func = tb_null;
    tb_cpointer_t           priv = tb_null;
    tb_bool_t               killed = tb_false;
    do
    {
        // empty? 
        if (!tb_heap_size(timer->heap))
        {
            ok = tb_true;
            break;
        }

        // the top task
        tb_timer_task_t* timer_task = (tb_timer_task_t*)tb_heap_top(timer->heap);
        tb_assert_and_check_break(timer_task);

        // check refn
        tb_assert(timer_task->refn);

        // the now
        tb_hong_t now = tb_timer_now(timer);

        // timeout?
        if (timer_task->when <= now)
        {
            // pop it
            tb_heap_pop(timer->heap);

            // save func and data for calling it later
            func = timer_task->func;
            priv = timer_task->priv;

            // killed?
            killed = timer_task->killed? tb_true : tb_false;

            // repeat?
            if (timer_task->repeat)
            {
                // update when
                timer_task->when = now + timer_task->period;

                // continue timer_task
                tb_heap_put(timer->heap, timer_task);
            }
            else 
            {
                // refn--
                if (timer_task->refn > 1) timer_task->refn--;
                // remove it from pool directly
                else tb_fixed_pool_free(timer->pool, timer_task);
            }
        }

        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&timer->lock);

    // done func
    if (func) func(killed, priv);

    // ok?
    return ok;
}
tb_void_t tb_timer_loop(tb_timer_ref_t self)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return(timer);

    // work++
    tb_atomic_fetch_and_inc(&timer->work);

    // init event 
    tb_spinlock_enter(&timer->lock);
    if (!timer->event) timer->event = tb_event_init();
    tb_spinlock_leave(&timer->lock);

    // loop
    while (!tb_atomic_get(&timer->stop))
    {
        // the delay
        tb_size_t delay = tb_timer_delay(self);
        if (delay)
        {
            // the event
            tb_spinlock_enter(&timer->lock);
            tb_event_ref_t event = timer->event;
            tb_spinlock_leave(&timer->lock);
            tb_check_break(event);

            // wait some time
            if (tb_event_wait(event, delay) < 0) break;
        }

        // spak ctime
        if (timer->ctime) tb_cache_time_spak();

        // spak it
        if (!tb_timer_spak(self)) break;
    }

    // work--
    tb_atomic_fetch_and_dec(&timer->work);
}
tb_timer_task_ref_t tb_timer_task_init(tb_timer_ref_t self, tb_size_t delay, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return_val(timer && func, tb_null);

    // add timer_task
    return tb_timer_task_init_at(self, tb_timer_now(timer) + delay, delay, repeat, func, priv);
}
tb_timer_task_ref_t tb_timer_task_init_at(tb_timer_ref_t self, tb_hize_t when, tb_size_t period, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return_val(timer && timer->pool && timer->heap && func, tb_null);

    // stoped?
    tb_assert_and_check_return_val(!tb_atomic_get(&timer->stop), tb_null);

    // enter
    tb_spinlock_enter(&timer->lock);

    // make task
    tb_event_ref_t      event = tb_null;
    tb_hize_t           when_top = -1;
    tb_timer_task_t*    timer_task = (tb_timer_task_t*)tb_fixed_pool_malloc0(timer->pool);
    if (timer_task)
    {
        // the top when 
        if (tb_heap_size(timer->heap))
        {
            tb_timer_task_t* timer_task = (tb_timer_task_t*)tb_heap_top(timer->heap);
            if (timer_task) when_top = timer_task->when;
        }

        // init task
        timer_task->refn      = 2;
        timer_task->func      = func;
        timer_task->priv      = priv;
        timer_task->when      = when;
        timer_task->period    = period;
        timer_task->repeat    = repeat? 1 : 0;

        // add task
        tb_heap_put(timer->heap, timer_task);

        // the event
        event = timer->event;
    }

    // leave
    tb_spinlock_leave(&timer->lock);

    // post event if the top task is changed
    if (event && timer_task && when < when_top)
        tb_event_post(event);

    // ok?
    return (tb_timer_task_ref_t)timer_task;
}
tb_timer_task_ref_t tb_timer_task_init_after(tb_timer_ref_t self, tb_hize_t after, tb_size_t period, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return_val(timer && func, tb_null);

    // add task
    return tb_timer_task_init_at(self, tb_timer_now(timer) + after, period, repeat, func, priv);
}
tb_void_t tb_timer_task_post(tb_timer_ref_t self, tb_size_t delay, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return(timer && func);

    // run task
    tb_timer_task_post_at(self, tb_timer_now(timer) + delay, delay, repeat, func, priv);
}
tb_void_t tb_timer_task_post_at(tb_timer_ref_t self, tb_hize_t when, tb_size_t period, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return(timer && timer->pool && timer->heap && func);

    // stoped?
    tb_assert_and_check_return(!tb_atomic_get(&timer->stop));

    // enter
    tb_spinlock_enter(&timer->lock);

    // make task
    tb_event_ref_t      event = tb_null;
    tb_hize_t           when_top = -1;
    tb_timer_task_t*    timer_task = (tb_timer_task_t*)tb_fixed_pool_malloc0(timer->pool);
    if (timer_task)
    {
        // the top when 
        if (tb_heap_size(timer->heap))
        {
            tb_timer_task_t* timer_task = (tb_timer_task_t*)tb_heap_top(timer->heap);
            if (timer_task) when_top = timer_task->when;
        }

        // init task
        timer_task->refn      = 1;
        timer_task->func      = func;
        timer_task->priv      = priv;
        timer_task->when      = when;
        timer_task->period    = period;
        timer_task->repeat    = repeat? 1 : 0;

        // add task
        tb_heap_put(timer->heap, timer_task);

        // the event
        event = timer->event;
    }

    // leave
    tb_spinlock_leave(&timer->lock);

    // post event if the top task is changed
    if (event && timer_task && when < when_top)
        tb_event_post(event);
}
tb_void_t tb_timer_task_post_after(tb_timer_ref_t self, tb_hize_t after, tb_size_t period, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_timer_t* timer = (tb_timer_t*)self;
    tb_assert_and_check_return(timer && func);

    // run task 
    tb_timer_task_post_at(self, tb_timer_now(timer) + after, period, repeat, func, priv);
}
tb_void_t tb_timer_task_exit(tb_timer_ref_t self, tb_timer_task_ref_t task)
{
    // check
    tb_timer_t*             timer = (tb_timer_t*)self;
    tb_timer_task_t*   timer_task = (tb_timer_task_t*)task;
    tb_assert_and_check_return(timer && timer->pool && timer_task);

    // trace
    tb_trace_d("exit: when: %lld, period: %u, refn: %u", timer_task->when, timer_task->period, timer_task->refn);

    // enter
    tb_spinlock_enter(&timer->lock);

    // remove it?
    if (timer_task->refn > 1)
    {
        // refn--
        timer_task->refn--;

        // cancel task 
        timer_task->func      = tb_null;
        timer_task->priv      = tb_null;
        timer_task->repeat    = 0;
    }
    // remove it from pool directly if the timer_task have been expired 
    else tb_fixed_pool_free(timer->pool, timer_task);

    // leave
    tb_spinlock_leave(&timer->lock);
}
tb_void_t tb_timer_task_kill(tb_timer_ref_t self, tb_timer_task_ref_t task)
{
    // check
    tb_timer_t*         timer = (tb_timer_t*)self;
    tb_timer_task_t*    timer_task = (tb_timer_task_t*)task;
    tb_assert_and_check_return(timer && timer->pool && timer_task);

    // trace
    tb_trace_d("kill: when: %lld, period: %u, refn: %u", timer_task->when, timer_task->period, timer_task->refn);

    // enter
    tb_spinlock_enter(&timer->lock);

    // done
    do
    {
        // expired or removed?
        tb_check_break(timer_task->refn == 2);

        // find it
        tb_size_t itor = tb_find_all_if(timer->heap, tb_timer_pred_by_task, timer_task);
        tb_assert_and_check_break(itor != tb_iterator_tail(timer->heap));

        // remove this task
        tb_heap_remove(timer->heap, itor);

        // killed
        timer_task->killed = 1;

        // no repeat
        timer_task->repeat = 0;
                
        // modify when => now
        timer_task->when = tb_timer_now(timer);

        // re-add timer_task
        tb_heap_put(timer->heap, timer_task);

    } while (0);

    // leave
    tb_spinlock_leave(&timer->lock);
}
