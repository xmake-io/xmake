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
