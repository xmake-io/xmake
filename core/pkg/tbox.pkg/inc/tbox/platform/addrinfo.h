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
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        addrinfo.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_ADDRINFO_H
#define TB_PLATFORM_ADDRINFO_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../network/ipaddr.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! get the first dns address from the host name 
 *
 * @code
 
    // get the default address (ipv4)
    tb_ipaddr_t addr = {0};
    if (tb_addrinfo_addr("www.tboox.org", &addr))
        tb_trace_i("%{ipaddr}", &addr);
 
    // get the ipv6 address by the hint info
    tb_ipaddr_t addr = {0};
    tb_ipaddr_family_set(&addr, TB_IPADDR_FAMILY_IPV6);
    if (tb_addrinfo_addr("www.tboox.org", &addr))
        tb_trace_i("%{ipaddr}", &addr);

 * @endcode
 *
 * @param name      the host name (cannot be null)
 * @param addr      the ip address (we can fill some hint info first)
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_addrinfo_addr(tb_char_t const* name, tb_ipaddr_ref_t addr);

/*! get the host name from the given address 
 *
 * @code
 
    // get the host name by address
    tb_ipaddr_t addr;
    tb_char_t   host[256];
    tb_ipaddr_ip_cstr_set(&addr, "127.0.0.1");
    tb_trace_i("%s", tb_addrinfo_name(&addr, host, sizeof(host)));

 * @endcode
 *
 * @param addr      the ip address (cannot be null)
 * @param name      the host name buffer
 * @param maxn      the host name buffer maxn
 *
 * @return          the host name or tb_null 
 */
tb_char_t const*    tb_addrinfo_name(tb_ipaddr_ref_t addr, tb_char_t* name, tb_size_t maxn);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
