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
 * @file        cache.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_DNS_CACHE_H
#define TB_NETWORK_DNS_CACHE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the cache list
 *
 * not using ctime default
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_dns_cache_init(tb_noarg_t);

/// exit the cache list
tb_void_t           tb_dns_cache_exit(tb_noarg_t);

/*! get addr from cache 
 *
 * @param name      the host name 
 * @param addr      the host addr
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_dns_cache_get(tb_char_t const* name, tb_ipaddr_ref_t addr);

/*! set addr to cache 
 *
 * @param name      the host name 
 * @param addr      the host addr
 */
tb_void_t           tb_dns_cache_set(tb_char_t const* name, tb_ipaddr_ref_t addr);

#endif
