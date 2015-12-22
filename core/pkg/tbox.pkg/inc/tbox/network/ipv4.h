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
 * @file        ipv4.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_IPV4_H
#define TB_NETWORK_IPV4_H

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

/// the ipv4 string data maxn
#define TB_IPV4_CSTR_MAXN           (16)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the ipv4 type
 *
 * xxx.xxx.xxx.xxx
 */
typedef union __tb_ipv4_t
{
    /// u32, little-endian 
    tb_uint32_t     u32;

    /// u16
    tb_uint16_t     u16[2];

    /// u8
    tb_uint8_t      u8[4];

}tb_ipv4_t, *tb_ipv4_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! clear the ipv4
 *
 * @param ipv4      the ipv4
 */
tb_void_t           tb_ipv4_clear(tb_ipv4_ref_t ipv4);

/*! is any address?
 *
 * @param ipv4      the ipv4
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipv4_is_any(tb_ipv4_ref_t ipv4);

/*! is loopback address?
 *
 * @param ipv4      the ipv4
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipv4_is_loopback(tb_ipv4_ref_t ipv4);

/*! is equal?
 *
 * @param ipv4      the ipv4
 * @param other     the other ipv4
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipv4_is_equal(tb_ipv4_ref_t ipv4, tb_ipv4_ref_t other);

/*! get the ipv4 string
 *
 * @param ipv4      the ipv4
 * @param data      the ipv4 data
 * @param maxn      the data maxn
 *
 * @return          the ipv4 address
 */
tb_char_t const*    tb_ipv4_cstr(tb_ipv4_ref_t ipv4, tb_char_t* data, tb_size_t maxn);

/*! set the ipv4 from string
 *
 * @param ipv4      the ipv4
 * @param cstr      the ipv4 string 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_ipv4_cstr_set(tb_ipv4_ref_t ipv4, tb_char_t const* cstr);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
