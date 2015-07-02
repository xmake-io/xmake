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
 * @file        aico.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_AICO_H
#define TB_ASIO_AICO_H

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
 * macros
 */
#define tb_aico_clos(aico, func, priv)                                          tb_aico_clos_(aico, func, priv __tb_debug_vals__)
#define tb_aico_acpt(aico, func, priv)                                          tb_aico_acpt_(aico, func, priv __tb_debug_vals__)
#define tb_aico_conn(aico, addr, func, priv)                                    tb_aico_conn_(aico, addr, func, priv __tb_debug_vals__)
#define tb_aico_recv(aico, data, size, func, priv)                              tb_aico_recv_(aico, data, size, func, priv __tb_debug_vals__)
#define tb_aico_send(aico, data, size, func, priv)                              tb_aico_send_(aico, data, size, func, priv __tb_debug_vals__)
#define tb_aico_urecv(aico, data, size, func, priv)                             tb_aico_urecv_(aico, data, size, func, priv __tb_debug_vals__)
#define tb_aico_usend(aico, addr, data, size, func, priv)                       tb_aico_usend_(aico, addr, data, size, func, priv __tb_debug_vals__)
#define tb_aico_recvv(aico, list, size, func, priv)                             tb_aico_recvv_(aico, list, size, func, priv __tb_debug_vals__)
#define tb_aico_sendv(aico, list, size, func, priv)                             tb_aico_sendv_(aico, list, size, func, priv __tb_debug_vals__)
#define tb_aico_urecvv(aico, addr, list, size, func, priv)                      tb_aico_urecvv_(aico, addr, list, size, func, priv __tb_debug_vals__)
#define tb_aico_usendv(aico, addr, list, size, func, priv)                      tb_aico_usendv_(aico, addr, list, size, func, priv __tb_debug_vals__)
#define tb_aico_sendf(aico, file, seek, size, func, priv)                       tb_aico_sendf_(aico, file, seek, size, func, priv __tb_debug_vals__)
#define tb_aico_read(aico, seek, data, size, func, priv)                        tb_aico_read_(aico, seek, data, size, func, priv __tb_debug_vals__)
#define tb_aico_writ(aico, seek, data, size, func, priv)                        tb_aico_writ_(aico, seek, data, size, func, priv __tb_debug_vals__)
#define tb_aico_readv(aico, seek, list, size, func, priv)                       tb_aico_readv_(aico, seek, list, size, func, priv __tb_debug_vals__)
#define tb_aico_writv(aico, seek, list, size, func, priv)                       tb_aico_writv_(aico, seek, list, size, func, priv __tb_debug_vals__)
#define tb_aico_fsync(aico, func, priv)                                         tb_aico_fsync_(aico, func, priv __tb_debug_vals__)

#define tb_aico_clos_after(aico, delay, func, priv)                             tb_aico_clos_after_(aico, delay, func, priv __tb_debug_vals__)
#define tb_aico_acpt_after(aico, delay, func, priv)                             tb_aico_acpt_after_(aico, delay, func, priv __tb_debug_vals__)
#define tb_aico_conn_after(aico, delay, addr, func, priv)                       tb_aico_conn_after_(aico, delay, addr, func, priv __tb_debug_vals__)
#define tb_aico_recv_after(aico, delay, data, size, func, priv)                 tb_aico_recv_after_(aico, delay, data, size, func, priv __tb_debug_vals__)
#define tb_aico_send_after(aico, delay, data, size, func, priv)                 tb_aico_send_after_(aico, delay, data, size, func, priv __tb_debug_vals__)
#define tb_aico_urecv_after(aico, delay, data, size, func, priv)                tb_aico_urecv_after_(aico, delay, data, size, func, priv __tb_debug_vals__)
#define tb_aico_usend_after(aico, delay, addr, data, size, func, priv)          tb_aico_usend_after_(aico, delay, addr, data, size, func, priv __tb_debug_vals__)
#define tb_aico_recvv_after(aico, delay, list, size, func, priv)                tb_aico_recvv_after_(aico, delay, list, size, func, priv __tb_debug_vals__)
#define tb_aico_sendv_after(aico, delay, list, size, func, priv)                tb_aico_sendv_after_(aico, delay, list, size, func, priv __tb_debug_vals__)
#define tb_aico_urecvv_after(aico, delay, addr, list, size, func, priv)         tb_aico_urecvv_after_(aico, delay, addr, list, size, func, priv __tb_debug_vals__)
#define tb_aico_usendv_after(aico, delay, addr, list, size, func, priv)         tb_aico_usendv_after_(aico, delay, addr, list, size, func, priv __tb_debug_vals__)
#define tb_aico_sendf_after(aico, delay, file, seek, size, func, priv)          tb_aico_sendf_after_(aico, delay, file, seek, size, func, priv __tb_debug_vals__)
#define tb_aico_read_after(aico, delay, seek, data, size, func, priv)           tb_aico_read_after_(aico, delay, seek, data, size, func, priv __tb_debug_vals__)
#define tb_aico_writ_after(aico, delay, seek, data, size, func, priv)           tb_aico_writ_after_(aico, delay, seek, data, size, func, priv __tb_debug_vals__)
#define tb_aico_readv_after(aico, delay, seek, list, size, func, priv)          tb_aico_readv_after_(aico, delay, seek, list, size, func, priv __tb_debug_vals__)
#define tb_aico_writv_after(aico, delay, seek, list, size, func, priv)          tb_aico_writv_after_(aico, delay, seek, list, size, func, priv __tb_debug_vals__)
#define tb_aico_fsync_after(aico, delay, func, priv)                            tb_aico_fsync_after_(aico, delay, func, priv __tb_debug_vals__)

#define tb_aico_task_run(aico, delay, func, priv)                               tb_aico_task_run_(aico, delay, func, priv __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

struct __tb_aice_t;
/// the aico func type
typedef tb_bool_t (*tb_aico_func_t)(struct __tb_aice_t* aice);

/// the aico type enum
typedef enum __tb_aico_type_e
{
    TB_AICO_TYPE_NONE       = 0     //!< null
,   TB_AICO_TYPE_SOCK       = 1     //!< sock
,   TB_AICO_TYPE_FILE       = 2     //!< file
,   TB_AICO_TYPE_TASK       = 3     //!< task
,   TB_AICO_TYPE_MAXN       = 4

}tb_aico_type_e;

/// the aico timeout enum, only for sock
typedef enum __tb_aico_timeout_e
{
    TB_AICO_TIMEOUT_CONN    = 0
,   TB_AICO_TIMEOUT_RECV    = 1
,   TB_AICO_TIMEOUT_SEND    = 2
,   TB_AICO_TIMEOUT_MAXN    = 3

}tb_aico_timeout_e;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the aico
 *
 * @param aicp      the aicp
 *
 * @return          the aico
 */
tb_aico_ref_t       tb_aico_init(tb_aicp_ref_t aicp);

/*! open the sock aico
 *
 * @param aicp      the aicp
 * @param sock      the socket
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_open_sock(tb_aico_ref_t aico, tb_socket_ref_t sock);

/*! open the sock aico from the socket type
 *
 * @param aicp      the aicp
 * @param type      the socket type
 * @param family    the address family, default: ipv4
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_open_sock_from_type(tb_aico_ref_t aico, tb_size_t type, tb_size_t family);

/*! open the file aico
 *
 * @param aicp      the aicp
 * @param file      the file 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_open_file(tb_aico_ref_t aico, tb_file_ref_t file);

/*! open the file aico from path
 *
 * @param aicp      the aicp
 * @param path      the file path
 * @param mode      the file mode
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_open_file_from_path(tb_aico_ref_t aico, tb_char_t const* path, tb_size_t mode);

/*! open the task aico 
 *
 * @param aicp      the aicp
 * @param ltimer    is the lower precision timer? 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_open_task(tb_aico_ref_t aico, tb_bool_t ltimer);

/*! kill the aico
 *
 * @param aico      the aico
 */
tb_void_t           tb_aico_kill(tb_aico_ref_t aico);

/*! exit the aico
 *
 * @param aico      the aico
 */
tb_void_t           tb_aico_exit(tb_aico_ref_t aico);

/*! the aico aicp
 *
 * @param aico      the aico
 *
 * @return          the aico aicp
 */
tb_aicp_ref_t       tb_aico_aicp(tb_aico_ref_t aico);

/*! the aico type
 *
 * @param aico      the aico
 *
 * @return          the aico type
 */
tb_size_t           tb_aico_type(tb_aico_ref_t aico);

/*! get the socket if the aico is socket type
 *
 * @param aico      the aico
 *
 * @return          the socket
 */
tb_socket_ref_t     tb_aico_sock(tb_aico_ref_t aico);

/*! get the file if the aico is file type
 *
 * @param aico      the aico
 *
 * @return          the file
 */
tb_file_ref_t       tb_aico_file(tb_aico_ref_t aico);

/*! try to close it
 *
 * @param aico      the aico
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_clos_try(tb_aico_ref_t aico);

/*! the aico timeout
 *
 * @param aico      the aico
 * @param type      the timeout type
 *
 * @return          the timeout
 */
tb_long_t           tb_aico_timeout(tb_aico_ref_t aico, tb_size_t type);

/*! set the aico timeout
 *
 * @param aico      the aico
 * @param type      the timeout type
 * @param timeout   the timeout
 */
tb_void_t           tb_aico_timeout_set(tb_aico_ref_t aico, tb_size_t type, tb_long_t timeout);

/*! post the clos
 *
 * @param aicp      the aicp
 * @param func      the func
 * @param priv      the func private data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_clos_(tb_aico_ref_t aico, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the acpt
 *
 * @param aico      the aico
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_acpt_(tb_aico_ref_t aico, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the conn
 *
 * @param aico      the aico
 * @param addr      the address
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_conn_(tb_aico_ref_t aico, tb_ipaddr_ref_t addr, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the recv for sock
 *
 * @param aico      the aico
 * @param data      the data
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_recv_(tb_aico_ref_t aico, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the send for sock
 *
 * @param aico      the aico
 * @param data      the data
 * @param size      the size, send the left file data if size == 0
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_send_(tb_aico_ref_t aico, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the urecv for sock
 *
 * @param aico      the aico
 * @param data      the data
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_urecv_(tb_aico_ref_t aico, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the usend for sock
 *
 * @param aico      the aico
 * @param addr      the addr
 * @param data      the data
 * @param size      the size, send the left file data if size == 0
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_usend_(tb_aico_ref_t aico, tb_ipaddr_ref_t addr, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the recvv for sock
 *
 * @param aico      the aico
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_recvv_(tb_aico_ref_t aico, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the sendv for sock
 *
 * @param aico      the aico
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_sendv_(tb_aico_ref_t aico, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the urecvv for sock
 *
 * @param aico      the aico
 * @param addr      the addr
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_urecvv_(tb_aico_ref_t aico, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the usendv for sock
 *
 * @param aico      the aico
 * @param addr      the addr
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_usendv_(tb_aico_ref_t aico, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the sendfile for sock
 *
 * @param aico      the aico
 * @param file      the file handle
 * @param seek      the seek
 * @param size      the size, send the left data if size == 0
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_sendf_(tb_aico_ref_t aico, tb_file_ref_t file, tb_hize_t seek, tb_hize_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the read for file
 *
 * @param aico      the aico
 * @param seek      the seek
 * @param data      the data
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_read_(tb_aico_ref_t aico, tb_hize_t seek, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the writ for file
 *
 * @param aico      the aico
 * @param seek      the seek
 * @param data      the data
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_writ_(tb_aico_ref_t aico, tb_hize_t seek, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the readv for file
 *
 * @param aico      the aico
 * @param seek      the seek
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_readv_(tb_aico_ref_t aico, tb_hize_t seek, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the writv for file
 *
 * @param aico      the aico
 * @param seek      the seek
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_writv_(tb_aico_ref_t aico, tb_hize_t seek, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the fsync for file
 *
 * @param aico      the aico
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_fsync_(tb_aico_ref_t aico, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the clos after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_clos_after_(tb_aico_ref_t aico, tb_size_t delay, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the acpt after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_acpt_after_(tb_aico_ref_t aico, tb_size_t delay, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the conn after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param addr      the address
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_conn_after_(tb_aico_ref_t aico, tb_size_t delay, tb_ipaddr_ref_t addr, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the recv for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param data      the data
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_recv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the send for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param data      the data
 * @param size      the size, send the left file data if size == 0
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_send_after_(tb_aico_ref_t aico, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the urecv for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param data      the data
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_urecv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the usend for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param addr      the addr
 * @param data      the data
 * @param size      the size, send the left file data if size == 0
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_usend_after_(tb_aico_ref_t aico, tb_size_t delay, tb_ipaddr_ref_t addr, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the recvv for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_recvv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the sendv for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_sendv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the urecvv for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param addr      the addr
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_urecvv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the usendv for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param addr      the addr
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_usendv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the sendfile for sock after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param file      the file handle
 * @param seek      the seek
 * @param size      the size, send the left data if size == 0
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_sendf_after_(tb_aico_ref_t aico, tb_size_t delay, tb_file_ref_t file, tb_hize_t seek, tb_hize_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the read for file after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param seek      the seek
 * @param data      the data
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_read_after_(tb_aico_ref_t aico, tb_size_t delay, tb_hize_t seek, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the writ for file after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param seek      the seek
 * @param data      the data
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_writ_after_(tb_aico_ref_t aico, tb_size_t delay, tb_hize_t seek, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the readv for file after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param seek      the seek
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_readv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_hize_t seek, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the writv for file after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param seek      the seek
 * @param list      the list
 * @param size      the size
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_writv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_hize_t seek, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! post the fsync for file after the delay time
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_fsync_after_(tb_aico_ref_t aico, tb_size_t delay, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/*! run aico task after timeout and will be auto-remove it after be expired
 *
 * only once, need continue to call it again if want to repeat task
 *
 * @param aico      the aico
 * @param delay     the delay time, ms
 * @param func      the callback func
 * @param priv      the callback data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aico_task_run_(tb_aico_ref_t aico, tb_size_t delay, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
