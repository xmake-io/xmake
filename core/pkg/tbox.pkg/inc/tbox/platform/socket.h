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
 * @file        socket.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_SOCKET_H
#define TB_PLATFORM_SOCKET_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../network/ipaddr.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the socket type enum
typedef enum __tb_socket_type_e
{
    TB_SOCKET_TYPE_NUL                  = 0
,   TB_SOCKET_TYPE_TCP                  = 1
,   TB_SOCKET_TYPE_UDP                  = 2

}tb_socket_type_e;

/// the socket kill enum
typedef enum __tb_socket_kill_e
{
    TB_SOCKET_KILL_RO                   = 0
,   TB_SOCKET_KILL_WO                   = 1
,   TB_SOCKET_KILL_RW                   = 2

}tb_socket_kill_e;

/// the socket ctrl enum
typedef enum __tb_socket_ctrl_e
{
    TB_SOCKET_CTRL_SET_BLOCK            = 0
,   TB_SOCKET_CTRL_GET_BLOCK            = 1
,   TB_SOCKET_CTRL_SET_RECV_BUFF_SIZE   = 2
,   TB_SOCKET_CTRL_GET_RECV_BUFF_SIZE   = 3
,   TB_SOCKET_CTRL_SET_SEND_BUFF_SIZE   = 4
,   TB_SOCKET_CTRL_GET_SEND_BUFF_SIZE   = 5
,   TB_SOCKET_CTRL_SET_TCP_NODELAY      = 6
,   TB_SOCKET_CTRL_GET_TCP_NODELAY      = 7

}tb_socket_ctrl_e;

/// the socket event enum, only for sock
typedef enum __tb_socket_event_e
{
    TB_SOCKET_EVENT_NONE                = 0x0000
,   TB_SOCKET_EVENT_RECV                = 0x0001
,   TB_SOCKET_EVENT_SEND                = 0x0002
,   TB_SOCKET_EVENT_CONN                = TB_SOCKET_EVENT_SEND
,   TB_SOCKET_EVENT_ACPT                = TB_SOCKET_EVENT_RECV
,   TB_SOCKET_EVENT_EALL                = TB_SOCKET_EVENT_RECV | TB_SOCKET_EVENT_SEND

}tb_socket_event_e;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init socket
 *
 * @param type      the socket type
 * @param family    the address family, default: ipv4
 *
 * @return          the socket 
 */
tb_socket_ref_t     tb_socket_init(tb_size_t type, tb_size_t family);

/*! exit socket
 *
 * @param sock      the socket 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_socket_exit(tb_socket_ref_t sock);

/*! init socket pair
 *
 * @param type      the socket type
 * @param pair      the socket pair
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_socket_pair(tb_size_t type, tb_socket_ref_t pair[2]);

/*! ctrl the socket 
 *
 * @param sock      the socket 
 * @param ctrl      the ctrl code
 */
tb_bool_t           tb_socket_ctrl(tb_socket_ref_t sock, tb_size_t ctrl, ...);

/*! connect socket
 *
 * @param sock      the socket 
 * @param addr      the address
 *
 * @return          ok: 1, continue: 0; failed: -1
 */
tb_long_t           tb_socket_connect(tb_socket_ref_t sock, tb_ipaddr_ref_t addr);

/*! bind socket
 *
 * you can call tb_socket_local for the bound address
 *
 * @param sock      the socket 
 * @param addr      the address
 *                  - bind any port if port == 0
 *                  - bind any ip address if ip is empty
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_socket_bind(tb_socket_ref_t sock, tb_ipaddr_ref_t addr);

/*! listen socket
 *
 * @param sock      the socket 
 * @param backlog   the maximum length for the queue of pending connections
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_socket_listen(tb_socket_ref_t sock, tb_size_t backlog);

/*! accept socket
 *
 * @param sock      the socket 
 * @param addr      the client address
 *
 * @return          the client socket 
 */
tb_socket_ref_t     tb_socket_accept(tb_socket_ref_t sock, tb_ipaddr_ref_t addr);

/*! get local address
 *
 * @param sock      the socket 
 * @param addr      the local address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_socket_local(tb_socket_ref_t sock, tb_ipaddr_ref_t addr);

/*! kill socket
 *
 * @param sock      the socket 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_socket_kill(tb_socket_ref_t sock, tb_size_t mode);

/*! recv the socket data for tcp
 *
 * @param sock      the socket 
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size or -1
 */
tb_long_t           tb_socket_recv(tb_socket_ref_t sock, tb_byte_t* data, tb_size_t size);

/*! send the socket data for tcp
 *
 * @param sock      the socket 
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size or -1
 */
tb_long_t           tb_socket_send(tb_socket_ref_t sock, tb_byte_t const* data, tb_size_t size);

/*! recvv the socket data for tcp
 * 
 * @param sock      the socket 
 * @param list      the iovec list
 * @param size      the iovec size
 *
 * @return          the real size or -1
 */
tb_long_t           tb_socket_recvv(tb_socket_ref_t sock, tb_iovec_t const* list, tb_size_t size);

/*! sendv the socket data for tcp
 * 
 * @param sock      the socket 
 * @param list      the iovec list
 * @param size      the iovec size
 *
 * @return          the real size or -1
 */
tb_long_t           tb_socket_sendv(tb_socket_ref_t sock, tb_iovec_t const* list, tb_size_t size);

/*! sendf the socket data
 * 
 * @param sock      the socket 
 * @param file      the file
 * @param offset    the offset
 * @param size      the size
 *
 * @return          the real size or -1
 */
tb_hong_t           tb_socket_sendf(tb_socket_ref_t sock, tb_file_ref_t file, tb_hize_t offset, tb_hize_t size);

/*! send the socket data for udp
 *
 * @param sock      the socket 
 * @param addr      the address
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size or -1
 */
tb_long_t           tb_socket_usend(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_byte_t const* data, tb_size_t size);
    
/*! recv the socket data for udp
 *
 * @param sock      the socket 
 * @param addr      the peer address(output)
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size or -1
 */
tb_long_t           tb_socket_urecv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_byte_t* data, tb_size_t size);

/*! urecvv the socket data for udp
 * 
 * @param sock      the socket 
 * @param addr      the peer address(output)
 * @param list      the iovec list
 * @param size      the iovec size
 *
 * @return          the real size or -1
 */
tb_long_t           tb_socket_urecvv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size);

/*! usendv the socket data for udp
 * 
 * @param sock      the socket 
 * @param addr      the addr
 * @param list      the iovec list
 * @param size      the iovec size
 *
 * @return          the real size or -1
 */
tb_long_t           tb_socket_usendv(tb_socket_ref_t sock, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size);

/*! wait socket events
 *
 * @param sock      the sock 
 * @param events    the socket events
 * @param timeout   the timeout, infinity: -1
 *
 * @return          > 0: the events code, 0: timeout, -1: failed
 */
tb_long_t           tb_socket_wait(tb_socket_ref_t sock, tb_size_t events, tb_long_t timeout);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
