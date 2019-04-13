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
 * @file        socket_select.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_WINDOWS
#   include "../windows/interface/interface.h"
#else
#   include <sys/socket.h>
#   include <sys/select.h>
#endif
#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) \
        && !defined(TB_CONFIG_MICRO_ENABLE)
#   include "../../coroutine/coroutine.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// FD_ISSET
#ifdef TB_CONFIG_OS_WINDOWS
#   undef FD_ISSET
#   define FD_ISSET(fd, set) tb_ws2_32()->__WSAFDIsSet((SOCKET)(fd), (fd_set FAR *)(set))
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_long_t tb_socket_wait(tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout)
{
    // check
    tb_assert_and_check_return_val(sock, -1);

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) \
        && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to wait it in coroutine
    if (tb_coroutine_self())
    {
        // wait it
        return tb_coroutine_waitio(sock, events, timeout);
    }
#endif

    // fd
    tb_long_t fd = tb_sock2fd(sock);
    tb_assert_and_check_return_val(fd >= 0, -1);
    
    // init time
    struct timeval t = {0};
    if (timeout > 0)
    {
#ifdef TB_CONFIG_OS_WINDOWS
        t.tv_sec = (LONG)(timeout / 1000);
#else
        t.tv_sec = (timeout / 1000);
#endif
        t.tv_usec = (timeout % 1000) * 1000;
    }

    // init fds
    fd_set  rfds;
    fd_set  wfds;
    fd_set* prfds = (events & TB_SOCKET_EVENT_RECV)? &rfds : tb_null;
    fd_set* pwfds = (events & TB_SOCKET_EVENT_SEND)? &wfds : tb_null;

    if (prfds)
    {
        FD_ZERO(prfds);
        FD_SET(fd, prfds);
    }

    if (pwfds)
    {
        FD_ZERO(pwfds);
        FD_SET(fd, pwfds);
    }
   
    // select
#ifdef TB_CONFIG_OS_WINDOWS
    tb_long_t r = tb_ws2_32()->select((tb_int_t)fd + 1, prfds, pwfds, tb_null, timeout >= 0? &t : tb_null);
#else
    tb_long_t r = select(fd + 1, prfds, pwfds, tb_null, timeout >= 0? &t : tb_null);
#endif
    tb_assert_and_check_return_val(r >= 0, -1);

    // timeout?
    tb_check_return_val(r, 0);

    // check socket error?
#ifdef TB_CONFIG_OS_WINDOWS
    tb_int_t error = 0;
    tb_int_t n = sizeof(tb_int_t);
    if (!tb_ws2_32()->getsockopt(fd, SOL_SOCKET, SO_ERROR, (tb_char_t*)&error, &n) && error)
        return -1;
#else
    tb_int_t error = 0;
    socklen_t n = sizeof(socklen_t);
    if (!getsockopt(fd, SOL_SOCKET, SO_ERROR, (tb_char_t*)&error, &n) && error)
        return -1;
#endif

    // ok
    tb_long_t e = TB_SOCKET_EVENT_NONE;
    if (prfds && FD_ISSET(fd, &rfds)) e |= TB_SOCKET_EVENT_RECV;
    if (pwfds && FD_ISSET(fd, &wfds)) e |= TB_SOCKET_EVENT_SEND;
    return e;
}

