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
 * @file        aiop.c
 * @ingroup     asio
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "aiop"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aiop.h"
#include "aioo.h"
#include "impl/prefix.h"
#include "../../math/math.h"
#include "../../utils/utils.h"
#include "../../memory/memory.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * aioo
 */
static tb_aioo_ref_t tb_aiop_aioo_init(tb_aiop_impl_t* impl, tb_socket_ref_t sock, tb_size_t code, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(impl && impl->pool, tb_null);

    // enter 
    tb_spinlock_enter(&impl->lock);

    // make aioo
    tb_aioo_impl_t* aioo = (tb_aioo_impl_t*)tb_fixed_pool_malloc0(impl->pool);

    // init aioo
    if (aioo)
    {
        aioo->code = code;
        aioo->priv = priv;
        aioo->sock = sock;
    }

    // leave 
    tb_spinlock_leave(&impl->lock);
    
    // ok?
    return (tb_aioo_ref_t)aioo;
}
static tb_void_t tb_aiop_aioo_exit(tb_aiop_impl_t* impl, tb_aioo_ref_t aioo)
{
    // check
    tb_assert_and_check_return(impl && impl->pool);

    // enter 
    tb_spinlock_enter(&impl->lock);

    // exit aioo
    if (aioo) tb_fixed_pool_free(impl->pool, aioo);

    // leave 
    tb_spinlock_leave(&impl->lock);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_aiop_ref_t tb_aiop_init(tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(maxn, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_aiop_impl_t* impl = tb_null;
    do
    {
        // make impl
        impl = tb_malloc0_type(tb_aiop_impl_t);
        tb_assert_and_check_break(impl);

        // init impl
        impl->maxn = maxn;

        // init lock
        if (!tb_spinlock_init(&impl->lock)) break;

        // init pool
        impl->pool = tb_fixed_pool_init(tb_null, (maxn >> 4) + 16, sizeof(tb_aioo_impl_t), tb_null, tb_null, tb_null);
        tb_assert_and_check_break(impl->pool);

        // init spak
        if (!tb_socket_pair(TB_SOCKET_TYPE_TCP, impl->spak)) break;

        // init reactor
        impl->rtor = tb_aiop_rtor_impl_init(impl);
        tb_assert_and_check_break(impl->rtor);

        // addo spak
        if (!tb_aiop_addo((tb_aiop_ref_t)impl, impl->spak[1], TB_AIOE_CODE_RECV, tb_null)) break;  

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
        if (impl) tb_aiop_exit((tb_aiop_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_aiop_ref_t)impl;
}
tb_void_t tb_aiop_exit(tb_aiop_ref_t aiop)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return(impl);

    // exit reactor
    if (impl->rtor && impl->rtor->exit)
        impl->rtor->exit(impl->rtor);

    // exit spak
    if (impl->spak[0]) tb_socket_exit(impl->spak[0]);
    if (impl->spak[1]) tb_socket_exit(impl->spak[1]);
    impl->spak[0] = tb_null;
    impl->spak[1] = tb_null;

    // exit pool
    tb_spinlock_enter(&impl->lock);
    if (impl->pool) tb_fixed_pool_exit(impl->pool);
    impl->pool = tb_null;
    tb_spinlock_leave(&impl->lock);

    // exit lock
    tb_spinlock_exit(&impl->lock);

    // free impl
    tb_free(impl);
}
tb_void_t tb_aiop_cler(tb_aiop_ref_t aiop)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return(impl);

    // clear reactor
    if (impl->rtor && impl->rtor->cler)
        impl->rtor->cler(impl->rtor);

    // clear pool
    tb_spinlock_enter(&impl->lock);
    if (impl->pool) tb_fixed_pool_clear(impl->pool);
    tb_spinlock_leave(&impl->lock);

    // addo spak
    if (impl->spak[1]) tb_aiop_addo(aiop, impl->spak[1], TB_AIOE_CODE_RECV, tb_null);   
}
tb_bool_t tb_aiop_have(tb_aiop_ref_t aiop, tb_size_t code)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return_val(impl && impl->rtor, tb_false);

    // have this code?
    return ((impl->rtor->code & code) == code)? tb_true : tb_false;
}
tb_void_t tb_aiop_kill(tb_aiop_ref_t aiop)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return(impl);

    // kill it
    if (impl->spak[0]) 
    {
        // post: 'k'
        tb_long_t ok = tb_socket_send(impl->spak[0], (tb_byte_t const*)"k", 1);
        if (ok != 1)
        {
            // trace
            tb_trace_e("kill: failed!");

            // abort it
            tb_assert(0);
        }
    }
}
tb_void_t tb_aiop_spak(tb_aiop_ref_t aiop)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return(impl);

    // spak it
    if (impl->spak[0]) 
    {
        // post: 'p'
        tb_long_t ok = tb_socket_send(impl->spak[0], (tb_byte_t const*)"p", 1);
        if (ok != 1)
        {
            // trace
            tb_trace_e("spak: failed!");

            // abort it
            tb_assert(0);
        }
    }
}
tb_aioo_ref_t tb_aiop_addo(tb_aiop_ref_t aiop, tb_socket_ref_t sock, tb_size_t code, tb_cpointer_t priv)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return_val(impl && impl->rtor && impl->rtor->addo && sock, tb_null);
    tb_assert(tb_aiop_have(aiop, code));

    // done
    tb_bool_t       ok = tb_false;
    tb_aioo_ref_t   aioo = tb_null;
    do
    {
        // init aioo
        aioo = tb_aiop_aioo_init(impl, sock, code, priv);
        tb_assert_and_check_break(aioo);
        
        // addo aioo
        if (!impl->rtor->addo(impl->rtor, (tb_aioo_impl_t*)aioo)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed? remove aioo
    if (!ok && aioo) 
    {
        tb_aiop_aioo_exit(impl, aioo);
        aioo = tb_null;
    }

    // ok?
    return aioo;
}
tb_void_t tb_aiop_delo(tb_aiop_ref_t aiop, tb_aioo_ref_t aioo)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return(impl && impl->rtor && impl->rtor->delo && aioo);

    // delete aioo from aiop
    if (!impl->rtor->delo(impl->rtor, (tb_aioo_impl_t*)aioo))
    {
        // trace
        tb_trace_e("delo: aioo[%p] failed!", aioo);
    }
    
    // exit aioo
    tb_aiop_aioo_exit(impl, aioo);
}
tb_bool_t tb_aiop_post(tb_aiop_ref_t aiop, tb_aioe_ref_t aioe)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return_val(impl && impl->rtor && impl->rtor->post && aioe, tb_false);
    tb_assert(tb_aiop_have(aiop, aioe->code));

    // post
    return impl->rtor->post(impl->rtor, aioe);
}
tb_bool_t tb_aiop_sete(tb_aiop_ref_t aiop, tb_aioo_ref_t aioo, tb_size_t code, tb_cpointer_t priv)
{
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return_val(impl && aioo && tb_aioo_sock(aioo) && code, tb_false);
 
    // init aioe
    tb_aioe_t aioe;
    aioe.code = code;
    aioe.priv = priv;
    aioe.aioo = aioo;

    // post aioe
    return tb_aiop_post(aiop, &aioe);
}
tb_long_t tb_aiop_wait(tb_aiop_ref_t aiop, tb_aioe_ref_t list, tb_size_t maxn, tb_long_t timeout)
{   
    // check
    tb_aiop_impl_t* impl = (tb_aiop_impl_t*)aiop;
    tb_assert_and_check_return_val(impl && impl->rtor && impl->rtor->wait && list, -1);

    // wait 
    return impl->rtor->wait(impl->rtor, list, maxn, timeout);
}

