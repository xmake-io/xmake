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
#include "../platform/timer.h"
#include "../container/container.h"

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
tb_aicp_ref_t       tb_aicp(tb_noarg_t);

/*! init the aicp
 *
 * @param maxn      the aico maxn, using the default maxn if be zero
 *
 * @return          the aicp
 */
tb_aicp_ref_t       tb_aicp_init(tb_size_t maxn);

/*! exit the aicp
 *
 * @param aicp      the aicp
 *
 * @return          tb_true or tb_false
 */     
tb_bool_t           tb_aicp_exit(tb_aicp_ref_t aicp);

/*! the aico maxn
 *
 * @param aicp      the aicp
 *
 * @return          the aico maxn 
 */     
tb_size_t           tb_aicp_maxn(tb_aicp_ref_t aicp);

/*! post the aice 
 *
 * @param aicp      the aicp
 * @param aice      the aice 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_post_(tb_aicp_ref_t aicp, tb_aice_ref_t aice __tb_debug_decl__);

/*! post the aice 
 *
 * @param aicp      the aicp
 * @param delay     the delay time, ms
 * @param aice      the aice 
 *
 * @return          tb_true or tb_false
 */
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
tb_void_t           tb_aicp_loop_util(tb_aicp_ref_t aicp, tb_bool_t (*stop)(tb_cpointer_t priv), tb_cpointer_t priv);

/*! kill loop
 *
 * @param aicp      the aicp
 */
tb_void_t           tb_aicp_kill(tb_aicp_ref_t aicp);

/*! kill all and cannot continue to post it, but not kill loop
 *
 * @param aicp      the aicp
 */
tb_void_t           tb_aicp_kill_all(tb_aicp_ref_t aicp);

/*! wait all exiting
 *
 * @param aicp      the aicp
 * @param timeout   the timeout
 * 
 * @return          ok: > 0, timeout: 0, failed: -1
 */
tb_long_t           tb_aicp_wait_all(tb_aicp_ref_t aicp, tb_long_t timeout);

/*! the spak time
 *
 * @param aicp      the aicp
 *
 * @return          the time
 */
tb_hong_t           tb_aicp_time(tb_aicp_ref_t aicp);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
