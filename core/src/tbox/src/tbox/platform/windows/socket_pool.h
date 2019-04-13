/*!The Treasure Box Library
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
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
