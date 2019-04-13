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
 * @file        dns.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../dynamic.h"
#include "../impl/dns.h"
#include "interface/interface.h"
#include "../../network/network.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_bool_t tb_dns_init_env()
{
    // done
    FIXED_INFO*             info = tb_null;
    ULONG                   size = 0;
    tb_size_t               count = 0;
    do 
    {
        // init func
        tb_iphlpapi_GetNetworkParams_t pGetNetworkParams = tb_iphlpapi()->GetNetworkParams;
        tb_assert_and_check_break(pGetNetworkParams);

        // init info
        info = tb_malloc0_type(FIXED_INFO);
        tb_assert_and_check_break(info);

        // get the info size
        size = sizeof(FIXED_INFO);
        if (pGetNetworkParams(info, &size) == ERROR_BUFFER_OVERFLOW) 
        {
            // grow info
            info = (FIXED_INFO *)tb_ralloc(info, size);
            tb_assert_and_check_break(info);
        }
        
        // get the info
        if (pGetNetworkParams(info, &size) != NO_ERROR) break;

        // trace
//      tb_trace_d("host: %s",  info->HostName);
//      tb_trace_d("domain: %s", info->DomainName);
        tb_trace_d("server: %s", info->DnsServerList.IpAddress.String);

        // add the first dns address
        if (info->DnsServerList.IpAddress.String)
        {
            tb_dns_server_add(info->DnsServerList.IpAddress.String);
            count++;
        }

        // walk dns address
        IP_ADDR_STRING* addr = info->DnsServerList.Next;
        for (; addr; addr = addr->Next) 
        {
            // trace
            tb_trace_d("server: %s", addr->IpAddress.String);
            
            // add the dns address
            if (addr->IpAddress.String)
            {
                tb_dns_server_add(addr->IpAddress.String);
                count++;
            }
        }

    } while (0);

    // exit info
    if (info) tb_free(info);
    info = tb_null;

    // ok
    return tb_true;
}
tb_void_t tb_dns_exit_env()
{
}

