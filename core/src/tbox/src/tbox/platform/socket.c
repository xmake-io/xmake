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
 * @file        socket.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "platform_socket"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "socket.h"
#include "impl/socket.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_OS_WINDOWS
#   include "windows/socket.c"
#elif defined(TB_CONFIG_POSIX_HAVE_SOCKET)
#   include "posix/socket.c"
#else
tb_bool_t tb_socket_init_env()
{
    // ok
    return tb_true;
}
tb_void_t tb_socket_exit_env()
{
}
tb_socket_ref_t tb_socket_init(tb_size_t type, tb_size_t family)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_bool_t tb_socket_pair(tb_size_t type, tb_socket_ref_t pair[2])
{
    tb_trace_noimpl();
    return tb_false;
}
tb_bool_t tb_socket_ctrl(tb_socket_ref_t sock, tb_size_t ctrl, ...)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_long_t tb_socket_connect(tb_socket_ref_t sock, tb_ipaddr_ref_t addr)
{
    tb_trace_noimpl();
    return -1;
}
tb_size_t tb_socket_bind(tb_socket_ref_t sock, tb_ipaddr_ref_t addr)
{
    tb_trace_noimpl();
    return 0;
}
tb_bool_t tb_socket_listen(tb_socket_ref_t sock, tb_size_t backlog)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_socket_ref_t tb_socket_accept(tb_socket_ref_t sock, tb_ipaddr_ref_t addr)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_bool_t tb_socket_local(tb_socket_ref_t sock, tb_ipaddr_ref_t addr)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_bool_t tb_socket_kill(tb_socket_ref_t sock, tb_size_t mode)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_bool_t tb_socket_exit(tb_socket_ref_t sock)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_long_t tb_socket_recv(tb_socket_ref_t sock, tb_byte_t* data, tb_size_t size)
{
    tb_trace_noimpl();
    return -1;
}
tb_long_t tb_socket_send(tb_socket_ref_t sock, tb_byte_t const* data, tb_size_t size)
{
    tb_trace_noimpl();
    return -1;
}
tb_long_t tb_socket_recvv(tb_handle_t socket, tb_iovec_t const* list, tb_size_t size)
{
    tb_trace_noimpl();
    return -1;
}
tb_long_t tb_socket_sendv(tb_handle_t socket, tb_iovec_t const* list, tb_size_t size)
{
    tb_trace_noimpl();
    return -1;
}
tb_hong_t tb_socket_sendf(tb_handle_t socket, tb_file_ref_t file, tb_hize_t offset, tb_hize_t size)
{
    tb_trace_noimpl();
    return -1;
}
tb_long_t tb_socket_urecv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_byte_t* data, tb_size_t size)
{
    tb_trace_noimpl();
    return -1;
}
tb_long_t tb_socket_usend(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_byte_t const* data, tb_size_t size)
{
    tb_trace_noimpl();
    return -1;
}
tb_long_t tb_socket_urecvv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size)
{
    tb_trace_noimpl();
    return -1;
}
tb_long_t tb_socket_usendv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size)
{
    tb_trace_noimpl();
    return -1;
}
#endif

#if defined(TB_CONFIG_OS_WINDOWS)
#   include "posix/socket_select.c"
#elif defined(TB_CONFIG_POSIX_HAVE_POLL)
#   include "posix/socket_poll.c"
#else
tb_long_t tb_socket_wait(tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout)
{
    tb_trace_noimpl();
    return -1;
}
#endif
