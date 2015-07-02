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
 * @file        socket_pool.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_WINDOWS_SOCKET_POOL_H
#define TB_PLATFORM_WINDOWS_SOCKET_POOL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../socket.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init socket pool 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_socket_pool_init(tb_noarg_t);

/*! exit socket pool 
 *
 */
tb_void_t           tb_socket_pool_exit(tb_noarg_t);

/*! put socket to the socket pool 
 *
 * @param sock      the tcp socket
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_socket_pool_put(tb_socket_ref_t sock);

/*! get socket from the socket pool 
 *
 * @return          the tcp socket
 */
tb_socket_ref_t     tb_socket_pool_get(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
