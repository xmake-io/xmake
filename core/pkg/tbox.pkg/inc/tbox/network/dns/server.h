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

#endif
