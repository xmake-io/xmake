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
 * @file        ssl.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_SSL_H
#define TB_NETWORK_SSL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// enable ssl?
#if defined(TB_CONFIG_PACKAGE_HAVE_OPENSSL) \
    || defined(TB_CONFIG_PACKAGE_HAVE_POLARSSL)
#   define TB_SSL_ENABLE
#else
#   undef TB_SSL_ENABLE
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the ssl read func type 
 *
 * @param priv      the priv data for context
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size, no data: 0, failed: -1
 */
typedef tb_long_t   (*tb_ssl_func_read_t)(tb_cpointer_t priv, tb_byte_t* data, tb_size_t size);

/*! the ssl writ func type 
 *
 * @param priv      the priv data for context
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size, no data: 0, failed: -1
 */
typedef tb_long_t   (*tb_ssl_func_writ_t)(tb_cpointer_t priv, tb_byte_t const* data, tb_size_t size);

/*! the ssl wait func type 
 *
 * @param priv      the priv data for context
 * @param code      the events code
 * @param timeout   the timeout
 *
 * @return          the real code, no event: 0, failed or closed: -1
 */
typedef tb_long_t   (*tb_ssl_func_wait_t)(tb_cpointer_t priv, tb_size_t code, tb_long_t timeout);

/// the ssl ref type
typedef __tb_typeref__(ssl);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init ssl
 *
 * @param bserver   is server endpoint?
 *
 * @return          the ssl 
 */
tb_ssl_ref_t        tb_ssl_init(tb_bool_t bserver);

/*! exit ssl
 *
 * @param ssl       the ssl
 */
tb_void_t           tb_ssl_exit(tb_ssl_ref_t ssl);

/*! set ssl bio sock
 *
 * @param ssl       the ssl
 * @param sock      the sock handle, non-blocking 
 */
tb_void_t           tb_ssl_set_bio_sock(tb_ssl_ref_t ssl, tb_socket_ref_t sock);

/*! set ssl bio read and writ func 
 *
 * @param ssl       the ssl
 * @param read      the read func
 * @param writ      the writ func
 * #param wait      the wait func only for tb_ssl_open and tb_ssl_wait
 * @param priv      the priv data
 */
tb_void_t           tb_ssl_set_bio_func(tb_ssl_ref_t ssl, tb_ssl_func_read_t read, tb_ssl_func_writ_t writ, tb_ssl_func_wait_t wait, tb_cpointer_t priv);

/*! set ssl timeout for opening
 *
 * @param ssl       the ssl
 * @param timeout   the timeout
 */
tb_void_t           tb_ssl_set_timeout(tb_ssl_ref_t ssl, tb_long_t timeout);

/*! open ssl using blocking mode
 *
 * @note need wait func
 *
 * @param ssl       the ssl
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ssl_open(tb_ssl_ref_t ssl);

/*! try opening ssl using non-blocking mode
 *
 * @code
 *
    // open it
    tb_long_t ok = -1;
    while (!(ok = tb_ssl_open_try(handle)))
    {
        // wait it
        ok = tb_ssl_wait(handle, TB_SOCKET_EVENT_RECV | TB_SOCKET_EVENT_SEND, timeout);
        tb_check_break(ok > 0);
    }

 * @endcode
 *
 * @param ssl       the ssl
 *
 * @return          ok: 1, continue: 0, failed: -1
 */
tb_long_t           tb_ssl_open_try(tb_ssl_ref_t ssl);

/*! clos ssl 
 *
 * @param ssl       the ssl
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ssl_clos(tb_ssl_ref_t ssl);

/*! try closing ssl  using non-blocking mode
 *
 * @code
 *
    // open it
    tb_long_t ok = -1;
    while (!(ok = tb_ssl_clos_try(handle)))
    {
        // wait it
        ok = tb_ssl_wait(handle, TB_SOCKET_EVENT_RECV | TB_SOCKET_EVENT_SEND, timeout);
        tb_check_break(ok > 0);
    }

 * @endcode
 *
 * @param ssl       the ssl
 *
 * @return          ok: 1, continue: 0, failed: -1
 */
tb_long_t           tb_ssl_clos_try(tb_ssl_ref_t ssl);

/*! read ssl data
 *
 * @param ssl       the ssl
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size, no data: 0 and see state for waiting, failed: -1
 */
tb_long_t           tb_ssl_read(tb_ssl_ref_t ssl, tb_byte_t* data, tb_size_t size);

/*! writ ssl data
 *
 * @param ssl       the ssl
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size, no data: 0 and see state for waiting, failed: -1
 */
tb_long_t           tb_ssl_writ(tb_ssl_ref_t ssl, tb_byte_t const* data, tb_size_t size);

/*! wait ssl data
 *
 * @param ssl       the ssl
 * @param events    the events 
 * @param timeout   the timeout
 *
 * @return          the real events, no event: 0, failed or closed: -1
 */
tb_long_t           tb_ssl_wait(tb_ssl_ref_t ssl, tb_size_t events, tb_long_t timeout);

/*! the ssl state see the stream ssl state
 *
 * @param ssl       the ssl
 *
 * @return          the ssl state
 */
tb_size_t           tb_ssl_state(tb_ssl_ref_t ssl);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
