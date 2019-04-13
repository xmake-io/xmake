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
 * @file        coroutine.h
 * @ingroup     coroutine
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "coroutine"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "coroutine.h"
#include "scheduler.h"
#include "../impl/impl.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
tb_lo_coroutine_t* tb_lo_coroutine_init(tb_lo_scheduler_ref_t scheduler, tb_lo_coroutine_func_t func, tb_cpointer_t priv, tb_lo_coroutine_free_t free)
{
    // check
    tb_assert_and_check_return_val(scheduler && func, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_lo_coroutine_t*  coroutine = tb_null;
    do
    {
        // make coroutine
        coroutine = tb_malloc0_type(tb_lo_coroutine_t);
        tb_assert_and_check_break(coroutine);

        // init core
        tb_lo_core_init(&coroutine->core);

        // save scheduler
        coroutine->scheduler = scheduler;

        // init function and user private data
        coroutine->func = func;
        coroutine->priv = priv;
        coroutine->free = free;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (coroutine) tb_lo_coroutine_exit(coroutine); 
        coroutine = tb_null;
    }

    // trace
    tb_trace_d("init %p", coroutine);

    // ok?
    return coroutine;
}
tb_bool_t tb_lo_coroutine_reinit(tb_lo_coroutine_t* coroutine, tb_lo_coroutine_func_t func, tb_cpointer_t priv, tb_lo_coroutine_free_t free)
{
    // check
    tb_assert_and_check_return_val(coroutine && func, tb_false);
    tb_assert_and_check_return_val(coroutine->scheduler && tb_lo_core_state(coroutine) == TB_STATE_END, tb_false);

    // init core
    tb_lo_core_init(&coroutine->core);

    // init function and user private data
    coroutine->func = func;
    coroutine->priv = priv;
    coroutine->free = free;

    // init rs data
    tb_memset(&coroutine->rs, 0, sizeof(coroutine->rs));

    // ok
    return tb_true;
}
tb_void_t tb_lo_coroutine_exit(tb_lo_coroutine_t* coroutine)
{
    // check
    tb_assert_and_check_return(coroutine && tb_lo_core_state(coroutine) == TB_STATE_END);

    // trace
    tb_trace_d("exit: %p", coroutine);

    // exit it
    tb_free(coroutine);
}
tb_lo_scheduler_ref_t tb_lo_coroutine_scheduler_(tb_lo_coroutine_ref_t self)
{
    // check
    tb_lo_coroutine_t* coroutine = (tb_lo_coroutine_t*)self;
    tb_assert(coroutine);

    // get scheduler 
    return coroutine->scheduler;
}
tb_void_t tb_lo_coroutine_sleep_(tb_lo_coroutine_ref_t self, tb_long_t interval)
{
    // check
    tb_lo_coroutine_t* coroutine = (tb_lo_coroutine_t*)self;
    tb_assert(coroutine);

    // get scheduler
    tb_lo_scheduler_t* scheduler = (tb_lo_scheduler_t*)coroutine->scheduler;
    tb_assert(scheduler);
    
    // init io scheduler first
    if (!tb_lo_scheduler_io_need(scheduler)) return ;

    // sleep it
    tb_lo_scheduler_io_sleep(scheduler->scheduler_io, interval);
}
tb_bool_t tb_lo_coroutine_waitio_(tb_lo_coroutine_ref_t self, tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout)
{
    // check
    tb_lo_coroutine_t* coroutine = (tb_lo_coroutine_t*)self;
    tb_assert(coroutine);

    // get scheduler
    tb_lo_scheduler_t* scheduler = (tb_lo_scheduler_t*)coroutine->scheduler;
    tb_assert(scheduler);
   
    // init io scheduler first
    if (!tb_lo_scheduler_io_need(scheduler)) return tb_false;

    // wait it
    return tb_lo_scheduler_io_wait(scheduler->scheduler_io, sock, events, timeout);
}
tb_long_t tb_lo_coroutine_events_(tb_lo_coroutine_ref_t self)
{
    // check
    tb_lo_coroutine_t* coroutine = (tb_lo_coroutine_t*)self;
    tb_assert(coroutine);

    // get events
    return coroutine->rs.wait.events_result;
}
tb_void_t tb_lo_coroutine_pass_free_(tb_cpointer_t priv)
{
    if (priv) tb_free(priv);
}
tb_pointer_t tb_lo_coroutine_pass1_make_(tb_size_t type_size, tb_cpointer_t value, tb_size_t offset, tb_size_t size)
{
    // check
    tb_assert(type_size && value && offset + size <= type_size);

    // make data
    tb_byte_t* data = tb_malloc0_bytes(type_size);
    if (data) tb_memcpy(data + offset, value, size);

    // ok?
    return data;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * public implementation
 */
tb_bool_t tb_lo_coroutine_start(tb_lo_scheduler_ref_t self, tb_lo_coroutine_func_t func, tb_cpointer_t priv, tb_lo_coroutine_free_t free)
{
    return tb_lo_scheduler_start((tb_lo_scheduler_t*)self, func, priv, free);
}
tb_void_t tb_lo_coroutine_resume(tb_lo_coroutine_ref_t self)
{
    tb_lo_scheduler_resume((tb_lo_scheduler_t*)tb_lo_coroutine_scheduler_(self), (tb_lo_coroutine_t*)self);
}
