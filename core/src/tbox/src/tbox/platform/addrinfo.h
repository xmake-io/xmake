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
