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
 * @file        ifaddrs.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../ifaddrs.h"
#include "../posix/sockaddr.h"
#include "interface/interface.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t tb_ifaddrs_interface_exit(tb_element_ref_t element, tb_pointer_t buff)
{
    // check
    tb_ifaddrs_interface_ref_t iface = (tb_ifaddrs_interface_ref_t)buff;
    if (iface)
    {
        // exit the interface name
        if (iface->name) tb_free(iface->name);
        iface->name = tb_null;
    }
}
static tb_void_t tb_ifaddrs_interface_load4(tb_list_ref_t interfaces)
{
    // check
    tb_assert_and_check_return(interfaces);

    // done
    PIP_ADAPTER_INFO adapter_info = tb_null;
    do
    {
        // make the adapter info 
        adapter_info = tb_malloc0_type(IP_ADAPTER_INFO);
        tb_assert_and_check_break(adapter_info);

        // get the real adapter info size
        ULONG size = sizeof(IP_ADAPTER_INFO);
        if (tb_iphlpapi()->GetAdaptersInfo(adapter_info, &size) == ERROR_BUFFER_OVERFLOW)
        {
            // grow the adapter info buffer
            adapter_info = (PIP_ADAPTER_INFO)tb_ralloc(adapter_info, size);
            tb_assert_and_check_break(adapter_info);

            // reclear it
            tb_memset(adapter_info, 0, size);
        }
    
        // get the adapter info 
        if (tb_iphlpapi()->GetAdaptersInfo(adapter_info, &size) != NO_ERROR) break;

        // done
        PIP_ADAPTER_INFO adapter = adapter_info;
        while (adapter)
        {
            // check
            tb_assert(adapter->AdapterName);

            /* attempt to get the interface from the cached interfaces
             * and make a new interface if no the cached interface
             */
            tb_ifaddrs_interface_t      iface_new = {0};
            tb_ifaddrs_interface_ref_t  iface = tb_ifaddrs_interface_find((tb_iterator_ref_t)interfaces, adapter->AdapterName);
            if (!iface) iface = &iface_new;

            // check
            tb_assert(iface == &iface_new || iface->name);

            // save flags
            if (adapter->Type == MIB_IF_TYPE_LOOPBACK) iface->flags |= TB_IFADDRS_INTERFACE_FLAG_IS_LOOPBACK;

            // save hwaddr
            if (adapter->AddressLength == sizeof(iface->hwaddr.u8))
            {
                iface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_HWADDR;
                tb_memcpy(iface->hwaddr.u8, adapter->Address, sizeof(iface->hwaddr.u8));
            }

            // save ipaddrs
            PIP_ADDR_STRING ipAddress = &adapter->IpAddressList;
            while (ipAddress && (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR) != TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR)
            {
                // done
                tb_ipaddr_t ipaddr;
                if (    ipAddress->IpAddress.String
                    &&  tb_ipaddr_ip_cstr_set(&ipaddr, ipAddress->IpAddress.String, TB_IPADDR_FAMILY_NONE))
                {
                    if (ipaddr.family == TB_IPADDR_FAMILY_IPV4)
                    {
                        iface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR4;
                        iface->ipaddr4 = ipaddr.u.ipv4;
                    }
                    else if (ipaddr.family == TB_IPADDR_FAMILY_IPV6)
                    {
                        iface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR6;
                        iface->ipaddr6 = ipaddr.u.ipv6;
                    }
                }

                // the next
                ipAddress = ipAddress->Next;
            }

            // new interface? save it
            if (    iface == &iface_new
                &&  iface->flags)
            {
                // save interface name
                iface->name = tb_strdup(adapter->AdapterName);
                tb_assert(iface->name);

                // save interface
                tb_list_insert_tail(interfaces, iface);
            }

            // the next adapter
            adapter = adapter->Next;
        }

    } while (0);

    // exit the adapter info
    if (adapter_info) tb_free(adapter_info);
    adapter_info = tb_null;
}
static tb_void_t tb_ifaddrs_interface_load6(tb_list_ref_t interfaces)
{
    // check
    tb_assert_and_check_return(interfaces);

    // done
    PIP_ADAPTER_ADDRESSES addresses = tb_null;
    do
    {
        // make the addresses
        addresses = (PIP_ADAPTER_ADDRESSES)tb_malloc0_type(IP_ADAPTER_ADDRESSES);
        tb_assert_and_check_break(addresses);

        // get the real adapter info size
        ULONG size = sizeof(IP_ADAPTER_ADDRESSES);
        if (tb_iphlpapi()->GetAdaptersAddresses(AF_INET6, GAA_FLAG_SKIP_DNS_SERVER, tb_null, addresses, &size) == ERROR_BUFFER_OVERFLOW)
        {
            // grow the adapter info buffer
            addresses = (PIP_ADAPTER_ADDRESSES)tb_ralloc(addresses, size);
            tb_assert_and_check_break(addresses);

            // reclear it
            tb_memset(addresses, 0, size);
        }
     
        // get the addresses
        if (tb_iphlpapi()->GetAdaptersAddresses(AF_INET6, GAA_FLAG_SKIP_DNS_SERVER, tb_null, addresses, &size) != NO_ERROR) break;

        // done
        PIP_ADAPTER_ADDRESSES address = addresses;
        while (address)
        {
            // check
            tb_assert(address->AdapterName);

            /* attempt to get the interface from the cached interfaces
             * and make a new interface if no the cached interface
             */
            tb_ifaddrs_interface_t      iface_new = {0};
            tb_ifaddrs_interface_ref_t  iface = tb_ifaddrs_interface_find((tb_iterator_ref_t)interfaces, address->AdapterName);
            if (!iface) iface = &iface_new;

            // check
            tb_assert(iface == &iface_new || iface->name);

            // save flags
            if (address->IfType == IF_TYPE_SOFTWARE_LOOPBACK) iface->flags |= TB_IFADDRS_INTERFACE_FLAG_IS_LOOPBACK;

            // save hwaddr
            if (address->PhysicalAddressLength == sizeof(iface->hwaddr.u8))
            {
                iface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_HWADDR;
                tb_memcpy(iface->hwaddr.u8, address->PhysicalAddress, sizeof(iface->hwaddr.u8));
            }

            // save ipaddrs
            PIP_ADAPTER_UNICAST_ADDRESS ipAddress = address->FirstUnicastAddress;
            while (ipAddress && (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR) != TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR)
            {
                // done
                tb_ipaddr_t ipaddr;
                struct sockaddr_storage* saddr = (struct sockaddr_storage*)ipAddress->Address.lpSockaddr;
                if (saddr && tb_sockaddr_save(&ipaddr, saddr))
                {
                    if (ipaddr.family == TB_IPADDR_FAMILY_IPV4)
                    {
                        iface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR4;
                        iface->ipaddr4 = ipaddr.u.ipv4;
                    }
                    else if (ipaddr.family == TB_IPADDR_FAMILY_IPV6)
                    {
                        iface->flags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR6;
                        iface->ipaddr6 = ipaddr.u.ipv6;
                    }
                }

                // the next
                ipAddress = ipAddress->Next;
            }

            // new interface? save it
            if (    iface == &iface_new
                &&  iface->flags)
            {
                // save interface name
                iface->name = tb_strdup(address->AdapterName);
                tb_assert(iface->name);

                // save interface
                tb_list_insert_tail(interfaces, iface);
            }

            // the next address
            address = address->Next;
        }

    } while (0);

    // exit the addresses
    if (addresses) tb_free(addresses);
    addresses = tb_null;
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

    // attempt to load interfaces for ipv6 first
    if (tb_iphlpapi()->GetAdaptersAddresses) tb_ifaddrs_interface_load6(interfaces);
    // load interfaces only for ipv4 
    if (tb_iphlpapi()->GetAdaptersInfo) tb_ifaddrs_interface_load4(interfaces);

    // ok?
    return (tb_iterator_ref_t)interfaces;
}

