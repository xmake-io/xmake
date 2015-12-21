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
 * @file        hwaddr.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_HWADDR_H
#define TB_NETWORK_HWADDR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the hwaddr string data maxn
#define TB_HWADDR_CSTR_MAXN           (18)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the hardware address type
 *
 * mac: xx:xx:xx:xx:xx:xx
 */
typedef struct __tb_hwaddr_t
{
    /// u8
    tb_byte_t       u8[6];

}tb_hwaddr_t, *tb_hwaddr_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! clear the hwaddr
 *
 * @param hwaddr    the hwaddr
 */
tb_void_t           tb_hwaddr_clear(tb_hwaddr_ref_t hwaddr);

/*! copy address, faster than *hwaddr = *other
 *
 * @param hwaddr    the address
 * @param copied    the copied address
 */
tb_void_t           tb_hwaddr_copy(tb_hwaddr_ref_t hwaddr, tb_hwaddr_ref_t copied);

/*! is equal?
 *
 * @param hwaddr    the hwaddr
 * @param other     the other hwaddr
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_hwaddr_is_equal(tb_hwaddr_ref_t hwaddr, tb_hwaddr_ref_t other);

/*! get the hwaddr string
 *
 * @param hwaddr    the hwaddr
 * @param data      the hwaddr data
 * @param maxn      the data maxn
 *
 * @return          the hwaddr address
 */
tb_char_t const*    tb_hwaddr_cstr(tb_hwaddr_ref_t hwaddr, tb_char_t* data, tb_size_t maxn);

/*! set the hwaddr from string
 *
 * @param hwaddr    the hwaddr
 * @param cstr      the hwaddr string 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_hwaddr_cstr_set(tb_hwaddr_ref_t hwaddr, tb_char_t const* cstr);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
