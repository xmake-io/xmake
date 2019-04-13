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
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../impl/dns.h"
#include "../../network/network.h"
#include <sys/system_properties.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_bool_t tb_dns_init_env()
{
    // done
    tb_size_t count = 0;
    for (count = 0; count < 6; count++)
    {
        // init the dns property name
        tb_char_t prop_name[PROP_NAME_MAX] = {0};
        tb_snprintf(prop_name, sizeof(prop_name) - 1, "net.dns%lu", count + 1);
        
        // get dns address name
        tb_char_t dns[64] = {0};
        if (!__system_property_get(prop_name, dns)) break;

        // trace
        tb_trace_d("addr: %s", dns);

        // add server
        tb_dns_server_add(dns);
    }

    // ok
    return tb_true;
}
tb_void_t tb_dns_exit_env()
{
}

