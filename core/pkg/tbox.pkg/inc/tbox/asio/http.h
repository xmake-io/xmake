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
 * @file        http.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_HTTP_H
#define TB_ASIO_HTTP_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aicp.h"
#include "../network/http.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the aicp http ref type
typedef struct{}*   tb_aicp_http_ref_t;

/*! the aicp http open func type
 *
 * @param http      the http handle
 * @param state     the state
 * @param status    the http status
 * @param priv      the func private data
 *
 * @return          tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t   (*tb_aicp_http_open_func_t)(tb_aicp_http_ref_t http, tb_size_t state, tb_http_status_t const* status, tb_cpointer_t priv);

/*! the aicp http open func type
 *
 * @param http      the http handle
 * @param state     the state
 * @param priv      the func private data
 *
 * @return          tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_void_t   (*tb_aicp_http_clos_func_t)(tb_aicp_http_ref_t http, tb_size_t state, tb_cpointer_t priv);

/*! the aicp http read func type
 *
 * @param http      the http handle
 * @param state     the state
 * @param data      the readed data
 * @param real      the real size, maybe zero
 * @param size      the need size
 * @param priv      the func private data
 *
 * @return          tb_true: ok and continue it if need, tb_false: break it, but not break aicp
 */
typedef tb_bool_t   (*tb_aicp_http_read_func_t)(tb_aicp_http_ref_t http, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv);

/*! the aicp http seek func type
 *
 * @param http      the http handle
 * @param state     the state
 * @param offset    the real offset
 * @param priv      the func private data
 *
 * @return          tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t   (*tb_aicp_http_seek_func_t)(tb_aicp_http_ref_t http, tb_size_t state, tb_hize_t offset, tb_cpointer_t priv);

/*! the aicp http task func type
 *
 * @param http      the http handle
 * @param state     the state
 * @param priv      the func private data
 *
 * @return          tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t   (*tb_aicp_http_task_func_t)(tb_aicp_http_ref_t http, tb_size_t state, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the http 
 *
 * @param aicp      the aicp
 *
 * @return          the http 
 */
tb_aicp_http_ref_t  tb_aicp_http_init(tb_aicp_ref_t aicp);

/*! kill the http
 *
 * @param http      the http
 */
tb_void_t           tb_aicp_http_kill(tb_aicp_http_ref_t http);

/*! exit the http
 *
 * @param http      the http
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_exit(tb_aicp_http_ref_t http);

/*! open the http 
 *
 * @param http      the http
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_open(tb_aicp_http_ref_t http, tb_aicp_http_open_func_t func, tb_cpointer_t priv);

/*! close the http
 *
 * @param http      the http
 * @param func      the func
 * @param priv      the private data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_clos(tb_aicp_http_ref_t http, tb_aicp_http_clos_func_t func, tb_cpointer_t priv);

/*! try closing the http
 *
 * @param http      the http
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_clos_try(tb_aicp_http_ref_t http);

/*! read the http
 *
 * @param http      the http
 * @param size      the read size, using the default size if be zero
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_read(tb_aicp_http_ref_t http, tb_size_t size, tb_aicp_http_read_func_t func, tb_cpointer_t priv);

/*! read the http after the delay time
 *
 * @param http      the http
 * @param delay     the delay time, ms
 * @param size      the read size, using the default size if be zero
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_read_after(tb_aicp_http_ref_t http, tb_size_t delay, tb_size_t size, tb_aicp_http_read_func_t func, tb_cpointer_t priv);

/*! seek the http
 *
 * @param http      the http
 * @param offset    the offset
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_seek(tb_aicp_http_ref_t http, tb_hize_t offset, tb_aicp_http_seek_func_t func, tb_cpointer_t priv);

/*! task the http
 *
 * @param http      the http
 * @param delay     the delay time, ms
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_task(tb_aicp_http_ref_t http, tb_size_t delay, tb_aicp_http_task_func_t func, tb_cpointer_t priv);

/*! open and read the http, open it first if not opened 
 *
 * @param http      the http
 * @param size      the read size, using the default size if be zero
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_open_read(tb_aicp_http_ref_t http, tb_size_t size, tb_aicp_http_read_func_t func, tb_cpointer_t priv);

/*! open and seek the http, open it first if not opened 
 *
 * @param http      the http
 * @param offset    the offset
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_open_seek(tb_aicp_http_ref_t http, tb_hize_t offset, tb_aicp_http_seek_func_t func, tb_cpointer_t priv);

/*! the http aicp
 *
 * @param http      the http
 *
 * @return          the aicp
 */
tb_aicp_ref_t       tb_aicp_http_aicp(tb_aicp_http_ref_t http);

/*! ctrl the http option
 *
 * @param http      the http
 * @param option    the http option
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_http_ctrl(tb_aicp_http_ref_t http, tb_size_t option, ...);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
