/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
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
typedef struct{}*           tb_ifaddrs_ref_t;

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
