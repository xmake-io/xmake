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
 * @file        looker.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_DNS_LOOKER_H
#define TB_NETWORK_DNS_LOOKER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the dns looker type
typedef struct{}*   tb_dns_looker_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init for looking ipv4 from the host name, non-block
 *
 * @param name      the host name
 *
 * @return          the looker handle
 */
tb_dns_looker_ref_t tb_dns_looker_init(tb_char_t const* name);

/*! spak the looker
 *
 * @param looker    the looker 
 * @param addr      the address
 *
 * @return          1: ok, 0: continue: -1: failed
 */
tb_long_t           tb_dns_looker_spak(tb_dns_looker_ref_t looker, tb_ipaddr_ref_t addr);

/*! wait the looker
 *
 * @param looker    the looker 
 * @param timeout   the timeout
 *
 * @return          1: ok, 0: continue: -1: failed
 */
tb_long_t           tb_dns_looker_wait(tb_dns_looker_ref_t looker, tb_long_t timeout);

/*! exit the looker
 *
 * @param looker    the looker 
 */
tb_void_t           tb_dns_looker_exit(tb_dns_looker_ref_t looker);

/*! look address from the host name, block
 *
 * try to look it from cache first
 *
 * @param name      the host name
 * @param addr      the address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_dns_looker_done(tb_char_t const* name, tb_ipaddr_ref_t addr);

#endif
