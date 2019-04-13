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
 * @file        poller_epoll.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <sys/epoll.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#ifdef TB_CONFIG_POSIX_HAVE_GETRLIMIT
#   include <sys/resource.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the epoll poller type
typedef struct __tb_poller_epoll_t
{
    // the maxn
    tb_size_t               maxn;

    // the user private data
    tb_cpointer_t           priv;

    // the pair sockets for spak, kill ..
    tb_socket_ref_t         pair[2];

    // the epoll fd
    tb_long_t               epfd;

    // the events
    struct epoll_event*     events;

    // the events count
    tb_size_t               events_count;

    // the socket data
    tb_sockdata_t           sockdata;
    
}tb_poller_epoll_t, *tb_poller_epoll_ref_t;

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

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_poller_ref_t tb_poller_init(tb_cpointer_t priv)
{
    // done
    tb_bool_t               ok = tb_false;
    tb_poller_epoll_ref_t   poller = tb_null;
    do
    {
        // make poller
        poller = tb_malloc0_type(tb_poller_epoll_t);
        tb_assert_and_check_break(poller);

        // init socket data
        tb_sockdata_init(&poller->sockdata);

        // init maxn
        poller->maxn = tb_poller_maxfds();
        tb_assert_and_check_break(poller->maxn);

        // init epoll
        poller->epfd = epoll_create(poller->maxn);
        tb_assert_and_check_break(poller->epfd > 0);

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
    tb_poller_epoll_ref_t poller = (tb_poller_epoll_ref_t)self;
    tb_assert_and_check_return(poller);

    // exit pair sockets
    if (poller->pair[0]) tb_socket_exit(poller->pair[0]);
    if (poller->pair[1]) tb_socket_exit(poller->pair[1]);
    poller->pair[0] = tb_null;
    poller->pair[1] = tb_null;

    // exit events
    if (poller->events) tb_free(poller->events);
    poller->events          = tb_null;
    poller->events_count    = 0;

    // close epfd
    if (poller->epfd > 0) close(poller->epfd);
    poller->epfd = 0;

    // exit socket data
    tb_sockdata_exit(&poller->sockdata);

    // free it
    tb_free(poller);
}
tb_size_t tb_poller_type(tb_poller_ref_t poller)
{
    return TB_POLLER_TYPE_EPOLL;
}
tb_cpointer_t tb_poller_priv(tb_poller_ref_t self)
{
    // check
    tb_poller_epoll_ref_t poller = (tb_poller_epoll_ref_t)self;
    tb_assert_and_check_return_val(poller, tb_null);

    // get the user private data
    return poller->priv;
}
tb_void_t tb_poller_kill(tb_poller_ref_t self)
{
    // check
    tb_poller_epoll_ref_t poller = (tb_poller_epoll_ref_t)self;
    tb_assert_and_check_return(poller);

    // kill it
    if (poller->pair[0]) tb_socket_send(poller->pair[0], (tb_byte_t const*)"k", 1);
}
tb_void_t tb_poller_spak(tb_poller_ref_t self)
{
    // check
    tb_poller_epoll_ref_t poller = (tb_poller_epoll_ref_t)self;
    tb_assert_and_check_return(poller);

    // post it
    if (poller->pair[0]) tb_socket_send(poller->pair[0], (tb_byte_t const*)"p", 1);
}
tb_bool_t tb_poller_support(tb_poller_ref_t self, tb_size_t events)
{
    // all supported events 
#ifdef EPOLLONESHOT 
    static const tb_size_t events_supported = TB_POLLER_EVENT_EALL | TB_POLLER_EVENT_CLEAR | TB_POLLER_EVENT_ONESHOT;
#else
    static const tb_size_t events_supported = TB_POLLER_EVENT_EALL | TB_POLLER_EVENT_CLEAR;
#endif

    // is supported?
    return (events_supported & events) == events;
}
tb_bool_t tb_poller_insert(tb_poller_ref_t self, tb_socket_ref_t sock, tb_size_t events, tb_cpointer_t priv)
{
    // check
    tb_poller_epoll_ref_t poller = (tb_poller_epoll_ref_t)self;
    tb_assert_and_check_return_val(poller && poller->epfd > 0 && sock, tb_false);

    // init event
    struct epoll_event e = {0};
    if (events & TB_POLLER_EVENT_RECV) e.events |= EPOLLIN;
    if (events & TB_POLLER_EVENT_SEND) e.events |= EPOLLOUT;
    if (events & TB_POLLER_EVENT_CLEAR)
    {
        e.events |= EPOLLET;
#ifdef EPOLLRDHUP
        e.events |= EPOLLRDHUP;
#endif
    }
#ifdef EPOLLONESHOT 
    if (events & TB_POLLER_EVENT_ONESHOT) e.events |= EPOLLONESHOT;
#else
    // oneshot is not supported now
    tb_assertf(!(events & TB_POLLER_EVENT_ONESHOT), "cannot insert events with oneshot, not supported!");
#endif

    // save fd
    e.data.fd = (tb_int_t)tb_sock2fd(sock);
    
    // bind user private data to socket
    tb_sockdata_insert(&poller->sockdata, sock, priv);

    // add socket and events
    if (epoll_ctl(poller->epfd, EPOLL_CTL_ADD, e.data.fd, &e) < 0)
    {
        // trace
        tb_trace_e("insert socket(%p) events: %lu failed, errno: %d", sock, events, errno);

        // failed
        return tb_false;
    }

    // ok
    return tb_true;
}
tb_bool_t tb_poller_remove(tb_poller_ref_t self, tb_socket_ref_t sock)
{
    // check
    tb_poller_epoll_ref_t poller = (tb_poller_epoll_ref_t)self;
    tb_assert_and_check_return_val(poller && poller->epfd > 0 && sock, tb_false);

    // remove socket and events
    struct epoll_event  e = {0};
    tb_long_t           fd = tb_sock2fd(sock);
    if (epoll_ctl(poller->epfd, EPOLL_CTL_DEL, fd, &e) < 0)
    {
        // trace
        tb_trace_e("remove socket(%p) failed, errno: %d", sock, errno);

        // failed
        return tb_false;
    }

    // remove user private data from this socket
    tb_sockdata_remove(&poller->sockdata, sock);
    
    // ok
    return tb_true;
}
tb_bool_t tb_poller_modify(tb_poller_ref_t self, tb_socket_ref_t sock, tb_size_t events, tb_cpointer_t priv)
{
    // check
    tb_poller_epoll_ref_t poller = (tb_poller_epoll_ref_t)self;
    tb_assert_and_check_return_val(poller && poller->epfd > 0 && sock, tb_false);

    // init event
    struct epoll_event e = {0};
    if (events & TB_POLLER_EVENT_RECV) e.events |= EPOLLIN;
    if (events & TB_POLLER_EVENT_SEND) e.events |= EPOLLOUT;
    if (events & TB_POLLER_EVENT_CLEAR) 
    {
        e.events |= EPOLLET;
#ifdef EPOLLRDHUP
        e.events |= EPOLLRDHUP;
#endif
    }
#ifdef EPOLLONESHOT 
    if (events & TB_POLLER_EVENT_ONESHOT) e.events |= EPOLLONESHOT;
#else
    // oneshot is not supported now
    tb_assertf(!(events & TB_POLLER_EVENT_ONESHOT), "cannot insert events with oneshot, not supported!");
#endif

    // save fd
    e.data.fd = (tb_int_t)tb_sock2fd(sock);
    
    // modify user private data to socket
    tb_sockdata_insert(&poller->sockdata, sock, priv);

    // modify events
    if (epoll_ctl(poller->epfd, EPOLL_CTL_MOD, e.data.fd, &e) < 0) 
    {
        // trace
        tb_trace_e("modify socket(%p) events: %lu failed, errno: %d", sock, events, errno);

        // failed
        return tb_false;
    }

    // ok
    return tb_true;
}
tb_long_t tb_poller_wait(tb_poller_ref_t self, tb_poller_event_func_t func, tb_long_t timeout)
{
    // check
    tb_poller_epoll_ref_t poller = (tb_poller_epoll_ref_t)self;
    tb_assert_and_check_return_val(poller && poller->epfd > 0 && poller->maxn && func, -1);

    // init events
    tb_size_t grow = tb_align8((poller->maxn >> 3) + 1);
    if (!poller->events)
    {
        poller->events_count = grow;
        poller->events = tb_nalloc_type(poller->events_count, struct epoll_event);
        tb_assert_and_check_return_val(poller->events, -1);
    }
    
    // wait events
    tb_long_t events_count = epoll_wait(poller->epfd, poller->events, poller->events_count, timeout);

    // interrupted?(for gdb?) continue it
    if (events_count < 0 && errno == EINTR) return 0;

    // check error?
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
        poller->events = (struct epoll_event*)tb_ralloc(poller->events, poller->events_count * sizeof(struct epoll_event));
        tb_assert_and_check_return_val(poller->events, -1);
    }
    tb_assert(events_count <= poller->events_count);

    // limit 
    events_count = tb_min(events_count, poller->maxn);

    // handle events
    tb_size_t           i = 0;
    tb_size_t           wait = 0; 
    struct epoll_event* e = tb_null;
    tb_socket_ref_t     pair = poller->pair[1];
    for (i = 0; i < events_count; i++)
    {
        // the epoll event
        e = poller->events + i;

        // the events for epoll
        tb_size_t epoll_events = e->events;

        // the socket
        tb_long_t       fd = e->data.fd;
        tb_socket_ref_t sock = tb_fd2sock(fd);

        // spak?
        if (sock == pair && (epoll_events & EPOLLIN)) 
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
        if (epoll_events & EPOLLIN) events |= TB_POLLER_EVENT_RECV;
        if (epoll_events & EPOLLOUT) events |= TB_POLLER_EVENT_SEND;
        if (epoll_events & (EPOLLHUP | EPOLLERR) && !(events & (TB_POLLER_EVENT_RECV | TB_POLLER_EVENT_SEND))) 
            events |= TB_POLLER_EVENT_RECV | TB_POLLER_EVENT_SEND;

#ifdef EPOLLRDHUP
        // connection closed for the edge trigger?
        if (epoll_events & EPOLLRDHUP) events |= TB_POLLER_EVENT_EOF;
#endif

        // call event function
        func(self, sock, events, tb_sockdata_get(&poller->sockdata, sock));

        // update the events count
        wait++;
    }

    // ok
    return wait;
}

