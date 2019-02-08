/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
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
 * @file        ifaddrs.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <string.h>
#include <stdlib.h>
#include <stddef.h>
#include <errno.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netpacket/packet.h>
#include <net/if_arp.h>
#include <netinet/in.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <sys/types.h>
#include <linux/if.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <unistd.h>
#include "../posix/sockaddr.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_long_t tb_ifaddrs_netlink_socket_init()
{
    // done
    tb_long_t sock = -1;
    tb_bool_t ok = tb_false;
    do
    {
        // make socket
        sock = socket(PF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
        tb_check_break(sock >= 0);

        // bind socket
        struct sockaddr_nl addr;
        memset(&addr, 0, sizeof(addr));
        addr.nl_family = AF_NETLINK;
        if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) break;

        // ok
        ok = tb_true;

    } while (0);
    
    // failed?
    if (!ok)
    {
        // exit it
        if (sock >= 0) close(sock);
        sock = -1;
    }

    // ok?
    return sock;
}
static tb_long_t tb_ifaddrs_netlink_socket_send(tb_long_t sock, tb_long_t request)
{
    // check
    tb_assert_and_check_return_val(sock >= 0, -1);

    // init packet
    struct
    {
        struct nlmsghdr m_hdr;
        struct rtgenmsg m_msg;

    } packet;
    tb_memset(&packet, 0, sizeof(packet));
    packet.m_hdr.nlmsg_len      = NLMSG_LENGTH(sizeof(struct rtgenmsg));
    packet.m_hdr.nlmsg_type     = (tb_int_t)request;
    packet.m_hdr.nlmsg_flags    = NLM_F_ROOT | NLM_F_MATCH | NLM_F_REQUEST;
    packet.m_hdr.nlmsg_pid      = 0;
    packet.m_hdr.nlmsg_seq      = (tb_int_t)sock;
    packet.m_msg.rtgen_family   = AF_UNSPEC;
    
    // send packet
    struct sockaddr_nl addr;
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    return sendto(sock, &packet.m_hdr, packet.m_hdr.nlmsg_len, 0, (struct sockaddr *)&addr, sizeof(addr));
}
static tb_long_t tb_ifaddrs_netlink_socket_recv(tb_long_t sock, tb_pointer_t data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(sock >= 0 && data && size, -1);

    // done
    struct msghdr       packet;
    struct iovec        iov = { data, size };
    struct sockaddr_nl  addr;
    while (1)
    {
        // init packet
        packet.msg_name         = (tb_pointer_t)&addr;
        packet.msg_namelen      = sizeof(addr);
        packet.msg_iov          = &iov;
        packet.msg_iovlen       = 1;
        packet.msg_control      = tb_null;
        packet.msg_controllen   = 0;
        packet.msg_flags        = 0;

        // recv packet
        tb_long_t ok = recvmsg(sock, &packet, 0);
        
        // failed or continue 
        if (ok < 0)
        {
            if (errno == EINTR) continue;
            return -2;
        }
        
        // buffer was too small
        if (packet.msg_flags & MSG_TRUNC) return -1;

        // ok
        return ok;
    }
}
static tb_size_t tb_ifaddrs_netlink_ipaddr_save(tb_ipaddr_ref_t ipaddr, tb_size_t family, tb_size_t scope_id, tb_cpointer_t saddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr && saddr, 0);

    // clear address
    tb_ipaddr_clear(ipaddr);

    // done
    tb_size_t size = 0;
    switch (family)
    {
    case AF_INET:
        {
            // the ipv4 ipaddr
            struct in_addr* addr4 = (struct in_addr*)saddr;

            // save family
            tb_ipaddr_family_set(ipaddr, TB_IPADDR_FAMILY_IPV4);

            // make ipv4
            tb_ipv4_t ipv4;
            ipv4.u32 = (tb_uint32_t)addr4->s_addr;

            // save ipv4
            tb_ipaddr_ipv4_set(ipaddr, &ipv4);

            // save size
            size = sizeof(struct in_addr);
        }
        break;
    case AF_INET6:
        {
            // the ipv6 ipaddr
            struct in6_addr* addr6 = (struct in6_addr*)saddr;

            // check
            tb_assert_static(sizeof(ipaddr->u.ipv6.addr.u8) == sizeof(addr6->s6_addr));
            tb_assert_static(tb_arrayn(ipaddr->u.ipv6.addr.u8) == tb_arrayn(addr6->s6_addr));

            // save family
            tb_ipaddr_family_set(ipaddr, TB_IPADDR_FAMILY_IPV6);

            // make ipv6
            tb_ipv6_t ipv6;
            tb_memcpy(ipv6.addr.u8, addr6->s6_addr, sizeof(ipv6.addr.u8));

            // save scope id
            ipv6.scope_id = 0;
            if (IN6_IS_ADDR_LINKLOCAL(addr6) || IN6_IS_ADDR_MC_LINKLOCAL(addr6))
                ipv6.scope_id = (tb_uint32_t)scope_id;

            // save ipv6
            tb_ipaddr_ipv6_set(ipaddr, &ipv6);

            // save size
            size = sizeof(struct in6_addr);
        }
        break;
    default:
        tb_assert(0);
        break;
    }
    
    // ok?
    return size;
}
static tb_void_t tb_ifaddrs_interface_exit(tb_element_ref_t element, tb_pointer_t buff)
{
    // check
    tb_ifaddrs_interface_ref_t interface = (tb_ifaddrs_interface_ref_t)buff;
    if (interface)
    {
        // exit the interface name
        if (interface->name) tb_free(interface->name);
        interface->name = tb_null;
    }
}
static tb_void_t tb_ifaddrs_interface_done_ipaddr(tb_list_ref_t interfaces, tb_hash_map_ref_t names, struct nlmsghdr* response)
{
    // check
    tb_assert_and_check_return(interfaces && names && response);

    // the info
    struct ifaddrmsg* info = (struct ifaddrmsg *)NLMSG_DATA(response);

    // must be not link 
    tb_assert_and_check_return(info->ifa_family != AF_PACKET);

    // attempt to find the interface name
    tb_bool_t   owner = tb_false;
    tb_char_t*  name = (tb_char_t*)tb_hash_map_get(names, tb_u2p(info->ifa_index));
    if (!name)
    {
        // get the interface name
        struct rtattr*  rta = tb_null;
        tb_size_t       rta_size = NLMSG_PAYLOAD(response, sizeof(struct ifaddrmsg));
        for(rta = IFA_RTA(info); RTA_OK(rta, rta_size); rta = RTA_NEXT(rta, rta_size))
        {
            // done
            tb_pointer_t    rta_data = RTA_DATA(rta);
            tb_size_t       rta_data_size = RTA_PAYLOAD(rta);
            switch(rta->rta_type)
            {
                case IFA_LABEL:
                    {
                        // make name
                        name = (tb_char_t*)tb_ralloc(name, rta_data_size + 1);
                        tb_assert_and_check_break(name);

                        // copy name
                        tb_strlcpy(name, rta_data, rta_data_size + 1);

                        // save name
                        tb_hash_map_insert(names, tb_u2p(info->ifa_index), name);
                        owner = tb_true;
                    }
                    break;
                default:
                    break;
            }
        }
    }

    // check
    tb_check_return(name);

    // done
    struct rtattr*  rta = tb_null;
    tb_size_t       rta_size = NLMSG_PAYLOAD(response, sizeof(struct ifaddrmsg));
    for(rta = IFA_RTA(info); RTA_OK(rta, rta_size); rta = RTA_NEXT(rta, rta_size))
    {
        /* attempt to get the interface from the cached interfaces
         * and make a new interface if no the cached interface
         */
        tb_ifaddrs_interface_t      interface_new = {0};
        tb_ifaddrs_interface_ref_t  interface = tb_ifaddrs_interface_find((tb_iterator_ref_t)interfaces, name);
        if (!interface) interface = &interface_new;

        // check
        tb_assert(interface == &interface_new || interface->name);

        // done
        tb_pointer_t rta_data = RTA_DATA(rta);
        switch(rta->rta_type)
        {
            case IFA_LOCAL:
            case IFA_ADDRESS:
                {
                    // make ipaddr
                    tb_ipaddr_t ipaddr;
                    if (!tb_ifaddrs_netlink_ipaddr_save(&ipaddr, info->ifa_family, info->ifa_index, rta_data)) break;

                    // save flags
                    if ((info->ifa_flags & IFF_LOOPBACK) || tb_ipaddr_ip_is_loopback(&ipaddr)) 
                        interface->flags |= TB_IFADDRS_INTERFACE_FLAG_IS_LOOPBACK;

                    // save ipaddr
                    switch (tb_ipaddr_family(&ipaddr))
                    {
                    case TB_IPADDR_FAMILY_IPV4:
                        {
                            interface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR4;
                            interface->ipaddr4 = ipaddr.u.ipv4;
                        }
                        break;
                    case TB_IPADDR_FAMILY_IPV6:
                        {
                            interface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR6;
                            interface->ipaddr6 = ipaddr.u.ipv6;
                        }
                        break;
                    default:
                        break;
                    }

                    // trace
                    tb_trace_d("name: %s, ipaddr: %{ipaddr}", name, &ipaddr);

                    // new interface? save it
                    if (tb_ipaddr_family(&ipaddr) && interface == &interface_new)
                    {
                        // save interface name
                        interface->name = tb_strdup(name);
                        tb_assert(interface->name);

                        // save interface
                        tb_list_insert_tail(interfaces, interface);
                    }
                }
                break;
            case IFA_LABEL:
            case IFA_BROADCAST:
                break;
            default:
                break;
        }
    }

    // exit name
    if (name && owner) tb_free(name);
    name = tb_null;
}
static tb_void_t tb_ifaddrs_interface_done_hwaddr(tb_list_ref_t interfaces, tb_hash_map_ref_t names, struct nlmsghdr* response)
{
    // check
    tb_assert_and_check_return(interfaces && names && response);

    // the info
    struct ifaddrmsg* info = (struct ifaddrmsg *)NLMSG_DATA(response);

    // attempt to find the interface name
    tb_bool_t   owner = tb_false;
    tb_char_t*  name = (tb_char_t*)tb_hash_map_get(names, tb_u2p(info->ifa_index));
    if (!name)
    {
        // get the interface name
        struct rtattr*  rta = tb_null;
        tb_size_t       rta_size = NLMSG_PAYLOAD(response, sizeof(struct ifaddrmsg));
        for(rta = IFLA_RTA(info); RTA_OK(rta, rta_size); rta = RTA_NEXT(rta, rta_size))
        {
            // done
            tb_pointer_t    rta_data = RTA_DATA(rta);
            tb_size_t       rta_data_size = RTA_PAYLOAD(rta);
            switch(rta->rta_type)
            {
                case IFLA_IFNAME:
                    {
                        // make name
                        name = (tb_char_t*)tb_ralloc(name, rta_data_size + 1);
                        tb_assert_and_check_break(name);

                        // copy name
                        tb_strlcpy(name, rta_data, rta_data_size + 1);

                        // save name
                        tb_hash_map_insert(names, tb_u2p(info->ifa_index), name);
                        owner = tb_true;
                    }
                    break;
                default:
                    break;
            }
        }
    }

    // check
    tb_check_return(name);

    // done
    struct rtattr*  rta = tb_null;
    tb_size_t       rta_size = NLMSG_PAYLOAD(response, sizeof(struct ifaddrmsg));
    for(rta = IFLA_RTA(info); RTA_OK(rta, rta_size); rta = RTA_NEXT(rta, rta_size))
    {
        /* attempt to get the interface from the cached interfaces
         * and make a new interface if no the cached interface
         */
        tb_ifaddrs_interface_t      interface_new = {0};
        tb_ifaddrs_interface_ref_t  interface = tb_ifaddrs_interface_find((tb_iterator_ref_t)interfaces, name);
        if (!interface) interface = &interface_new;

        // check
        tb_assert(interface == &interface_new || interface->name);

        // done
        tb_pointer_t    rta_data = RTA_DATA(rta);
        tb_size_t       rta_data_size = RTA_PAYLOAD(rta);
        switch(rta->rta_type)
        {
            case IFLA_ADDRESS:
                {
                    // no hwaddr?
                    if (!(interface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_HWADDR))
                    {
                        // check
                        tb_check_break(rta_data_size == sizeof(interface->hwaddr.u8));

                        // save flags
                        interface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_HWADDR;
                        if (info->ifa_flags & IFF_LOOPBACK) interface->flags |= TB_IFADDRS_INTERFACE_FLAG_IS_LOOPBACK;

                        // save hwaddr
                        tb_memcpy(interface->hwaddr.u8, rta_data, sizeof(interface->hwaddr.u8));

                        // trace
                        tb_trace_d("name: %s, hwaddr: %{hwaddr}", name, &interface->hwaddr);

                        // new interface? save it
                        if (interface == &interface_new)
                        {
                            // save interface name
                            interface->name = tb_strdup(name);
                            tb_assert(interface->name);

                            // save interface
                            tb_list_insert_tail(interfaces, interface);
                        }
                    }
                }
                break;
            case IFLA_IFNAME:
            case IFLA_BROADCAST:
            case IFLA_STATS:
                break;
            default:
                break;
        }
    }

    // exit name
    if (name && owner) tb_free(name);
    name = tb_null;
}
static tb_long_t tb_ifaddrs_interface_done(tb_list_ref_t interfaces, tb_hash_map_ref_t names, tb_long_t sock, tb_long_t request)
{
    // check
    tb_assert_and_check_return_val(interfaces && names && sock >= 0, -1);

    // done
    tb_size_t       size    = 4096;
    tb_pointer_t    data    = tb_null;
    tb_long_t       ok      = -1;
    pid_t           pid     = getpid();
    while (ok < 0)
    {
        // make data
        data = tb_ralloc(data, size);
        tb_assert_and_check_break(data);
        
        // trace
        tb_trace_d("netlink: recv: ..");

        // recv response
        tb_long_t recv = tb_ifaddrs_netlink_socket_recv(sock, data, size);

        // trace
        tb_trace_d("netlink: recv: %ld", recv);

        // space not enough?
        if (recv == -1)
        {
            // grow space and continue it
            size <<= 1;
            continue ;
        }

        // check
        tb_assert_and_check_break(recv > 0);

        // done
        tb_bool_t failed = tb_false;
        struct nlmsghdr* response = tb_null;
        for (response = (struct nlmsghdr *)data; NLMSG_OK(response, (tb_uint_t)recv); response = (struct nlmsghdr *)NLMSG_NEXT(response, recv))
        {
            // trace
            tb_trace_d("type: %d, pid: %ld ?= %ld, sock: %ld ?= %ld", response->nlmsg_type, (tb_long_t)response->nlmsg_pid, (tb_long_t)pid, (tb_long_t)response->nlmsg_seq, (tb_long_t)sock);
 
            // failed?
            tb_check_break_state(response->nlmsg_type != NLMSG_ERROR, failed, tb_true);

            // invalid pid?
            tb_assert_and_check_break_state((tb_long_t)response->nlmsg_pid > 0, failed, tb_true);

            // isn't it?
            if ((pid_t)response->nlmsg_pid != pid || (tb_long_t)response->nlmsg_seq != sock)
                continue;
           
            // done?
            if (response->nlmsg_type == NLMSG_DONE)
            {
                // trace
                tb_trace_d("done");

                // ok
                ok = 1;
                break;
            }

            // get hwaddr?
            if (request == RTM_GETLINK && response->nlmsg_type == RTM_NEWLINK)
            {
                // done hwaddr
                tb_ifaddrs_interface_done_hwaddr(interfaces, names, response);
            }
            // get ipaddr?
            else if (request == RTM_GETADDR && response->nlmsg_type == RTM_NEWADDR)
            {
                // done ipaddr
                tb_ifaddrs_interface_done_ipaddr(interfaces, names, response);
            }
        }

        // failed?
        tb_check_break(!failed);

        // continue if empty?
        if (ok < 0) ok = 0;
        break;
    }

    // exit data
    if (data) tb_free(data);
    data = tb_null;

    // ok?
    return ok;
}
static tb_bool_t tb_ifaddrs_interface_load(tb_list_ref_t interfaces, tb_long_t sock, tb_long_t request)
{
    // trace
    tb_trace_d("netlink: load: ..");

    // send request
    if (tb_ifaddrs_netlink_socket_send(sock, request) < 0) return tb_false;

    // make names
    tb_hash_map_ref_t names = tb_hash_map_init(8, tb_element_size(), tb_element_str(tb_true));
    tb_assert_and_check_return_val(names, tb_false);

    // done
    tb_long_t ok = -1;
    while (!(ok = tb_ifaddrs_interface_done(interfaces, names, sock, request))) ;

    // trace
    tb_trace_d("netlink: load: %s", ok > 0? "ok" : "no");

    // exit names
    if (names) tb_hash_map_exit(names);
    names = tb_null;

    // ok?
    return ok > 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_ifaddrs_ref_t tb_ifaddrs_init()
{
    // init it
    return (tb_ifaddrs_ref_t)tb_list_init(8, tb_element_mem(sizeof(tb_ifaddrs_interface_t), tb_ifaddrs_interface_exit, tb_null));
}
tb_void_t tb_ifaddrs_exit(tb_ifaddrs_ref_t ifaddrs)
{
    // exit it
    if (ifaddrs) tb_list_exit((tb_list_ref_t)ifaddrs);
}
tb_iterator_ref_t tb_ifaddrs_itor(tb_ifaddrs_ref_t ifaddrs, tb_bool_t reload)
{
    // check
    tb_list_ref_t interfaces = (tb_list_ref_t)ifaddrs;
    tb_assert_and_check_return_val(interfaces, tb_null);

    // uses the cached interfaces?
    tb_check_return_val(reload, (tb_iterator_ref_t)interfaces); 

    // clear interfaces first
    tb_list_clear(interfaces);

    // done
    tb_long_t sock = -1;
    do
    {
        // make sock
        sock = tb_ifaddrs_netlink_socket_init();
        tb_assert_and_check_break(sock >= 0);

        // load ipaddr
        if (!tb_ifaddrs_interface_load(interfaces, sock, RTM_GETADDR)) break;

        // load hwaddr
        if (!tb_ifaddrs_interface_load(interfaces, sock, RTM_GETLINK)) break;

    } while (0);

    // exit sock
    if (sock >= 0) close(sock);
    sock = -1;

    // ok?
    return (tb_iterator_ref_t)interfaces;
}
