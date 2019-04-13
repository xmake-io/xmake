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
 * @file        addrinfo.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include "sockaddr.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#if defined(TB_ADDRINFO_ADDR_IMPL) \
    && defined(TB_CONFIG_POSIX_HAVE_GETADDRINFO)
static __tb_inline__ tb_int_t tb_addrinfo_ai_family(tb_ipaddr_ref_t addr)
{
    // get the ai family for getaddrinfo 
    switch (tb_ipaddr_family(addr))
    {
    case TB_IPADDR_FAMILY_IPV4:
        return AF_INET;
    case TB_IPADDR_FAMILY_IPV6:
        return AF_INET6;
    default:
        return AF_UNSPEC;
    }
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_ADDRINFO_ADDR_IMPL
tb_bool_t tb_addrinfo_addr(tb_char_t const* name, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(name && addr, tb_false);

#ifndef TB_CONFIG_MICRO_ENABLE
    // attempt to get address using dns looker
    if (tb_ipaddr_family(addr) != TB_IPADDR_FAMILY_IPV6 && tb_dns_looker_done(name, addr))
        return tb_true;
#endif

#if defined(TB_CONFIG_POSIX_HAVE_GETADDRINFO)
    // done
    tb_bool_t           ok = tb_false;
    struct addrinfo*    answer = tb_null;
    do
    {
        // init hints
        struct addrinfo hints = {0};
        hints.ai_family = tb_addrinfo_ai_family(addr);
        hints.ai_socktype = SOCK_STREAM;

        // init service
        tb_char_t   service[32] = {0};
        tb_uint16_t port = tb_ipaddr_port(addr);
        if (port) tb_snprintf(service, sizeof(service), "%u", port);

        // get address info
        if (getaddrinfo(name, port? service : tb_null, &hints, &answer)) break;
        tb_assert_and_check_break(answer && answer->ai_addr);

        // save address
        ok = tb_sockaddr_save(addr, (struct sockaddr_storage const*)answer->ai_addr) != 0;

    } while (0);

    // exit answer
    if (answer) freeaddrinfo(answer);
    answer = tb_null;

    // ok?
    return ok;

#elif defined(TB_CONFIG_POSIX_HAVE_GETHOSTBYNAME)

    // not support ipv6
    tb_assert_and_check_return_val(tb_ipaddr_family(addr) != TB_IPADDR_FAMILY_IPV6, tb_false);

    // get first host address
    struct hostent* hostaddr = gethostbyname(name);
    tb_check_return_val(hostaddr && hostaddr->h_addr && hostaddr->h_addrtype == AF_INET, tb_false);

    // save family
    tb_ipaddr_family_set(addr, TB_IPADDR_FAMILY_IPV4);

    // make ipv4
    tb_ipv4_t ipv4;
    ipv4.u32 = (tb_uint32_t)((struct in_addr const*)hostaddr->h_addr)->s_addr;

    // save ipv4
    tb_ipaddr_ipv4_set(addr, &ipv4);

    // ok
    return tb_true;
#else
    tb_trace_noimpl();
    return tb_false;
#endif
}
#endif

#ifdef TB_ADDRINFO_NAME_IMPL
tb_char_t const* tb_addrinfo_name(tb_ipaddr_ref_t addr, tb_char_t* name, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(addr && name && maxn, tb_null);

#if defined(TB_CONFIG_POSIX_HAVE_GETNAMEINFO)
    // load socket address
    struct sockaddr_storage saddr;
    socklen_t saddrlen = (socklen_t)tb_sockaddr_load(&saddr, addr);
    tb_assert_and_check_return_val(saddrlen, tb_null);

    // get host name from address
    return !getnameinfo((struct sockaddr const*)&saddr, saddrlen, name, maxn, tb_null, 0, NI_NAMEREQD)? name : tb_null;
#elif defined(TB_CONFIG_POSIX_HAVE_GETHOSTBYNAME)

    // done
    struct hostent* hostaddr = tb_null;
    switch (tb_ipaddr_family(addr))
    {
    case TB_IPADDR_FAMILY_IPV4:
        {
            // init ip address
            struct in_addr ipaddr = {0};
            ipaddr.s_addr = tb_ipaddr_ip_is_any(addr)? INADDR_ANY : addr->u.ipv4.u32;

            // get host name from address
            hostaddr = gethostbyaddr((tb_char_t const*)&ipaddr, sizeof(ipaddr), AF_INET);
        }
        break;
    case TB_IPADDR_FAMILY_IPV6:
        {
            // init ip address
            struct in6_addr ipaddr;
            tb_memset(&ipaddr, 0, sizeof(ipaddr));

            // save ipv6
            if (tb_ipaddr_ip_is_any(addr)) ipaddr = in6addr_any;
            else tb_memcpy(ipaddr.s6_addr, addr->u.ipv6.addr.u8, sizeof(ipaddr.s6_addr));

            // get host name from address
            hostaddr = gethostbyaddr((tb_char_t const*)&ipaddr, sizeof(ipaddr), AF_INET6);
        }
        break;
    default:
        break;
    }
    tb_check_return_val(hostaddr && hostaddr->h_name, tb_null);

    // save name
    tb_strlcpy(name, hostaddr->h_name, maxn);

    // ok?
    return name;
#else
    tb_trace_noimpl();
    return tb_null;
#endif
}
#endif

