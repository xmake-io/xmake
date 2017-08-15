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
 * @file        poller_kqueue.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <errno.h>
#include <sys/event.h>
#include <sys/time.h>
#include <unistd.h>
#ifdef TB_CONFIG_POSIX_HAVE_GETRLIMIT
#   include <sys/resource.h>
#endif

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

// the kqueue poller type
typedef struct __tb_poller_kqueue_t
{
    // the maxn
    tb_size_t               maxn;

    // the user private data
    tb_cpointer_t           priv;

    // the pair sockets for spak, kill ..
    tb_socket_ref_t         pair[2];

    // the kqueue fd
    tb_long_t               kqfd;

    // the events
    struct kevent*          events;

    // the events count
    tb_size_t               events_count;
    
    // the events hash (socket => events)
    tb_size_t*              hash;

    // the events hash size
    tb_size_t               hash_size;
    
}tb_poller_kqueue_t, *tb_poller_kqueue_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_size_t tb_poller_maxfds()
{
    // attempt to get it from getdtablesize
    tb_size_t maxfds = 0;
#ifdef TB_CONFIG_POSIX_HAVE_GETDTABLESIZE
    if (!maxfds) maxfds = getdtablesize();
#endif

    // attempt to get it from getrlimit
#ifdef TB_CONFIG_POSIX_HAVE_GETRLIMIT
	struct rlimit rl;
    if (!maxfds && !getrlimit(RLIMIT_NOFILE, &rl))
        maxfds = rl.rlim_cur;
#endif

    // attempt to get it from sysconf
    if (!maxfds) maxfds = sysconf(_SC_OPEN_MAX);

    // ok?
    return maxfds;
}
static tb_bool_t tb_poller_change(tb_poller_kqueue_ref_t poller, struct kevent* events, tb_size_t count)
{
    // check
    tb_assert_and_check_return_val(events && count, tb_false);

    // change events
    struct timespec t = {0};
    if (kevent(poller->kqfd, events, count, tb_null, 0, &t) < 0) 
    {
        // trace
        tb_trace_e("change kevent failed, errno: %d", errno);

        // failed
        return tb_false;
    }

    // ok
    return tb_true;
}
static tb_void_t tb_poller_hash_set(tb_poller_kqueue_ref_t poller, tb_socket_ref_t sock, tb_size_t events)
{
    // check
    tb_assert(poller && sock);

    // the socket fd
    tb_long_t fd = tb_sock2fd(sock);
    tb_assert(fd > 0 && fd < TB_MAXS32);

    // not empty events?
    if (events)
    {
        // no hash? init it first
        tb_size_t need = fd + 1;
        if (!poller->hash)
        {
            // init hash
            poller->hash = tb_nalloc0_type(need, tb_size_t);
            tb_assert_and_check_return(poller->hash);

            // init hash size
            poller->hash_size = need;
        }
        else if (need > poller->hash_size)
        {
            // grow hash
            poller->hash = (tb_size_t*)tb_ralloc(poller->hash, need * sizeof(tb_size_t));
            tb_assert_and_check_return(poller->hash);

            // init growed space
            tb_memset(poller->hash + poller->hash_size, 0, (need - poller->hash_size) * sizeof(tb_size_t));

            // grow hash size
            poller->hash_size = need;
        }

        // save events
        poller->hash[fd] = events;
    }
}
static __tb_inline__ tb_size_t tb_poller_hash_get(tb_poller_kqueue_ref_t poller, tb_socket_ref_t sock)
{
    // check
    tb_assert(poller && poller->hash && sock);

    // the socket fd
    tb_long_t fd = tb_sock2fd(sock);
    tb_assert(fd > 0 && fd < TB_MAXS32);

    // get the user private data
    return fd < poller->hash_size? poller->hash[fd] : 0;
}
static __tb_inline__ tb_void_t tb_poller_hash_del(tb_poller_kqueue_ref_t poller, tb_socket_ref_t sock)
{
    // check
    tb_assert(poller && poller->hash && sock);

    // the socket fd
    tb_long_t fd = tb_sock2fd(sock);
    tb_assert(fd > 0 && fd < TB_MAXS32);

    // remove the user private data
    if (fd < poller->hash_size) poller->hash[fd] = 0;
}


/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_poller_ref_t tb_poller_init(tb_cpointer_t priv)
{
    // done
    tb_bool_t               ok = tb_false;
    tb_poller_kqueue_ref_t  poller = tb_null;
    do
    {
        // make poller
        poller = tb_malloc0_type(tb_poller_kqueue_t);
        tb_assert_and_check_break(poller);

        // init kqueue
        poller->kqfd = kqueue();
        tb_assert_and_check_break(poller->kqfd > 0);

        // init maxn
        poller->maxn = tb_poller_maxfds();
        tb_assert_and_check_break(poller->maxn);

        // init user private data
        poller->priv = priv;

        // init pair sockets
        if (!tb_socket_pair(TB_SOCKET_TYPE_TCP, poller->pair)) break;

        // insert pair socket first
        if (!tb_poller_insert((tb_poller_ref_t)poller, poller->pair[1], TB_POLLER_EVENT_RECV, tb_null)) break;  

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (poller) tb_poller_exit((tb_poller_ref_t)poller);
        poller = tb_null;
    }

    // ok?
    return (tb_poller_ref_t)poller;
}
tb_void_t tb_poller_exit(tb_poller_ref_t self)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return(poller);

    // exit pair sockets
    if (poller->pair[0]) tb_socket_exit(poller->pair[0]);
    if (poller->pair[1]) tb_socket_exit(poller->pair[1]);
    poller->pair[0] = tb_null;
    poller->pair[1] = tb_null;

    // exit hash
    if (poller->hash) tb_free(poller->hash);
    poller->hash        = tb_null;
    poller->hash_size   = 0;

    // exit events
    if (poller->events) tb_free(poller->events);
    poller->events = tb_null;
    poller->events_count = 0;

    // close kqfd
    if (poller->kqfd > 0) close(poller->kqfd);
    poller->kqfd = 0;

    // free it
    tb_free(poller);
}
tb_void_t tb_poller_clear(tb_poller_ref_t self)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return(poller);

    // clear hash
    if (poller->hash) tb_memset(poller->hash, 0, poller->hash_size * sizeof(tb_size_t));

    // close the previous kqueue fd first
    if (poller->kqfd > 0) close(poller->kqfd);

    // recreate a new kqueue
    poller->kqfd = kqueue();
    tb_assert(poller->kqfd > 0);
}
tb_cpointer_t tb_poller_priv(tb_poller_ref_t self)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return_val(poller, tb_null);

    // get the user private data
    return poller->priv;
}
tb_void_t tb_poller_kill(tb_poller_ref_t self)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return(poller);

    // kill it
    if (poller->pair[0]) tb_socket_send(poller->pair[0], (tb_byte_t const*)"k", 1);
}
tb_void_t tb_poller_spak(tb_poller_ref_t self)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return(poller);

    // post it
    if (poller->pair[0]) tb_socket_send(poller->pair[0], (tb_byte_t const*)"p", 1);
}
tb_bool_t tb_poller_support(tb_poller_ref_t self, tb_size_t events)
{
    // all supported events 
    static tb_size_t events_supported = TB_POLLER_EVENT_EALL | TB_POLLER_EVENT_CLEAR | TB_POLLER_EVENT_ONESHOT;

    // is supported?
    return (events_supported & events) == events;
}
tb_bool_t tb_poller_insert(tb_poller_ref_t self, tb_socket_ref_t sock, tb_size_t events, tb_cpointer_t priv)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return_val(poller && poller->kqfd > 0 && sock, tb_false);

    // init the add event
    tb_size_t adde = EV_ADD | EV_ENABLE;
    if (events & TB_POLLER_EVENT_CLEAR) adde |= EV_CLEAR;
    if (events & TB_POLLER_EVENT_ONESHOT) adde |= EV_ONESHOT;

    // insert socket and add events
    struct kevent   e[2];
    tb_size_t       n = 0;
    tb_int_t        fd = tb_sock2fd(sock);
    if (events & TB_POLLER_EVENT_RECV)
    {
        EV_SET(&e[n], fd, EVFILT_READ, adde, NOTE_EOF, 0, (tb_pointer_t)priv); n++;
    }
    if (events & TB_POLLER_EVENT_SEND)
    {
        EV_SET(&e[n], fd, EVFILT_WRITE, adde, NOTE_EOF, 0, (tb_pointer_t)priv); n++;
    }

    // change it
    tb_bool_t ok = n? tb_poller_change(poller, e, n) : tb_true;
    
    // save events to socket
    if (ok) tb_poller_hash_set(poller, sock, events);

    // ok?
    return ok;
}
tb_bool_t tb_poller_remove(tb_poller_ref_t self, tb_socket_ref_t sock)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return_val(poller && poller->kqfd > 0 && sock, tb_false);

    // get the previous events
    tb_size_t events = tb_poller_hash_get(poller, sock);

    // remove this socket and events
    struct kevent   e[2];
    tb_size_t       n = 0;
    tb_int_t        fd = tb_sock2fd(sock);
    if (events & TB_POLLER_EVENT_RECV)
    {
        EV_SET(&e[n], fd, EVFILT_READ, EV_DELETE, 0, 0, tb_null);
        n++;
    }
    if (events & TB_POLLER_EVENT_SEND)
    {
        EV_SET(&e[n], fd, EVFILT_WRITE, EV_DELETE, 0, 0, tb_null);
        n++;
    }

    // change it
    tb_bool_t ok = n? tb_poller_change(poller, e, n) : tb_true;

    // remove events from socket
    if (ok) tb_poller_hash_del(poller, sock);

    // ok?
    return ok;
}
tb_bool_t tb_poller_modify(tb_poller_ref_t self, tb_socket_ref_t sock, tb_size_t events, tb_cpointer_t priv)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return_val(poller && poller->kqfd > 0 && sock, tb_false);

    // get the previous events
    tb_size_t events_old = tb_poller_hash_get(poller, sock);

    // change
    tb_size_t adde = events & ~events_old;
    tb_size_t dele = ~events & events_old;

    // init the add event
    tb_size_t add_event = EV_ADD | EV_ENABLE;
    if (events & TB_POLLER_EVENT_CLEAR) add_event |= EV_CLEAR;
    if (events & TB_POLLER_EVENT_ONESHOT) add_event |= EV_ONESHOT;

    // modify events
    struct kevent   e[2];
    tb_size_t       n = 0;
    tb_int_t        fd = tb_sock2fd(sock);
    if (adde & TB_SOCKET_EVENT_RECV) 
    {
        EV_SET(&e[n], fd, EVFILT_READ, add_event, NOTE_EOF, 0, (tb_pointer_t)priv);
        n++;
    }
    else if (dele & TB_SOCKET_EVENT_RECV) 
    {
        EV_SET(&e[n], fd, EVFILT_READ, EV_DELETE, 0, 0, (tb_pointer_t)priv);
        n++;
    }
    if (adde & TB_SOCKET_EVENT_SEND)
    {
        EV_SET(&e[n], fd, EVFILT_WRITE, add_event, NOTE_EOF, 0, (tb_pointer_t)priv);
        n++;
    }
    else if (dele & TB_SOCKET_EVENT_SEND)
    {
        EV_SET(&e[n], fd, EVFILT_WRITE, EV_DELETE, 0, 0, (tb_pointer_t)priv);
        n++;
    }

    // change it
    tb_bool_t ok = n? tb_poller_change(poller, e, n) : tb_true;

    // save events to socket
    if (ok) tb_poller_hash_set(poller, sock, events);

    // ok?
    return ok;
}
tb_long_t tb_poller_wait(tb_poller_ref_t self, tb_poller_event_func_t func, tb_long_t timeout)
{
    // check
    tb_poller_kqueue_ref_t poller = (tb_poller_kqueue_ref_t)self;
    tb_assert_and_check_return_val(poller && poller->kqfd > 0 && poller->maxn && func, -1);

    // init time
    struct timespec t = {0};
    if (timeout > 0)
    {
        t.tv_sec = timeout / 1000;
        t.tv_nsec = (timeout % 1000) * 1000000;
    }

    // init events
    tb_size_t grow = tb_align8((poller->maxn >> 3) + 1);
    if (!poller->events)
    {
        poller->events_count = grow;
        poller->events = tb_nalloc_type(poller->events_count, struct kevent);
        tb_assert_and_check_return_val(poller->events, -1);
    }

    // wait events
    tb_long_t events_count = kevent(poller->kqfd, tb_null, 0, poller->events, poller->events_count, timeout >= 0? &t : tb_null);
    tb_assert_and_check_return_val(events_count >= 0 && events_count <= poller->events_count, -1);
    
    // timeout?
    tb_check_return_val(events_count, 0);

    // grow it if events is full
    if (events_count == poller->events_count)
    {
        // grow size
        poller->events_count += grow;
        if (poller->events_count > poller->maxn) poller->events_count = poller->maxn;

        // grow data
        poller->events = (struct kevent*)tb_ralloc(poller->events, poller->events_count * sizeof(struct kevent));
        tb_assert_and_check_return_val(poller->events, -1);
    }
    tb_assert(events_count <= poller->events_count);

    // limit 
    events_count = tb_min(events_count, poller->maxn);

    // handle events 
    tb_size_t       i = 0;
    tb_size_t       wait = 0;
    struct kevent*  e = tb_null;
    tb_socket_ref_t pair = poller->pair[1];
    for (i = 0; i < events_count; i++)
    {
        // the kevents 
        e = poller->events + i;

        // the socket
        tb_socket_ref_t sock = tb_fd2sock(e->ident);
        tb_assert(sock);

        // spak?
        if (sock == pair && e->filter == EVFILT_READ) 
        {
            // read spak
            tb_char_t spak = '\0';
            if (1 != tb_socket_recv(pair, (tb_byte_t*)&spak, 1)) return -1;

            // killed?
            if (spak == 'k') return -1;

            // continue it
            continue ;
        }

        // skip spak
        tb_check_continue(sock != pair);

        // init events 
        tb_size_t events = TB_POLLER_EVENT_NONE;
        if (e->filter == EVFILT_READ) events |= TB_POLLER_EVENT_RECV;
        if (e->filter == EVFILT_WRITE) events |= TB_POLLER_EVENT_SEND;
        if ((e->flags & EV_ERROR) && !(events & (TB_POLLER_EVENT_RECV | TB_POLLER_EVENT_SEND))) 
            events |= TB_POLLER_EVENT_RECV | TB_POLLER_EVENT_SEND;

        // connection closed for the edge trigger?
        if (e->flags & EV_EOF) 
            events |= TB_POLLER_EVENT_EOF;

        // call event function
        func(self, sock, events, e->udata);

        // update the events count
        wait++;
    }

    // ok
    return wait;
}

