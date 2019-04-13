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
 * @file        server.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_DNS_SERVER_H
#define TB_NETWORK_DNS_SERVER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the server list
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_dns_server_init(tb_noarg_t);

/// exit the server list
tb_void_t           tb_dns_server_exit(tb_noarg_t);

/// dump the server list
tb_void_t           tb_dns_server_dump(tb_noarg_t);

/// sort the server list by the response speed
tb_void_t           tb_dns_server_sort(tb_noarg_t);

/*! get the server 
 *
 * @param addr      the server address list, addr[0] is the fastest 
 *
 * @return          the server size
 */
tb_size_t           tb_dns_server_get(tb_ipaddr_t addr[2]);

/*! add the server 
 *
 * @param addr      the server address 
 */
tb_void_t           tb_dns_server_add(tb_char_t const* addr);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
