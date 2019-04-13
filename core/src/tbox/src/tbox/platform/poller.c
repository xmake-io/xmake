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
 * @file        poller.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "poller"
#define TB_TRACE_MODULE_DEBUG           (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "poller.h"
#include "impl/sockdata.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if defined(TB_CONFIG_OS_WINDOWS)
#   if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
#       include "windows/poller_iocp.c"
#   else
#       include "posix/poller_select.c"
#   endif
#elif defined(TB_CONFIG_POSIX_HAVE_EPOLL_CREATE) \
    && defined(TB_CONFIG_POSIX_HAVE_EPOLL_WAIT)
#   include "linux/poller_epoll.c"
#elif defined(TB_CONFIG_OS_MACOSX)
#   include "mach/poller_kqueue.c"
#elif defined(TB_CONFIG_POSIX_HAVE_POLL) && !defined(TB_CONFIG_MICRO_ENABLE) /* TODO remove vector for supporting the micro mode */
#   include "posix/poller_poll.c"
#elif defined(TB_CONFIG_POSIX_HAVE_SELECT)
#   include "posix/poller_select.c"
#else
tb_poller_ref_t tb_poller_init(tb_cpointer_t priv)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_void_t tb_poller_exit(tb_poller_ref_t poller)
{
    tb_trace_noimpl();
}
tb_cpointer_t tb_poller_priv(tb_poller_ref_t poller)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_void_t tb_poller_kill(tb_poller_ref_t poller)
{
    tb_trace_noimpl();
}
tb_void_t tb_poller_spak(tb_poller_ref_t poller)
{
    tb_trace_noimpl();
}
tb_bool_t tb_poller_support(tb_poller_ref_t poller, tb_size_t events)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_bool_t tb_poller_insert(tb_poller_ref_t poller, tb_socket_ref_t sock, tb_size_t events, tb_cpointer_t priv)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_bool_t tb_poller_remove(tb_poller_ref_t poller, tb_socket_ref_t sock)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_bool_t tb_poller_modify(tb_poller_ref_t poller, tb_socket_ref_t sock, tb_size_t events, tb_cpointer_t priv)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_long_t tb_poller_wait(tb_poller_ref_t poller, tb_poller_event_func_t func, tb_long_t timeout)
{
    tb_trace_noimpl();
    return 0;
}
#endif

