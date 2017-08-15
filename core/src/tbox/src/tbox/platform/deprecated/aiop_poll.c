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
 * @file        aiop_poll.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <sys/poll.h>
#include "../spinlock.h"
#include "../../asio/deprecated/impl/prefix.h"
#include "../../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the poll lock type
typedef struct __tb_poll_lock_t
{
    // the pfds
    tb_spinlock_t               pfds;

    // the hash
    tb_spinlock_t               hash;

}tb_poll_lock_t;

// the poll rtor impl type
typedef struct __tb_aiop_rtor_poll_impl_t
{
    // the rtor base
    tb_aiop_rtor_impl_t         base;

    // the poll fds
    tb_vector_ref_t             pfds;

    // the copy fds
    tb_vector_ref_t             cfds;

    // the hash
    tb_hash_map_ref_t           hash;

    // the lock
    tb_poll_lock_t              lock;

}tb_aiop_rtor_poll_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_poll_walk_delo(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t priv)
{
    // check
    tb_assert(priv);

    // the fd
    tb_long_t fd = (tb_long_t)priv;

    // the poll fd
    struct pollfd* pfd = (struct pollfd*)item;

    // remove it?
    return (pfd && pfd->fd == fd);
}
static tb_bool_t tb_poll_walk_sete(tb_iterator_ref_t iterator, tb_pointer_t item, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(iterator, tb_false);

    // the aioe
    tb_aioe_ref_t aioe = (tb_aioe_ref_t)priv;
    tb_assert_and_check_return_val(aioe, tb_false);

    // the aioo
    tb_aioo_impl_t const* aioo = (tb_aioo_impl_t const*)aioe->aioo;
    tb_assert_and_check_return_val(aioo && aioo->sock, tb_false);

    // is this?
    struct pollfd* pfd = (struct pollfd*)item;
    if (pfd && pfd->fd == ((tb_long_t)aioo->sock - 1)) 
    {
        pfd->events = 0;
        if (aioe->code & TB_AIOE_CODE_RECV || aioe->code & TB_AIOE_CODE_ACPT) pfd->events |= POLLIN;
        if (aioe->code & TB_AIOE_CODE_SEND || aioe->code & TB_AIOE_CODE_CONN) pfd->events |= POLLOUT;

        // break
        return tb_false;
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_aiop_rtor_poll_addo(tb_aiop_rtor_impl_t* rtor, tb_aioo_impl_t const* aioo)
{
    // check
    tb_aiop_rtor_poll_impl_t* impl = (tb_aiop_rtor_poll_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && impl->pfds && impl->cfds && aioo && aioo->sock, tb_false);

    // the aiop
    tb_aiop_impl_t* aiop = rtor->aiop;
    tb_assert_and_check_return_val(aiop, tb_false);

    // add sock => aioo
    tb_bool_t ok = tb_false;
    tb_spinlock_enter(&impl->lock.hash);
    if (impl->hash) 
    {
        tb_hash_map_insert(impl->hash, aioo->sock, aioo);
        ok = tb_true;
    }
    tb_spinlock_leave(&impl->lock.hash);
    tb_assert_and_check_return_val(ok, tb_false);

    // the code
    tb_size_t code = aioo->code;

    // init pfd
    struct pollfd pfd = {0};
    pfd.fd = ((tb_long_t)aioo->sock) - 1;
    if (code & TB_AIOE_CODE_RECV || code & TB_AIOE_CODE_ACPT) pfd.events |= POLLIN;
    if (code & TB_AIOE_CODE_SEND || code & TB_AIOE_CODE_CONN) pfd.events |= POLLOUT;

    // add pfd, TODO: addo by binary search
    tb_spinlock_enter(&impl->lock.pfds);
    tb_vector_insert_tail(impl->pfds, &pfd);
    tb_spinlock_leave(&impl->lock.pfds);

    // spak it
    if (aiop->spak[0] && code) tb_socket_send(aiop->spak[0], (tb_byte_t const*)"p", 1);

    // ok?
    return ok;
}
static tb_bool_t tb_aiop_rtor_poll_delo(tb_aiop_rtor_impl_t* rtor, tb_aioo_impl_t const* aioo)
{
    // check
    tb_aiop_rtor_poll_impl_t* impl = (tb_aiop_rtor_poll_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && impl->pfds && impl->cfds && aioo && aioo->sock, tb_false);

    // the aiop
    tb_aiop_impl_t* aiop = rtor->aiop;
    tb_assert_and_check_return_val(aiop, tb_false);

    // delo it, TODO: delo by binary search
    tb_spinlock_enter(&impl->lock.pfds);
    tb_remove_first_if(impl->pfds, tb_poll_walk_delo, (tb_pointer_t)(((tb_long_t)aioo->sock) - 1));
    tb_spinlock_leave(&impl->lock.pfds);

    // del sock => aioo
    tb_spinlock_enter(&impl->lock.hash);
    if (impl->hash) tb_hash_map_remove(impl->hash, aioo->sock);
    tb_spinlock_leave(&impl->lock.hash);

    // spak it
    if (aiop->spak[0]) tb_socket_send(aiop->spak[0], (tb_byte_t const*)"p", 1);

    // ok
    return tb_true;
}
static tb_bool_t tb_aiop_rtor_poll_post(tb_aiop_rtor_impl_t* rtor, tb_aioe_ref_t aioe)
{
    // check
    tb_aiop_rtor_poll_impl_t* impl = (tb_aiop_rtor_poll_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && impl->pfds && impl->cfds && aioe, tb_false);

    // the aiop
    tb_aiop_impl_t* aiop = rtor->aiop;
    tb_assert_and_check_return_val(aiop, tb_false);

    // the aioo
    tb_aioo_impl_t* aioo = (tb_aioo_impl_t*)aioe->aioo;
    tb_assert_and_check_return_val(aioo, tb_false);

    // save aioo
    aioo->code = aioe->code;
    aioo->priv = aioe->priv;

    // sete it, TODO: sete by binary search
    tb_spinlock_enter(&impl->lock.pfds);
    tb_walk_all(impl->pfds, tb_poll_walk_sete, (tb_pointer_t)aioe);
    tb_spinlock_leave(&impl->lock.pfds);

    // spak it
    if (aiop->spak[0]) tb_socket_send(aiop->spak[0], (tb_byte_t const*)"p", 1);

    // ok
    return tb_true;
}
static tb_long_t tb_aiop_rtor_poll_wait(tb_aiop_rtor_impl_t* rtor, tb_aioe_ref_t list, tb_size_t maxn, tb_long_t timeout)
{   
    // check
    tb_aiop_rtor_poll_impl_t* impl = (tb_aiop_rtor_poll_impl_t*)rtor;
    tb_assert_and_check_return_val(impl && impl->pfds && impl->cfds && list && maxn, -1);

    // the aiop
    tb_aiop_impl_t* aiop = rtor->aiop;
    tb_assert_and_check_return_val(aiop, tb_false);

    // loop
    tb_long_t wait = 0;
    tb_bool_t stop = tb_false;
    tb_hong_t time = tb_mclock();
    while (!wait && !stop && (timeout < 0 || tb_mclock() < time + timeout))
    {
        // copy pfds
        tb_spinlock_enter(&impl->lock.pfds);
        tb_vector_copy(impl->cfds, impl->pfds);
        tb_spinlock_leave(&impl->lock.pfds);

        // cfds
        struct pollfd*  cfds = (struct pollfd*)tb_vector_data(impl->cfds);
        tb_size_t       cfdm = tb_vector_size(impl->cfds);
        tb_assert_and_check_return_val(cfds && cfdm, -1);

        // wait
        tb_long_t cfdn = poll(cfds, cfdm, timeout);
        tb_assert_and_check_return_val(cfdn >= 0, -1);

        // timeout?
        tb_check_return_val(cfdn, 0);

        // sync
        tb_size_t i = 0;
        for (i = 0; i < cfdm && wait < maxn; i++)
        {
            // the sock
            tb_socket_ref_t sock = tb_fd2sock(cfds[i].fd);
            tb_assert_and_check_return_val(sock, -1);

            // the events
            tb_size_t events = cfds[i].revents;
            tb_check_continue(events);

            // spak?
            if (sock == aiop->spak[1] && (events & POLLIN))
            {
                // read spak
                tb_char_t spak = '\0';
                if (1 != tb_socket_recv(aiop->spak[1], (tb_byte_t*)&spak, 1)) return -1;

                // killed?
                if (spak == 'k') return -1;

                // stop to wait
                stop = tb_true;

                // continue it
                continue ;
            }

            // skip spak
            tb_check_continue(sock != aiop->spak[1]);

            // the aioo
            tb_size_t       code = TB_AIOE_CODE_NONE;
            tb_cpointer_t   priv = tb_null;
            tb_aioo_impl_t*      aioo = tb_null;
            tb_spinlock_enter(&impl->lock.hash);
            if (impl->hash)
            {
                aioo = (tb_aioo_impl_t*)tb_hash_map_get(impl->hash, sock);
                if (aioo) 
                {
                    // save code & data
                    code = aioo->code;
                    priv = aioo->priv;

                    // oneshot? clear it
                    if (aioo->code & TB_AIOE_CODE_ONESHOT)
                    {
                        aioo->code = TB_AIOE_CODE_NONE;
                        aioo->priv = tb_null;
                    }
                }
            }
            tb_spinlock_leave(&impl->lock.hash);
            tb_check_continue(aioo && code);
            
            // init aioe
            tb_aioe_t   aioe = {0};
            aioe.priv   = priv;
            aioe.aioo   = (tb_aioo_ref_t)aioo;
            if (events & POLLIN)
            {
                aioe.code |= TB_AIOE_CODE_RECV;
                if (code & TB_AIOE_CODE_ACPT) aioe.code |= TB_AIOE_CODE_ACPT;
            }
            if (events & POLLOUT) 
            {
                aioe.code |= TB_AIOE_CODE_SEND;
                if (code & TB_AIOE_CODE_CONN) aioe.code |= TB_AIOE_CODE_CONN;
            }
            if ((events & POLLHUP) && !(code & (TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND))) 
                aioe.code |= TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND;

            // save aioe
            list[wait++] = aioe;

            // oneshot?
            if (code & TB_AIOE_CODE_ONESHOT)
            {
                tb_spinlock_enter(&impl->lock.pfds);
                struct pollfd* pfds = (struct pollfd*)tb_vector_data(impl->pfds);
                if (pfds) pfds[i].events = 0;
                tb_spinlock_leave(&impl->lock.pfds);
            }
        }
    }

    // ok
    return wait;
}
static tb_void_t tb_aiop_rtor_poll_exit(tb_aiop_rtor_impl_t* rtor)
{
    tb_aiop_rtor_poll_impl_t* impl = (tb_aiop_rtor_poll_impl_t*)rtor;
    if (impl)
    {
        // exit pfds
        tb_spinlock_enter(&impl->lock.pfds);
        if (impl->pfds) tb_vector_exit(impl->pfds);
        impl->pfds = tb_null;
        tb_spinlock_leave(&impl->lock.pfds);

        // exit cfds
        if (impl->cfds) tb_vector_exit(impl->cfds);
        impl->cfds = tb_null;

        // exit hash
        tb_spinlock_enter(&impl->lock.hash);
        if (impl->hash) tb_hash_map_exit(impl->hash);
        impl->hash = tb_null;
        tb_spinlock_leave(&impl->lock.hash);

        // exit lock
        tb_spinlock_exit(&impl->lock.pfds);
        tb_spinlock_exit(&impl->lock.hash);

        // free it
        tb_free(impl);
    }
}
static tb_void_t tb_aiop_rtor_poll_cler(tb_aiop_rtor_impl_t* rtor)
{
    tb_aiop_rtor_poll_impl_t* impl = (tb_aiop_rtor_poll_impl_t*)rtor;
    if (impl)
    {
        // clear pfds
        tb_spinlock_enter(&impl->lock.pfds);
        if (impl->pfds) tb_vector_clear(impl->pfds);
        tb_spinlock_leave(&impl->lock.pfds);

        // clear hash
        tb_spinlock_enter(&impl->lock.hash);
        if (impl->hash) tb_hash_map_clear(impl->hash);
        tb_spinlock_leave(&impl->lock.hash);

        // spak it
        if (rtor->aiop && rtor->aiop->spak[0])
            tb_socket_send(rtor->aiop->spak[0], (tb_byte_t const*)"p", 1);
    }
}
static tb_aiop_rtor_impl_t* tb_aiop_rtor_poll_init(tb_aiop_impl_t* aiop)
{
    // check
    tb_assert_and_check_return_val(aiop && aiop->maxn, tb_null);

    // done
    tb_bool_t                   ok = tb_false;
    tb_aiop_rtor_poll_impl_t*   impl = tb_null;
    do
    {
        // make rtor
        impl = tb_malloc0_type(tb_aiop_rtor_poll_impl_t);
        tb_assert_and_check_break(impl);

        // init base
        impl->base.aiop = aiop;
        impl->base.code = TB_AIOE_CODE_EALL | TB_AIOE_CODE_ONESHOT;
        impl->base.exit = tb_aiop_rtor_poll_exit;
        impl->base.cler = tb_aiop_rtor_poll_cler;
        impl->base.addo = tb_aiop_rtor_poll_addo;
        impl->base.delo = tb_aiop_rtor_poll_delo;
        impl->base.post = tb_aiop_rtor_poll_post;
        impl->base.wait = tb_aiop_rtor_poll_wait;

        // init lock
        if (!tb_spinlock_init(&impl->lock.pfds)) break;
        if (!tb_spinlock_init(&impl->lock.hash)) break;

        // init pfds
        impl->pfds = tb_vector_init(tb_align8((aiop->maxn >> 3) + 1), tb_element_mem(sizeof(struct pollfd), tb_null, tb_null));
        tb_assert_and_check_break(impl->pfds);

        // init cfds
        impl->cfds = tb_vector_init(tb_align8((aiop->maxn >> 3) + 1), tb_element_mem(sizeof(struct pollfd), tb_null, tb_null));
        tb_assert_and_check_break(impl->cfds);

        // init hash
        impl->hash = tb_hash_map_init(tb_align8(tb_isqrti(aiop->maxn) + 1), tb_element_ptr(tb_null, tb_null), tb_element_ptr(tb_null, tb_null));
        tb_assert_and_check_break(impl->hash);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_aiop_rtor_poll_exit((tb_aiop_rtor_impl_t*)impl);
        impl = tb_null;
    }

    // ok
    return (tb_aiop_rtor_impl_t*)impl;
}
