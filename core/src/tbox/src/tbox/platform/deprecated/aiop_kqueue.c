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
 * @file        aiop_kqueue.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../../asio/deprecated/impl/prefix.h"
#include <errno.h>
#include <sys/event.h>
#include <sys/time.h>
#include <unistd.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifndef EV_ENABLE
#   define EV_ENABLE    (0)
#endif

#ifndef NOTE_EOF
#   define NOTE_EOF     (0)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the kqueue impl impl type
typedef struct __tb_aiop_rtor_kqueue_impl_t
{
    // the rtor base
    tb_aiop_rtor_impl_t     base;

    // the kqueue fd
    tb_long_t               kqfd;

    // the events
    struct kevent*          evts;
    tb_size_t               evtn;
    
}tb_aiop_rtor_kqueue_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_aiop_rtor_kqueue_sync(tb_aiop_rtor_impl_t* rtor, struct kevent* evts, tb_size_t evtn)
{
    // check
    tb_aiop_rtor_kqueue_impl_t* impl = (tb_aiop_rtor_kqueue_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && impl->kqfd >= 0, tb_false);
    tb_assert_and_check_return_val(evts && evtn, tb_false);

    // change events
    struct timespec t = {0};
    if (kevent(impl->kqfd, evts, evtn, tb_null, 0, &t) < 0) 
    {
        // trace
        tb_trace_e("sync failed, errno: %d", errno);

        // failed
        return tb_false;
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_aiop_rtor_kqueue_addo(tb_aiop_rtor_impl_t* rtor, tb_aioo_impl_t const* aioo)
{
    // check
    tb_aiop_rtor_kqueue_impl_t* impl = (tb_aiop_rtor_kqueue_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && impl->kqfd >= 0 && aioo && aioo->sock, tb_false);

    // the code
    tb_size_t code = aioo->code;

    // init the add event
    tb_size_t add_event = EV_ADD | EV_ENABLE;
    if (code & TB_AIOE_CODE_CLEAR) add_event |= EV_CLEAR;
    if (code & TB_AIOE_CODE_ONESHOT) add_event |= EV_ONESHOT;

    // add event
    struct kevent   e[2];
    tb_size_t       n = 0;
    tb_int_t        fd = tb_sock2fd(aioo->sock);
    if ((code & TB_AIOE_CODE_RECV) || (code & TB_AIOE_CODE_ACPT)) 
    {
        EV_SET(&e[n], fd, EVFILT_READ, add_event, NOTE_EOF, 0, (tb_pointer_t)aioo); n++;
    }
    if ((code & TB_AIOE_CODE_SEND) || (code & TB_AIOE_CODE_CONN))
    {
        EV_SET(&e[n], fd, EVFILT_WRITE, add_event, NOTE_EOF, 0, (tb_pointer_t)aioo); n++;
    }

    // ok?
    return n? tb_aiop_rtor_kqueue_sync(rtor, e, n) : tb_true;
}
static tb_bool_t tb_aiop_rtor_kqueue_delo(tb_aiop_rtor_impl_t* rtor, tb_aioo_impl_t const* aioo)
{
    // check
    tb_aiop_rtor_kqueue_impl_t* impl = (tb_aiop_rtor_kqueue_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && impl->kqfd >= 0 && aioo && aioo->sock, tb_false);

    // the code
    tb_size_t code = aioo->code;

    // delete event
    struct kevent   e[2];
    tb_size_t       n = 0;
    tb_int_t        fd = tb_sock2fd(aioo->sock);
    if ((code & TB_AIOE_CODE_RECV) || (code & TB_AIOE_CODE_ACPT)) 
    {
        EV_SET(&e[n], fd, EVFILT_READ, EV_DELETE, 0, 0, (tb_pointer_t)aioo); n++;
    }
    if ((code & TB_AIOE_CODE_SEND) || (code & TB_AIOE_CODE_CONN))
    {
        EV_SET(&e[n], fd, EVFILT_WRITE, EV_DELETE, 0, 0, (tb_pointer_t)aioo); n++;
    }

    // ok?
    return n? tb_aiop_rtor_kqueue_sync(rtor, e, n) : tb_true;
}
static tb_bool_t tb_aiop_rtor_kqueue_post(tb_aiop_rtor_impl_t* rtor, tb_aioe_ref_t aioe)
{
    // check
    tb_aiop_rtor_kqueue_impl_t* impl = (tb_aiop_rtor_kqueue_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && aioe, tb_false);

    // the aioo
    tb_aioo_impl_t* aioo = (tb_aioo_impl_t*)aioe->aioo;
    tb_assert_and_check_return_val(aioo && aioo->sock, tb_false);

    // change
    tb_size_t adde = aioe->code & ~aioo->code;
    tb_size_t dele = ~aioe->code & aioo->code;

    // init the add event
    tb_size_t add_event = EV_ADD | EV_ENABLE;
    if (aioe->code & TB_AIOE_CODE_CLEAR) add_event |= EV_CLEAR;
    if (aioe->code & TB_AIOE_CODE_ONESHOT) add_event |= EV_ONESHOT;

    // save aioo
    aioo->code = aioe->code;
    aioo->priv = aioe->priv;

    // add event
    struct kevent   e[2];
    tb_size_t       n = 0;
    tb_int_t        fd = tb_sock2fd(aioo->sock);
    if (adde & TB_AIOE_CODE_RECV || adde & TB_AIOE_CODE_ACPT) 
    {
        EV_SET(&e[n], fd, EVFILT_READ, add_event, NOTE_EOF, 0, aioo);
        n++;
    }
    else if (dele & TB_AIOE_CODE_RECV || dele & TB_AIOE_CODE_ACPT) 
    {
        EV_SET(&e[n], fd, EVFILT_READ, EV_DELETE, 0, 0, aioo);
        n++;
    }
    if (adde & TB_AIOE_CODE_SEND || adde & TB_AIOE_CODE_CONN)
    {
        EV_SET(&e[n], fd, EVFILT_WRITE, add_event, NOTE_EOF, 0, aioo);
        n++;
    }
    else if (dele & TB_AIOE_CODE_SEND || dele & TB_AIOE_CODE_CONN)
    {
        EV_SET(&e[n], fd, EVFILT_WRITE, EV_DELETE, 0, 0, aioo);
        n++;
    }

    // ok?
    return n? tb_aiop_rtor_kqueue_sync(rtor, e, n) : tb_true;
}
static tb_long_t tb_aiop_rtor_kqueue_wait(tb_aiop_rtor_impl_t* rtor, tb_aioe_ref_t list, tb_size_t maxn, tb_long_t timeout)
{   
    // check
    tb_aiop_rtor_kqueue_impl_t* impl = (tb_aiop_rtor_kqueue_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && impl->kqfd >= 0 && rtor->aiop && list && maxn, -1);

    // the aiop
    tb_aiop_impl_t* aiop = rtor->aiop;
    tb_assert_and_check_return_val(aiop, -1);

    // init time
    struct timespec t = {0};
    if (timeout > 0)
    {
        t.tv_sec = timeout / 1000;
        t.tv_nsec = (timeout % 1000) * 1000000;
    }

    // init grow
    tb_size_t grow = tb_align8((rtor->aiop->maxn >> 3) + 1);

    // init events
    if (!impl->evts)
    {
        impl->evtn = grow;
        impl->evts = tb_nalloc0(impl->evtn, sizeof(struct kevent));
        tb_assert_and_check_return_val(impl->evts, -1);
    }

    // wait events
    tb_long_t evtn = kevent(impl->kqfd, tb_null, 0, impl->evts, impl->evtn, timeout >= 0? &t : tb_null);
    tb_assert_and_check_return_val(evtn >= 0 && evtn <= impl->evtn, -1);
    
    // timeout?
    tb_check_return_val(evtn, 0);

    // grow it if events is full
    if (evtn == impl->evtn)
    {
        // grow size
        impl->evtn += grow;
        if (impl->evtn > rtor->aiop->maxn) impl->evtn = rtor->aiop->maxn;

        // grow data
        impl->evts = tb_ralloc(impl->evts, impl->evtn * sizeof(struct kevent));
        tb_assert_and_check_return_val(impl->evts, -1);
    }
    tb_assert(evtn <= impl->evtn);

    // limit 
    evtn = tb_min(evtn, maxn);

    // sync
    tb_size_t i = 0;
    tb_size_t wait = 0;
    for (i = 0; i < evtn; i++)
    {
        // the kevents 
        struct kevent* e = impl->evts + i;

        // the aioo
        tb_aioo_impl_t* aioo = (tb_aioo_impl_t*)e->udata;
        tb_assert_and_check_return_val(aioo && aioo->sock, -1);
        
        // the sock 
        tb_socket_ref_t sock = aioo->sock;

        // spak?
        if (sock == aiop->spak[1] && e->filter == EVFILT_READ) 
        {
            // read spak
            tb_char_t spak = '\0';
            if (1 != tb_socket_recv(aiop->spak[1], (tb_byte_t*)&spak, 1)) return -1;

            // killed?
            if (spak == 'k') return -1;

            // continue it
            continue ;
        }

        // skip spak
        tb_check_continue(sock != aiop->spak[1]);

        // init the aioe
        tb_aioe_ref_t aioe = &list[wait++];
        aioe->code = TB_AIOE_CODE_NONE;
        aioe->aioo = (tb_aioo_ref_t)aioo;
        aioe->priv = aioo->priv;
        if (e->filter == EVFILT_READ) 
        {
            aioe->code |= TB_AIOE_CODE_RECV;
            if (aioo->code & TB_AIOE_CODE_ACPT) aioe->code |= TB_AIOE_CODE_ACPT;
        }
        if (e->filter == EVFILT_WRITE) 
        {
            aioe->code |= TB_AIOE_CODE_SEND;
            if (aioo->code & TB_AIOE_CODE_CONN) aioe->code |= TB_AIOE_CODE_CONN;
        }
        if ((e->flags & EV_ERROR) && !(aioe->code & (TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND))) 
            aioe->code |= TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND;

        // oneshot? clear it
        if (aioo->code & TB_AIOE_CODE_ONESHOT) 
        {
            aioo->code = TB_AIOE_CODE_NONE;
            aioo->priv = tb_null;
        }
    }

    // ok
    return wait;
}
static tb_void_t tb_aiop_rtor_kqueue_exit(tb_aiop_rtor_impl_t* rtor)
{
    tb_aiop_rtor_kqueue_impl_t* impl = (tb_aiop_rtor_kqueue_impl_t*)rtor;
    if (impl)
    {
        // free events
        if (impl->evts) tb_free(impl->evts);

        // close kqfd
        if (impl->kqfd >= 0) close(impl->kqfd);

        // free it
        tb_free(impl);
    }
}
static tb_void_t tb_aiop_rtor_kqueue_cler(tb_aiop_rtor_impl_t* rtor)
{
    tb_aiop_rtor_kqueue_impl_t* impl = (tb_aiop_rtor_kqueue_impl_t*)rtor;
    if (impl)
    {
        // close kqfd
        if (impl->kqfd >= 0)
        {
            close(impl->kqfd);
            impl->kqfd = kqueue();
        }
    }
}
static tb_aiop_rtor_impl_t* tb_aiop_rtor_kqueue_init(tb_aiop_impl_t* aiop)
{
    // check
    tb_assert_and_check_return_val(aiop && aiop->maxn, tb_null);

    // done
    tb_bool_t                   ok = tb_false;
    tb_aiop_rtor_kqueue_impl_t* impl = tb_null;
    do
    {
        // make impl
        impl = tb_malloc0(sizeof(tb_aiop_rtor_kqueue_impl_t));
        tb_assert_and_check_break(impl);

        // init base
        impl->base.aiop = aiop;
        impl->base.code = TB_AIOE_CODE_EALL | TB_AIOE_CODE_CLEAR | TB_AIOE_CODE_ONESHOT;
        impl->base.exit = tb_aiop_rtor_kqueue_exit;
        impl->base.cler = tb_aiop_rtor_kqueue_cler;
        impl->base.addo = tb_aiop_rtor_kqueue_addo;
        impl->base.delo = tb_aiop_rtor_kqueue_delo;
        impl->base.post = tb_aiop_rtor_kqueue_post;
        impl->base.wait = tb_aiop_rtor_kqueue_wait;

        // init kqueue
        impl->kqfd = kqueue();
        tb_assert_and_check_break(impl->kqfd >= 0);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_aiop_rtor_kqueue_exit((tb_aiop_rtor_impl_t*)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_aiop_rtor_impl_t*)impl;
}

