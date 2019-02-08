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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        socket.c
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../socket.h"
#include "interface/interface.h"
#include "iocp_object.h"
#include "socket_pool.h"
#include "../posix/sockaddr.h"
#ifdef TB_CONFIG_MODULE_HAVE_COROUTINE
#   include "../../coroutine/coroutine.h"
#   include "../../coroutine/impl/impl.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_int_t tb_socket_type(tb_size_t type)
{
    // get socket type
    switch ((type >> 8) << 8)
    {
    case TB_SOCKET_TYPE_SOCK_STREAM:
        return SOCK_STREAM;
    case TB_SOCKET_TYPE_SOCK_DGRAM: 
        return SOCK_DGRAM;
    case TB_SOCKET_TYPE_SOCK_RAW: 
        return SOCK_RAW;
    }

    // failed
    return -1;
}
static tb_int_t tb_socket_proto(tb_size_t type, tb_size_t family)
{
    // get protocal type
    switch (type & 0xff)
    {
    case TB_SOCKET_TYPE_IPPROTO_TCP:
        return IPPROTO_TCP;
    case TB_SOCKET_TYPE_IPPROTO_UDP: 
        return IPPROTO_UDP;
    case TB_SOCKET_TYPE_IPPROTO_ICMP: 
        return family == TB_IPADDR_FAMILY_IPV6? IPPROTO_ICMPV6 : IPPROTO_ICMP;
    }

    // failed
    return -1;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_socket_init_env()
{
    // load WSA* interfaces
    tb_ws2_32_ref_t ws2_32 = tb_ws2_32();
    tb_assert_and_check_return_val(ws2_32, tb_false);

    // check WSA* interfaces
    tb_assert_and_check_return_val(ws2_32->WSAStartup, tb_false);
    tb_assert_and_check_return_val(ws2_32->WSACleanup, tb_false);
    tb_assert_and_check_return_val(ws2_32->WSASocketA, tb_false);
    tb_assert_and_check_return_val(ws2_32->WSAIoctl, tb_false);
    tb_assert_and_check_return_val(ws2_32->WSAGetLastError, tb_false);
    tb_assert_and_check_return_val(ws2_32->WSASend, tb_false);
    tb_assert_and_check_return_val(ws2_32->WSARecv, tb_false);
    tb_assert_and_check_return_val(ws2_32->WSASendTo, tb_false);
    tb_assert_and_check_return_val(ws2_32->WSARecvFrom, tb_false);
    tb_assert_and_check_return_val(ws2_32->bind, tb_false);
    tb_assert_and_check_return_val(ws2_32->send, tb_false);
    tb_assert_and_check_return_val(ws2_32->recv, tb_false);
    tb_assert_and_check_return_val(ws2_32->sendto, tb_false);
    tb_assert_and_check_return_val(ws2_32->recvfrom, tb_false);
    tb_assert_and_check_return_val(ws2_32->accept, tb_false);
    tb_assert_and_check_return_val(ws2_32->listen, tb_false);
    tb_assert_and_check_return_val(ws2_32->select, tb_false);
    tb_assert_and_check_return_val(ws2_32->connect, tb_false);
    tb_assert_and_check_return_val(ws2_32->shutdown, tb_false);
    tb_assert_and_check_return_val(ws2_32->getsockname, tb_false);
    tb_assert_and_check_return_val(ws2_32->getsockopt, tb_false);
    tb_assert_and_check_return_val(ws2_32->setsockopt, tb_false);
    tb_assert_and_check_return_val(ws2_32->ioctlsocket, tb_false);
    tb_assert_and_check_return_val(ws2_32->closesocket, tb_false);
    tb_assert_and_check_return_val(ws2_32->gethostname, tb_false);
    tb_assert_and_check_return_val(ws2_32->__WSAFDIsSet, tb_false);

    // init socket context
    WSADATA WSAData = {0};
    if (ws2_32->WSAStartup(MAKEWORD(2, 2), &WSAData))
    {
        ws2_32->WSACleanup();
        return tb_false;
    }

#ifndef TB_CONFIG_MICRO_ENABLE
    // init socket pool
    if (!tb_socket_pool_init()) return tb_false;
#endif

    // ok
    return tb_true;
}
tb_void_t tb_socket_exit_env()
{
#ifndef TB_CONFIG_MICRO_ENABLE
    // exit socket pool
    tb_socket_pool_exit();
#endif

    // exit socket context
    tb_ws2_32()->WSACleanup();
}
tb_socket_ref_t tb_socket_init(tb_size_t type, tb_size_t family)
{
    // check
    tb_assert_and_check_return_val(type, tb_null);
    
    // done
    tb_socket_ref_t sock = tb_null;
    do
    {
        // init socket type and protocol
        tb_int_t t = tb_socket_type(type);
        tb_int_t p = tb_socket_proto(type, family);
        tb_assert_and_check_break(t >= 0 && p >= 0);

        // init socket family
        tb_int_t f = (family == TB_IPADDR_FAMILY_IPV6)? AF_INET6 : AF_INET;

        // sock
        SOCKET fd = tb_ws2_32()->WSASocketA(f, t, p, tb_null, 0, WSA_FLAG_OVERLAPPED); //!< for iocp
        tb_assert_and_check_break(fd >= 0 && fd != INVALID_SOCKET);

        // set the non-block mode
        ULONG nb = 1;
        if (tb_ws2_32()->ioctlsocket(fd, FIONBIO, &nb) == SOCKET_ERROR) break;

        // save socket
        sock = tb_fd2sock(fd);

    } while (0);

    // trace
    tb_trace_d("init: type: %lu, family: %lu, sock: %p", type, family, sock);

    // ok?
    return sock;
}
tb_bool_t tb_socket_pair(tb_size_t type, tb_socket_ref_t pair[2])
{
    // check
    tb_assert_and_check_return_val(type && pair, tb_false);
    
    // init pair
    pair[0] = tb_null;
    pair[1] = tb_null;
 
    // init socket type and protocol
    tb_int_t t = tb_socket_type(type);
    tb_int_t p = tb_socket_proto(type, TB_IPADDR_FAMILY_NONE);
    tb_assert_and_check_return_val(t >= 0 && p >= 0, tb_false);

    // done
    tb_bool_t   ok = tb_false;
    SOCKET      listener = INVALID_SOCKET;
    SOCKET      sock1 = INVALID_SOCKET;
    SOCKET      sock2 = INVALID_SOCKET;
    do
    {
        // init listener
        listener = tb_ws2_32()->WSASocketA(AF_INET, t, p, tb_null, 0, WSA_FLAG_OVERLAPPED);
        tb_assert_and_check_break(listener != INVALID_SOCKET);

        // init bind address
        SOCKADDR_IN b = {0};
        b.sin_family = AF_INET;
        b.sin_port = 0;
        b.sin_addr.S_un.S_addr = tb_bits_ne_to_be_u32(INADDR_LOOPBACK); 

        // reuse addr
#ifdef SO_REUSEADDR
        {
            tb_int_t reuseaddr = 1;
            if (tb_ws2_32()->setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, (tb_char_t*)&reuseaddr, sizeof(reuseaddr)) < 0) 
                break; 
        }
#endif

        // bind it
        if (tb_ws2_32()->bind(listener, (struct sockaddr *)&b, sizeof(b)) == SOCKET_ERROR) break;

        // get socket address
        SOCKADDR_IN d = {0};
        tb_int_t    n = sizeof(SOCKADDR_IN);
        if (tb_ws2_32()->getsockname(listener, (struct sockaddr *)&d, &n) == SOCKET_ERROR) break;
        d.sin_addr.S_un.S_addr = tb_bits_ne_to_be_u32(INADDR_LOOPBACK);
        d.sin_family = AF_INET;

        // listen it
        if (tb_ws2_32()->listen(listener, 1) == SOCKET_ERROR) break;

        // init sock1
        sock1 = tb_ws2_32()->WSASocketA(AF_INET, t, p, tb_null, 0, WSA_FLAG_OVERLAPPED);
        tb_assert_and_check_break(sock1 != INVALID_SOCKET);

        // connect it
        if (tb_ws2_32()->connect(sock1, (struct sockaddr const*)&d, sizeof(d)) == SOCKET_ERROR) break;

        // accept it
        sock2 = tb_ws2_32()->accept(listener, tb_null, tb_null);
        tb_assert_and_check_break(sock2 != INVALID_SOCKET);

        // set non-block
        ULONG nb = 1;
        if (tb_ws2_32()->ioctlsocket(sock1, FIONBIO, &nb) == SOCKET_ERROR) break;
        if (tb_ws2_32()->ioctlsocket(sock2, FIONBIO, &nb) == SOCKET_ERROR) break;

        // ok 
        ok = tb_true;

    } while (0);

    // exit listener
    if (listener != INVALID_SOCKET) tb_ws2_32()->closesocket(listener);
    listener = INVALID_SOCKET;

    // failed? exit it
    if (!ok)
    {
        // exit sock1
        if (sock1 != INVALID_SOCKET) tb_ws2_32()->closesocket(sock1);
        sock1 = INVALID_SOCKET;

        // exit sock2
        if (sock2 != INVALID_SOCKET) tb_ws2_32()->closesocket(sock2);
        sock2 = INVALID_SOCKET;
    }
    else
    {
        pair[0] = tb_fd2sock(sock1);
        pair[1] = tb_fd2sock(sock2);
    }

    // ok?
    return ok;
}
tb_bool_t tb_socket_ctrl(tb_socket_ref_t sock, tb_size_t ctrl, ...)
{
    // check
    tb_assert_and_check_return_val(sock, tb_false);

    // init args
    tb_va_list_t args;
    tb_va_start(args, ctrl);

    // done
    SOCKET      fd = tb_sock2fd(sock);
    tb_bool_t   ok = tb_false;
    switch (ctrl)
    {
    case TB_SOCKET_CTRL_SET_BLOCK:
        {
            // set block
            tb_bool_t is_block = (tb_bool_t)tb_va_arg(args, tb_bool_t);

            // block it?
            ULONG nb = is_block? 0 : 1;
            tb_ws2_32()->ioctlsocket(tb_sock2fd(sock), FIONBIO, &nb);

            // ok 
            ok = tb_true;
        }
        break;
    case TB_SOCKET_CTRL_GET_BLOCK:
        {
            // TODO
            tb_trace_noimpl();
        }
        break;
    case TB_SOCKET_CTRL_SET_TCP_NODELAY:
        {
            // enable the nagle's algorithm
            tb_int_t enable = (tb_int_t)tb_va_arg(args, tb_bool_t);
            if (!tb_ws2_32()->setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (tb_char_t*)&enable, sizeof(enable)))
                ok = tb_true;
        }
        break;
    case TB_SOCKET_CTRL_GET_TCP_NODELAY:
        {
            // the penable
            tb_bool_t* penable = (tb_bool_t*)tb_va_arg(args, tb_bool_t*);
            tb_assert_and_check_return_val(penable, tb_false);

            // the nagle's algorithm is enabled?
            tb_int_t    enable = 0;
            tb_int_t    size = sizeof(enable);
            if (!tb_ws2_32()->getsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (tb_char_t*)&enable, &size))
            {
                // save it
                *penable = (tb_bool_t)enable;
            
                // ok
                ok = tb_true;
            }
            else *penable = tb_false;
        }
        break;
    case TB_SOCKET_CTRL_SET_RECV_BUFF_SIZE:
        {
            // the buff_size
            tb_size_t buff_size = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set the recv buffer size
            tb_int_t real = (tb_int_t)buff_size;
            if (!tb_ws2_32()->setsockopt(fd, SOL_SOCKET, SO_RCVBUF, (tb_char_t*)&real, sizeof(real)))
                ok = tb_true;
        }
        break;
    case TB_SOCKET_CTRL_GET_RECV_BUFF_SIZE:
        {
            // the pbuff_size
            tb_size_t* pbuff_size = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pbuff_size, tb_false);

            // get the recv buffer size
            tb_int_t    real = 0;
            tb_int_t    size = sizeof(real);
            if (!tb_ws2_32()->getsockopt(fd, SOL_SOCKET, SO_RCVBUF, (tb_char_t*)&real, &size))
            {
                // save it
                *pbuff_size = real;
            
                // ok
                ok = tb_true;
            }
            else *pbuff_size = 0;
        }
        break;
    case TB_SOCKET_CTRL_SET_SEND_BUFF_SIZE:
        {
            // the buff_size
            tb_size_t buff_size = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set the send buffer size
            tb_int_t real = (tb_int_t)buff_size;
            if (!tb_ws2_32()->setsockopt(fd, SOL_SOCKET, SO_SNDBUF, (tb_char_t*)&real, sizeof(real)))
                ok = tb_true;
        }
        break;
    case TB_SOCKET_CTRL_GET_SEND_BUFF_SIZE:
        {
            // the pbuff_size
            tb_size_t* pbuff_size = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pbuff_size, tb_false);

            // get the send buffer size
            tb_int_t    real = 0;
            tb_int_t    size = sizeof(real);
            if (!tb_ws2_32()->getsockopt(fd, SOL_SOCKET, SO_SNDBUF, (tb_char_t*)&real, &size))
            {
                // save it
                *pbuff_size = real;
            
                // ok
                ok = tb_true;
            }
            else *pbuff_size = 0;
        }
        break;
    default:
        {
            // trace
            tb_trace_e("unknown socket ctrl: %lu", ctrl);
        }
        break;
    }
    
    // exit args
    tb_va_end(args);

    // ok?
    return ok;
}
tb_long_t tb_socket_connect(tb_socket_ref_t sock, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(sock && addr, -1);
    tb_assert_and_check_return_val(!tb_ipaddr_is_empty(addr), -1);

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to use iocp object to connect if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_connect(object, addr);
#endif

    // load addr
    tb_size_t               n = 0;
	struct sockaddr_storage d = {0};
    if (!(n = tb_sockaddr_load(&d, addr))) return -1;

    // connect
    tb_long_t r = tb_ws2_32()->connect(tb_sock2fd(sock), (struct sockaddr *)&d, (tb_int_t)n);

    // ok?
    if (!r) return 1;

    // errno
    tb_long_t e = tb_ws2_32()->WSAGetLastError();

    // have been connected?
    if (e == WSAEISCONN) return 1;

    // continue?
    if (e == WSAEWOULDBLOCK || e == WSAEINPROGRESS) 
        return 0;

    // error
    return -1;
}
tb_bool_t tb_socket_bind(tb_socket_ref_t sock, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(sock && addr, tb_false);

    // load addr
    tb_int_t                n = 0;
	struct sockaddr_storage d = {0};
    if (!(n = (tb_int_t)tb_sockaddr_load(&d, addr))) return tb_false;

    // reuse addr
#ifdef SO_REUSEADDR
    {
        tb_int_t reuseaddr = 1;
        if (tb_ws2_32()->setsockopt(tb_sock2fd(sock), SOL_SOCKET, SO_REUSEADDR, (tb_char_t*)&reuseaddr, sizeof(reuseaddr)) < 0) 
        {
            // trace
            tb_trace_e("reuseaddr: failed");
        }
    }
#endif

    // reuse port
#ifdef SO_REUSEPORT
    if (tb_ipaddr_port(addr))
    {
        tb_int_t reuseport = 1;
        if (tb_ws2_32()->setsockopt(tb_sock2fd(sock), SOL_SOCKET, SO_REUSEPORT, (tb_char_t*)&reuseport, sizeof(reuseport)) < 0) 
        {
            // trace
            tb_trace_e("reuseport: %u failed", tb_ipaddr_port(addr));
        }
    }
#endif

    // bind 
    return !tb_ws2_32()->bind(tb_sock2fd(sock), (struct sockaddr *)&d, n);
}
tb_bool_t tb_socket_listen(tb_socket_ref_t sock, tb_size_t backlog)
{
    // check
    tb_assert_and_check_return_val(sock, tb_false);

    // listen
    return (tb_ws2_32()->listen(tb_sock2fd(sock), (tb_int_t)backlog) < 0)? tb_false : tb_true;
}
tb_socket_ref_t tb_socket_accept(tb_socket_ref_t sock, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(sock, tb_null);

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to use iocp object to accept if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_accept(object, addr);
#endif

    // done
    tb_bool_t       ok = tb_false;
    tb_socket_ref_t acpt = tb_null;
    do
    {
        // done  
        struct sockaddr_storage d = {0};
        tb_int_t                n = sizeof(d);
        SOCKET                  fd = tb_ws2_32()->accept(tb_sock2fd(sock), (struct sockaddr *)&d, &n);

        // no client?
        tb_check_break(fd >= 0 && fd != INVALID_SOCKET);

        // save sock
        acpt = tb_fd2sock(fd);

        // non-block
        ULONG nb = 1;
        if (tb_ws2_32()->ioctlsocket(fd, FIONBIO, &nb) == SOCKET_ERROR) break;

        /* disable the nagle's algorithm to fix 40ms ack delay in some case (.e.g send-send-40ms-recv)
         *
         * 40ms is the tcp ack delay, which indicates that you are likely 
         * encountering a bad interaction between delayed acks and the nagle's algorithm. 
         *
         * TCP_NODELAY simply disables the nagle's algorithm and is a one-time setting on the socket, 
         * whereas the other two must be set at the appropriate times during the life of the connection 
         * and can therefore be trickier to use.
         * 
         * so we set TCP_NODELAY to reduce response delay for the accepted socket in the server by default
         */
        tb_int_t enable = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (tb_char_t*)&enable, sizeof(enable));

        // save address
        if (addr) tb_sockaddr_save(addr, &d);
        
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (acpt) tb_socket_exit(acpt);
        acpt = tb_null;
    }

    // ok?
    return acpt;
}
tb_bool_t tb_socket_local(tb_socket_ref_t sock, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(sock, tb_false);

    // get local address
    struct sockaddr_storage d = {0};
    tb_int_t                n = sizeof(d);
    if (tb_ws2_32()->getsockname(tb_sock2fd(sock), (struct sockaddr *)&d, &n) == -1) return tb_false;

    // save address
    if (addr) tb_sockaddr_save(addr, &d);

    // ok
    return tb_true;
}
tb_bool_t tb_socket_kill(tb_socket_ref_t sock, tb_size_t mode)
{
    // check
    tb_assert_and_check_return_val(sock, tb_false);

    // init how
    tb_int_t how = SD_BOTH;
    switch (mode)
    {
    case TB_SOCKET_KILL_RO:
        how = SD_RECEIVE;
        break;
    case TB_SOCKET_KILL_WO:
        how = SD_SEND;
        break;
    case TB_SOCKET_KILL_RW:
        how = SD_BOTH;
        break;
    default:
        break;
    }

    // kill it
    tb_bool_t ok = !tb_ws2_32()->shutdown(tb_sock2fd(sock), how)? tb_true : tb_false;
 
    // failed?
    if (!ok)
    {
        // trace
        tb_trace_e("kill: %p failed, errno: %d", sock, GetLastError());
    }

    // ok?
    return ok;
}
tb_bool_t tb_socket_exit(tb_socket_ref_t sock)
{
    // check
    tb_assert_and_check_return_val(sock, tb_false);

    // trace
    tb_trace_d("close: %p", sock);

#ifdef TB_CONFIG_MODULE_HAVE_COROUTINE
    // attempt to cancel waiting from coroutine first
    tb_pointer_t scheduler_io = tb_null;
#   ifndef TB_CONFIG_MICRO_ENABLE
    if ((scheduler_io = tb_co_scheduler_io_self()) && tb_co_scheduler_io_cancel((tb_co_scheduler_io_ref_t)scheduler_io, sock)) {}
    else
#   endif
    if ((scheduler_io = tb_lo_scheduler_io_self()) && tb_lo_scheduler_io_cancel((tb_lo_scheduler_io_ref_t)scheduler_io, sock)) {}
#endif

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
    // remove iocp object for this socket if exists
    tb_iocp_object_remove(sock);
#endif

    // close it
    tb_bool_t ok = !tb_ws2_32()->closesocket(tb_sock2fd(sock))? tb_true : tb_false;
    if (!ok)
    {
        // trace
        tb_trace_e("close: %p failed, errno: %d", sock, GetLastError());
    }

    // ok?
    return ok;
}
tb_long_t tb_socket_recv(tb_socket_ref_t sock, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock && data, -1);
    tb_check_return_val(size, 0);

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to use iocp object to recv data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_recv(object, data, size);
#endif

    // recv
    tb_long_t real = tb_ws2_32()->recv(tb_sock2fd(sock), (tb_char_t*)data, (tb_int_t)size, 0);

    // ok?
    if (real >= 0) return real;

    // errno
    tb_long_t e = tb_ws2_32()->WSAGetLastError();

    // continue?
    if (e == WSAEWOULDBLOCK || e == WSAEINPROGRESS) return 0;

    // error
    return -1;
}
tb_long_t tb_socket_send(tb_socket_ref_t sock, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock && data, -1);
    tb_check_return_val(size, 0);

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to use iocp object to send data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_send(object, data, size);
#endif

    // recv
    tb_long_t real = tb_ws2_32()->send(tb_sock2fd(sock), (tb_char_t const*)data, (tb_int_t)size, 0);

    // ok?
    if (real >= 0) return real;

    // errno
    tb_long_t e = tb_ws2_32()->WSAGetLastError();

    // continue?
    if (e == WSAEWOULDBLOCK || e == WSAEINPROGRESS) return 0;

    // error
    return -1;
}
tb_hong_t tb_socket_sendf(tb_socket_ref_t sock, tb_file_ref_t file, tb_hize_t offset, tb_hize_t size)
{
    // check
    tb_assert_and_check_return_val(sock && file && size, -1);

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to use iocp object to send file data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_sendf(object, file, offset, size);
#endif

    // read data
    tb_byte_t data[8192];
    tb_long_t read = tb_file_pread(file, data, sizeof(data), offset);
    tb_check_return_val(read > 0, read);

    // send data
    tb_size_t writ = 0;
    while (writ < read)
    {
        tb_long_t real = tb_socket_send(sock, data + writ, read - writ);
        if (real > 0) writ += real;
        else break;
    }

    // ok?
    return writ == read? writ : -1;
}
tb_long_t tb_socket_urecv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock && data, -1);

    // no size?
    tb_check_return_val(size, 0);

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to use iocp object to urecv data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_urecv(object, addr, data, size);
#endif

    // recv
	struct sockaddr_storage d = {0};
    tb_int_t                n = sizeof(d);
    tb_long_t               r = tb_ws2_32()->recvfrom(tb_sock2fd(sock), (tb_char_t*)data, (tb_int_t)size, 0, (struct sockaddr*)&d, &n);

    // ok?
    if (r >= 0) 
    {
        // save address
        if (addr) tb_sockaddr_save(addr, &d);
        
        // ok
        return r;
    }

    // continue?
    if (tb_ws2_32()->WSAGetLastError() == WSAEWOULDBLOCK) return 0;

    // error
    return -1;
}
tb_long_t tb_socket_usend(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock && addr && data, -1);
    tb_assert_and_check_return_val(!tb_ipaddr_is_empty(addr), -1);

    // no size?
    tb_check_return_val(size, 0);

#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE) && !defined(TB_CONFIG_MICRO_ENABLE)
    // attempt to use iocp object to usend data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_usend(object, addr, data, size);
#endif

    // load addr
    tb_size_t               n = 0;
	struct sockaddr_storage d = {0};
    if (!(n = tb_sockaddr_load(&d, addr))) return -1;

    // send
    tb_long_t r = tb_ws2_32()->sendto(tb_sock2fd(sock), (tb_char_t const*)data, (tb_int_t)size, 0, (struct sockaddr*)&d, (tb_int_t)n);

    // ok?
    if (r >= 0) return r;

    // continue?
    if (tb_ws2_32()->WSAGetLastError() == WSAEWOULDBLOCK) return 0;

    // error
    return -1;
}
#ifndef TB_CONFIG_MICRO_ENABLE
tb_long_t tb_socket_recvv(tb_socket_ref_t sock, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock && list && size, -1);

#ifdef TB_CONFIG_MODULE_HAVE_COROUTINE
    // attempt to use iocp object to recv data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_recvv(object, list, size);
#endif

    // walk read
    tb_size_t i = 0;
    tb_size_t read = 0;
    for (i = 0; i < size; i++)
    {
        // the data & size
        tb_byte_t*  data = list[i].data;
        tb_size_t   need = list[i].size;
        tb_check_break(data && need);

        // read it
        tb_long_t real = tb_socket_recv(sock, data, need);

        // full? next it
        if (real == need)
        {
            read += real;
            continue ;
        }

        // failed?
        tb_check_return_val(real >= 0, -1);

        // ok?
        if (real > 0) read += real;

        // end
        break;
    }

    // ok?
    return read;
}
tb_long_t tb_socket_sendv(tb_socket_ref_t sock, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock && list && size, -1);

#ifdef TB_CONFIG_MODULE_HAVE_COROUTINE
    // attempt to use iocp object to send data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_sendv(object, list, size);
#endif

    // walk writ
    tb_size_t i = 0;
    tb_size_t writ = 0;
    for (i = 0; i < size; i++)
    {
        // the data & size
        tb_byte_t*  data = list[i].data;
        tb_size_t   need = list[i].size;
        tb_check_break(data && need);

        // writ it
        tb_long_t real = tb_socket_send(sock, data, need);

        // full? next it
        if (real == need)
        {
            writ += real;
            continue ;
        }

        // failed?
        tb_check_return_val(real >= 0, -1);

        // ok?
        if (real > 0) writ += real;

        // end
        break;
    }

    // ok?
    return writ;
}
tb_long_t tb_socket_urecvv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock && list && size, -1);

#ifdef TB_CONFIG_MODULE_HAVE_COROUTINE
    // attempt to use iocp object to recv data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_urecvv(object, addr, list, size);
#endif

    // done
    tb_size_t               i = 0;
	struct sockaddr_storage d = {0};
    tb_int_t                n = sizeof(d);
    tb_size_t               read = 0;
    for (i = 0; i < size; i++)
    {
        // the data and size
        tb_byte_t*  data = list[i].data;
        tb_size_t   need = list[i].size;
        tb_check_break(data && need);

        // read it
        tb_long_t real = tb_ws2_32()->recvfrom(tb_sock2fd(sock), (tb_char_t*)data, (tb_int_t)need, 0, (struct sockaddr*)&d, &n);

        // full? next it
        if (real == need)
        {
            read += real;
            continue ;
        }

        // failed?
        tb_check_return_val(real >= 0, -1);

        // ok?
        if (real > 0) read += real;

        // end
        break;
    }

    // save address
    if (addr) tb_sockaddr_save(addr, &d);
 
    // ok?
    return read;
}
tb_long_t tb_socket_usendv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock && addr && list && size, -1);
    tb_assert_and_check_return_val(!tb_ipaddr_is_empty(addr), -1);

#ifdef TB_CONFIG_MODULE_HAVE_COROUTINE
    // attempt to use iocp object to send data if exists
    tb_iocp_object_ref_t object = tb_iocp_object_get_or_new(sock);
    if (object) return tb_iocp_object_usendv(object, addr, list, size);
#endif

    // load addr
    tb_size_t               n = 0;
	struct sockaddr_storage d = {0};
    if (!(n = tb_sockaddr_load(&d, addr))) return -1;

    // done
    tb_size_t i = 0;
    tb_size_t writ = 0;
    for (i = 0; i < size; i++)
    {
        // the data and size
        tb_byte_t*  data = list[i].data;
        tb_size_t   need = list[i].size;
        tb_check_break(data && need);

        // writ it
        tb_long_t real = tb_ws2_32()->sendto(tb_sock2fd(sock), (tb_char_t const*)data, (tb_int_t)need, 0, (struct sockaddr*)&d, (tb_int_t)n);

        // full? next it
        if (real == need)
        {
            writ += real;
            continue ;
        }

        // failed?
        tb_check_return_val(real >= 0, -1);

        // ok?
        if (real > 0) writ += real;

        // end
        break;
    }

    // ok?
    return writ;
}
#endif
