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
#include "../transfer.h"
#include "async_stream.h"
#include "async_transfer.h"
#include "../../asio/deprecated/asio.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the transfer pool ref type
typedef __tb_typeref__(transfer_pool);

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
