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
 * @file        cache.c
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "dns_cache"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "cache.h"
#include "../../platform/platform.h"
#include "../../container/container.h"
#include "../../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the cache maxn
#ifdef __tb_small__
#   define TB_DNS_CACHE_MAXN        (64)
#else
#   define TB_DNS_CACHE_MAXN        (256)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the dns cache type
typedef struct __tb_dns_cache_t
{
    // the hash
    tb_hash_map_ref_t       hash;

    // the times
    tb_hize_t               times;

    // the expired
    tb_size_t               expired;

}tb_dns_cache_t;

// the dns cache addr type
typedef struct __tb_dns_cache_addr_t
{
    // the addr
    tb_ipaddr_t             addr;

    // the time
    tb_size_t               time;

}tb_dns_cache_addr_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the lock
static tb_spinlock_t        g_lock = TB_SPINLOCK_INIT;

// the cache
static tb_dns_cache_t       g_cache = {0};

/* //////////////////////////////////////////////////////////////////////////////////////
 * helper
 */
static __tb_inline__ tb_size_t tb_dns_cache_now()
{
    return (tb_size_t)(tb_cache_time_spak() / 1000);
}
static tb_bool_t tb_dns_cache_clear(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // check
    tb_assert(item);

    // the dns cache address
    tb_dns_cache_addr_t const* caddr = (tb_dns_cache_addr_t const*)((tb_hash_map_item_ref_t)item)->data;
    tb_assert(caddr);

    // is expired?
    tb_bool_t ok = tb_false;
    if (caddr->time < g_cache.expired)
    {
        // remove it
        ok = tb_true;

        // trace
        tb_trace_d("del: %s => %{ipaddr}, time: %u, size: %u", (tb_char_t const*)item->name, &caddr->addr, caddr->time, tb_hash_map_size(g_cache.hash));

        // update times
        tb_assert(g_cache.times >= caddr->time);
        g_cache.times -= caddr->time;
    }

    // ok?
    return ok;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_dns_cache_init()
{
    // enter
    tb_spinlock_enter(&g_lock);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // init hash
        if (!g_cache.hash) g_cache.hash = tb_hash_map_init(tb_align8(tb_isqrti(TB_DNS_CACHE_MAXN) + 1), tb_element_str(tb_false), tb_element_mem(sizeof(tb_dns_cache_addr_t), tb_null, tb_null));
        tb_assert_and_check_break(g_cache.hash);

        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);

    // failed? exit it
    if (!ok) tb_dns_cache_exit();

    // ok?
    return ok;
}
tb_void_t tb_dns_cache_exit()
{
    // enter
    tb_spinlock_enter(&g_lock);

    // exit hash
    if (g_cache.hash) tb_hash_map_exit(g_cache.hash);
    g_cache.hash = tb_null;

    // exit times
    g_cache.times = 0;

    // exit expired 
    g_cache.expired = 0;

    // leave
    tb_spinlock_leave(&g_lock);
}
tb_bool_t tb_dns_cache_get(tb_char_t const* name, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(name && addr, tb_false);

    // trace
    tb_trace_d("get: %s", name);

    // is addr?
    tb_check_return_val(!tb_ipaddr_ip_cstr_set(addr, name, TB_IPADDR_FAMILY_NONE), tb_true);

    // is localhost?
    if (!tb_stricmp(name, "localhost"))
    {
        // save address
        tb_ipaddr_ip_cstr_set(addr, "127.0.0.1", TB_IPADDR_FAMILY_IPV4);

        // ok
        return tb_true;
    }

    // clear address
    tb_ipaddr_clear(addr);

    // enter
    tb_spinlock_enter(&g_lock);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // check
        tb_assert_and_check_break(g_cache.hash);

        // get the host address
        tb_dns_cache_addr_t* caddr = (tb_dns_cache_addr_t*)tb_hash_map_get(g_cache.hash, name);
        tb_check_break(caddr);

        // trace
        tb_trace_d("get: %s => %{ipaddr}, time: %u => %u, size: %u", name, &caddr->addr, caddr->time, tb_dns_cache_now(), tb_hash_map_size(g_cache.hash));

        // update time
        tb_assert_and_check_break(g_cache.times >= caddr->time);
        g_cache.times -= caddr->time;
        caddr->time = tb_dns_cache_now();
        g_cache.times += caddr->time;

        // save address
        tb_ipaddr_copy(addr, &caddr->addr);

        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return ok;
}
tb_void_t tb_dns_cache_set(tb_char_t const* name, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return(name && addr);

    // check address
    tb_assert(!tb_ipaddr_ip_is_empty(addr));

    // trace
    tb_trace_d("set: %s => %{ipaddr}", name, addr);

    // init addr
    tb_dns_cache_addr_t caddr;
    caddr.time = tb_dns_cache_now();
    tb_ipaddr_copy(&caddr.addr, addr);

    // enter
    tb_spinlock_enter(&g_lock);

    // done
    do
    {
        // check
        tb_assert_and_check_break(g_cache.hash);

        // remove the expired items if full
        if (tb_hash_map_size(g_cache.hash) >= TB_DNS_CACHE_MAXN)
        {
            // the expired time
            g_cache.expired = ((tb_size_t)(g_cache.times / tb_hash_map_size(g_cache.hash)) + 1);

            // check
            tb_assert_and_check_break(g_cache.expired);

            // trace
            tb_trace_d("expired: %lu", g_cache.expired);

            // remove the expired times
            tb_remove_if(g_cache.hash, tb_dns_cache_clear, tb_null);
        }

        // check
        tb_assert_and_check_break(tb_hash_map_size(g_cache.hash) < TB_DNS_CACHE_MAXN);

        // save addr
        tb_hash_map_insert(g_cache.hash, name, &caddr);

        // update times
        g_cache.times += caddr.time;

        // trace
        tb_trace_d("set: %s => %{ipaddr}, time: %u, size: %u", name, &caddr.addr, caddr.time, tb_hash_map_size(g_cache.hash));

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);
}
