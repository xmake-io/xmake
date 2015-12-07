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
 * @file        network.h
 * @defgroup    network
 *
 */
#ifndef TB_NETWORK_H
#define TB_NETWORK_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "ssl.h"
#include "url.h"
#include "ipv4.h"
#include "ipv6.h"
#include "ipaddr.h"
#include "hwaddr.h"
#include "http.h"
#include "cookies.h"
#include "dns/dns.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init network 
 *
 * @return      tb_true or tb_false
 */
tb_bool_t       tb_network_init(tb_noarg_t);

/// exit network 
tb_void_t       tb_network_exit(tb_noarg_t);

#endif
