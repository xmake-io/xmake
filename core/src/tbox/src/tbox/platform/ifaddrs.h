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
 * @file        ifaddrs.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_IFADDRS_H
#define TB_PLATFORM_IFADDRS_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../network/ipaddr.h"
#include "../network/hwaddr.h"
#include "../container/iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the ifaddrs interface flag enum
typedef enum __tb_ifaddrs_interface_flag_e
{
    TB_IFADDRS_INTERFACE_FLAG_NONE          = 0
,   TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR4  = 1
,   TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR6  = 2
,   TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR   = TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR4 | TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR6
,   TB_IFADDRS_INTERFACE_FLAG_HAVE_HWADDR   = 4
,   TB_IFADDRS_INTERFACE_FLAG_IS_LOOPBACK   = 8

}tb_ifaddrs_interface_flag_e;

/// the ifaddrs interface type
typedef struct __tb_ifaddrs_interface_t
{
    /// the interface name
	tb_char_t const*        name;

    /// the interface flags
    tb_uint32_t             flags;

    // the hardware address
    tb_hwaddr_t             hwaddr;

    // the ipv4 address
    tb_ipv4_t               ipaddr4;

    // the ipv6 address
    tb_ipv6_t               ipaddr6;

}tb_ifaddrs_interface_t, *tb_ifaddrs_interface_ref_t;

/// the ifaddrs type
typedef __tb_typeref__(ifaddrs);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the ifaddrs instance
 *
 * @return                  the ifaddrs
 */
tb_ifaddrs_ref_t            tb_ifaddrs(tb_noarg_t);

/*! init ifaddrs
 *
 * @return                  the ifaddrs
 */
tb_ifaddrs_ref_t            tb_ifaddrs_init(tb_noarg_t);

/*! exit ifaddrs
 *
 * @param ifaddrs           the ifaddrs
 */
tb_void_t                   tb_ifaddrs_exit(tb_ifaddrs_ref_t ifaddrs);

/*! the ifaddrs interface iterator
 *
 * @code
 * tb_for_all_if (tb_ifaddrs_interface_ref_t, interface, tb_ifaddrs_itor(ifaddrs, tb_false), interface)
 * {
 *     // ...
 * }
 * @endcode
 *
 * @param ifaddrs           the ifaddrs
 * @param reload            force to reload the ifaddrs list, will cache list if be false
 *
 * @return                  the interface iterator 
 */
tb_iterator_ref_t           tb_ifaddrs_itor(tb_ifaddrs_ref_t ifaddrs, tb_bool_t reload);

/*! get the interface from the given interface name
 *
 * @param ifaddrs           the ifaddrs
 * @param name              the interface name
 * @param reload            force to reload the ifaddrs list, will cache list if be false
 *
 * @return                  tb_true or tb_false
 */
tb_ifaddrs_interface_ref_t  tb_ifaddrs_interface(tb_ifaddrs_ref_t ifaddrs, tb_char_t const* name, tb_bool_t reload);

/*! the hardware address from the given interface name
 *
 * @param ifaddrs           the ifaddrs
 * @param name              the interface name, get the first ether address if be null
 * @param reload            force to reload the ifaddrs list, will cache list if be false
 * @param hwaddr            the hardware address
 *
 * @return                  tb_true or tb_false
 */
tb_bool_t                   tb_ifaddrs_hwaddr(tb_ifaddrs_ref_t ifaddrs, tb_char_t const* name, tb_bool_t reload, tb_hwaddr_ref_t hwaddr);

/*! the hardware address from the given interface name
 *
 * @param ifaddrs           the ifaddrs
 * @param name              the interface name, get the first ether address if be null
 * @param reload            force to reload the ifaddrs list, will cache list if be false
 * @param family            the address family 
 * @param ipaddr            the ip address
 *
 * @return                  tb_true or tb_false
 */
tb_bool_t                   tb_ifaddrs_ipaddr(tb_ifaddrs_ref_t ifaddrs, tb_char_t const* name, tb_bool_t reload, tb_size_t family, tb_ipaddr_ref_t ipaddr);

#ifdef __tb_debug__
/*! dump the ifaddrs
 *
 * @param ifaddrs           the ifaddrs
 */
tb_void_t                   tb_ifaddrs_dump(tb_ifaddrs_ref_t ifaddrs);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
