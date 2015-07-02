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
 * @file        dns.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_DNS_H
#define TB_ASIO_DNS_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aicp.h"
#include "../network/ipaddr.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the aicp dns ref type
typedef struct{}*   tb_aicp_dns_ref_t;

/// the aicp dns done func type
typedef tb_void_t   (*tb_aicp_dns_done_func_t)(tb_aicp_dns_ref_t dns, tb_char_t const* host, tb_ipaddr_ref_t addr, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the dns 
 *
 * @param aicp      the aicp
 *
 * @return          the dns 
 */
tb_aicp_dns_ref_t   tb_aicp_dns_init(tb_aicp_ref_t aicp);

/*! kill the dns
 *
 * @param dns       the dns 
 */
tb_void_t           tb_aicp_dns_kill(tb_aicp_dns_ref_t dns);

/*! exit the dns
 *
 * @param dns       the dns 
 */
tb_void_t           tb_aicp_dns_exit(tb_aicp_dns_ref_t dns);

/*! done the dns
 *
 * @param dns       the dns 
 * @param host      the host
 * @param timeout   the timeout, ms
 * @param func      the done func
 * @param priv      the func private data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_aicp_dns_done(tb_aicp_dns_ref_t dns, tb_char_t const* host, tb_long_t timeout, tb_aicp_dns_done_func_t func, tb_cpointer_t priv);

/*! the dns aicp
 *
 * @param handle    the dns handle
 *
 * @return          the aicp
 */
tb_aicp_ref_t       tb_aicp_dns_aicp(tb_aicp_dns_ref_t dns);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
