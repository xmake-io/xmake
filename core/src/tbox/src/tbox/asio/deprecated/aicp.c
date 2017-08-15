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
 * @file        aicp.c
 * @ingroup     asio
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "aicp"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aicp.h"
#include "aico.h"
#include "impl/prefix.h"
#include "../../math/math.h"
#include "../../utils/utils.h"
#include "../../memory/memory.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t tb_aicp_walk_wait(tb_pointer_t item, tb_cpointer_t priv)
{
    // check
    tb_aico_impl_t* aico = (tb_aico_impl_t*)item;
    tb_assert_and_check_return_val(aico, tb_false);

    // trace
#ifdef __tb_debug__
    tb_trace_e("aico[%p]: wait exited failed, type: %lu, handle: %p, state: %s for func: %s, line: %lu, file: %s", aico, tb_aico_type((tb_aico_ref_t)aico), aico->handle, tb_state_cstr(tb_atomic_get(&aico->state)), aico->func, aico->line, aico->file);
#else
    tb_trace_e("aico[%p]: wait exited failed, type: %lu, handle: %p, state: %s", aico, tb_aico_type((tb_aico_ref_t)aico), aico->handle, tb_state_cstr(tb_atomic_get(&aico->state)));
#endif

    // ok
    return tb_true;
}
static tb_bool_t tb_aicp_walk_kill(tb_pointer_t item, tb_cpointer_t priv)
{
    // check
    tb_aico_impl_t* aico = (tb_aico_impl_t*)item;
    tb_assert_and_check_return_val(aico, tb_false);

    // kill it
    tb_aico_kill((tb_aico_ref_t)aico);

    // ok
    return tb_true;
}
static tb_bool_t tb_aicp_post_after_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_RUNTASK, tb_false);

    // the posted aice
    tb_aice_ref_t posted_aice = (tb_aice_ref_t)aice->priv;
    tb_assert_and_check_return_val(posted_aice && posted_aice->aico, tb_false);

    // the impl
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)tb_aico_aicp(aice->aico);
    tb_assert_and_check_return_val(impl && impl->ptor && impl->ptor->post, tb_false);

    // ok?
    tb_bool_t ok = tb_true;
    tb_bool_t posted = tb_true;
    if (aice->state == TB_STATE_OK)
    {
        // post it  
#ifdef __tb_debug__
        if (!tb_aicp_post_((tb_aicp_ref_t)impl, posted_aice, ((tb_aico_impl_t*)aice->aico)->func, ((tb_aico_impl_t*)aice->aico)->line, ((tb_aico_impl_t*)aice->aico)->file))
#else
        if (!tb_aicp_post_((tb_aicp_ref_t)impl, posted_aice))
#endif
        {
            // not posted
            posted = tb_false;

            // failed
            posted_aice->state = TB_STATE_FAILED;
        }
    }
    // failed?
    else 
    {
        // not posted
        posted = tb_false;

        // save state
        posted_aice->state = aice->state;
    }

    // not posted? done func now
    if (!posted)
    {
        // done func: notify failed
        if (posted_aice->func && !posted_aice->func(posted_aice)) ok = tb_false;
    }

    // exit the posted aice
    tb_free(posted_aice);

    // ok?
    return ok;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * instance implementation
 */
static tb_int_t tb_aicp_instance_loop(tb_cpointer_t priv)
{
    // aicp
    tb_aicp_ref_t aicp = (tb_aicp_ref_t)priv;

    // trace
    tb_trace_d("loop: init");

    // loop aicp
    if (aicp) tb_aicp_loop(aicp);
    
    // trace
    tb_trace_d("loop: exit");

    // exit
    return 0;
}
static tb_handle_t tb_aicp_instance_init(tb_cpointer_t* ppriv)
{
    // check
    tb_assert_and_check_return_val(ppriv, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_aicp_ref_t   aicp = tb_null;
    do
    {
        // init aicp
        aicp = tb_aicp_init(0);
        tb_assert_and_check_break(aicp);

        // init loop
        *ppriv = (tb_cpointer_t)tb_thread_init(tb_null, tb_aicp_instance_loop, aicp, 0);
        tb_assert_and_check_break(*ppriv);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit aicp
        if (aicp) tb_aicp_exit(aicp);
        aicp = tb_null;
    }

    // ok?
    return (tb_handle_t)aicp;
}
static tb_void_t tb_aicp_instance_exit(tb_handle_t handle, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return(handle);

    // wait all
    if (!tb_aicp_wait_all((tb_aicp_ref_t)handle, 5000)) return ;

    // kill aicp
    tb_aicp_kill((tb_aicp_ref_t)handle);

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
    tb_aicp_exit((tb_aicp_ref_t)handle);
}
static tb_void_t tb_aicp_instance_kill(tb_handle_t handle, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return(handle);

    // kill all
    tb_aicp_kill_all((tb_aicp_ref_t)handle);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_aicp_ref_t tb_aicp()
{
    return (tb_aicp_ref_t)tb_singleton_instance(TB_SINGLETON_TYPE_AICP, tb_aicp_instance_init, tb_aicp_instance_exit, tb_aicp_instance_kill, tb_null);
}
tb_aicp_ref_t tb_aicp_init(tb_size_t maxn)
{
    // check iovec
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, data, tb_iovec_t, data), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, size, tb_iovec_t, size), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_send_t, data, tb_iovec_t, data), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_send_t, size, tb_iovec_t, size), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_read_t, data, tb_iovec_t, data), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_read_t, size, tb_iovec_t, size), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_writ_t, data, tb_iovec_t, data), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_writ_t, size, tb_iovec_t, size), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_urecv_t, data, tb_iovec_t, data), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_urecv_t, size, tb_iovec_t, size), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_usend_t, data, tb_iovec_t, data), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_usend_t, size, tb_iovec_t, size), tb_null);

    // check real
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_send_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_read_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_writ_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_sendf_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_sendv_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_recvv_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_readv_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_writv_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_urecv_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_usend_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_urecvv_t, real), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_aice_recv_t, real, tb_aice_usendv_t, real), tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_aicp_impl_t*     impl = tb_null;
    do
    {
        // make impl
        impl = tb_malloc0_type(tb_aicp_impl_t);
        tb_assert_and_check_break(impl);

        // init impl
#ifdef __tb_small__
        impl->maxn = maxn? maxn : (1 << 4);
#else
        impl->maxn = maxn? maxn : (1 << 8);
#endif

        // init lock
        if (!tb_spinlock_init(&impl->lock)) break;

        // init proactor
        impl->ptor = tb_aicp_ptor_impl_init(impl);
        tb_assert_and_check_break(impl->ptor && impl->ptor->step >= sizeof(tb_aico_impl_t));

        // init aico pool
        impl->pool = tb_fixed_pool_init(tb_null, (impl->maxn >> 4) + 16, impl->ptor->step, tb_null, tb_null, tb_null);
        tb_assert_and_check_break(impl->pool);

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
        // exit impl
        if (impl) tb_aicp_exit((tb_aicp_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_aicp_ref_t)impl;
}
tb_bool_t tb_aicp_exit(tb_aicp_ref_t aicp)
{
    // check
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return_val(impl, tb_false);

    // kill all first
    tb_aicp_kill_all((tb_aicp_ref_t)impl);

    // wait all exiting
    if (tb_aicp_wait_all((tb_aicp_ref_t)impl, 5000) <= 0) 
    {
        // wait failed, trace left aicos
        tb_spinlock_enter(&impl->lock);
        if (impl->pool) tb_fixed_pool_walk(impl->pool, tb_aicp_walk_wait, tb_null);
        tb_spinlock_leave(&impl->lock);
        return tb_false;
    }
   
    // kill loop
    tb_aicp_kill((tb_aicp_ref_t)impl);

    // wait workers exiting 
    tb_hong_t time = tb_mclock();
    while (tb_atomic_get(&impl->work) && (tb_mclock() < time + 5000)) tb_msleep(500);

    // exit proactor
    if (impl->ptor)
    {
        tb_assert(impl->ptor && impl->ptor->exit);
        impl->ptor->exit(impl->ptor);
        impl->ptor = tb_null;
    }

    // exit aico pool
    tb_spinlock_enter(&impl->lock);
    if (impl->pool) tb_fixed_pool_exit(impl->pool);
    impl->pool = tb_null;
    tb_spinlock_leave(&impl->lock);

    // exit lock
    tb_spinlock_exit(&impl->lock);

    // free impl
    tb_free(impl);

    // ok
    return tb_true;
}
tb_size_t tb_aicp_maxn(tb_aicp_ref_t aicp)
{
    // check
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return_val(impl, 0);

    // the maxn
    return impl->maxn;
}
tb_bool_t tb_aicp_post_(tb_aicp_ref_t aicp, tb_aice_ref_t aice __tb_debug_decl__)
{
    // check
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return_val(impl && impl->ptor && impl->ptor->post, tb_false);
    tb_assert_and_check_return_val(aice && aice->aico, tb_false);

    // the aico
    tb_aico_impl_t* aico = (tb_aico_impl_t*)aice->aico;
    tb_assert_and_check_return_val(aico, tb_false);

    // opened or killed or closed? pending it
    tb_size_t state = tb_atomic_fetch_and_pset(&aico->state, TB_STATE_OPENED, TB_STATE_PENDING);
    if (state == TB_STATE_OPENED || state == TB_STATE_KILLED)
    {
        // save debug info
#ifdef __tb_debug__
        aico->func = func_;
        aico->file = file_;
        aico->line = line_;
#endif

        // post aice
        return impl->ptor->post(impl->ptor, aice);
    }

    // trace
#ifdef __tb_debug__
    tb_trace_e("post aice[%lu] failed, the aico[%p]: type: %lu, handle: %p, state: %s for func: %s, line: %lu, file: %s", aice->code, aico, tb_aico_type((tb_aico_ref_t)aico), aico->handle, tb_state_cstr(state), func_, line_, file_);
#else
    tb_trace_e("post aice[%lu] failed, the aico[%p]: type: %lu, handle: %p, state: %s", aice->code, aico, tb_aico_type((tb_aico_ref_t)aico), aico->handle, tb_state_cstr(state));
#endif

    // abort it
    tb_assert(0);

    // post failed
    return tb_false;
}
tb_bool_t tb_aicp_post_after_(tb_aicp_ref_t aicp, tb_size_t delay, tb_aice_ref_t aice __tb_debug_decl__)
{
    // check
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return_val(impl && impl->ptor && impl->ptor->post, tb_false);
    tb_assert_and_check_return_val(aice && aice->aico, tb_false);

    // killed?
    tb_check_return_val(!tb_atomic_get(&impl->kill_all), tb_false);

    // no delay?
    if (!delay) return tb_aicp_post_(aicp, aice __tb_debug_args__);

    // the aico
    tb_aico_impl_t* aico = (tb_aico_impl_t*)aice->aico;
    tb_assert_and_check_return_val(aico, tb_false);

    // make the posted aice
    tb_aice_ref_t posted_aice = tb_malloc0_type(tb_aice_t);
    tb_assert_and_check_return_val(posted_aice, tb_false);

    // init the posted aice
    *posted_aice = *aice;

    // run the delay task
    return tb_aico_task_run_((tb_aico_ref_t)aico, delay, tb_aicp_post_after_func, posted_aice __tb_debug_args__);
}
tb_void_t tb_aicp_loop(tb_aicp_ref_t aicp)
{
    tb_aicp_loop_util(aicp, tb_null, tb_null);  
}
tb_void_t tb_aicp_loop_util(tb_aicp_ref_t aicp, tb_bool_t (*stop)(tb_cpointer_t priv), tb_cpointer_t priv)
{   
    // check
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return(impl);
   
    // the ptor 
    tb_aicp_ptor_impl_t* ptor = impl->ptor;
    tb_assert_and_check_return(ptor && ptor->loop_spak);

    // the loop spak
    tb_long_t (*loop_spak)(tb_aicp_ptor_impl_t* , tb_handle_t, tb_aice_ref_t , tb_long_t ) = ptor->loop_spak;

    // worker++
    tb_atomic_fetch_and_inc(&impl->work);

    // init loop
    tb_handle_t loop = ptor->loop_init? ptor->loop_init(ptor) : tb_null;
 
    // trace
    tb_trace_d("loop[%p]: init", loop);

    // spak ctime
    tb_cache_time_spak();

    // loop
    while (1)
    {
        // spak
        tb_aice_t   resp = {0};
        tb_long_t   ok = loop_spak(ptor, loop, &resp, -1);

        // spak ctime
        tb_cache_time_spak();

        // failed?
        tb_check_break(ok >= 0);

        // timeout?
        tb_check_continue(ok);

        // check aico
        tb_aico_impl_t* aico = (tb_aico_impl_t*)resp.aico;
        tb_assert_and_check_continue(aico);

        // trace
        tb_trace_d("loop[%p]: spak: code: %lu, aico: %p, state: %s: %ld", loop, resp.code, aico, aico? tb_state_cstr(tb_atomic_get(&aico->state)) : "null", ok);

        // pending? clear state if be not accept or accept failed
        tb_size_t state = TB_STATE_OPENED;
        state = (resp.code != TB_AICE_CODE_ACPT || resp.state != TB_STATE_OK)? tb_atomic_fetch_and_pset(&aico->state, TB_STATE_PENDING, state) : tb_atomic_get(&aico->state);

        // killed or killing?
        if (state == TB_STATE_KILLED || state == TB_STATE_KILLING)
        {
            // update the aice state 
            resp.state = TB_STATE_KILLED;

            // killing? update to the killed state
            tb_atomic_fetch_and_pset(&aico->state, TB_STATE_KILLING, TB_STATE_KILLED);
        }

        // done func, @note maybe the aico exit will be called
        if (resp.func && !resp.func(&resp)) 
        {
            // trace
#ifdef __tb_debug__
            tb_trace_e("loop[%p]: done aice func failed with code: %lu at line: %lu, func: %s, file: %s!", loop, resp.code, aico->line, aico->func, aico->file);
#else
            tb_trace_e("loop[%p]: done aice func failed with code: %lu!", loop, resp.code);
#endif
        }

        // killing? update to the killed state
        tb_atomic_fetch_and_pset(&aico->state, TB_STATE_KILLING, TB_STATE_KILLED);

        // stop it?
        if (stop && stop(priv)) tb_aicp_kill(aicp);
    }

    // exit loop
    if (ptor->loop_exit) ptor->loop_exit(ptor, loop);

    // worker--
    tb_atomic_fetch_and_dec(&impl->work);

    // trace
    tb_trace_d("loop[%p]: exit", loop);
}
tb_void_t tb_aicp_kill(tb_aicp_ref_t aicp)
{
    // check
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return(impl);
        
    // trace
    tb_trace_d("kill: ..");

    // kill all
    tb_aicp_kill_all(aicp);

    // kill it
    if (!tb_atomic_fetch_and_set(&impl->kill, 1))
    {
        // kill proactor
        if (impl->ptor && impl->ptor->kill) impl->ptor->kill(impl->ptor);
    }
}
tb_void_t tb_aicp_kill_all(tb_aicp_ref_t aicp)
{
    // check
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("kill: all: ..");

    // kill all
    if (!tb_atomic_fetch_and_set(&impl->kill_all, 1))
    {
        tb_spinlock_enter(&impl->lock);
        if (impl->pool) tb_fixed_pool_walk(impl->pool, tb_aicp_walk_kill, impl);
        tb_spinlock_leave(&impl->lock);
    }
}
tb_long_t tb_aicp_wait_all(tb_aicp_ref_t aicp, tb_long_t timeout)
{
    // check
    tb_aicp_impl_t* impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return_val(impl, -1);

    // trace
    tb_trace_d("wait: all: ..");

    // wait it
    tb_size_t size = 0;
    tb_hong_t time = tb_cache_time_spak();
    while ((timeout < 0 || tb_cache_time_spak() < time + timeout))
    {
        // enter
        tb_spinlock_enter(&impl->lock);

        // the aico count
        size = impl->pool? tb_fixed_pool_size(impl->pool) : 0;

        // trace
        tb_trace_d("wait: count: %lu: ..", size);

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
tb_hong_t tb_aicp_time(tb_aicp_ref_t aicp)
{
    return tb_cache_time_mclock();
}
