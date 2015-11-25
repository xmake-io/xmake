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
 * @param code      the aioe code
 * @param timeout   the timeout
 *
 * @return          the real code, no event: 0, failed or closed: -1
 */
typedef tb_long_t   (*tb_ssl_func_wait_t)(tb_cpointer_t priv, tb_size_t code, tb_long_t timeout);

/// the ssl ref type
typedef struct{}*   tb_ssl_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init ssl
 *
 * @param bserver   is server endpoint?
 *
 * @return          the ssl handle 
 */
tb_ssl_ref_t        tb_ssl_init(tb_bool_t bserver);

/*! exit ssl
 *
 * @param ssl       the ssl handle
 */
tb_void_t           tb_ssl_exit(tb_ssl_ref_t ssl);

/*! set ssl bio sock
 *
 * @param ssl       the ssl handle
 * @param sock      the sock handle, non-blocking 
 */
tb_void_t           tb_ssl_set_bio_sock(tb_ssl_ref_t ssl, tb_socket_ref_t sock);

/*! set ssl bio read and writ func 
 *
 * @param ssl       the ssl handle
 * @param read      the read func
 * @param writ      the writ func
 * #param wait      the wait func only for tb_ssl_open and tb_ssl_wait
 * @param priv      the priv data
 */
tb_void_t           tb_ssl_set_bio_func(tb_ssl_ref_t ssl, tb_ssl_func_read_t read, tb_ssl_func_writ_t writ, tb_ssl_func_wait_t wait, tb_cpointer_t priv);

/*! set ssl timeout for opening
 *
 * @param ssl       the ssl handle
 * @param timeout   the timeout
 */
tb_void_t           tb_ssl_set_timeout(tb_ssl_ref_t ssl, tb_long_t timeout);

/*! open ssl using blocking mode
 *
 * @note need wait func
 *
 * @param ssl       the ssl handle
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
        ok = tb_ssl_wait(handle, TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND, timeout);
        tb_check_break(ok > 0);
    }

 * @endcode
 *
 * @param ssl       the ssl handle
 *
 * @return          ok: 1, continue: 0, failed: -1
 */
tb_long_t           tb_ssl_open_try(tb_ssl_ref_t ssl);

/*! clos ssl 
 *
 * @param ssl       the ssl handle
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
        ok = tb_ssl_wait(handle, TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND, timeout);
        tb_check_break(ok > 0);
    }

 * @endcode
 *
 * @param ssl       the ssl handle
 *
 * @return          ok: 1, continue: 0, failed: -1
 */
tb_long_t           tb_ssl_clos_try(tb_ssl_ref_t ssl);

/*! read ssl data
 *
 * @param ssl       the ssl handle
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size, no data: 0 and see state for waiting, failed: -1
 */
tb_long_t           tb_ssl_read(tb_ssl_ref_t ssl, tb_byte_t* data, tb_size_t size);

/*! writ ssl data
 *
 * @param ssl       the ssl handle
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size, no data: 0 and see state for waiting, failed: -1
 */
tb_long_t           tb_ssl_writ(tb_ssl_ref_t ssl, tb_byte_t const* data, tb_size_t size);

/*! wait ssl data
 *
 * @param ssl       the ssl handle
 * @param code      the aioe code
 * @param timeout   the timeout
 *
 * @return          the real code, no event: 0, failed or closed: -1
 */
tb_long_t           tb_ssl_wait(tb_ssl_ref_t ssl, tb_size_t code, tb_long_t timeout);

/*! the ssl state see the stream ssl state
 *
 * @param ssl       the ssl handle
 *
 * @return          the ssl state
 */
tb_size_t           tb_ssl_state(tb_ssl_ref_t ssl);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
