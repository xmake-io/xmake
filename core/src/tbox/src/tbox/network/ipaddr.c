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
 * @file        ipaddr.c
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "ipaddr.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static __tb_inline__ tb_bool_t tb_ipaddr_ipv6_to_ipv4(tb_ipv6_ref_t ipv6, tb_ipv4_ref_t ipv4)
{
    // check
    tb_assert(ipv6 && ipv4);

    // is ipv4?
    if (!ipv6->addr.u32[0] && !ipv6->addr.u32[1] && ipv6->addr.u32[2] == 0xffff0000)
    {
        // make ipv4
        ipv4->u32 = ipv6->addr.u32[3];

        // ok
        return tb_true;
    }

    // failed
    return tb_false;
}
static __tb_inline__ tb_bool_t tb_ipaddr_ipv4_to_ipv6(tb_ipv4_ref_t ipv4, tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert(ipv6 && ipv4);

    // make ipv6
    ipv6->addr.u32[0]   = 0;
    ipv6->addr.u32[1]   = 0;
    ipv6->addr.u32[2]   = 0xffff0000;
    ipv6->addr.u32[3]   = ipv4->u32;
    ipv6->scope_id      = 0;

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_ipaddr_clear(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return(ipaddr);

    // clear it
    ipaddr->family  = TB_IPADDR_FAMILY_IPV4;
    ipaddr->have_ip = 0;
    ipaddr->port    = 0;
}
tb_void_t tb_ipaddr_copy(tb_ipaddr_ref_t ipaddr, tb_ipaddr_ref_t copied)
{
    // check
    tb_assert_and_check_return(ipaddr && copied);

    // no ip? only copy port and family
    if (!copied->have_ip)
    {
        ipaddr->port      = copied->port;
        ipaddr->family    = copied->family;
    }
    // attempt to copy ipv4 fastly
    else if (copied->family == TB_IPADDR_FAMILY_IPV4)
    {
        ipaddr->port      = copied->port;
        ipaddr->have_ip   = 1;
        ipaddr->family    = TB_IPADDR_FAMILY_IPV4;
        ipaddr->u.ipv4    = copied->u.ipv4;
    }
    // copy it
    else *ipaddr = *copied;
}
tb_bool_t tb_ipaddr_is_empty(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr, tb_true);

    // no ip?
    return tb_ipaddr_ip_is_empty(ipaddr);
}
tb_bool_t tb_ipaddr_is_equal(tb_ipaddr_ref_t ipaddr, tb_ipaddr_ref_t other)
{
    // check
    tb_assert_and_check_return_val(ipaddr && other, tb_false);

    // port is equal?
    if (ipaddr->port != other->port) return tb_false;

    // ip is equal?
    return tb_ipaddr_ip_is_equal(ipaddr, other);
}
tb_char_t const* tb_ipaddr_cstr(tb_ipaddr_ref_t ipaddr, tb_char_t* data, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(ipaddr && data && maxn >= TB_IPADDR_CSTR_MAXN, tb_null);

    // is empty?
    if (tb_ipaddr_is_empty(ipaddr))
    {
        // make it
        tb_long_t size = tb_snprintf(data, maxn - 1, "0.0.0.0:0");
        if (size >= 0) data[size] = '\0';
    }
    // ip is empty?
    else if (tb_ipaddr_ip_is_empty(ipaddr))
    {
        // make it
        tb_long_t size = tb_snprintf(data, maxn - 1, "0.0.0.0:%u", ipaddr->port);
        if (size >= 0) data[size] = '\0';
    }
    else
    {
        // make it
        tb_char_t buff[TB_IPADDR_CSTR_MAXN];
        tb_bool_t ipv6 = ipaddr->family == TB_IPADDR_FAMILY_IPV6;
        tb_long_t size = tb_snprintf(data, maxn - 1, "%s%s%s:%u", ipv6? "[" : "", tb_ipaddr_ip_cstr(ipaddr, buff, sizeof(buff)), ipv6? "]" : "", ipaddr->port);
        if (size >= 0) data[size] = '\0';
    }

    // ok
    return data;
}
tb_bool_t tb_ipaddr_set(tb_ipaddr_ref_t ipaddr, tb_char_t const* cstr, tb_uint16_t port, tb_uint8_t family)
{
    // check
    tb_assert_and_check_return_val(ipaddr, tb_false);

    // save port
    tb_ipaddr_port_set(ipaddr, port);

    // save ip address and family
    return tb_ipaddr_ip_cstr_set(ipaddr, cstr, family);
}
tb_void_t tb_ipaddr_ip_clear(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return(ipaddr);

    // clear ip
    ipaddr->have_ip = 0;
}
tb_bool_t tb_ipaddr_ip_is_empty(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr, tb_true);

    // is empty?
    return !ipaddr->have_ip;
}
tb_bool_t tb_ipaddr_ip_is_any(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr, tb_true);

    // is empty? ok
    tb_check_return_val(ipaddr->have_ip, tb_true); 

    // done
    tb_bool_t is_any = tb_true;
    switch (ipaddr->family)
    {
    case TB_IPADDR_FAMILY_IPV4:
        is_any = tb_ipv4_is_any(&ipaddr->u.ipv4);
        break;
    case TB_IPADDR_FAMILY_IPV6:
        is_any = tb_ipv6_is_any(&ipaddr->u.ipv6);
        break;
    default:
        break;
    }

    // is any?
    return is_any;
}
tb_bool_t tb_ipaddr_ip_is_loopback(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr, tb_true);

    // done
    tb_bool_t is_loopback = tb_false;
    switch (ipaddr->family)
    {
    case TB_IPADDR_FAMILY_IPV4:
        is_loopback = tb_ipv4_is_loopback(&ipaddr->u.ipv4);
        break;
    case TB_IPADDR_FAMILY_IPV6:
        is_loopback = tb_ipv6_is_loopback(&ipaddr->u.ipv6);
        break;
    default:
        break;
    }

    // is loopback?
    return is_loopback;
}
tb_bool_t tb_ipaddr_ip_is_equal(tb_ipaddr_ref_t ipaddr, tb_ipaddr_ref_t other)
{
    // check
    tb_assert_and_check_return_val(ipaddr && other, tb_false);

    // both empty?
    if (!ipaddr->have_ip && !other->have_ip) return tb_true;
    // only one is empty?
    else if (ipaddr->have_ip != other->have_ip) return tb_false;
    // both ipv4?
    else if (ipaddr->family == TB_IPADDR_FAMILY_IPV4 && other->family == TB_IPADDR_FAMILY_IPV4)
    {
        // is equal?
        return tb_ipv4_is_equal(&ipaddr->u.ipv4, &other->u.ipv4);
    }
    // both ipv6?
    else if (ipaddr->family == TB_IPADDR_FAMILY_IPV6 && other->family == TB_IPADDR_FAMILY_IPV6)
    {
        // is equal?
        return tb_ipv6_is_equal(&ipaddr->u.ipv6, &other->u.ipv6);
    }
    // ipaddr is ipv6?
    else if (ipaddr->family == TB_IPADDR_FAMILY_IPV6)
    {
        // is equal?
        tb_ipv4_t ipv4;
        return tb_ipaddr_ipv6_to_ipv4(&ipaddr->u.ipv6, &ipv4) && tb_ipv4_is_equal(&ipv4, &other->u.ipv4);
    }
    // other is ipv6?
    else if (other->family == TB_IPADDR_FAMILY_IPV6)
    {
        // is equal?
        tb_ipv4_t ipv4;
        return tb_ipaddr_ipv6_to_ipv4(&other->u.ipv6, &ipv4) && tb_ipv4_is_equal(&ipaddr->u.ipv4, &ipv4);
    }

    // failed
    tb_assert(0);
    return tb_false;
}
tb_char_t const* tb_ipaddr_ip_cstr(tb_ipaddr_ref_t ipaddr, tb_char_t* data, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(ipaddr && data && maxn, tb_null);

    // done
    tb_char_t const* cstr = tb_null;
    switch (ipaddr->family)
    {
    case TB_IPADDR_FAMILY_IPV4:
        {
            // make ipv4 cstr
            if (ipaddr->have_ip) cstr = tb_ipv4_cstr(&ipaddr->u.ipv4, data, maxn);
            else 
            {
                // check
                tb_assert(maxn >= TB_IPV4_CSTR_MAXN);

                // make empty cstr
                tb_long_t size = tb_snprintf(data, maxn - 1, "0.0.0.0");
                if (size >= 0) data[size] = '\0';

                // ok
                cstr = data;
            }
        }
        break;
    case TB_IPADDR_FAMILY_IPV6:
        {
            // make ipv6 cstr
            if (ipaddr->have_ip) cstr = tb_ipv6_cstr(&ipaddr->u.ipv6, data, maxn);
            else
            {
                // check
                tb_assert(maxn >= TB_IPV6_CSTR_MAXN);

                // make empty cstr
                tb_long_t size = tb_snprintf(data, maxn - 1, "::");
                if (size >= 0) data[size] = '\0';

                // ok
                cstr = data;
            }
        }
        break;
    default:
        tb_assert(0);
        break;
    }

    // ok?
    return cstr;
}
tb_bool_t tb_ipaddr_ip_cstr_set(tb_ipaddr_ref_t ipaddr, tb_char_t const* cstr, tb_uint8_t family)
{
    // no ip? clear it fastly
    if (!cstr)
    {
        // check
        tb_assert(ipaddr);

        // clear it
        ipaddr->family    = family;
        ipaddr->have_ip   = 0;
        return tb_true;
    }

    // done
    tb_bool_t ok = tb_false;
    tb_ipaddr_t temp;
    switch (family)
    {
    case TB_IPADDR_FAMILY_IPV4:
        {
            // make ipv4
            ok = tb_ipv4_cstr_set(&temp.u.ipv4, cstr);

            // make family
            if (ok) temp.family = family;
        }
        break;
    case TB_IPADDR_FAMILY_IPV6:
        {
            // make ipv6
            ok = tb_ipv6_cstr_set(&temp.u.ipv6, cstr);

            // make family
            if (ok) temp.family = family;
        }
        break;
    default:
        {
            // attempt to make ipv4
            if ((ok = tb_ipv4_cstr_set(&temp.u.ipv4, cstr))) temp.family = TB_IPADDR_FAMILY_IPV4;
            // make ipv6
            else if ((ok = tb_ipv6_cstr_set(&temp.u.ipv6, cstr))) temp.family = TB_IPADDR_FAMILY_IPV6;
        }
        break;
    }

    // ok? save it
    if (ok && ipaddr) 
    {
        // save port
        temp.port = ipaddr->port;

        // have ip?
        temp.have_ip = 1;

        // save ipaddr
        tb_ipaddr_copy(ipaddr, &temp);
    }

    // ok?
    return ok;
}
tb_void_t tb_ipaddr_ip_set(tb_ipaddr_ref_t ipaddr, tb_ipaddr_ref_t other)
{
    // check
    tb_assert_and_check_return(ipaddr);

    // no ip? clear it
    if (!other)
    {
        ipaddr->have_ip = 0;
        return ;
    }

    // done
    switch (other->family)
    {
    case TB_IPADDR_FAMILY_IPV4:
        {
            // save ipv4
            tb_ipaddr_ipv4_set(ipaddr, &other->u.ipv4);

            // save state
            ipaddr->have_ip = 1;
        }
        break;
    case TB_IPADDR_FAMILY_IPV6:
        {
            // save ipv6
            tb_ipaddr_ipv6_set(ipaddr, &other->u.ipv6);

            // save state
            ipaddr->have_ip = 1;
        }
        break;
    default:
        tb_assert(0);
        break;
    }
}
tb_ipv4_ref_t tb_ipaddr_ipv4(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr, tb_null);

    // no ip?
    tb_check_return_val(ipaddr->have_ip, tb_null);

    // done
    tb_ipv4_ref_t ipv4 = tb_null;
    switch (ipaddr->family)
    {
    case TB_IPADDR_FAMILY_IPV4:
        ipv4 = &ipaddr->u.ipv4;
        break;
    case TB_IPADDR_FAMILY_IPV6:
        {
            tb_ipv4_t temp;
            if (tb_ipaddr_ipv6_to_ipv4(&ipaddr->u.ipv6, &temp))
            {
                ipaddr->family = TB_IPADDR_FAMILY_IPV4;
                ipaddr->u.ipv4 = temp;
                ipv4 = &ipaddr->u.ipv4;
            }
        }
        break;
    default:
        tb_assert(0);
        break;
    }

    // ok?
    return ipv4;
}
tb_void_t tb_ipaddr_ipv4_set(tb_ipaddr_ref_t ipaddr, tb_ipv4_ref_t ipv4)
{
    // check
    tb_assert_and_check_return(ipaddr);

    // no ipv4? clear it
    if (!ipv4)
    {
        ipaddr->have_ip = 0;
        return ;
    }

    // save it
    ipaddr->family    = TB_IPADDR_FAMILY_IPV4;
    ipaddr->have_ip   = 1;
    ipaddr->u.ipv4    = *ipv4;
}
tb_ipv6_ref_t tb_ipaddr_ipv6(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr, tb_null);

    // no ip?
    tb_check_return_val(ipaddr->have_ip, tb_null);

    // done
    tb_ipv6_ref_t ipv6 = tb_null;
    switch (ipaddr->family)
    {
    case TB_IPADDR_FAMILY_IPV4:
        {
            tb_ipv6_t temp;
            if (tb_ipaddr_ipv4_to_ipv6(&ipaddr->u.ipv4, &temp))
            {
                ipaddr->family = TB_IPADDR_FAMILY_IPV6;
                ipaddr->u.ipv6 = temp;
                ipv6 = &ipaddr->u.ipv6;
            }
        }
        break;
    case TB_IPADDR_FAMILY_IPV6:
        ipv6 = &ipaddr->u.ipv6;
        break;
    default:
        tb_assert(0);
        break;
    }

    // ok?
    return ipv6;
}
tb_void_t tb_ipaddr_ipv6_set(tb_ipaddr_ref_t ipaddr, tb_ipv6_ref_t ipv6)
{
    // check
    tb_assert_and_check_return(ipaddr && ipv6);

    // no ipv6? clear it
    if (!ipv6)
    {
        ipaddr->have_ip = 0;
        return ;
    }

    // save it
    ipaddr->family    = TB_IPADDR_FAMILY_IPV6;
    ipaddr->u.ipv6    = *ipv6;
    ipaddr->have_ip   = 1;
}
tb_size_t tb_ipaddr_family(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr, TB_IPADDR_FAMILY_NONE);

    // the family
    return ipaddr->family;
}
tb_void_t tb_ipaddr_family_set(tb_ipaddr_ref_t ipaddr, tb_size_t family)
{
    // check
    tb_assert_and_check_return(ipaddr);

    // ipv4 => ipv6?
    if (ipaddr->family == TB_IPADDR_FAMILY_IPV4 && family == TB_IPADDR_FAMILY_IPV6)
    {
        tb_ipv6_t temp;
        if (tb_ipaddr_ipv4_to_ipv6(&ipaddr->u.ipv4, &temp))
        {
            ipaddr->family = TB_IPADDR_FAMILY_IPV6;
            ipaddr->u.ipv6 = temp;
        }
        else
        {
            // check
            tb_assert(0);
        }
    }
    // ipv6 => ipv4?
    else if (ipaddr->family == TB_IPADDR_FAMILY_IPV4 && family == TB_IPADDR_FAMILY_IPV6)
    {
        tb_ipv4_t temp;
        if (tb_ipaddr_ipv6_to_ipv4(&ipaddr->u.ipv6, &temp))
        {
            ipaddr->family = TB_IPADDR_FAMILY_IPV4;
            ipaddr->u.ipv4 = temp;
        }
        else
        {
            // check
            tb_assert(0);
        }
    }
    else ipaddr->family = family;

    // no family? clear ip
    if (!ipaddr->family) ipaddr->have_ip = 0;
}
tb_uint16_t tb_ipaddr_port(tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ipaddr, 0);

    // the port
    return ipaddr->port;
}
tb_void_t tb_ipaddr_port_set(tb_ipaddr_ref_t ipaddr, tb_uint16_t port)
{
    // check
    tb_assert_and_check_return(ipaddr);

    // set port
    ipaddr->port = port;
}
