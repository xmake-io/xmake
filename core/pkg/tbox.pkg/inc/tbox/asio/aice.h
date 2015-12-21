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
 * @file        aice.h
 * @ingroup     asio
 */
#ifndef TB_ASIO_AICE_H
#define TB_ASIO_AICE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aico.h"
#include "../network/ipaddr.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the aice code enum
typedef enum __tb_aice_code_e
{
    TB_AICE_CODE_NONE           = 0

,   TB_AICE_CODE_ACPT           = 1     //!< for sock, accept it
,   TB_AICE_CODE_CONN           = 2     //!< for sock, connect to the host address
,   TB_AICE_CODE_RECV           = 3     //!< for sock, recv data for tcp
,   TB_AICE_CODE_SEND           = 4     //!< for sock, send data for tcp
,   TB_AICE_CODE_URECV          = 5     //!< for sock, recv data for udp
,   TB_AICE_CODE_USEND          = 6     //!< for sock, send data for udp
,   TB_AICE_CODE_RECVV          = 7     //!< for sock, recv iovec data for tcp
,   TB_AICE_CODE_SENDV          = 8     //!< for sock, send iovec data for tcp
,   TB_AICE_CODE_URECVV         = 9     //!< for sock, recv iovec data for udp
,   TB_AICE_CODE_USENDV         = 10    //!< for sock, send iovec data for udp
,   TB_AICE_CODE_SENDF          = 11    //!< for sock, maybe return TB_STATE_NOT_SUPPORTED

,   TB_AICE_CODE_READ           = 12    //!< for file, read data
,   TB_AICE_CODE_WRIT           = 13    //!< for file, writ data
,   TB_AICE_CODE_READV          = 14    //!< for file, read iovec data
,   TB_AICE_CODE_WRITV          = 15    //!< for file, writ iovec data
,   TB_AICE_CODE_FSYNC          = 16    //!< for file, flush data to file

,   TB_AICE_CODE_RUNTASK        = 17    //!< for task or sock or file, run task with the given delay
,   TB_AICE_CODE_CLOS           = 18    //!< for task or sock or file

,   TB_AICE_CODE_MAXN           = 19

}tb_aice_code_e;

/// the acpt aice type
typedef struct __tb_aice_acpt_t
{
    /// the client aico 
    tb_aico_ref_t               aico;

    /// the client addr
    tb_ipaddr_t                   addr;

    /// the private data for using the left space of the union
    tb_cpointer_t               priv[1];

}tb_aice_acpt_t;

/// the conn aice type
typedef struct __tb_aice_conn_t
{
    /// the addr
    tb_ipaddr_t                   addr;

}tb_aice_conn_t;

#ifdef TB_CONFIG_OS_WINDOWS
/// the recv aice type, base: tb_iovec_t
typedef struct __tb_aice_recv_t
{
    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the recv data for (tb_iovec_t*)->data
    tb_byte_t*                  data;

    /// the data real
    tb_size_t                   real;

}tb_aice_recv_t;

/// the send aice type, base: tb_iovec_t
typedef struct __tb_aice_send_t
{
    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the send data for (tb_iovec_t*)->data
    tb_byte_t const*            data;

    /// the data real
    tb_size_t                   real;

}tb_aice_send_t;

/// the urecv aice type, base: tb_iovec_t
typedef struct __tb_aice_urecv_t
{
    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the recv data for (tb_iovec_t*)->data
    tb_byte_t*                  data;

    /// the data real
    tb_size_t                   real;

    /// the addr
    tb_ipaddr_t                   addr;

}tb_aice_urecv_t;

/// the usend aice type, base: tb_iovec_t
typedef struct __tb_aice_usend_t
{
    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the send data for (tb_iovec_t*)->data
    tb_byte_t const*            data;

    /// the data real
    tb_size_t                   real;

    /// the peer addr
    tb_ipaddr_t                   addr;

}tb_aice_usend_t;

/// the read aice type, base: tb_iovec_t
typedef struct __tb_aice_read_t
{
    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the read data for (tb_iovec_t*)->data
    tb_byte_t*                  data;

    /// the data real
    tb_size_t                   real;

    /// the file seek
    tb_hize_t                   seek;

}tb_aice_read_t;

/// the writ aice type, base: tb_iovec_t
typedef struct __tb_aice_writ_t
{
    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the writ data for (tb_iovec_t*)->data
    tb_byte_t const*            data;

    /// the data real
    tb_size_t                   real;

    /// the file seek
    tb_hize_t                   seek;

}tb_aice_writ_t;
#else
/// the recv aice type, base: tb_iovec_t
typedef struct __tb_aice_recv_t
{
    /// the recv data for (tb_iovec_t*)->data
    tb_byte_t*                  data;

    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

}tb_aice_recv_t;

/// the send aice type, base: tb_iovec_t
typedef struct __tb_aice_send_t
{
    /// the send data for (tb_iovec_t*)->data
    tb_byte_t const*            data;

    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

}tb_aice_send_t;

/// the urecv aice type, base: tb_iovec_t
typedef struct __tb_aice_urecv_t
{
    /// the recv data for (tb_iovec_t*)->data
    tb_byte_t*                  data;

    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

    /// the addr
    tb_ipaddr_t                   addr;

}tb_aice_urecv_t;

/// the usend aice type, base: tb_iovec_t
typedef struct __tb_aice_usend_t
{
    /// the send data for (tb_iovec_t*)->data
    tb_byte_t const*            data;

    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

    /// the addr
    tb_ipaddr_t                   addr;

}tb_aice_usend_t;

/// the read aice type, base: tb_iovec_t
typedef struct __tb_aice_read_t
{
    /// the read data for (tb_iovec_t*)->data
    tb_byte_t*                  data;

    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

    /// the file seek
    tb_hize_t                   seek;

}tb_aice_read_t;

/// the writ aice type, base: tb_iovec_t
typedef struct __tb_aice_writ_t
{
    /// the writ data for (tb_iovec_t*)->data
    tb_byte_t const*            data;

    /// the data size for (tb_iovec_t*)->size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

    /// the file seek
    tb_hize_t                   seek;

}tb_aice_writ_t;
#endif

/// the recvv aice type
typedef struct __tb_aice_recvv_t
{
    /// the recv list
    tb_iovec_t const*           list;

    /// the list size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

}tb_aice_recvv_t;

/// the sendv aice type
typedef struct __tb_aice_sendv_t
{
    /// the send list
    tb_iovec_t const*           list;

    /// the list size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

}tb_aice_sendv_t;

/// the urecvv aice type
typedef struct __tb_aice_urecvv_t
{
    /// the recv list
    tb_iovec_t const*           list;

    /// the list size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

    /// the peer addr
    tb_ipaddr_t                   addr;

}tb_aice_urecvv_t;

/// the usendv aice type
typedef struct __tb_aice_usendv_t
{
    /// the send list
    tb_iovec_t const*           list;

    /// the list size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

    /// the addr
    tb_ipaddr_t                   addr;

}tb_aice_usendv_t;

/// the sendf aice type
typedef struct __tb_aice_sendf_t
{
    /// the file
    tb_file_ref_t               file;

    /// the private data for using the left space of the union
    tb_handle_t                 priv[1];

    /// the real
    tb_size_t                   real;

    /// the size
    tb_hize_t                   size;

    /// the seek
    tb_hize_t                   seek;

}tb_aice_sendf_t;

/// the readv aice type
typedef struct __tb_aice_readv_t
{
    /// the read list
    tb_iovec_t const*           list;

    /// the list size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

    /// the file seek
    tb_hize_t                   seek;

}tb_aice_readv_t;

/// the writv aice type
typedef struct __tb_aice_writv_t
{
    /// the writ list
    tb_iovec_t const*           list;

    /// the list size
    tb_size_t                   size;

    /// the data real
    tb_size_t                   real;

    /// the file seek
    tb_hize_t                   seek;

}tb_aice_writv_t;

/// the runtask aice type
typedef struct __tb_aice_runtask_t
{
    /// the when
    tb_hize_t                   when;

    /// the delay
    tb_size_t                   delay;

}tb_aice_runtask_t;

/// the aice type
typedef struct __tb_aice_t
{
    /// the aice code
    tb_uint8_t                  code;

    /*! the state
     *
     * TB_STATE_OK      
     * TB_STATE_FAILED  
     * TB_STATE_KILLED  
     * TB_STATE_CLOSED  
     * TB_STATE_PENDING 
     * TB_STATE_TIMEOUT 
     * TB_STATE_NOT_SUPPORTED 
     */
    tb_size_t                   state;

    /// the aico func
    tb_aico_func_t              func;

    /// the aico private data
    tb_cpointer_t               priv;

    /// the aico
    tb_aico_ref_t               aico;

    /*! the events 
     *
     * tb_iovec_t must be aligned by cpu-bytes for windows WSABUF
     */
#ifdef TB_CONFIG_OS_WINDOWS
    __tb_cpu_aligned__ union
#else
    union
#endif
    {
        // for sock
        tb_aice_acpt_t          acpt;
        tb_aice_conn_t          conn;
        tb_aice_recv_t          recv;
        tb_aice_send_t          send;
        tb_aice_urecv_t         urecv;
        tb_aice_usend_t         usend;
        tb_aice_recvv_t         recvv;
        tb_aice_sendv_t         sendv;
        tb_aice_urecvv_t        urecvv;
        tb_aice_usendv_t        usendv;
        tb_aice_sendf_t         sendf;

        // for file
        tb_aice_read_t          read;
        tb_aice_writ_t          writ;
        tb_aice_readv_t         readv;
        tb_aice_writv_t         writv;

        // for task
        tb_aice_runtask_t       runtask;

    } u;

}tb_aice_t, *tb_aice_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
