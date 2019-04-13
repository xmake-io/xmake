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
 * @file        network.c
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "network.h"
#include "../network.h"
#include "../../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#ifndef TB_CONFIG_MICRO_ENABLE
static tb_long_t tb_network_printf_format_ipv4(tb_cpointer_t object, tb_char_t* cstr, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(object && cstr && maxn, -1);

    // the ipv4
    tb_ipv4_ref_t ipv4 = (tb_ipv4_ref_t)object;

    // make it
    cstr = (tb_char_t*)tb_ipv4_cstr(ipv4, cstr, maxn);

    // ok?
    return cstr? tb_strlen(cstr) : -1;
}
static tb_long_t tb_network_printf_format_ipv6(tb_cpointer_t object, tb_char_t* cstr, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(object && cstr && maxn, -1);

    // the ipv6
    tb_ipv6_ref_t ipv6 = (tb_ipv6_ref_t)object;

    // make it
    cstr = (tb_char_t*)tb_ipv6_cstr(ipv6, cstr, maxn);

    // ok?
    return cstr? tb_strlen(cstr) : -1;
}
static tb_long_t tb_network_printf_format_ipaddr(tb_cpointer_t object, tb_char_t* cstr, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(object && cstr && maxn, -1);

    // the ipaddr
    tb_ipaddr_ref_t ipaddr = (tb_ipaddr_ref_t)object;

    // make it
    cstr = (tb_char_t*)tb_ipaddr_cstr(ipaddr, cstr, maxn);

    // ok?
    return cstr? tb_strlen(cstr) : -1;
}
static tb_long_t tb_network_printf_format_hwaddr(tb_cpointer_t object, tb_char_t* cstr, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(object && cstr && maxn, -1);

    // the hwaddr
    tb_hwaddr_ref_t hwaddr = (tb_hwaddr_ref_t)object;

    // make it
    cstr = (tb_char_t*)tb_hwaddr_cstr(hwaddr, cstr, maxn);

    // ok?
    return cstr? tb_strlen(cstr) : -1;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_network_init_env()
{
#ifndef TB_CONFIG_MICRO_ENABLE
    // init dns server
    if (!tb_dns_server_init()) return tb_false;

    // init dns cache
    if (!tb_dns_cache_init()) return tb_false;

    // register printf("%{ipv4}", &ipv4);
    tb_printf_object_register("ipv4", tb_network_printf_format_ipv4);

    // register printf("%{ipv6}", &ipv6);
    tb_printf_object_register("ipv6", tb_network_printf_format_ipv6);

    // register printf("%{ipaddr}", &ipaddr);
    tb_printf_object_register("ipaddr", tb_network_printf_format_ipaddr);

    // register printf("%{hwaddr}", &hwaddr);
    tb_printf_object_register("hwaddr", tb_network_printf_format_hwaddr);
#endif

    // ok
    return tb_true;
}
tb_void_t tb_network_exit_env()
{
#ifndef TB_CONFIG_MICRO_ENABLE
    // exit dns cache
    tb_dns_cache_exit();

    // exit dns server
    tb_dns_server_exit();
#endif
}
