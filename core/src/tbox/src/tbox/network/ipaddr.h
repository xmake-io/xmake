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
 * @file        ipaddr.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_IPADDR_H
#define TB_NETWORK_IPADDR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "ipv4.h"
#include "ipv6.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the address string data maxn
#define TB_IPADDR_CSTR_MAXN           (TB_IPV6_CSTR_MAXN + 20)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the ip address family enum
typedef enum __tb_ipaddr_family_e
{
    TB_IPADDR_FAMILY_NONE     = 0
,   TB_IPADDR_FAMILY_IPV4     = 1
,   TB_IPADDR_FAMILY_IPV6     = 2

}tb_ipaddr_family_e;

/// the ip address type
typedef struct __tb_ipaddr_t
{
    /// the family
    tb_uint8_t              family      : 7;

    /// have ip?
    tb_uint8_t              have_ip     : 1;

    /// the port
    tb_uint16_t             port;

    /// the address
    union
    {
        /// the ipv4
        tb_ipv4_t           ipv4;

        /// the ipv6
        tb_ipv6_t           ipv6;

    }u;

}tb_ipaddr_t, *tb_ipaddr_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! clear the address
 *
 * @param ipaddr    the address
 */
tb_void_t           tb_ipaddr_clear(tb_ipaddr_ref_t ipaddr);

/*! copy address, faster than *ipaddr = *other
 *
 * @param ipaddr    the address
 * @param copied    the copied address
 */
tb_void_t           tb_ipaddr_copy(tb_ipaddr_ref_t ipaddr, tb_ipaddr_ref_t copied);

/*! is empty?
 *
 * @param ipaddr    the address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipaddr_is_empty(tb_ipaddr_ref_t ipaddr);

/*! is equal?
 *
 * @param ipaddr    the address
 * @param other     the other address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipaddr_is_equal(tb_ipaddr_ref_t ipaddr, tb_ipaddr_ref_t other);

/*! get the address string
 *
 * @param ipaddr    the address
 * @param data      the address string data
 * @param maxn      the address string data maxn
 *
 * @return          the address string
 */
tb_char_t const*    tb_ipaddr_cstr(tb_ipaddr_ref_t ipaddr, tb_char_t* data, tb_size_t maxn);

/*! set the ip address from string
 *
 * @param ipaddr    the address, only analyze format if be null
 * @param cstr      the address string, init any address if be null
 * @param port      the port, optional
 * @param family    the address family, will analyze family automaticly if be none, optional
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipaddr_set(tb_ipaddr_ref_t ipaddr, tb_char_t const* cstr, tb_uint16_t port, tb_uint8_t family);

/*! clear ip
 *
 * @param ipaddr    the address
 */
tb_void_t           tb_ipaddr_ip_clear(tb_ipaddr_ref_t ipaddr);

/*! the ip is empty?
 *
 * @param ipaddr    the address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipaddr_ip_is_empty(tb_ipaddr_ref_t ipaddr);

/*! the ip is any?
 *
 * @param ipaddr    the address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipaddr_ip_is_any(tb_ipaddr_ref_t ipaddr);

/*! the ip is loopback?
 *
 * @param ipaddr    the address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipaddr_ip_is_loopback(tb_ipaddr_ref_t ipaddr);

/*! the ip is equal?
 *
 * @param ipaddr    the address
 * @param other     the other address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipaddr_ip_is_equal(tb_ipaddr_ref_t ipaddr, tb_ipaddr_ref_t other);

/*! get the ip address string
 *
 * @param ipaddr    the address
 * @param data      the address string data
 * @param maxn      the address string data maxn
 *
 * @return          the address string
 */
tb_char_t const*    tb_ipaddr_ip_cstr(tb_ipaddr_ref_t ipaddr, tb_char_t* data, tb_size_t maxn);

/*! set the ip address from string
 *
 * @param ipaddr    the address, only analyze format if be null
 * @param cstr      the address string
 * @param family    the address family, will analyze family automaticly if be none
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipaddr_ip_cstr_set(tb_ipaddr_ref_t ipaddr, tb_char_t const* cstr, tb_uint8_t family);

/*! only set ip address
 *
 * @param ipaddr    the address
 * @param other     the other address with ip data, clear it if be null
 */
tb_void_t           tb_ipaddr_ip_set(tb_ipaddr_ref_t ipaddr, tb_ipaddr_ref_t other);

/*! get the ipv4 address
 *
 * @param ipaddr    the address
 *
 * @return          the ipv4
 */
tb_ipv4_ref_t       tb_ipaddr_ipv4(tb_ipaddr_ref_t ipaddr);

/*! set the address from ipv4
 *
 * @param ipaddr    the address
 * @param ipv4      the ipv4, clear it if be null
 */
tb_void_t           tb_ipaddr_ipv4_set(tb_ipaddr_ref_t ipaddr, tb_ipv4_ref_t ipv4);

/*! get the ipv6 address
 *
 * @param ipaddr    the address
 *
 * @return          the ipv6
 */
tb_ipv6_ref_t       tb_ipaddr_ipv6(tb_ipaddr_ref_t ipaddr);

/*! set the address from ipv6
 *
 * @param ipaddr    the address
 * @param ipv6      the ipv6, clear it if be null
 */
tb_void_t           tb_ipaddr_ipv6_set(tb_ipaddr_ref_t ipaddr, tb_ipv6_ref_t ipv6);

/*! get the address family
 *
 * @param ipaddr    the address
 *
 * @return          the family
 */
tb_size_t           tb_ipaddr_family(tb_ipaddr_ref_t ipaddr);

/*! set the address family
 *
 * @param ipaddr    the address
 * @param family    the family
 */
tb_void_t           tb_ipaddr_family_set(tb_ipaddr_ref_t ipaddr, tb_size_t family);

/*! get the address port
 *
 * @param ipaddr    the address
 *
 * @return          the port
 */
tb_uint16_t         tb_ipaddr_port(tb_ipaddr_ref_t ipaddr);

/*! set the address family
 *
 * @param ipaddr    the address
 * @param port      the port
 */
tb_void_t           tb_ipaddr_port_set(tb_ipaddr_ref_t ipaddr, tb_uint16_t port);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
