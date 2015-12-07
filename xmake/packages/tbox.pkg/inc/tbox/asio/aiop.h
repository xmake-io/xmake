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
 * @file        aiop.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_AIOP_H
#define TB_ASIO_AIOP_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "aioo.h"
#include "aioe.h"
#include "../platform/prefix.h"
#include "../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the aiop
 *
 * @param maxn      the maximum number of concurrent objects
 *
 * @return          the aiop
 */
tb_aiop_ref_t       tb_aiop_init(tb_size_t maxn);

/*! exit the aiop
 *
 * @param aiop      the aiop
 */
tb_void_t           tb_aiop_exit(tb_aiop_ref_t aiop);

/*! cler the aiop
 *
 * @param aiop      the aiop
 */
tb_void_t           tb_aiop_cler(tb_aiop_ref_t aiop);

/*! kill the aiop
 *
 * @param aiop      the aiop
 */
tb_void_t           tb_aiop_kill(tb_aiop_ref_t aiop);

/*! spak the aiop, break the wait
 *
 * @param aiop      the aiop
 */
tb_void_t           tb_aiop_spak(tb_aiop_ref_t aiop);

/*! the aioe code is supported for the aiop?
 *
 * @param aiop      the aiop
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aiop_have(tb_aiop_ref_t aiop, tb_size_t code);

/*! addo the aioo
 *
 * @param aiop      the aiop
 * @param sock      the socket
 * @param code      the code
 * @param priv      the private data
 *
 * @return          the aioo
 */
tb_aioo_ref_t       tb_aiop_addo(tb_aiop_ref_t aiop, tb_socket_ref_t sock, tb_size_t code, tb_cpointer_t priv);

/*! delo the aioo
 *
 * @param aiop      the aiop
 * @param aioo      the aioo
 *
 */
tb_void_t           tb_aiop_delo(tb_aiop_ref_t aiop, tb_aioo_ref_t aioo);

/*! post the aioe 
 *
 * @param aiop      the aiop
 * @param aioe      the aioe
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aiop_post(tb_aiop_ref_t aiop, tb_aioe_ref_t aioe);

/*! set the aioe
 *
 * @param aiop      the aiop
 * @param aioo      the aioo
 * @param code      the code
 * @param priv      the private data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aiop_sete(tb_aiop_ref_t aiop, tb_aioo_ref_t aioo, tb_size_t code, tb_cpointer_t priv);

/*! wait the asio objects in the pool
 *
 * blocking wait the multiple event objects
 * return the event number if ok, otherwise return 0 for timeout
 *
 * @param aiop      the aiop
 * @param list      the aioe list
 * @param maxn      the aioe maxn
 * @param timeout   the timeout, infinity: -1
 *
 * @return          > 0: the aioe list size, 0: timeout, -1: failed
 */
tb_long_t           tb_aiop_wait(tb_aiop_ref_t aiop, tb_aioe_ref_t list, tb_size_t maxn, tb_long_t timeout);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
