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
 * @file        ipv6.c 
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "ipv6"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "ipv6.h"
#include "ipv4.h"
#include "ipaddr.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../string/string.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_void_t tb_ipv6_clear(tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert_and_check_return(ipv6);

    // clear it
    tb_memset(ipv6, 0, sizeof(tb_ipv6_t));
}
tb_bool_t tb_ipv6_is_any(tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert_and_check_return_val(ipv6, tb_true);

    // is any?
    return !(ipv6->addr.u32[0] || ipv6->addr.u32[1] || ipv6->addr.u32[2] || ipv6->addr.u32[3]);
}
tb_bool_t tb_ipv6_is_loopback(tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert_and_check_return_val(ipv6, tb_true);

    // is loopback?
    return !(ipv6->addr.u32[0] || ipv6->addr.u32[1] || ipv6->addr.u32[2]) && (ipv6->addr.u32[3] == 0x01000000);
}
tb_bool_t tb_ipv6_is_linklocal(tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert_and_check_return_val(ipv6, tb_true);

    // is linklocal?
    return (ipv6->addr.u8[0] == 0xfe) && ((ipv6->addr.u8[1] & 0xc0) == 0x80);
}
tb_bool_t tb_ipv6_is_mc_linklocal(tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert_and_check_return_val(ipv6, tb_true);

    // is mc linklocal?
    return tb_ipv6_is_multicast(ipv6) && ((ipv6->addr.u8[1] & 0x0f) == 0x02);
}
tb_bool_t tb_ipv6_is_sitelocal(tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert_and_check_return_val(ipv6, tb_true);

    // is sitelocal?
    return (ipv6->addr.u8[0] == 0xfe) && ((ipv6->addr.u8[1] & 0xc0) == 0xc0);
}
tb_bool_t tb_ipv6_is_multicast(tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert_and_check_return_val(ipv6, tb_true);

    // is multicast?
    return (ipv6->addr.u8[0] == 0xff);
}
tb_bool_t tb_ipv6_is_equal(tb_ipv6_ref_t ipv6, tb_ipv6_ref_t other)
{
    // check
    tb_assert_and_check_return_val(ipv6 && other, tb_false);

    // have scope id?
    tb_bool_t have_scope_id = tb_ipv6_is_linklocal(ipv6) || tb_ipv6_is_mc_linklocal(ipv6);

    // is equal?
    return (!have_scope_id || (ipv6->scope_id == other->scope_id))
        && (ipv6->addr.u32[0] == other->addr.u32[0])
        && (ipv6->addr.u32[1] == other->addr.u32[1])
        && (ipv6->addr.u32[2] == other->addr.u32[2])
        && (ipv6->addr.u32[3] == other->addr.u32[3]);
}
tb_char_t const* tb_ipv6_cstr(tb_ipv6_ref_t ipv6, tb_char_t* data, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(ipv6 && data && maxn >= TB_IPV6_CSTR_MAXN, tb_null);

    // make scope_id
    tb_char_t scope_id[20] = {0};
    tb_bool_t have_scope_id = tb_ipv6_is_linklocal(ipv6) || tb_ipv6_is_mc_linklocal(ipv6);
    if (have_scope_id) tb_snprintf(scope_id, sizeof(scope_id) - 1, "%%%u", ipv6->scope_id);

    // make ipv6
    tb_long_t size = tb_snprintf(   data
                                ,   maxn - 1
                                ,   "%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x%s"
                                ,   tb_bits_swap_u16(ipv6->addr.u16[0])
                                ,   tb_bits_swap_u16(ipv6->addr.u16[1])
                                ,   tb_bits_swap_u16(ipv6->addr.u16[2])
                                ,   tb_bits_swap_u16(ipv6->addr.u16[3])
                                ,   tb_bits_swap_u16(ipv6->addr.u16[4])
                                ,   tb_bits_swap_u16(ipv6->addr.u16[5])
                                ,   tb_bits_swap_u16(ipv6->addr.u16[6])
                                ,   tb_bits_swap_u16(ipv6->addr.u16[7])
                                ,   have_scope_id? scope_id : "");
    if (size >= 0) data[size] = '\0';

    // ok
    return data;
}
tb_bool_t tb_ipv6_cstr_set(tb_ipv6_ref_t ipv6, tb_char_t const* cstr)
{
    // check
    tb_assert_and_check_return_val(cstr, tb_false);

    // ipv4: ::ffff:xxx.xxx.xxx.xxx?
    if (!tb_strnicmp(cstr, "::ffff:", 7))
    {
        // attempt to make ipv6 from ipv4
        tb_ipv4_t ipv4;
        if (tb_ipv4_cstr_set(&ipv4, cstr + 7))
        {
            // make ipv6
            ipv6->addr.u32[0] = 0;
            ipv6->addr.u32[1] = 0;
            ipv6->addr.u32[2] = 0xffff0000;
            ipv6->addr.u32[3] = ipv4.u32;

            // ok
            return tb_true;
        }
    }
    // ipv4: ::xxx.xxx.xxx.xxx?
    else if (!tb_strnicmp(cstr, "::", 2))
    {
        // attempt to make ipv6 from ipv4
        tb_ipv4_t ipv4;
        if (tb_ipv4_cstr_set(&ipv4, cstr + 2))
        {
            // make ipv6
            ipv6->addr.u32[0] = 0;
            ipv6->addr.u32[1] = 0;
            ipv6->addr.u32[2] = 0;
            ipv6->addr.u32[3] = ipv4.u32;

            // ok
            return tb_true;
        }
    }

    // done
    tb_uint32_t         v = 0;
    tb_size_t           i = 0;
    tb_char_t           c = '\0';
    tb_char_t const*    p = cstr;
    tb_bool_t           ok = tb_true;
    tb_bool_t           stub = tb_false;
    tb_char_t           prev = '\0';
    tb_ipv6_t           temp = {0};
    do
    {
        // save previous character
        prev = c;

        // the character
        c = *p++;

        // digit?
        if (tb_isdigit16(c) && v <= 0xffff)
        {
            // update value
            if (tb_isdigit10(c))
                v = (v << 4) + (c - '0');
            else if (c > ('a' - 1) && c < ('f' + 1))
                v = (v << 4) + (c - 'a') + 10;
            else if (c > ('A' - 1) && c < ('F' + 1))
                v = (v << 4) + (c - 'A') + 10;
            else 
            {
                // abort
                tb_assert(0);

                // failed
                ok = tb_false;
                break;
            }
        }
        // "::"?
        else if (c == ':' && *p == ':' && p[1] != ':' && !stub)
        {
            // save value
            temp.addr.u16[i++] = tb_bits_swap_u16(v);

            // clear value
            v = 0;

            // clear previous value
            prev = '\0';

            // find the left count of ':'
            tb_long_t           n = 0;
            tb_char_t const*    q = p;
            while (*q)
            {
                if (*q == ':') n++;
                q++;
            }
            tb_check_break_state(n <= 6, ok, tb_false);

            // compute the stub count
            n = 8 - n - i;
            tb_check_break_state(n > 0, ok, tb_false);

            // save the stub value
            while (n-- > 0) temp.addr.u16[i++] = 0;

            // only one "::"
            stub = tb_true;

            // skip ':'
            p++;
        }
        // ':' or '\0' or '%'?
        else if (i < 8 && ((c == ':' && *p != ':') || !c) && v <= 0xffff && prev)
        {
            // save value
            temp.addr.u16[i++] = tb_bits_swap_u16(v);

            // clear value
            v = 0;

            // clear previous value
            prev = '\0';
        }
        // "%xxx"?
        else if (i == 7 && c == '%' && *p)
        {
            // save value
            temp.addr.u16[i++] = tb_bits_swap_u16(v);

            // is scope id?
            if (tb_isdigit(*p))
            {
                // save the scope id 
                temp.scope_id = tb_atoi(p);
 
                // trace
                tb_trace_d("scope_id: %u", temp.scope_id);
            }
#ifndef TB_CONFIG_MICRO_ENABLE
            // is interface name?
            else 
            {
                // trace
                tb_trace_d("name: %s", p);

                // get the scope id from the interface name
                tb_ipaddr_t ipaddr;
                if (tb_ifaddrs_ipaddr(tb_ifaddrs(), p, tb_false, TB_IPADDR_FAMILY_IPV6, &ipaddr))
                {
                    // trace
                    tb_trace_d("scope_id: %u", ipaddr.u.ipv6.scope_id);

                    // save the scope id
                    temp.scope_id = ipaddr.u.ipv6.scope_id;
                }
                // clear the scope id 
                else temp.scope_id = 0;
            }
#else
            // clear the scope id 
            else temp.scope_id = 0;
#endif

            // end    
            break;
        }
        // failed?
        else 
        {
            ok = tb_false;
            break;
        }

    } while (c);

    // failed
    if (i != 8) ok = tb_false;

    // save it if ok
    if (ok && ipv6) *ipv6 = temp;

    // trace
//    tb_assertf(ok, "invalid addr: %s", cstr);

    // ok?
    return ok;
}

