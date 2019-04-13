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
 * @file        ifaddrs.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "ifaddrs"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "ifaddrs.h"
#include "../utils/utils.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * instance implementation
 */
static tb_handle_t tb_ifaddrs_instance_init(tb_cpointer_t* ppriv)
{
    // init it
    return (tb_handle_t)tb_ifaddrs_init();
}
static tb_void_t tb_ifaddrs_instance_exit(tb_handle_t ifaddrs, tb_cpointer_t priv)
{
    // exit it
    tb_ifaddrs_exit((tb_ifaddrs_ref_t)ifaddrs);
}
static tb_bool_t tb_ifaddrs_interface_pred(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t name)
{
    // check
    tb_assert(item);

    // is equal?
    return !tb_stricmp(((tb_ifaddrs_interface_ref_t)item)->name, (tb_char_t const*)name);
}
static tb_ifaddrs_interface_ref_t tb_ifaddrs_interface_find(tb_iterator_ref_t iterator, tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(iterator && name, tb_null);

    // find it
    tb_size_t itor = tb_find_all_if(iterator, tb_ifaddrs_interface_pred, name);
    tb_check_return_val(itor != tb_iterator_tail(iterator), tb_null);

    // ok
    return (tb_ifaddrs_interface_ref_t)tb_iterator_item(iterator, itor);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_OS_WINDOWS
#   include "windows/ifaddrs.c"
#elif defined(TB_CONFIG_POSIX_HAVE_GETIFADDRS)
#   if defined(TB_CONFIG_OS_LINUX) || defined(TB_CONFIG_OS_ANDROID)
#       include "linux/ifaddrs.c"
#   else
#       include "posix/ifaddrs.c"
#   endif
#elif defined(TB_CONFIG_OS_LINUX) || defined(TB_CONFIG_OS_ANDROID)
#   include "linux/ifaddrs2.c"
#else
tb_ifaddrs_ref_t tb_ifaddrs_init()
{
    tb_trace_noimpl();
    return tb_null;
}
tb_void_t tb_ifaddrs_exit(tb_ifaddrs_ref_t ifaddrs)
{
    tb_trace_noimpl();
}
tb_iterator_ref_t tb_ifaddrs_itor(tb_ifaddrs_ref_t ifaddrs, tb_bool_t reload)
{
    tb_trace_noimpl();
    return tb_null;
}
#endif
tb_ifaddrs_ref_t tb_ifaddrs()
{
    return (tb_ifaddrs_ref_t)tb_singleton_instance(TB_SINGLETON_TYPE_IFADDRS, tb_ifaddrs_instance_init, tb_ifaddrs_instance_exit, tb_null, tb_null);
}
tb_ifaddrs_interface_ref_t tb_ifaddrs_interface(tb_ifaddrs_ref_t ifaddrs, tb_char_t const* name, tb_bool_t reload)
{
    // check
    tb_assert_and_check_return_val(ifaddrs && name, tb_null);

    // the iterator
    tb_iterator_ref_t iterator = tb_ifaddrs_itor(ifaddrs, reload);
    tb_assert_and_check_return_val(iterator, tb_null);

    // reload it if the cached interfaces is empty
    if (!reload && !tb_iterator_size(iterator)) iterator = tb_ifaddrs_itor(ifaddrs, tb_true);

    // ok
    return tb_ifaddrs_interface_find(iterator, name);
}
tb_bool_t tb_ifaddrs_hwaddr(tb_ifaddrs_ref_t ifaddrs, tb_char_t const* name, tb_bool_t reload, tb_hwaddr_ref_t hwaddr)
{
    // check
    tb_assert_and_check_return_val(ifaddrs && hwaddr, tb_false);

    // clear it first
    tb_hwaddr_clear(hwaddr);

    // the iterator
    tb_iterator_ref_t iterator = tb_ifaddrs_itor(ifaddrs, reload);
    tb_assert_and_check_return_val(iterator, tb_false);

    // reload it if the cached interfaces is empty
    if (!reload && !tb_iterator_size(iterator)) iterator = tb_ifaddrs_itor(ifaddrs, tb_true);

    // done
    tb_bool_t ok = tb_false;
    tb_for_all_if (tb_ifaddrs_interface_ref_t, iface, iterator, iface)
    {
        // get hwaddr from the given iface name?
        if (name)
        {
            // is this?
            if (    (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_HWADDR)
                &&  (iface->name && !tb_strcmp(iface->name, name)))
            {
                // save hwaddr
                tb_hwaddr_copy(hwaddr, &iface->hwaddr);

                // ok
                ok = tb_true;
                break;
            }
        }
        else
        {
            // is this?
            if (    (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_HWADDR)
                &&  (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR)
                &&  !(iface->flags & TB_IFADDRS_INTERFACE_FLAG_IS_LOOPBACK))
            {
                // save hwaddr
                tb_hwaddr_copy(hwaddr, &iface->hwaddr);

                // ok
                ok = tb_true;
                break;
            }
        }
    }

    // ok?
    return ok;
}
tb_bool_t tb_ifaddrs_ipaddr(tb_ifaddrs_ref_t ifaddrs, tb_char_t const* name, tb_bool_t reload, tb_size_t family, tb_ipaddr_ref_t ipaddr)
{
    // check
    tb_assert_and_check_return_val(ifaddrs && ipaddr, tb_false);

    // clear it first
    tb_ipaddr_clear(ipaddr);

    // the iterator
    tb_iterator_ref_t iterator = tb_ifaddrs_itor(ifaddrs, reload);
    tb_assert_and_check_return_val(iterator, tb_false);

    // reload it if the cached interfaces is empty
    if (!reload && !tb_iterator_size(iterator)) iterator = tb_ifaddrs_itor(ifaddrs, tb_true);

    // the ipaddr flags
    tb_uint32_t ipflags = 0;
    if (family == TB_IPADDR_FAMILY_IPV4) ipflags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR4;
    else if (family == TB_IPADDR_FAMILY_IPV6) ipflags |= TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR6;

    // done
    tb_bool_t ok = tb_false;
    tb_for_all_if (tb_ifaddrs_interface_ref_t, iface, iterator, iface)
    {
        // is this?
        if (    (name || !(iface->flags & TB_IFADDRS_INTERFACE_FLAG_IS_LOOPBACK))
            &&  (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR)
            &&  (!name || (iface->name && !tb_strcmp(iface->name, name))))
        {
            // ipv4?
            if (    iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR4
                &&  (!family || family == TB_IPADDR_FAMILY_IPV4))
            {
                // save ipaddr4
                tb_ipaddr_ipv4_set(ipaddr, &iface->ipaddr4);

                // ok
                ok = tb_true;
                break;
            }
            // ipv6?
            else if (    iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR6
                    &&  (!family || family == TB_IPADDR_FAMILY_IPV6))
            {
                // save ipaddr6
                tb_ipaddr_ipv6_set(ipaddr, &iface->ipaddr6);

                // ok
                ok = tb_true;
                break;
            }
        }
    }

    // ok?
    return ok;
}
#ifdef __tb_debug__
tb_void_t tb_ifaddrs_dump(tb_ifaddrs_ref_t ifaddrs)
{
    // trace
    tb_trace_i("");

    // done
    tb_for_all_if (tb_ifaddrs_interface_ref_t, iface, tb_ifaddrs_itor(ifaddrs, tb_true), iface)
    {
        // trace
        tb_trace_i("name: %s%s", iface->name, (iface->flags & TB_IFADDRS_INTERFACE_FLAG_IS_LOOPBACK)? "[loopback]" : "");
        if (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR4)
            tb_trace_i("    ipaddr4: %{ipv4}",  &iface->ipaddr4);
        if (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_IPADDR6)
            tb_trace_i("    ipaddr6: %{ipv6}",  &iface->ipaddr6);
        if (iface->flags & TB_IFADDRS_INTERFACE_FLAG_HAVE_HWADDR)
            tb_trace_i("    hwaddr: %{hwaddr}", &iface->hwaddr);
    }
}
#endif
