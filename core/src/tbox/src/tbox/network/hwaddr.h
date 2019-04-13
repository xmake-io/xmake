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
