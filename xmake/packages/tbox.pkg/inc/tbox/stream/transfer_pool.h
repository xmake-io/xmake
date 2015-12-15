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
 * @file        transfer_pool.h
 * @ingroup     stream
 *
 */
#ifndef TB_STREAM_TRANSFER_POOL_H
#define TB_STREAM_TRANSFER_POOL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "transfer.h"
#include "../asio/asio.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the transfer pool ref type
typedef struct{}*       tb_transfer_pool_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the transfer pool instance
 *
 * @return              the transfer pool instance
 */
tb_transfer_pool_ref_t  tb_transfer_pool(tb_noarg_t);

/*! init transfer pool
 *
 * @param aicp          the aicp, using the default aicp if be null
 *
 * @return              the transfer pool 
 */
tb_transfer_pool_ref_t  tb_transfer_pool_init(tb_aicp_ref_t aicp);

/*! exit transfer pool
 *
 * @param pool          the transfer pool 
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_transfer_pool_exit(tb_transfer_pool_ref_t pool);

/*! kill transfer pool
 *
 * @param pool          the transfer pool 
 */
tb_void_t               tb_transfer_pool_kill(tb_transfer_pool_ref_t pool);

/*! kill all working tasks
 *
 * @param pool          the transfer pool handle
 */
tb_void_t               tb_transfer_pool_kill_all(tb_transfer_pool_ref_t pool);

/*! wait all working tasks
 *
 * @param pool          the transfer pool handle
 * @param timeout       the timeout
 *
 * @return              ok: 1, timeout: 0, error: -1
 */
tb_long_t               tb_transfer_pool_wait_all(tb_transfer_pool_ref_t pool, tb_long_t timeout);

/*! the transfer pool size
 *
 * @param pool          the transfer pool 
 */
tb_size_t               tb_transfer_pool_size(tb_transfer_pool_ref_t pool);

/*! the transfer pool maxn
 *
 * @param pool          the transfer pool 
 */
tb_size_t               tb_transfer_pool_maxn(tb_transfer_pool_ref_t pool);

/*! done transfer from iurl to ourl
 *
 * @param pool          the transfer pool 
 * @param iurl          the input url
 * @param ourl          the output url
 * @param offset        the offset
 * @param rate          the limited rate, not limit if be zero
 * @param done          the done func 
 * @param ctrl          the ctrl func 
 * @param priv          the func private data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_transfer_pool_done(tb_transfer_pool_ref_t pool, tb_char_t const* iurl, tb_char_t const* ourl, tb_hize_t offset, tb_size_t rate, tb_async_transfer_done_func_t done, tb_async_transfer_ctrl_func_t ctrl, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
