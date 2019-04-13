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
#include "../file.h"
#include "../../libc/libc.h"
#include "../../stream/stream.h"
#include "../../network/network.h"
#include "../impl/dns.h"
#include <resolv.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the res_ninit func type
typedef tb_int_t (*tb_dns_res_ninit_func_t)(res_state);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_bool_t tb_dns_init_env()
{
    // done
    tb_size_t           count = 0;
    tb_dynamic_ref_t    library = tb_dynamic_init("libresolv.dylib");
    if (library) 
    {
        // the res_ninit func
        tb_dns_res_ninit_func_t pres_ninit = (tb_dns_res_ninit_func_t)tb_dynamic_func(library, "res_9_ninit");
        if (pres_ninit)
        {
            // init state
            struct __res_state state;
            if (!pres_ninit(&state))
            {
                // walk it
                tb_size_t i = 0;
                for (i = 0; i < state.nscount; i++, count++)
                {
                    // the address
                    tb_char_t const* addr = inet_ntoa(state.nsaddr_list[i].sin_addr);
                    tb_assert_and_check_continue(addr);

                    // trace
                    tb_trace_d("addr: %s", addr);

                    // add address
                    tb_dns_server_add(addr);
                }
            }
        }
    }

    // ok
    return tb_true;
}
tb_void_t tb_dns_exit_env()
{
}

