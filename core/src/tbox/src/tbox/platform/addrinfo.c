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
 * trace
 */
#define TB_TRACE_MODULE_NAME                "addrinfo"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "addrinfo.h"
#include "../network/network.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if defined(TB_CONFIG_POSIX_HAVE_GETADDRINFO) || \
    defined(TB_CONFIG_POSIX_HAVE_GETHOSTBYNAME)
#   define TB_ADDRINFO_ADDR_IMPL
#   include "posix/addrinfo.c"
#   undef TB_ADDRINFO_ADDR_IMPL
#elif defined(TB_CONFIG_OS_WINDOWS)
#   define TB_ADDRINFO_ADDR_IMPL
#   include "windows/addrinfo.c"
#   undef TB_ADDRINFO_ADDR_IMPL
#else
tb_bool_t tb_addrinfo_addr(tb_char_t const* name, tb_ipaddr_ref_t addr)
{
#ifndef TB_CONFIG_MICRO_ENABLE
    // attempt to get address using dns looker
    if (tb_ipaddr_family(addr) != TB_IPADDR_FAMILY_IPV6 && tb_dns_looker_done(name, addr))
        return tb_true;
#endif

    // not implemented
    tb_trace_noimpl();
    return tb_false;
}
#endif

#if defined(TB_CONFIG_POSIX_HAVE_GETNAMEINFO) || \
    defined(TB_CONFIG_POSIX_HAVE_GETHOSTBYADDR)
#   define TB_ADDRINFO_NAME_IMPL
#   include "posix/addrinfo.c"
#   undef TB_ADDRINFO_NAME_IMPL
#elif defined(TB_CONFIG_OS_WINDOWS)
#   define TB_ADDRINFO_NAME_IMPL
#   include "windows/addrinfo.c"
#   undef TB_ADDRINFO_NAME_IMPL
#else
tb_char_t const* tb_addrinfo_name(tb_ipaddr_ref_t addr, tb_char_t* name, tb_size_t maxn)
{
    tb_trace_noimpl();
    return tb_null;
}
#endif

