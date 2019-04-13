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
#include "interface/interface.h"
#include "../posix/sockaddr.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#ifdef TB_ADDRINFO_ADDR_IMPL
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
static tb_bool_t tb_addrinfo_addr_impl_1(tb_char_t const* name, tb_ipaddr_ref_t addr)
{
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
        if (tb_ws2_32()->getaddrinfo(name, port? service : tb_null, &hints, &answer)) break;
        tb_assert_and_check_break(answer && answer->ai_addr);

        // save address
        ok = tb_sockaddr_save(addr, (struct sockaddr_storage const*)answer->ai_addr) != 0;

    } while (0);

    // exit answer
    if (answer) tb_ws2_32()->freeaddrinfo(answer);
    answer = tb_null;

    // ok?
    return ok;
}
static tb_bool_t tb_addrinfo_addr_impl_2(tb_char_t const* name, tb_ipaddr_ref_t addr)
{
    // not support ipv6
    tb_assert_and_check_return_val(tb_ipaddr_family(addr) != TB_IPADDR_FAMILY_IPV6, tb_false);

    // get first host address
    struct hostent* hostaddr = tb_ws2_32()->gethostbyname(name);
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
}
#endif

#ifdef TB_ADDRINFO_NAME_IMPL
static tb_char_t const* tb_addrinfo_name_impl_1(tb_ipaddr_ref_t addr, tb_char_t* name, tb_size_t maxn)
{
    // load socket address
    struct sockaddr_storage saddr;
    socklen_t saddrlen = (socklen_t)tb_sockaddr_load(&saddr, addr);
    tb_assert_and_check_return_val(saddrlen, tb_null);

    // get host name from address
    return !tb_ws2_32()->getnameinfo((struct sockaddr const*)&saddr, saddrlen, name, (DWORD)maxn, tb_null, 0, NI_NAMEREQD)? name : tb_null;
}
static tb_char_t const* tb_addrinfo_name_impl_2(tb_ipaddr_ref_t addr, tb_char_t* name, tb_size_t maxn)
{
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
            hostaddr = tb_ws2_32()->gethostbyaddr((tb_char_t const*)&ipaddr, sizeof(ipaddr), AF_INET);
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
            hostaddr = tb_ws2_32()->gethostbyaddr((tb_char_t const*)&ipaddr, sizeof(ipaddr), AF_INET6);
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

    // get address info using getaddrinfo
    if (tb_ws2_32()->getaddrinfo) return tb_addrinfo_addr_impl_1(name, addr);
    // get address info using gethostbyname
    else if (tb_ws2_32()->gethostbyname) return tb_addrinfo_addr_impl_2(name, addr);

    // not implemented
    tb_trace_noimpl();
    return tb_false;
}
#endif

#ifdef TB_ADDRINFO_NAME_IMPL
tb_char_t const* tb_addrinfo_name(tb_ipaddr_ref_t addr, tb_char_t* name, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(addr && name && maxn, tb_null);

    // get name info using getnameinfo
    if (tb_ws2_32()->getnameinfo) return tb_addrinfo_name_impl_1(addr, name, maxn);
    // get name info using gethostbyaddr
    else if (tb_ws2_32()->gethostbyaddr) return tb_addrinfo_name_impl_2(addr, name, maxn);

    // not implemented
    tb_trace_noimpl();
    return tb_null;
}
#endif

