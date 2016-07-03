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
 * @file        sockaddr.h
 */
#ifndef TB_PLATFORM_POSIX_SOCKADDR_H
#define TB_PLATFORM_POSIX_SOCKADDR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_WINDOWS
#   include "ws2tcpip.h"
#else
#   include <netinet/in.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* save the socket address to the ip address
 *
 * @param ipaddr                the ip address
 * @param saddr                 the socket address
 *
 * @return                      the socket address size
 */
static __tb_inline__ tb_size_t  tb_sockaddr_save(tb_ipaddr_ref_t ipaddr, struct sockaddr_storage const* saddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr && saddr, 0);

    // clear address
    tb_ipaddr_clear(ipaddr);

    // done
    tb_size_t size = 0;
    switch (saddr->ss_family)
    {
    case AF_INET:
        {
            // the ipv4 ipaddr
            struct sockaddr_in* addr4 = (struct sockaddr_in*)saddr;

            // save family
            tb_ipaddr_family_set(ipaddr, TB_IPADDR_FAMILY_IPV4);

            // make ipv4
            tb_ipv4_t ipv4;
            ipv4.u32 = (tb_uint32_t)addr4->sin_addr.s_addr;

            // save ipv4
            tb_ipaddr_ipv4_set(ipaddr, &ipv4);

            // save port
            tb_ipaddr_port_set(ipaddr, tb_bits_be_to_ne_u16(addr4->sin_port));

            // save size
            size = sizeof(struct sockaddr_in);
        }
        break;
    case AF_INET6:
        {
            // the ipv6 ipaddr
            struct sockaddr_in6* addr6 = (struct sockaddr_in6*)saddr;

            // check
            tb_assert_static(sizeof(ipaddr->u.ipv6.addr.u8) == sizeof(addr6->sin6_addr.s6_addr));
            tb_assert_static(tb_arrayn(ipaddr->u.ipv6.addr.u8) == tb_arrayn(addr6->sin6_addr.s6_addr));

            // save family
            tb_ipaddr_family_set(ipaddr, TB_IPADDR_FAMILY_IPV6);

            // save port
            tb_ipaddr_port_set(ipaddr, tb_bits_be_to_ne_u16(addr6->sin6_port));

            // make ipv6
            tb_ipv6_t ipv6;
            tb_memcpy(ipv6.addr.u8, addr6->sin6_addr.s6_addr, sizeof(ipv6.addr.u8));

            // save scope id
            ipv6.scope_id = 0;
            if (IN6_IS_ADDR_LINKLOCAL(&addr6->sin6_addr) || IN6_IS_ADDR_MC_LINKLOCAL(&addr6->sin6_addr))
                ipv6.scope_id = addr6->sin6_scope_id;

            // save ipv6
            tb_ipaddr_ipv6_set(ipaddr, &ipv6);

            // save size
            size = sizeof(struct sockaddr_in6);
        }
        break;
    default:
        tb_assert(0);
        break;
    }
    
    // ok?
    return size;
}

/* load the ip address to socket address
 *
 * @param saddr                 the socket address
 * @param ipaddr                the ip address
 *
 * @return                      the socket address size
 */
static __tb_inline__ tb_size_t  tb_sockaddr_load(struct sockaddr_storage* saddr, tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(saddr && ipaddr, 0);

    // clear address
    tb_memset(saddr, 0, sizeof(struct sockaddr_storage));

    // done
    tb_size_t size = 0;
    switch (tb_ipaddr_family(ipaddr))
    {
    case TB_IPADDR_FAMILY_IPV4:
        {
            // the ipv4 ipaddr
            struct sockaddr_in* addr4 = (struct sockaddr_in*)saddr;

            // save family
            addr4->sin_family = AF_INET;

            // save ipv4
            addr4->sin_addr.s_addr = tb_ipaddr_ip_is_any(ipaddr)? INADDR_ANY : ipaddr->u.ipv4.u32;

            // save port
            addr4->sin_port = tb_bits_ne_to_be_u16(tb_ipaddr_port(ipaddr));

            // save size
            size = sizeof(struct sockaddr_in);
        }
        break;
    case TB_IPADDR_FAMILY_IPV6:
        {
            // the ipv6 ipaddr
            struct sockaddr_in6* addr6 = (struct sockaddr_in6*)saddr;

            // check
            tb_assert_static(sizeof(ipaddr->u.ipv6.addr.u8) == sizeof(addr6->sin6_addr.s6_addr));
            tb_assert_static(tb_arrayn(ipaddr->u.ipv6.addr.u8) == tb_arrayn(addr6->sin6_addr.s6_addr));

            // save family
            addr6->sin6_family = AF_INET6;

            // save ipv6
            if (tb_ipaddr_ip_is_any(ipaddr)) addr6->sin6_addr = in6addr_any;
            else tb_memcpy(addr6->sin6_addr.s6_addr, ipaddr->u.ipv6.addr.u8, sizeof(addr6->sin6_addr.s6_addr));

            // save port
            addr6->sin6_port = tb_bits_ne_to_be_u16(tb_ipaddr_port(ipaddr));

            // save scope id
            if (tb_ipv6_is_linklocal(&ipaddr->u.ipv6) || tb_ipv6_is_mc_linklocal(&ipaddr->u.ipv6))
                addr6->sin6_scope_id = ipaddr->u.ipv6.scope_id;

            // save size
            size = sizeof(struct sockaddr_in6);
        }
        break;
    default:
        tb_assert(0);
        break;
    }
    
    // ok?
    return size;
}


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
