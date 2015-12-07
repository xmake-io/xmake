/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
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

}tb_socket_ctrl_e;

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

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
