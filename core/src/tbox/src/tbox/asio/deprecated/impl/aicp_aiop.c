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
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the aiop ptor type
typedef struct __tb_aiop_ptor_impl_t
{
    // the ptor base
    tb_aicp_ptor_impl_t         base;

    // the wait aiop
    tb_aiop_ref_t               aiop;

    /* the aice spak
     *
     * index: 0: higher priority for conn, acpt and task
     * index: 1: lower priority for io aice 
     */
    tb_queue_ref_t              spak[2];
    
    // the spak lock
    tb_spinlock_t               lock;

    // the spak wait
    tb_semaphore_ref_t          wait;

    // the spak loop
    tb_thread_ref_t             loop;

    // the aioe list
    tb_aioe_ref_t               list;

    // the aioe size
    tb_size_t                   maxn;
 
    // the timer for task
    tb_timer_ref_t              timer;

    // the low precision timer for timeout
    tb_ltimer_ref_t             ltimer;

    // the private data for file
    tb_handle_t                 fpriv;

    // the killing list lock
    tb_spinlock_t               klock;

    // the killing aico list
    tb_vector_ref_t             klist;

}tb_aiop_ptor_impl_t;

// the aiop aico type
typedef struct __tb_aiop_aico_t
{
    // the base
    tb_aico_impl_t              base;

    // the impl
    tb_aiop_ptor_impl_t*        impl;

    // the aioo
    tb_aioo_ref_t               aioo;

    // the aice
    tb_aice_t                   aice;

    // the task
    tb_handle_t                 task;

    /* wait ok? avoid spak double aice when wait killed/timeout and ok at same time
     * need lock it using impl->lock
     */
    tb_uint8_t                  wait_ok : 1;

    // is waiting?
    tb_uint8_t                  waiting : 1;

    // is ltimer?
    tb_uint8_t                  bltimer : 1;

}tb_aiop_aico_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * file declaration
 */
static tb_bool_t    tb_aicp_file_init(tb_aiop_ptor_impl_t* impl);
static tb_void_t    tb_aicp_file_exit(tb_aiop_ptor_impl_t* impl);
static tb_bool_t    tb_aicp_file_addo(tb_aiop_ptor_impl_t* impl, tb_aico_impl_t* aico);
static tb_void_t    tb_aicp_file_kilo(tb_aiop_ptor_impl_t* impl, tb_aico_impl_t* aico);
static tb_bool_t    tb_aicp_file_post(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice);
static tb_void_t    tb_aicp_file_kill(tb_aiop_ptor_impl_t* impl);
static tb_void_t    tb_aicp_file_poll(tb_aiop_ptor_impl_t* impl);
static tb_long_t    tb_aicp_file_spak_read(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice);
static tb_long_t    tb_aicp_file_spak_writ(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice);
static tb_long_t    tb_aicp_file_spak_readv(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice);
static tb_long_t    tb_aicp_file_spak_writv(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice);
static tb_long_t    tb_aicp_file_spak_fsync(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice);
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * spak
 */
static __tb_inline__ tb_size_t tb_aiop_aioe_code(tb_aice_ref_t aice)
{
    // the aioe code
    static tb_size_t s_code[] =
    {
        TB_AIOE_CODE_NONE

    ,   TB_AIOE_CODE_ACPT           //< acpt
    ,   TB_AIOE_CODE_CONN           //< conn
    ,   TB_AIOE_CODE_RECV           //< recv
    ,   TB_AIOE_CODE_SEND           //< send
    ,   TB_AIOE_CODE_RECV           //< urecv
    ,   TB_AIOE_CODE_SEND           //< usend
    ,   TB_AIOE_CODE_RECV           //< recvv
    ,   TB_AIOE_CODE_SEND           //< sendv
    ,   TB_AIOE_CODE_RECV           //< urecvv
    ,   TB_AIOE_CODE_SEND           //< usendv
    ,   TB_AIOE_CODE_SEND           //< sendf

    ,   TB_AIOE_CODE_NONE
    ,   TB_AIOE_CODE_NONE
    ,   TB_AIOE_CODE_NONE
    ,   TB_AIOE_CODE_NONE
    ,   TB_AIOE_CODE_NONE

    ,   TB_AIOE_CODE_NONE
    };
    tb_assert_and_check_return_val(aice->code && aice->code < tb_arrayn(s_code), TB_AIOE_CODE_NONE);

    // the aioe code
    return s_code[aice->code];
}
static tb_void_t tb_aiop_spak_work(tb_aiop_ptor_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl && impl->wait && impl->base.aicp);

    // the worker size
    tb_size_t work = tb_atomic_get(&impl->base.aicp->work);

    // the semaphore value
    tb_long_t value = tb_semaphore_value(impl->wait);
    
    // post wait
    if (value >= 0 && value < work) tb_semaphore_post(impl->wait, work - value);
}
static tb_bool_t tb_aiop_push_sock(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check 
    tb_assert_and_check_return_val(impl && aice && aice->aico, tb_false);

    // the priority
    tb_size_t priority = tb_aice_impl_priority(aice);
    tb_assert_and_check_return_val(priority < tb_arrayn(impl->spak) && impl->spak[priority], tb_false);

    // this aico is killed? post to higher priority queue
    if (tb_aico_impl_is_killed((tb_aico_impl_t*)aice->aico)) priority = 0;

    // trace
    tb_trace_d("push: aico: %p, handle: %p, code: %lu, priority: %lu", aice->aico, tb_aico_sock(aice->aico), aice->code, priority);

    // enter 
    tb_spinlock_enter(&impl->lock);

    // not full?
    if (!tb_queue_full(impl->spak[priority])) 
    {
        // push aice to the spak queue
        tb_queue_put(impl->spak[priority], aice);

        // wait ok if be not acpt aice
        if (aice->code != TB_AICE_CODE_ACPT) ((tb_aiop_aico_t*)aice->aico)->wait_ok = 1;
    }
    else 
    {
        // trace
        tb_trace_e("push: failed, the spak queue is full!");
    }

    // leave 
    tb_spinlock_leave(&impl->lock);

    // ok
    return tb_true;
}
static tb_bool_t tb_aiop_push_acpt(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, tb_false);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_ACPT, tb_false);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // the priority
    tb_size_t priority = tb_aice_impl_priority(aice);
    tb_assert_and_check_return_val(priority < tb_arrayn(impl->spak) && impl->spak[priority], tb_false);

    // init the acpt aice
    tb_aice_t acpt_aice = *aice;
    acpt_aice.state = TB_STATE_OK;

    // done
    tb_size_t       list_indx = 0;
    tb_size_t       list_size = 0;
    tb_socket_ref_t list_sock[2048];
    tb_ipaddr_t       list_addr[2048];
    tb_size_t       list_maxn = tb_arrayn(list_sock);
    tb_socket_ref_t acpt = (tb_socket_ref_t)aico->base.handle;
    tb_queue_ref_t  spak = impl->spak[priority];
    tb_socket_ref_t sock = tb_null;
    do
    {
        // accept it
        for (list_size = 0; list_size < list_maxn && (list_sock[list_size] = tb_socket_accept(acpt, list_addr + list_size)); list_size++) ;

        // enter 
        tb_spinlock_enter(&impl->lock);

        // push some acpt aice
        for (list_indx = 0; list_indx < list_size && (sock = list_sock[list_indx]); list_indx++)
        {
            // init aico
            acpt_aice.u.acpt.aico = tb_aico_init(aico->base.aicp);

            // trace
            tb_trace_d("push: acpt[%p]: sock: %p, aico: %p", aico->base.handle, sock, acpt_aice.u.acpt.aico);

            // open aico and push the acpt aice if not full?
            if (    acpt_aice.u.acpt.aico 
                &&  tb_aico_open_sock(acpt_aice.u.acpt.aico, sock) 
                &&  !tb_queue_full(spak)) 
            {
                // save addr
                tb_ipaddr_copy(&acpt_aice.u.acpt.addr, list_addr + list_indx);

                // push to the spak queue
                tb_queue_put(spak, &acpt_aice);
            }
            else 
            {
                // close the left sock
                tb_size_t i;
                for (i = list_indx; i < list_size; i++) 
                {
                    // close it
                    if (list_sock[i]) tb_socket_exit(list_sock[i]);
                    list_sock[i] = tb_null;
                }

                // exit aico
                if (acpt_aice.u.acpt.aico) tb_aico_exit(acpt_aice.u.acpt.aico);
                acpt_aice.u.acpt.aico = tb_null;

                // trace
                tb_trace_e("push: acpt failed!");
                break;
            }
        }

        // leave 
        tb_spinlock_leave(&impl->lock);

    } while (list_indx == list_maxn);

    // ok
    return tb_true;
}
static tb_int_t tb_aiop_spak_loop(tb_cpointer_t priv)
{
    // check
    tb_aiop_ptor_impl_t*    impl = (tb_aiop_ptor_impl_t*)priv;
    tb_aicp_impl_t*         aicp = impl? impl->base.aicp : tb_null;

    // done
    do
    {
        // check
        tb_assert_and_check_break(impl && impl->aiop && impl->list && impl->timer && impl->ltimer && aicp);

        // trace
        tb_trace_d("loop: init");

        // loop 
        while (!tb_atomic_get(&aicp->kill))
        {
            // the delay
            tb_size_t delay = tb_timer_delay(impl->timer);

            // the ldelay
            tb_size_t ldelay = tb_ltimer_delay(impl->ltimer);
            tb_assert_and_check_break(ldelay != -1);

            // trace
            tb_trace_d("loop: wait: ..");

            // wait aioe
            tb_long_t real = tb_aiop_wait(impl->aiop, impl->list, impl->maxn, tb_min(delay, ldelay));

            // trace
            tb_trace_d("loop: wait: %ld", real);

            // spak ctime
            tb_cache_time_spak();

            // spak timer
            if (!tb_timer_spak(impl->timer)) break;

            // spak ltimer
            if (!tb_ltimer_spak(impl->ltimer)) break;

            // killed?
            tb_check_break(real >= 0);

            // error? out of range
            tb_assert_and_check_break(real <= impl->maxn);
            
            // timeout?
            tb_check_continue(real);
        
            // grow it if aioe is full
            if (real == impl->maxn)
            {
                // grow size
                impl->maxn += (aicp->maxn >> 4) + 16;
                if (impl->maxn > aicp->maxn) impl->maxn = aicp->maxn;

                // grow list
                impl->list = tb_ralloc(impl->list, impl->maxn * sizeof(tb_aioe_t));
                tb_assert_and_check_break(impl->list);
            }

            // walk aioe list
            tb_size_t i = 0;
            tb_bool_t end = tb_false;
            for (i = 0; i < real && !end; i++)
            {
                // the aioe
                tb_aioe_ref_t aioe = &impl->list[i];
                tb_assert_and_check_break_state(aioe, end, tb_true);

                // the aice
                tb_aice_ref_t aice = (tb_aice_ref_t)aioe->priv;
                tb_assert_and_check_break_state(aice, end, tb_true);

                // the aico
                tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
                tb_assert_and_check_break_state(aico, end, tb_true);

                // have wait?
                tb_check_continue(aice->code);

                // have been waited ok for the timer timeout/killed func? need not spak it repeatly
                tb_check_continue(!aico->wait_ok);

                // sock?
                if (aico->base.type == TB_AICO_TYPE_SOCK)
                {
                    // push the acpt aice
                    if (aice->code == TB_AICE_CODE_ACPT) end = tb_aiop_push_acpt(impl, aice)? tb_false : tb_true;
                    // push the sock aice
                    else end = tb_aiop_push_sock(impl, aice)? tb_false : tb_true;
                }
                else if (aico->base.type == TB_AICO_TYPE_FILE)
                {
                    // poll file
                    tb_aicp_file_poll(impl);
                }
                else tb_assert(0);
            }

            // end?
            tb_check_break(!end);

            // work it
            tb_aiop_spak_work(impl);
        }

    } while (0);

    // trace
    tb_trace_d("loop: exit");

    // kill
    tb_aicp_kill((tb_aicp_ref_t)aicp);

    // exit
    return 0;
}
static tb_void_t tb_aiop_spak_wait_timeout(tb_bool_t killed, tb_cpointer_t priv)
{
    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)priv;
    tb_assert_and_check_return(aico && aico->waiting);

    // the impl
    tb_aiop_ptor_impl_t* impl = aico->impl;
    tb_assert_and_check_return(impl && impl->aiop);

    // for sock
    if (aico->base.type == TB_AICO_TYPE_SOCK)
    {
        // check
        tb_assert_and_check_return(aico->aioo);

        // delo aioo
        tb_aiop_delo(impl->aiop, aico->aioo);
        aico->aioo = tb_null;
    }

    // have been waited ok for the spak loop? need not spak it repeatly
    tb_bool_t ok = tb_false;
    if (!aico->wait_ok)
    {
        // the priority
        tb_size_t priority = tb_aice_impl_priority(&aico->aice);
        tb_assert_and_check_return(priority < tb_arrayn(impl->spak) && impl->spak[priority]);

        // trace
        tb_trace_d("wait: timeout: code: %lu, priority: %lu, time: %lld", aico->aice.code, priority, tb_cache_time_mclock());

        // enter 
        tb_spinlock_enter(&impl->lock);

        // spak aice
        if (!tb_queue_full(impl->spak[priority])) 
        {
            // save state
            aico->aice.state = killed? TB_STATE_KILLED : TB_STATE_TIMEOUT;

            // put it
            tb_queue_put(impl->spak[priority], &aico->aice);

            // ok
            ok = tb_true;
            aico->wait_ok = 1;
        }
        else tb_assert(0);

        // leave 
        tb_spinlock_leave(&impl->lock);
    }

    // work it
    if (ok) tb_aiop_spak_work(impl);
}
static tb_bool_t tb_aiop_spak_wait(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{   
    // check
    tb_assert_and_check_return_val(impl && impl->aiop && impl->ltimer && aice, tb_false);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle && !aico->task, tb_false);

    // the aioe code
    tb_size_t code = tb_aiop_aioe_code(aice);
    tb_assert_and_check_return_val(code != TB_AIOE_CODE_NONE, tb_false);
                
    // trace
    tb_trace_d("wait: aico: %p, code: %lu: time: %lld: ..", aico, aice->code, tb_cache_time_mclock());

    // done
    tb_bool_t ok = tb_false;
    tb_aice_t prev = aico->aice;
    do
    {
        // wait it
        aico->aice = *aice;
        aico->waiting = 1;
        aico->wait_ok = 0;

        // wait once if not accept 
        if (aice->code != TB_AICE_CODE_ACPT) code |= TB_AIOE_CODE_ONESHOT;

        // using the edge triggered mode
        if (tb_aiop_have(impl->aiop, TB_AIOE_CODE_CLEAR))
            code |= TB_AIOE_CODE_CLEAR;

        // have aioo?
        if (!aico->aioo) 
        {
            // addo wait
            if (!(aico->aioo = tb_aiop_addo(impl->aiop, aico->base.handle, code, &aico->aice))) break;
        }
        else
        {
            // sete wait
            if (!tb_aiop_sete(impl->aiop, aico->aioo, code, &aico->aice)) break;
        }

        // add timeout task
        tb_long_t timeout = tb_aico_impl_timeout_from_code((tb_aico_impl_t*)aico, aice->code);
        if (timeout >= 0) 
        {
            // add it
            aico->task = tb_ltimer_task_init(impl->ltimer, timeout, tb_false, tb_aiop_spak_wait_timeout, aico);
            tb_assert_and_check_break(aico->task);
            aico->bltimer = 1;
        }

        // ok
        ok = tb_true;

    } while (0);

    // failed? restore it
    if (!ok) 
    {
        // trace
        tb_trace_d("wait: aico: %p, code: %lu: failed", aico, aice->code);

        // restore it
        aico->aice = prev;
        aico->waiting = 0;
    }

    // ok?
    return ok;
}
static tb_long_t tb_aiop_spak_acpt(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_ACPT, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);
    tb_assert_and_check_return_val(!aico->waiting, -1);

    // trace
    tb_trace_d("acpt[%p]: wait: ..", aico);

    // wait ok?
    if (tb_aiop_spak_wait(impl, aice)) return 0;
    // wait failed
    else aice->state = TB_STATE_FAILED;
 
    // trace
    tb_trace_d("acpt[%p]: wait: failed", aico);

    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_conn(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_CONN, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // check address
    tb_assert(!tb_ipaddr_is_empty(&aice->u.conn.addr));

    // try to connect it
    tb_long_t ok = tb_socket_connect(aico->base.handle, &aice->u.conn.addr);

    // trace
    tb_trace_d("conn[%p]: %{ipaddr}: %ld", aico, &aice->u.conn.addr, ok);

    // no connected? wait it
    if (!ok) 
    {
        // wait it
        if (!aico->waiting)
        {
            // wait ok?
            if (tb_aiop_spak_wait(impl, aice)) return 0;
            // wait failed
            else aice->state = TB_STATE_FAILED;
        }
        // closed
        else aice->state = TB_STATE_FAILED;
    }

    // save it
    aice->state = ok > 0? TB_STATE_OK : TB_STATE_FAILED;
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_recv(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_RECV, -1);
    tb_assert_and_check_return_val(aice->u.recv.data && aice->u.recv.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // try to recv it
    tb_size_t recv = 0;
    tb_long_t real = 0;
    while (recv < aice->u.recv.size)
    {
        // recv it
        real = tb_socket_recv(aico->base.handle, aice->u.recv.data + recv, aice->u.recv.size - recv);

        // save recv
        if (real > 0) recv += real;
        else break;
    }

    // trace
    tb_trace_d("recv[%p]: %lu", aico, recv);

    // no recv? 
    if (!recv) 
    {
        // wait it
        if (!real && !aico->waiting)
        {
            // wait ok?
            if (tb_aiop_spak_wait(impl, aice)) return 0;
            // wait failed
            else aice->state = TB_STATE_FAILED;
        }
        // closed
        else aice->state = TB_STATE_CLOSED;
    }
    else
    {
        // ok or closed?
        aice->state = TB_STATE_OK;

        // save the recv size
        aice->u.recv.real = recv;
    }
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_send(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_SEND, -1);
    tb_assert_and_check_return_val(aice->u.send.data && aice->u.send.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // try to send it
    tb_size_t send = 0;
    tb_long_t real = 0;
    while (send < aice->u.send.size)
    {
        // send it
        real = tb_socket_send(aico->base.handle, aice->u.send.data + send, aice->u.send.size - send);
        
        // save send
        if (real > 0) send += real;
        else break;
    }

    // trace
    tb_trace_d("send[%p]: %lu", aico, send);

    // no send? 
    if (!send) 
    {
        // wait it
        if (!real && !aico->waiting) 
        {
            // wait ok?
            if (tb_aiop_spak_wait(impl, aice)) return 0;
            // wait failed
            else aice->state = TB_STATE_FAILED;
        }
        // closed
        else aice->state = TB_STATE_CLOSED;
    }
    else
    {
        // ok or closed?
        aice->state = TB_STATE_OK;

        // save the send size
        aice->u.send.real = send;
    }
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_urecv(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_URECV, -1);
    tb_assert_and_check_return_val(aice->u.urecv.data && aice->u.urecv.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // try to recv it
    tb_size_t   recv = 0;
    tb_long_t   real = 0;
    while (recv < aice->u.urecv.size)
    {
        // recv it
        real = tb_socket_urecv(aico->base.handle, &aice->u.urecv.addr, aice->u.urecv.data + recv, aice->u.urecv.size - recv);

        // save recv
        if (real > 0) recv += real;
        else break;
    }

    // no recv? 
    if (!recv) 
    {
        // wait it
        if (!real && !aico->waiting)
        {
            // wait ok?
            if (tb_aiop_spak_wait(impl, aice)) return 0;
            // wait failed
            else aice->state = TB_STATE_FAILED;
        }
        // closed
        else aice->state = TB_STATE_CLOSED;
    }
    else
    {
        // trace
        tb_trace_d("urecv[%p]: %{ipaddr}: %lu", aico, &aice->u.urecv.addr, recv);

        // ok or closed?
        aice->state = TB_STATE_OK;

        // save the recv size
        aice->u.urecv.real = recv;
    }
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_usend(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_USEND, -1);
    tb_assert_and_check_return_val(aice->u.usend.data && aice->u.usend.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // try to send it
    tb_size_t send = 0;
    tb_long_t real = 0;
    while (send < aice->u.usend.size)
    {
        // send it
        real = tb_socket_usend(aico->base.handle, &aice->u.usend.addr, aice->u.usend.data + send, aice->u.usend.size - send);
        
        // save send
        if (real > 0) send += real;
        else break;
    }

    // trace
    tb_trace_d("usend[%p]: %{ipaddr}: %lu", aico, &aice->u.usend.addr, send);

    // no send? 
    if (!send) 
    {
        // wait it
        if (!real && !aico->waiting)
        {
            // wait ok?
            if (tb_aiop_spak_wait(impl, aice)) return 0;
            // wait failed
            else aice->state = TB_STATE_FAILED;
        }
        // closed
        else aice->state = TB_STATE_CLOSED;
    }
    else
    {
        // ok or closed?
        aice->state = TB_STATE_OK;

        // save the send size
        aice->u.usend.real = send;
    }
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_recvv(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_RECVV, -1);
    tb_assert_and_check_return_val(aice->u.recvv.list && aice->u.recvv.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // recv it
    tb_long_t real = tb_socket_recvv(aico->base.handle, aice->u.recvv.list, aice->u.recvv.size);

    // trace
    tb_trace_d("recvv[%p]: %lu", aico, real);

    // ok? 
    if (real > 0) 
    {
        aice->u.recvv.real = real;
        aice->state = TB_STATE_OK;
    }
    // no recv?
    else if (!real && !aico->waiting)
    {
        // wait ok?
        if (tb_aiop_spak_wait(impl, aice)) return 0;
        // wait failed
        else aice->state = TB_STATE_FAILED;
    }
    // closed?
    else aice->state = TB_STATE_CLOSED;
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_sendv(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_SENDV, -1);
    tb_assert_and_check_return_val(aice->u.sendv.list && aice->u.sendv.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // send it
    tb_long_t real = tb_socket_sendv(aico->base.handle, aice->u.sendv.list, aice->u.sendv.size);

    // trace
    tb_trace_d("sendv[%p]: %lu", aico, real);

    // ok? 
    if (real > 0) 
    {
        aice->u.sendv.real = real;
        aice->state = TB_STATE_OK;
    }
    // no send?
    else if (!real && !aico->waiting) 
    {
        // wait ok?
        if (tb_aiop_spak_wait(impl, aice)) return 0;
        // wait failed
        else aice->state = TB_STATE_FAILED;
    }
    // closed?
    else aice->state = TB_STATE_CLOSED;
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_urecvv(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_URECVV, -1);
    tb_assert_and_check_return_val(aice->u.urecvv.list && aice->u.urecvv.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // recv it
    tb_long_t real = tb_socket_urecvv(aico->base.handle, &aice->u.urecvv.addr, aice->u.urecvv.list, aice->u.urecvv.size);

    // trace
    tb_trace_d("urecvv[%p]: %{ipaddr}: %lu", aico, &aice->u.urecvv.addr, real);

    // ok? 
    if (real > 0) 
    {
        aice->u.urecvv.real = real;
        aice->state = TB_STATE_OK;
    }
    // no recv?
    else if (!real && !aico->waiting)
    {
        // wait ok?
        if (tb_aiop_spak_wait(impl, aice)) return 0;
        // wait failed
        else aice->state = TB_STATE_FAILED;
    }
    // closed?
    else aice->state = TB_STATE_CLOSED;
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_usendv(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_USENDV, -1);
    tb_assert_and_check_return_val(aice->u.usendv.list && aice->u.usendv.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // send it
    tb_long_t real = tb_socket_usendv(aico->base.handle, &aice->u.usendv.addr, aice->u.usendv.list, aice->u.usendv.size);

    // trace
    tb_trace_d("usendv[%p]: %{ipaddr}: %lu", aico, &aice->u.usendv.addr, real);

    // ok? 
    if (real > 0) 
    {
        aice->u.usendv.real = real;
        aice->state = TB_STATE_OK;
    }
    // no send?
    else if (!real && !aico->waiting) 
    {
        // wait ok?
        if (tb_aiop_spak_wait(impl, aice)) return 0;
        // wait failed
        else aice->state = TB_STATE_FAILED;
    }
    // closed?
    else aice->state = TB_STATE_CLOSED;
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_long_t tb_aiop_spak_sendf(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_SENDF, -1);
    tb_assert_and_check_return_val(aice->u.sendf.file && aice->u.sendf.size, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, -1);

    // try to send it
    tb_long_t   real = 0;
    tb_hize_t   send = 0;
    tb_hize_t   seek = aice->u.sendf.seek;
    tb_hize_t   size = aice->u.sendf.size;
    tb_handle_t file = aice->u.sendf.file;
    while (send < size)
    {
        // send it
        real = tb_socket_sendf(aico->base.handle, file, seek + send, size - send);
        
        // save send
        if (real > 0) send += real;
        else break;
    }

    // trace
    tb_trace_d("sendf[%p]: %llu", aico, send);

    // no send? 
    if (!send) 
    {
        // wait it
        if (!real && !aico->waiting) 
        {
            // wait ok?
            if (tb_aiop_spak_wait(impl, aice)) return 0;
            // wait failed
            else aice->state = TB_STATE_FAILED;
        }
        // closed
        else aice->state = TB_STATE_CLOSED;
    }
    else
    {
        // ok or closed?
        aice->state = TB_STATE_OK;

        // save the send size
        aice->u.sendf.real = send;
    }
    
    // reset wait
    aico->waiting = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // ok
    return 1;
}
static tb_void_t tb_aiop_spak_runtask_timeout(tb_bool_t killed, tb_cpointer_t priv)
{
    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)priv;
    tb_assert_and_check_return(aico && aico->waiting);

    // the impl
    tb_aiop_ptor_impl_t* impl = aico->impl;
    tb_assert_and_check_return(impl);

    // the priority
    tb_size_t priority = tb_aice_impl_priority(&aico->aice);
    tb_assert_and_check_return(priority < tb_arrayn(impl->spak) && impl->spak[priority]);

    // enter 
    tb_spinlock_enter(&impl->lock);

    // trace
    tb_trace_d("runtask: timeout: code: %lu, priority: %lu, size: %lu", aico->aice.code, priority, tb_queue_size(impl->spak[priority]));

    // spak aice
    tb_bool_t ok = tb_false;
    if (!tb_queue_full(impl->spak[priority])) 
    {
        // save state
        aico->aice.state = killed? TB_STATE_KILLED : TB_STATE_OK;

        // put it
        tb_queue_put(impl->spak[priority], &aico->aice);

        // ok
        ok = tb_true;
    }
    else tb_assert(0);

    // leave 
    tb_spinlock_leave(&impl->lock);

    // work it
    if (ok) tb_aiop_spak_work(impl);
}
static tb_long_t tb_aiop_spak_runtask(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->aiop && impl->ltimer && impl->timer && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_RUNTASK, -1);
    tb_assert_and_check_return_val(aice->u.runtask.when, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && !aico->task, -1);

    // now
    tb_hong_t now = tb_cache_time_mclock();

    // timeout?
    tb_long_t ok = -1;
    if (aice->u.runtask.when <= now)
    {
        // trace
        tb_trace_d("runtask: when: %llu, now: %lld: ok", aice->u.runtask.when, now);
    
        // ok
        aice->state = TB_STATE_OK;
        ok = 1;
    }
    else
    {
        // trace
        tb_trace_d("runtask: when: %llu, now: %lld: ..", aice->u.runtask.when, now);

        // wait it
        aico->aice = *aice;
        aico->waiting = 1;

        // add timeout task, is the higher precision timer?
        if (aico->base.handle)
        {
            // the top when
            tb_hize_t top = tb_timer_top(impl->timer);

            // add task
            aico->task = tb_timer_task_init_at(impl->timer, aice->u.runtask.when, 0, tb_false, tb_aiop_spak_runtask_timeout, aico);
            aico->bltimer = 0;

            // the top task is changed? spak aiop
            if (aico->task && aice->u.runtask.when < top)
                tb_aiop_spak(impl->aiop);
        }
        else
        {
            aico->task = tb_ltimer_task_init_at(impl->ltimer, aice->u.runtask.when, 0, tb_false, tb_aiop_spak_runtask_timeout, aico);
            aico->bltimer = 1;
        }

        // wait
        ok = 0;
    }

    // ok
    return ok;
}
static tb_long_t tb_aiop_spak_clos(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->aiop && impl->ltimer && impl->timer && aice, -1);
    tb_assert_and_check_return_val(aice->code == TB_AICE_CODE_CLOS, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico, -1);

    // trace
    tb_trace_d("clos: aico: %p, code: %u: %s", aico, aice->code, tb_state_cstr(tb_atomic_get(&aico->base.state)));
 
    // exit the timer task
    if (aico->task) 
    {
        if (aico->bltimer) tb_ltimer_task_exit(impl->ltimer, aico->task);
        else tb_timer_task_exit(impl->timer, aico->task);
        aico->bltimer = 0;
    }
    aico->task = tb_null;

    // exit the sock 
    if (aico->base.type == TB_AICO_TYPE_SOCK)
    {
        // remove aioo
        if (aico->aioo) tb_aiop_delo(impl->aiop, aico->aioo);
        aico->aioo = tb_null;

        // close the socket handle
        if (aico->base.handle) tb_socket_exit((tb_socket_ref_t)aico->base.handle);
        aico->base.handle = tb_null;
    }
    // exit file
    else if (aico->base.type == TB_AICO_TYPE_FILE)
    {
        // exit the file handle
        if (aico->base.handle) tb_file_exit((tb_file_ref_t)aico->base.handle);
        aico->base.handle = tb_null;
    }

    // clear waiting state
    aico->waiting = 0;
    aico->wait_ok = 0;
    aico->aice.code = TB_AICE_CODE_NONE;

    // clear type
    aico->base.type = TB_AICO_TYPE_NONE;

    // clear timeout
    tb_size_t i = 0;
    tb_size_t n = tb_arrayn(aico->base.timeout);
    for (i = 0; i < n; i++) aico->base.timeout[i] = -1;

    // closed
    tb_atomic_set(&aico->base.state, TB_STATE_CLOSED);

    // ok
    aice->state = TB_STATE_OK;
    return 1;
}
static tb_long_t tb_aiop_spak_done(tb_aiop_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->timer && impl->ltimer && aice, -1);

    // the aico
    tb_aiop_aico_t* aico = (tb_aiop_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico, -1);

    // remove task
    if (aico->task) 
    {
        if (aico->bltimer) tb_ltimer_task_exit(impl->ltimer, aico->task);
        else tb_timer_task_exit(impl->timer, aico->task);
        aico->bltimer = 0;
    }
    aico->task = tb_null;

    // spak the killed aice if not closing
    if (tb_aico_impl_is_killed(&aico->base) && aice->code != TB_AICE_CODE_CLOS)
    {
        // clear waiting state if not accept
        if (aice->code != TB_AICE_CODE_ACPT)
        {
            aico->waiting = 0;
            aico->aice.code = TB_AICE_CODE_NONE;
        }

        // save state
        aice->state = TB_STATE_KILLED;

        // trace
        tb_trace_d("spak: aico: %p, code: %u: killed", aico, aice->code);

        // ok
        return 1;
    }

    // no pending? spak it directly
    if (aice->state != TB_STATE_PENDING)
    {
        // clear waiting state if not accept
        if (aice->code != TB_AICE_CODE_ACPT)
        {
            aico->waiting = 0;
            aico->aice.code = TB_AICE_CODE_NONE;
        }

        // ok
        return 1;
    }

    // init spak
    static tb_long_t (*s_spak[])(tb_aiop_ptor_impl_t* , tb_aice_ref_t) = 
    {
        tb_null

    ,   tb_aiop_spak_acpt
    ,   tb_aiop_spak_conn
    ,   tb_aiop_spak_recv
    ,   tb_aiop_spak_send
    ,   tb_aiop_spak_urecv
    ,   tb_aiop_spak_usend
    ,   tb_aiop_spak_recvv
    ,   tb_aiop_spak_sendv
    ,   tb_aiop_spak_urecvv
    ,   tb_aiop_spak_usendv
    ,   tb_aiop_spak_sendf

    ,   tb_aicp_file_spak_read
    ,   tb_aicp_file_spak_writ
    ,   tb_aicp_file_spak_readv
    ,   tb_aicp_file_spak_writv
    ,   tb_aicp_file_spak_fsync

    ,   tb_aiop_spak_runtask
    ,   tb_null
    };
    tb_assert_and_check_return_val(aice->code && aice->code < tb_arrayn(s_spak) && s_spak[aice->code], -1);

    // done spak 
    return s_spak[aice->code](impl, aice);
}
static tb_void_t tb_aiop_spak_klist(tb_aiop_ptor_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl && impl->klist);

    // enter
    tb_spinlock_enter(&impl->klock);

    // kill it if exists the killing aico
    if (tb_vector_size(impl->klist)) 
    {
        // kill all
        tb_for_all_if (tb_aico_impl_t*, aico, impl->klist, aico)
        {
            // the aiop aico
            tb_aiop_aico_t* aiop_aico = (tb_aiop_aico_t*)aico;

            // sock?
            if (aico->type == TB_AICO_TYPE_SOCK) 
            {
                // add it first if do not exists timeout task
                if (!aiop_aico->task) 
                {
                    aiop_aico->task = tb_ltimer_task_init(impl->ltimer, 10000, tb_false, tb_aiop_spak_wait_timeout, aico);
                    aiop_aico->bltimer = 1;
                }

                // kill the task
                if (aiop_aico->task) 
                {
                    // kill task
                    if (aiop_aico->bltimer) tb_ltimer_task_kill(impl->ltimer, aiop_aico->task);
                    else tb_timer_task_kill(impl->timer, aiop_aico->task);
                }
            }
            else if (aico->type == TB_AICO_TYPE_FILE)
            {
                // kill file
                tb_aicp_file_kilo(impl, aico);
            }

            // trace
            tb_trace_d("kill: aico: %p, type: %u: ok", aico, aico->type);
        }
    }

    // clear the killing aico list
    tb_vector_clear(impl->klist);

    // leave
    tb_spinlock_leave(&impl->klock);

    /* the aiop will wait long time if the lastest task wait period is too long
     * so spak the aiop manually for spak the timer
     */
    tb_aiop_spak(impl->aiop);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_aiop_ptor_addo(tb_aicp_ptor_impl_t* ptor, tb_aico_impl_t* aico)
{
    // check
    tb_aiop_ptor_impl_t* impl = (tb_aiop_ptor_impl_t*)ptor;
    tb_assert_and_check_return_val(impl && impl->aiop && aico, tb_false);
            
    // the aiop aico
    tb_aiop_aico_t* aiop_aico = (tb_aiop_aico_t*)aico;

    // init impl
    aiop_aico->impl = impl;

    // done
    tb_bool_t ok = tb_false;
    switch (aico->type)
    {
    case TB_AICO_TYPE_SOCK:
        {
            // check
            tb_assert_and_check_break(aico->handle);

            // ok
            ok = tb_true;
        }
        break;
    case TB_AICO_TYPE_FILE:
        {
            // check
            tb_assert_and_check_break(aico->handle);

            // file: addo
            ok = tb_aicp_file_addo(impl, aico);
        }
        break;
    case TB_AICO_TYPE_TASK:
        {
            // ok
            ok = tb_true;
        }
        break;
    default:
        break;
    }

    // ok?
    return ok;
}
static tb_void_t tb_aiop_ptor_kilo(tb_aicp_ptor_impl_t* ptor, tb_aico_impl_t* aico)
{
    // check
    tb_aiop_ptor_impl_t* impl = (tb_aiop_ptor_impl_t*)ptor;
    tb_assert_and_check_return(impl && impl->klist && aico);

    // trace
    tb_trace_d("kill: aico: %p, type: %u: ..", aico, aico->type);

    // append the killing aico
    tb_spinlock_enter(&impl->klock);
    tb_vector_insert_tail(impl->klist, aico);
    tb_spinlock_leave(&impl->klock);

    // work it
    tb_aiop_spak_work(impl);
}
static tb_bool_t tb_aiop_ptor_post(tb_aicp_ptor_impl_t* ptor, tb_aice_ref_t aice)
{
    // check
    tb_aiop_ptor_impl_t* impl = (tb_aiop_ptor_impl_t*)ptor;
    tb_assert_and_check_return_val(impl && aice && aice->aico, tb_false);

    // optimizate to spak the clos aice 
    if (aice->code == TB_AICE_CODE_CLOS)
    {
        // spak the clos
        tb_aice_t resp = *aice;
        if (tb_aiop_spak_clos(impl, &resp) <= 0) return tb_false;

        // done the aice response function
        aice->func(&resp);

        // post ok
        return tb_true;
    }
    
    // the priority
    tb_size_t priority = tb_aice_impl_priority(aice);
    tb_assert_and_check_return_val(priority < tb_arrayn(impl->spak) && impl->spak[priority], tb_false);

    // done
    tb_bool_t           ok = tb_true;
    tb_aico_impl_t*     aico = (tb_aico_impl_t*)aice->aico;
    switch (aico->type)
    {
    case TB_AICO_TYPE_SOCK:
    case TB_AICO_TYPE_TASK:
        {
            // enter 
            tb_spinlock_enter(&impl->lock);

            // post aice
            if (!tb_queue_full(impl->spak[priority])) 
            {
                // put
                tb_queue_put(impl->spak[priority], aice);

                // trace
                tb_trace_d("post: code: %lu, priority: %lu, size: %lu", aice->code, priority, tb_queue_size(impl->spak[priority]));
            }
            else
            {
                // failed
                ok = tb_false;

                // trace
                tb_trace_e("post: code: %lu, priority: %lu, size: %lu: failed", aice->code, priority, tb_queue_size(impl->spak[priority]));
            }

            // leave 
            tb_spinlock_leave(&impl->lock);
        }
        break;
    case TB_AICO_TYPE_FILE:
        {
            // post file
            ok = tb_aicp_file_post(impl, aice);
        }
        break;
    default:
        ok = tb_false;
        break;
    }

    // work it 
    if (ok) tb_aiop_spak_work(impl);

    // ok?
    return ok;
}
static tb_void_t tb_aiop_ptor_kill(tb_aicp_ptor_impl_t* ptor)
{
    // check
    tb_aiop_ptor_impl_t* impl = (tb_aiop_ptor_impl_t*)ptor;
    tb_assert_and_check_return(impl && impl->timer && impl->ltimer && impl->aiop);

    // trace
    tb_trace_d("kill: ..");

    // kill aiop
    tb_aiop_kill(impl->aiop);

    // kill file
    tb_aicp_file_kill(impl); 

    // work it
    tb_aiop_spak_work(impl);
}
static tb_void_t tb_aiop_ptor_exit(tb_aicp_ptor_impl_t* ptor)
{
    // check
    tb_aiop_ptor_impl_t* impl = (tb_aiop_ptor_impl_t*)ptor;
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("exit");

    // exit file
    tb_aicp_file_exit(impl);

    // exit loop
    if (impl->loop)
    {
        tb_long_t wait = 0;
        if ((wait = tb_thread_wait(impl->loop, 5000, tb_null)) <= 0)
        {
            // trace
            tb_trace_e("loop[%p]: wait failed: %ld!", impl->loop, wait);
        }
        tb_thread_exit(impl->loop);
        impl->loop = tb_null;
    }

    // exit spak
    tb_spinlock_enter(&impl->lock);
    if (impl->spak[0]) tb_queue_exit(impl->spak[0]);
    if (impl->spak[1]) tb_queue_exit(impl->spak[1]);
    impl->spak[0] = tb_null;
    impl->spak[1] = tb_null;
    tb_spinlock_leave(&impl->lock);

    // exit kill
    tb_spinlock_enter(&impl->klock);
    if (impl->klist) tb_vector_exit(impl->klist);
    impl->klist = tb_null;
    tb_spinlock_leave(&impl->klock);

    // exit aiop
    if (impl->aiop) tb_aiop_exit(impl->aiop);
    impl->aiop = tb_null;

    // exit list
    if (impl->list) tb_free(impl->list);
    impl->list = tb_null;

    // exit wait
    if (impl->wait) tb_semaphore_exit(impl->wait);
    impl->wait = tb_null;

    // exit timer
    if (impl->timer) tb_timer_exit(impl->timer);
    impl->timer = tb_null;

    // exit ltimer
    if (impl->ltimer) tb_ltimer_exit(impl->ltimer);
    impl->ltimer = tb_null;

    // exit lock
    tb_spinlock_exit(&impl->lock);

    // exit it
    tb_free(impl);
}
static tb_long_t tb_aiop_ptor_spak(tb_aicp_ptor_impl_t* ptor, tb_handle_t loop, tb_aice_ref_t resp, tb_long_t timeout)
{
    // check
    tb_aiop_ptor_impl_t* impl = (tb_aiop_ptor_impl_t*)ptor;
    tb_aicp_impl_t*      aicp = impl? impl->base.aicp : tb_null;
    tb_assert_and_check_return_val(impl && impl->wait && aicp && resp, -1);

    // spak the killing list
    tb_aiop_spak_klist(impl);

    // enter 
    tb_spinlock_enter(&impl->lock);

    // done
    tb_long_t ok = -1;
    tb_bool_t null = tb_false;
    do
    {
        // check
        tb_assert_and_check_break(impl->spak[0] && impl->spak[1]);

        // clear ok
        ok = 0;

        // spak aice from the higher priority spak first
        if (!(null = tb_queue_null(impl->spak[0]))) 
        {
            // get resp
            tb_aice_ref_t aice = tb_queue_get(impl->spak[0]);
            if (aice) 
            {
                // save resp
                *resp = *aice;

                // trace
                tb_trace_d("spak[%u]: code: %lu, priority: 0, size: %lu", (tb_uint16_t)tb_thread_self(), aice->code, tb_queue_size(impl->spak[0]));

                // pop it
                tb_queue_pop(impl->spak[0]);

                // ok
                ok = 1;
            }
        }

        // no aice? spak aice from the lower priority spak next
        if (!ok && !(null = tb_queue_null(impl->spak[1]))) 
        {
            // get resp
            tb_aice_ref_t aice = tb_queue_get(impl->spak[1]);
            if (aice) 
            {
                // save resp
                *resp = *aice;

                // trace
                tb_trace_d("spak[%u]: code: %lu, priority: 1, size: %lu", (tb_uint16_t)tb_thread_self(), aice->code, tb_queue_size(impl->spak[1]));

                // pop it
                tb_queue_pop(impl->spak[1]);

                // ok
                ok = 1;
            }
        }

    } while (0);

    // leave 
    tb_spinlock_leave(&impl->lock);

    // done it
    if (ok) ok = tb_aiop_spak_done(impl, resp);

    // null? wait it
    tb_check_return_val(!ok && null, ok);
    
    // killed? break it
    tb_check_return_val(!tb_atomic_get(&aicp->kill), -1);

    // trace
    tb_trace_d("wait[%u]: ..", (tb_uint16_t)tb_thread_self());

    // wait some time
    if (tb_semaphore_wait(impl->wait, timeout) < 0) return -1;

    // timeout 
    return 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * file implementation
 */
#include "aicp_file.c"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
static tb_aicp_ptor_impl_t* tb_aiop_ptor_init(tb_aicp_impl_t* aicp)
{
    // check
    tb_assert_and_check_return_val(aicp && aicp->maxn, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_aiop_ptor_impl_t*    impl = tb_null;
    do
    {
        // make ptor
        impl = tb_malloc0_type(tb_aiop_ptor_impl_t);
        tb_assert_and_check_break(impl);

        // init base
        impl->base.aicp         = aicp;
        impl->base.step         = sizeof(tb_aiop_aico_t);
        impl->base.kill         = tb_aiop_ptor_kill;
        impl->base.exit         = tb_aiop_ptor_exit;
        impl->base.addo         = tb_aiop_ptor_addo;
        impl->base.kilo         = tb_aiop_ptor_kilo;
        impl->base.post         = tb_aiop_ptor_post;
        impl->base.loop_spak    = tb_aiop_ptor_spak;

        // init lock
        if (!tb_spinlock_init(&impl->lock)) break;

        // init wait
        impl->wait = tb_semaphore_init(0);
        tb_assert_and_check_break(impl->wait);

        // init aiop
        impl->aiop = tb_aiop_init(aicp->maxn);
        tb_assert_and_check_break(impl->aiop);

        // check 
        tb_assert_and_check_break(tb_aiop_have(impl->aiop, TB_AIOE_CODE_EALL | TB_AIOE_CODE_ONESHOT));

        // init spak
        impl->spak[0] = tb_queue_init((aicp->maxn >> 4) + 16, tb_element_mem(sizeof(tb_aice_t), tb_null, tb_null));
        impl->spak[1] = tb_queue_init((aicp->maxn >> 4) + 16, tb_element_mem(sizeof(tb_aice_t), tb_null, tb_null));
        tb_assert_and_check_break(impl->spak[0] && impl->spak[1]);

        // init file
        if (!tb_aicp_file_init(impl)) break;

        // init list
        impl->maxn = (aicp->maxn >> 4) + 16;
        impl->list = tb_nalloc0(impl->maxn, sizeof(tb_aioe_t));
        tb_assert_and_check_break(impl->list);

        // init timer and using cache time
        impl->timer = tb_timer_init(aicp->maxn >> 8, tb_true);
        tb_assert_and_check_break(impl->timer);

        // init ltimer and using cache time
        impl->ltimer = tb_ltimer_init(aicp->maxn >> 8, TB_LTIMER_TICK_S, tb_true);
        tb_assert_and_check_break(impl->ltimer);

        // init the killing list lock
        if (!tb_spinlock_init(&impl->klock)) break;

        // init the killing aico list
        impl->klist = tb_vector_init((aicp->maxn >> 6) + 16, tb_element_ptr(tb_null, tb_null));
        tb_assert_and_check_break(impl->klist);

        // register lock profiler
#ifdef TB_LOCK_PROFILER_ENABLE
        tb_lock_profiler_register(tb_lock_profiler(), (tb_pointer_t)&impl->lock, "aicp_aiop");
#endif

        // init loop
        impl->loop = tb_thread_init(tb_null, tb_aiop_spak_loop, impl, 0);
        tb_assert_and_check_break(impl->loop);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_aiop_ptor_exit((tb_aicp_ptor_impl_t*)impl);
        return tb_null;
    }

    // ok?
    return (tb_aicp_ptor_impl_t*)impl;
}

