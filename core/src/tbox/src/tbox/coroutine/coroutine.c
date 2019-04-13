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
#include "impl/impl.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_coroutine_start(tb_co_scheduler_ref_t scheduler, tb_coroutine_func_t func, tb_cpointer_t priv, tb_size_t stacksize)
{
    // check
    tb_assert_and_check_return_val(func, tb_false);

    // start it
    return tb_co_scheduler_start((tb_co_scheduler_t*)scheduler, func, priv, stacksize);
}
tb_bool_t tb_coroutine_yield()
{
    // get current scheduler
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_co_scheduler_self();

    // yield the current coroutine
    return scheduler? tb_co_scheduler_yield(scheduler) : tb_false;
}
tb_pointer_t tb_coroutine_resume(tb_coroutine_ref_t coroutine, tb_cpointer_t priv)
{
    // get current scheduler
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_co_scheduler_self();
        
    // resume the given coroutine
    return scheduler? tb_co_scheduler_resume(scheduler, (tb_coroutine_t*)coroutine, priv) : tb_null;
}
tb_pointer_t tb_coroutine_suspend(tb_cpointer_t priv)
{
    // get current scheduler
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_co_scheduler_self();

    // suspend the current coroutine
    return scheduler? tb_co_scheduler_suspend(scheduler, priv) : tb_null;
}
tb_pointer_t tb_coroutine_sleep(tb_long_t interval)
{
    // get current scheduler
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_co_scheduler_self();

    // sleep the current coroutine
    return scheduler? tb_co_scheduler_sleep(scheduler, interval) : tb_null;
}
tb_long_t tb_coroutine_waitio(tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout)
{
    // get current scheduler
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_co_scheduler_self();

    // wait events
    return scheduler? tb_co_scheduler_wait(scheduler, sock, events, timeout) : -1;
}
tb_coroutine_ref_t tb_coroutine_self()
{
    // get coroutine
    tb_co_scheduler_t* scheduler = (tb_co_scheduler_t*)tb_co_scheduler_self();

    // get running coroutine
    return scheduler? (tb_coroutine_ref_t)tb_co_scheduler_running(scheduler) : tb_null;
}

