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
 * @file        ipv4.c 
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "ipv4"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "ipv4.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../string/string.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_void_t tb_ipv4_clear(tb_ipv4_ref_t ipv4)
{
    // check
    tb_assert_and_check_return(ipv4);

    // clear it
    ipv4->u32 = 0;
}
tb_bool_t tb_ipv4_is_any(tb_ipv4_ref_t ipv4)
{
    // check
    tb_assert_and_check_return_val(ipv4, tb_true);

    // is empty?
    return !ipv4->u32;
}
tb_bool_t tb_ipv4_is_loopback(tb_ipv4_ref_t ipv4)
{
    // check
    tb_assert_and_check_return_val(ipv4, tb_false);

    // is loopback?
    return (ipv4->u32 == 0x0100007f);
}
tb_bool_t tb_ipv4_is_equal(tb_ipv4_ref_t ipv4, tb_ipv4_ref_t other)
{
    // check
    tb_assert_and_check_return_val(ipv4 && other, tb_false);

    // is equal?
    return ipv4->u32 == other->u32;
}
tb_char_t const* tb_ipv4_cstr(tb_ipv4_ref_t ipv4, tb_char_t* data, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(ipv4 && data && maxn >= TB_IPV4_CSTR_MAXN, tb_null);

    // make it
    tb_long_t size = tb_snprintf(data, maxn - 1, "%u.%u.%u.%u", ipv4->u8[0], ipv4->u8[1], ipv4->u8[2], ipv4->u8[3]);
    if (size >= 0) data[size] = '\0';

    // ok
    return data;
}
tb_bool_t tb_ipv4_cstr_set(tb_ipv4_ref_t ipv4, tb_char_t const* cstr)
{
    // check
    tb_assert_and_check_return_val(cstr, tb_false);

    // done
    tb_uint32_t         r = 0;
    tb_uint32_t         v = 0;
    tb_char_t           c = '\0';
    tb_size_t           i = 0;
    tb_char_t const*    p = cstr;
    do
    {
        // the character
        c = *p++;

        // digit?
        if (tb_isdigit10(c) && v <= 0xff)
        {
            v *= 10;
            v += (tb_uint32_t)(c - '0') & 0xff;
        }
        // '.' or '\0'?
        else if ((c == '.' || !c) && v <= 0xff)
        {
            r |= ((tb_uint32_t)v) << ((i++) << 3);
            v = 0;
        }
        // failed?
        else 
        {
            // trace
            tb_trace_d("invalid ipv4 addr: %s", cstr);

            // clear it
            i = 0;
            break;
        }

    } while (c);

    // save it if ok
    if (ipv4) ipv4->u32 = r;

    // ok?
    return i == 4;
}
