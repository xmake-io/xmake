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
 * @file        ssl.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_SSL_H
#define TB_ASIO_SSL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aicp.h"
#include "../../network/ssl.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the aicp ssl ref type
typedef __tb_typeref__(aicp_ssl);

/*! the aicp ssl open func type
 *
 * @param ssl       the ssl
 * @param state     the state
 * @param priv      the func private data
 *
 * @return          tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t   (*tb_aicp_ssl_open_func_t)(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_cpointer_t priv);

/*! the aicp ssl clos func type
 *
 * @param ssl       the ssl
 * @param state     the state
 * @param priv      the func private data
 */
typedef tb_void_t   (*tb_aicp_ssl_clos_func_t)(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_cpointer_t priv);

/*! the aicp ssl read func type
 *
 * @param ssl       the ssl
 * @param state     the state
 * @param data      the readed data
 * @param real      the real size, maybe zero
 * @param size      the need size
 * @param priv      the func private data
 *
 * @return          tb_true: ok and continue it if need, tb_false: break it, but not break aicp
 */
typedef tb_bool_t   (*tb_aicp_ssl_read_func_t)(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_byte_t* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv);

/*! the aicp ssl writ func type
 *
 * @param ssl       the ssl
 * @param state     the state
 * @param data      the writed data
 * @param real      the real size, maybe zero
 * @param size      the need size
 * @param priv      the func private data
 *
 * @return          tb_true: ok and continue it if need, tb_false: break it, but not break aicp
 */
typedef tb_bool_t   (*tb_aicp_ssl_writ_func_t)(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv);

/*! the aicp ssl task func type
 *
 * @param ssl       the ssl
 * @param state     the state
 * @param delay     the delay
 * @param priv      the func private data
 *
 * @return          tb_true: ok, tb_false: error, but not break aicp
 */
typedef tb_bool_t   (*tb_aicp_ssl_task_func_t)(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_size_t delay, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the ssl 
 *
 * @param aicp      the aicp
 * @param bserver   is server endpoint?
 *
 * @return          the ssl
 */
__tb_deprecated__
tb_aicp_ssl_ref_t   tb_aicp_ssl_init(tb_aicp_ref_t aicp, tb_bool_t bserver);

/*! kill the ssl
 *
 * @param ssl       the ssl
 */
__tb_deprecated__
tb_void_t           tb_aicp_ssl_kill(tb_aicp_ssl_ref_t ssl);

/*! exit the ssl
 *
 * @param ssl       the ssl
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_exit(tb_aicp_ssl_ref_t ssl);

/*! set the ssl aico
 * 
 * @param ssl       the ssl
 * @param aico      the aico
 */
__tb_deprecated__
tb_void_t           tb_aicp_ssl_set_aico(tb_aicp_ssl_ref_t ssl, tb_aico_ref_t aico);

/*! set the ssl timeout
 * 
 * @param ssl       the ssl
 * @param timeout   the ssl timeout, using the default timeout if be zero
 */
__tb_deprecated__
tb_void_t           tb_aicp_ssl_set_timeout(tb_aicp_ssl_ref_t ssl, tb_long_t timeout);

/*! open the ssl 
 *
 * @param ssl       the ssl
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_open(tb_aicp_ssl_ref_t ssl, tb_aicp_ssl_open_func_t func, tb_cpointer_t priv);

/*! close the ssl
 *
 * @param handle    the ssl
 * @param func      the func
 * @param priv      the func private data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_clos(tb_aicp_ssl_ref_t ssl, tb_aicp_ssl_clos_func_t func, tb_cpointer_t priv);

/*! try closing the ssl
 *
 * @param ssl       the ssl
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_clos_try(tb_aicp_ssl_ref_t ssl);

/*! read the ssl
 *
 * @param ssl       the ssl
 * @param data      the read data
 * @param size      the read size
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_read(tb_aicp_ssl_ref_t ssl, tb_byte_t* data, tb_size_t size, tb_aicp_ssl_read_func_t func, tb_cpointer_t priv);

/*! writ the ssl
 *
 * @param ssl       the ssl
 * @param data      the data
 * @param size      the size
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_writ(tb_aicp_ssl_ref_t ssl, tb_byte_t const* data, tb_size_t size, tb_aicp_ssl_writ_func_t func, tb_cpointer_t priv);

/*! read the ssl after the delay time
 *
 * @param ssl       the ssl
 * @param delay     the delay time, ms
 * @param data      the read data
 * @param size      the read size
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_read_after(tb_aicp_ssl_ref_t ssl, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_aicp_ssl_read_func_t func, tb_cpointer_t priv);

/*! writ the ssl after the delay time
 *
 * @param ssl       the ssl
 * @param delay     the delay time, ms
 * @param data      the data
 * @param size      the size
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_writ_after(tb_aicp_ssl_ref_t ssl, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_aicp_ssl_writ_func_t func, tb_cpointer_t priv);

/*! task the ssl
 *
 * @param ssl       the ssl
 * @param delay     the delay time, ms
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_task(tb_aicp_ssl_ref_t ssl, tb_size_t delay, tb_aicp_ssl_task_func_t func, tb_cpointer_t priv);

/*! open and read the ssl, open it first if not opened 
 *
 * @param ssl       the ssl
 * @param data      the read data
 * @param size      the read size
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_open_read(tb_aicp_ssl_ref_t ssl, tb_byte_t* data, tb_size_t size, tb_aicp_ssl_read_func_t func, tb_cpointer_t priv);

/*! open and writ the ssl, open it first if not opened 
 *
 * @param ssl       the ssl
 * @param data      the data
 * @param size      the size
 * @param func      the func
 * @param priv      the func data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_ssl_open_writ(tb_aicp_ssl_ref_t ssl, tb_byte_t const* data, tb_size_t size, tb_aicp_ssl_writ_func_t func, tb_cpointer_t priv);

/*! the ssl aicp
 *
 * @param ssl       the ssl
 *
 * @return          the aicp
 */
__tb_deprecated__
tb_aicp_ref_t       tb_aicp_ssl_aicp(tb_aicp_ssl_ref_t ssl);


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

