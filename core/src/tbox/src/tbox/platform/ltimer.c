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
 * @file        ltimer.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "ltimer"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "platform.h"
#include "../memory/memory.h"
#include "../container/container.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the timer wheel maxn
#ifdef __tb_small__
#   define TB_LTIMER_WHEEL_MAXN             (4096)
#else
#   define TB_LTIMER_WHEEL_MAXN             (8192)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the timer task type
typedef struct __tb_ltimer_task_t
{
    // the func
    tb_ltimer_task_func_t       func;

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

    // the wheel index
    tb_uint32_t                 windx;

}tb_ltimer_task_t;

/*! the timer type
 *
 * <pre>
 *
 * tick: 1s
 *
 *           1s    1s   ..
 * wheel: |-----|-----|-----|-----|-----|-----|---- ... -----|  <= circle queue
 *                             timers
 *                 btime ==================> now
 *                       |     |     |
 *                       |     |     |
 *                       |     |     | => the same timeout timer_task list (vector)
 *                                   |
 *
 * </pre>
 */
typedef struct __tb_ltimer_t
{
    // the grow
    tb_size_t                   grow;

    // is stoped?
    tb_atomic_t                 stop;

    // is worked?
    tb_atomic_t                 work;

    // the base time
    tb_hong_t                   btime;

    // cache time?
    tb_bool_t                   ctime;

    // the tick
    tb_size_t                   tick;

    // the lock
    tb_spinlock_t               lock;

    // the pool
    tb_fixed_pool_ref_t         pool;

    // the expired tasks
    tb_vector_ref_t             expired;

    // the wheel
    tb_vector_ref_t             wheel[TB_LTIMER_WHEEL_MAXN];

    // the wheel base
    tb_size_t                   wbase;

}tb_ltimer_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_hong_t tb_ltimer_now(tb_ltimer_t* timer)
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
static tb_bool_t tb_ltimer_add_task(tb_ltimer_t* timer, tb_ltimer_task_t* timer_task)
{
    // check
    tb_assert_and_check_return_val(timer && timer->pool && timer->tick, tb_false);
    tb_assert_and_check_return_val(timer_task && timer_task->func && timer_task->refn && timer_task->when, tb_false);

    // trace
    tb_trace_d("add: when: %lld, period: %u, refn: %u", timer_task->when, timer_task->period, timer_task->refn);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // empty? move to the wheel head
        if (!tb_fixed_pool_size(timer->pool)) 
        {
            timer->btime = tb_ltimer_now(timer);
            timer->wbase = 0;
        }

        // trace
        tb_trace_d("add: btime: %lld, wbase: %lu", timer->btime, timer->wbase);

        // the timer difference
        tb_hong_t tdiff = timer_task->when - timer->btime;
        tb_assert_and_check_break(tdiff >= 0);

        // trace
        tb_trace_d("add: tdiff: %lld", tdiff);

        // the wheel difference
        tb_size_t wdiff = (tb_size_t)(tdiff / timer->tick);
        tb_assert_and_check_break(wdiff < TB_LTIMER_WHEEL_MAXN);

        // trace
        tb_trace_d("add: wdiff: %lu", wdiff);

        // the wheel index
        tb_size_t windx = (timer->wbase + wdiff) & (TB_LTIMER_WHEEL_MAXN - 1);

        // trace
        tb_trace_d("add: windx: %lu", windx);

        // the wheel list
        tb_vector_ref_t wlist = timer->wheel[windx];
        if (!wlist) wlist = timer->wheel[windx] = tb_vector_init(timer->grow, tb_element_ptr(tb_null, tb_null));
        tb_assert_and_check_break(wlist);

        // save the wheel index
        timer_task->windx = (tb_uint32_t)windx;

        // add task to the wheel list
        tb_vector_insert_tail(wlist, timer_task);

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
static tb_bool_t tb_ltimer_del_task(tb_ltimer_t* timer, tb_ltimer_task_t* timer_task)
{
    // check
    tb_assert_and_check_return_val(timer && timer->pool && timer->tick, tb_false);
    tb_assert_and_check_return_val(timer_task && timer_task->func && timer_task->refn && timer_task->when, tb_false);

    // trace
    tb_trace_d("del: when: %lld, period: %u, refn: %u", timer_task->when, timer_task->period, timer_task->refn);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // check
        tb_assert_and_check_break(timer_task->windx != -1 && timer_task->windx < tb_arrayn(timer->wheel));

        // the wheel list
        tb_vector_ref_t wlist = timer->wheel[timer_task->windx];
        tb_assert_and_check_break(wlist);

        // find the task from the wheel list
        tb_size_t itor = tb_find_all(wlist, timer_task);
        tb_assert_and_check_break(itor != tb_iterator_tail(wlist));

        // del the task from the wheel list
        tb_vector_remove(wlist, itor);

        // clear the wheel index
        timer_task->windx = -1;

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
static tb_bool_t tb_ltimer_expired_task_done(tb_iterator_ref_t iterator, tb_pointer_t item, tb_cpointer_t priv)
{
    // the task
    tb_ltimer_task_t const* timer_task = (tb_ltimer_task_t const*)item;
    
    // done func
    if (timer_task && timer_task->func) 
    { 
        // trace
        tb_trace_d("done: expired: when: %lld, period: %u, refn: %u, killed: %u", timer_task->when, timer_task->period, timer_task->refn, timer_task->killed);

        // done
        timer_task->func(timer_task->killed? tb_true : tb_false, timer_task->priv);
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_ltimer_expired_task_exit(tb_iterator_ref_t iterator, tb_pointer_t item, tb_cpointer_t priv)
{
    // check
    tb_ltimer_t*    timer = priv? (tb_ltimer_t*)(((tb_pointer_t*)priv)[0]) : tb_null;
    tb_hong_t*      now = priv? (tb_hong_t*)(((tb_pointer_t*)priv)[1]) : tb_null;
    tb_assert_and_check_return_val(timer && now, tb_false);

    // the task
    tb_ltimer_task_t* timer_task = (tb_ltimer_task_t*)item;
    if (timer_task)
    {
        // repeat?
        if (timer_task->repeat)
        {
            // update when
            timer_task->when = *now + timer_task->period;

            // continue the task
            if (!tb_ltimer_add_task(timer, timer_task))
            {
                // trace
                tb_trace_e("continue to add timer_task failed");
            }
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
    return tb_true;
}
static tb_void_t tb_ltimer_expired_list_exit(tb_element_ref_t element, tb_pointer_t buff)
{
    // check
    tb_vector_ref_t list = buff? *((tb_vector_ref_t*)buff) : tb_null;
    tb_assert_and_check_return(list);

    // exit list
    tb_vector_exit(list);

    // clear it
    *((tb_pointer_t*)buff) = tb_null;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_ltimer_ref_t tb_ltimer_init(tb_size_t grow, tb_size_t tick, tb_bool_t ctime)
{
    // check
    tb_assert_and_check_return_val(tick >= TB_LTIMER_TICK_100MS, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_ltimer_t*    timer = tb_null;
    do
    {
        // make timer
        timer = tb_malloc0_type(tb_ltimer_t);
        tb_assert_and_check_break(timer);

        // init timer
        timer->grow     = tb_max(grow, 16);
        timer->ctime    = ctime;
        timer->tick     = tick;
        timer->btime    = tb_ltimer_now(timer);

        // init lock
        if (!tb_spinlock_init(&timer->lock)) break;

        // init pool
        timer->pool         = tb_fixed_pool_init(tb_null, timer->grow, sizeof(tb_ltimer_task_t), tb_null, tb_null, tb_null);
        tb_assert_and_check_break(timer->pool);

        // init the expired tasks
        timer->expired      = tb_vector_init((TB_LTIMER_WHEEL_MAXN >> 3) + 8, tb_element_ptr(tb_ltimer_expired_list_exit, tb_null));
        tb_assert_and_check_break(timer->expired);

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
        if (timer) tb_ltimer_exit((tb_ltimer_ref_t)timer);
        timer = tb_null;
    }

    // ok?
    return (tb_ltimer_ref_t)timer;
}
tb_void_t tb_ltimer_exit(tb_ltimer_ref_t self)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return(self);

    // kill it first
    tb_ltimer_kill(self);

    // wait loop exit
    tb_size_t tryn = 10;
    while (tb_atomic_get(&timer->work) && tryn--) tb_msleep(500);

    // warning
    if (!tryn && tb_atomic_get(&timer->work))
    {
        tb_trace_w("[ltimer]: the loop has been not exited now!");
    }

    // enter
    tb_spinlock_enter(&timer->lock);

    // exit wheel
    {
        tb_size_t i = 0;
        for (i = 0; i < TB_LTIMER_WHEEL_MAXN; i++)
        {
            if (timer->wheel[i]) tb_vector_exit(timer->wheel[i]);
            timer->wheel[i] = tb_null;
        }
    }

    // exit pool
    if (timer->pool) tb_fixed_pool_exit(timer->pool);
    timer->pool = tb_null;

    // leave
    tb_spinlock_leave(&timer->lock);

    // exit the expired tasks
    if (timer->expired) tb_vector_exit(timer->expired);
    timer->expired = tb_null;

    // exit lock
    tb_spinlock_exit(&timer->lock);

    // exit it
    tb_free(timer);
}
tb_void_t tb_ltimer_kill(tb_ltimer_ref_t self)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return(self);

    // stop it
    tb_atomic_set(&timer->stop, 1);
}
tb_void_t tb_ltimer_clear(tb_ltimer_ref_t self)
{
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    if (timer)
    {
        // enter
        tb_spinlock_enter(&timer->lock);

        // move to the wheel head
        timer->btime = tb_ltimer_now(timer);
        timer->wbase = 0;

        // clear wheel
        {
            tb_size_t i = 0;
            for (i = 0; i < TB_LTIMER_WHEEL_MAXN; i++)
            {
                if (timer->wheel[i]) tb_vector_clear(timer->wheel[i]);
            }
        }

        // clear pool
        if (timer->pool) tb_fixed_pool_clear(timer->pool);

        // leave
        tb_spinlock_leave(&timer->lock);
    }
}
tb_size_t tb_ltimer_limit(tb_ltimer_ref_t self)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return_val(timer, 0);

    // the self limit
    return (TB_LTIMER_WHEEL_MAXN * timer->tick);
}
tb_size_t tb_ltimer_delay(tb_ltimer_ref_t self)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return_val(timer, -1);

    // ok?
    return timer->tick;
}
tb_bool_t tb_ltimer_spak(tb_ltimer_ref_t self)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return_val(timer && timer->pool && timer->tick && timer->expired, tb_false);

    // stoped?
    tb_check_return_val(!tb_atomic_get(&timer->stop), tb_false);

    // the now time
    tb_hong_t now = tb_ltimer_now(timer);

    // enter
    tb_spinlock_enter(&timer->lock);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // less than one tick? continue to wait
        if (now - timer->btime < timer->tick)
        {
            ok = tb_true;
            break;
        }

        // empty? move to the wheel head
        if (!tb_fixed_pool_size(timer->pool))
        {
            timer->btime = now;
            timer->wbase = 0;
            ok = tb_true;
            break;
        }

        // the diff
        tb_size_t diff = (tb_size_t)((now - timer->btime) / timer->tick);

        // trace
        tb_trace_d("spak: btime: %lld, wbase: %lu, now: %lld, diff: %lu", timer->btime, timer->wbase, now, diff);

        // walk the expired lists
        tb_size_t i = 0;
        tb_size_t n = tb_min(diff, TB_LTIMER_WHEEL_MAXN - 1);
        for (i = 0; i <= n; i++)
        {
            // the wheel index
            tb_size_t indx = (timer->wbase + i) & (TB_LTIMER_WHEEL_MAXN - 1);

            // the wheel list
            tb_vector_ref_t list = timer->wheel[indx];
            tb_check_continue(list && tb_vector_size(list));

            // detach the wheel list to the expired tasks
            tb_vector_insert_tail(timer->expired, list);
            timer->wheel[indx] = tb_null;
        }

        // update the base time
        timer->btime = now;

        // update the wheel base
        timer->wbase = (timer->wbase + diff) & (TB_LTIMER_WHEEL_MAXN - 1);
        
        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&timer->lock);

    // ok? and exists expired tasks?
    if (ok && tb_vector_size(timer->expired))
    {
        // done all expired list
        tb_for_all_if (tb_vector_ref_t, list, timer->expired, list)
        {
            // done the expired task 
            tb_walk_all(list, tb_ltimer_expired_task_done, tb_null);

            // enter
            tb_spinlock_enter(&timer->lock);

            // exit the expired task
            tb_pointer_t data[2]; data[0] = (tb_pointer_t)self; data[1] = &now;
            tb_walk_all(list, tb_ltimer_expired_task_exit, data);

            // leave
            tb_spinlock_leave(&timer->lock);
        }
    }

    // clear expired
    tb_vector_clear(timer->expired);

    // ok?
    return ok;
}
tb_void_t tb_ltimer_loop(tb_ltimer_ref_t self)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return(timer);

    // work++
    tb_atomic_fetch_and_inc(&timer->work);

    // loop
    while (!tb_atomic_get(&timer->stop))
    {
        // the delay
        tb_size_t delay = tb_ltimer_delay(self);
        tb_assert_and_check_break(delay != -1);

        // wait some time
        if (delay) tb_msleep(delay);

        // spak ctime
        if (timer->ctime) tb_cache_time_spak();

        // spak it
        if (!tb_ltimer_spak(self)) break;
    }

    // work--
    tb_atomic_fetch_and_dec(&timer->work);
}
tb_ltimer_task_ref_t tb_ltimer_task_init(tb_ltimer_ref_t self, tb_size_t delay, tb_bool_t repeat, tb_ltimer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return_val(timer && func, tb_null);

    // add task
    return tb_ltimer_task_init_at(self, tb_ltimer_now(timer) + delay, delay, repeat, func, priv);
}
tb_ltimer_task_ref_t tb_ltimer_task_init_at(tb_ltimer_ref_t self, tb_hize_t when, tb_size_t period, tb_bool_t repeat, tb_ltimer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return_val(timer && timer->pool && func, tb_null);

    // stoped?
    tb_assert_and_check_return_val(!tb_atomic_get(&timer->stop), tb_null);

    // enter
    tb_spinlock_enter(&timer->lock);

    // make task
    tb_ltimer_task_t* timer_task = (tb_ltimer_task_t*)tb_fixed_pool_malloc0(timer->pool);
    if (timer_task)
    {
        // init task
        timer_task->refn      = 2;
        timer_task->func      = func;
        timer_task->priv      = priv;
        timer_task->when      = when;
        timer_task->period    = period;
        timer_task->repeat    = repeat? 1 : 0;
        timer_task->killed    = 0;
        timer_task->windx     = -1;

        // add timer_task
        if (!tb_ltimer_add_task(timer, timer_task))
        {
            tb_fixed_pool_free(timer->pool, timer_task);
            timer_task = tb_null;
        }
    }

    // leave
    tb_spinlock_leave(&timer->lock);

    // ok?
    return (tb_ltimer_task_ref_t)timer_task;
}
tb_ltimer_task_ref_t tb_ltimer_task_init_after(tb_ltimer_ref_t self, tb_hize_t after, tb_size_t period, tb_bool_t repeat, tb_ltimer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return_val(timer && func, tb_null);

    // add task
    return tb_ltimer_task_init_at(self, tb_ltimer_now(timer) + after, period, repeat, func, priv);
}
tb_void_t tb_ltimer_task_post(tb_ltimer_ref_t self, tb_size_t delay, tb_bool_t repeat, tb_ltimer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return(timer && func);

    // run task
    tb_ltimer_task_post_at(self, tb_ltimer_now(timer) + delay, delay, repeat, func, priv);
}
tb_void_t tb_ltimer_task_post_at(tb_ltimer_ref_t self, tb_hize_t when, tb_size_t period, tb_bool_t repeat, tb_ltimer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return(timer && timer->pool && func);

    // stoped?
    tb_assert_and_check_return(!tb_atomic_get(&timer->stop));

    // enter
    tb_spinlock_enter(&timer->lock);

    // make task
    tb_ltimer_task_t* timer_task = (tb_ltimer_task_t*)tb_fixed_pool_malloc0(timer->pool);
    if (timer_task)
    {
        // init task
        timer_task->refn      = 1;
        timer_task->func      = func;
        timer_task->priv      = priv;
        timer_task->when      = when;
        timer_task->period    = period;
        timer_task->repeat    = repeat? 1 : 0;
        timer_task->killed    = 0;
        timer_task->windx     = -1;

        // add task
        if (!tb_ltimer_add_task(timer, timer_task))
            tb_fixed_pool_free(timer->pool, timer_task);
    }

    // leave
    tb_spinlock_leave(&timer->lock);
}
tb_void_t tb_ltimer_task_post_after(tb_ltimer_ref_t self, tb_hize_t after, tb_size_t period, tb_bool_t repeat, tb_ltimer_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_ltimer_t* timer = (tb_ltimer_t*)self;
    tb_assert_and_check_return(timer && func);

    // run task
    tb_ltimer_task_post_at(self, tb_ltimer_now(timer) + after, period, repeat, func, priv);
}
tb_void_t tb_ltimer_task_exit(tb_ltimer_ref_t self, tb_ltimer_task_ref_t task)
{
    // check
    tb_ltimer_t*        timer = (tb_ltimer_t*)self;
    tb_ltimer_task_t*   timer_task = (tb_ltimer_task_t*)task;
    tb_assert_and_check_return(timer && timer->pool && timer_task);

    // trace
    tb_trace_d("exit: when: %lld, period: %u, refn: %u", timer_task->when, timer_task->period, timer_task->refn);

    // enter
    tb_spinlock_enter(&timer->lock);

    if (timer_task->refn > 1)
    {
        // refn--
        timer_task->refn--;

        // cancel task
        timer_task->func      = tb_null;
        timer_task->priv      = tb_null;
        timer_task->repeat    = 0;
    }
    // remove it from pool directly if the task have been expired 
    else tb_fixed_pool_free(timer->pool, timer_task);

    // leave
    tb_spinlock_leave(&timer->lock);
}
tb_void_t tb_ltimer_task_kill(tb_ltimer_ref_t self, tb_ltimer_task_ref_t task)
{
    // check
    tb_ltimer_t*        timer = (tb_ltimer_t*)self;
    tb_ltimer_task_t*   timer_task = (tb_ltimer_task_t*)task;
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

        // del the task first
        if (!tb_ltimer_del_task(timer, timer_task))
        {
            // trace
            tb_trace_e("del timer_task failed");
            break;
        }

        // killed
        timer_task->killed = 1;

        // no repeat
        timer_task->repeat = 0;
                
        // modify when => now
        timer_task->when = tb_ltimer_now(timer);

        // re-add task
        if (!tb_ltimer_add_task(timer, timer_task))
        {
            // trace
            tb_trace_e("re-add timer_task failed");
            break;
        }

    } while (0);

    // leave
    tb_spinlock_leave(&timer->lock);
}

