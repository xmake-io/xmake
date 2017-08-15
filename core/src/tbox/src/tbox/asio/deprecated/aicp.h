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
 * @file        aicp.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_AICP_H
#define TB_ASIO_AICP_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "aice.h"
#include "../../platform/timer.h"
#include "../../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// post
#define tb_aicp_post(aicp, aice)                tb_aicp_post_(aicp, aice __tb_debug_vals__)
#define tb_aicp_post_after(aicp, delay, aice)   tb_aicp_post_after_(aicp, delay, aice __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the aicp instance
 *
 * @return          the aicp
 */
__tb_deprecated__
tb_aicp_ref_t       tb_aicp(tb_noarg_t);

/*! init the aicp
 *
 * @param maxn      the aico maxn, using the default maxn if be zero
 *
 * @return          the aicp
 */
__tb_deprecated__
tb_aicp_ref_t       tb_aicp_init(tb_size_t maxn);

/*! exit the aicp
 *
 * @param aicp      the aicp
 *
 * @return          tb_true or tb_false
 */     
__tb_deprecated__
tb_bool_t           tb_aicp_exit(tb_aicp_ref_t aicp);

/*! the aico maxn
 *
 * @param aicp      the aicp
 *
 * @return          the aico maxn 
 */     
__tb_deprecated__
tb_size_t           tb_aicp_maxn(tb_aicp_ref_t aicp);

/*! post the aice 
 *
 * @param aicp      the aicp
 * @param aice      the aice 
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_post_(tb_aicp_ref_t aicp, tb_aice_ref_t aice __tb_debug_decl__);

/*! post the aice 
 *
 * @param aicp      the aicp
 * @param delay     the delay time, ms
 * @param aice      the aice 
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_post_after_(tb_aicp_ref_t aicp, tb_size_t delay, tb_aice_ref_t aice __tb_debug_decl__);

/*! loop aicp for the external thread
 *
 * @code
 * tb_pointer_t tb_aicp_worker_thread(tb_pointer_t)
 * {
 *      tb_aicp_loop(aicp);
 * }
 * @endcode
 *
 * @param aicp      the aicp
 */
__tb_deprecated__
tb_void_t           tb_aicp_loop(tb_aicp_ref_t aicp);

/*! loop aicp util ... for the external thread
 *
 * @code
 * tb_bool_t tb_aicp_stop_func(tb_pointer_t)
 * {
 *     if (...) return tb_true;
 *     return tb_false;
 * }
 * tb_pointer_t tb_aicp_worker_thread(tb_pointer_t)
 * {
 *      tb_aicp_loop_util(aicp, stop_func, tb_null);
 * }
 * @endcode
 *
 * @param aicp      the aicp
 */
__tb_deprecated__
tb_void_t           tb_aicp_loop_util(tb_aicp_ref_t aicp, tb_bool_t (*stop)(tb_cpointer_t priv), tb_cpointer_t priv);

/*! kill loop
 *
 * @param aicp      the aicp
 */
__tb_deprecated__
tb_void_t           tb_aicp_kill(tb_aicp_ref_t aicp);

/*! kill all and cannot continue to post it, but not kill loop
 *
 * @param aicp      the aicp
 */
__tb_deprecated__
tb_void_t           tb_aicp_kill_all(tb_aicp_ref_t aicp);

/*! wait all exiting
 *
 * @param aicp      the aicp
 * @param timeout   the timeout
 * 
 * @return          ok: > 0, timeout: 0, failed: -1
 */
__tb_deprecated__
tb_long_t           tb_aicp_wait_all(tb_aicp_ref_t aicp, tb_long_t timeout);

/*! the spak time
 *
 * @param aicp      the aicp
 *
 * @return          the time
 */
__tb_deprecated__
tb_hong_t           tb_aicp_time(tb_aicp_ref_t aicp);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
