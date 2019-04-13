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
 * @file        string_pool.c
 * @ingroup     memory
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "string_pool"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "allocator.h"
#include "memory.h"
#include "../libc/libc.h"
#include "../utils/utils.h"
#include "../platform/platform.h"
#include "../container/container.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the string pool type
typedef struct __tb_string_pool_t
{
    // the cache
    tb_hash_map_ref_t           cache;

}tb_string_pool_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_string_pool_ref_t tb_string_pool_init(tb_bool_t bcase)
{
    // done
    tb_bool_t           ok = tb_false;
    tb_string_pool_t*   pool = tb_null;
    do
    {
        // make pool
        pool = tb_malloc0_type(tb_string_pool_t);
        tb_assert_and_check_break(pool);

        // init hash
        pool->cache = tb_hash_map_init(0, tb_element_str(bcase), tb_element_size());
        tb_assert_and_check_break(pool->cache);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (pool) tb_string_pool_exit((tb_string_pool_ref_t)pool);
        pool = tb_null;
    }

    // ok?
    return (tb_string_pool_ref_t)pool;
}
tb_void_t tb_string_pool_exit(tb_string_pool_ref_t self)
{
    // check
    tb_string_pool_t* pool = (tb_string_pool_t*)self;
    tb_assert_and_check_return(pool);

    // exit cache
    if (pool->cache) tb_hash_map_exit(pool->cache);
    pool->cache = tb_null;

    // exit it
    tb_free(pool);
}
tb_void_t tb_string_pool_clear(tb_string_pool_ref_t self)
{
    // check
    tb_string_pool_t* pool = (tb_string_pool_t*)self;
    tb_assert_and_check_return(pool);

    // clear cache
    if (pool->cache) tb_hash_map_clear(pool->cache);
}
tb_char_t const* tb_string_pool_insert(tb_string_pool_ref_t self, tb_char_t const* data)
{
    // check
    tb_string_pool_t* pool = (tb_string_pool_t*)self;
    tb_assert_and_check_return_val(pool && data, tb_null);

    // done
    tb_char_t const* cstr = tb_null;
    if (pool->cache)
    {
        // exists?
        tb_size_t               itor;
        tb_hash_map_item_ref_t  item = tb_null;
        if (    ((itor = tb_hash_map_find(pool->cache, data)) != tb_iterator_tail(pool->cache))
            &&  (item = (tb_hash_map_item_ref_t)tb_iterator_item(pool->cache, itor)))
        {
            // refn
            tb_size_t refn = (tb_size_t)item->data;

            // refn++
            if (refn) tb_iterator_copy(pool->cache, itor, (tb_pointer_t)(refn + 1));
            // no refn? remove it
            else
            {
                // assert
                tb_assert(0);

                // del it
                tb_iterator_remove(pool->cache, itor);
                item = tb_null;
            }
        }
        
        // no item? insert it
        if (!item)
        {
            // insert it
            if ((itor = tb_hash_map_insert(pool->cache, data, (tb_pointer_t)1)) != tb_iterator_tail(pool->cache))
                item = (tb_hash_map_item_ref_t)tb_iterator_item(pool->cache, itor);
        }

        // save the cstr
        if (item) cstr = (tb_char_t const*)item->name;
    }

    // ok?
    return cstr;
}
tb_void_t tb_string_pool_remove(tb_string_pool_ref_t self, tb_char_t const* data)
{
    // check
    tb_string_pool_t* pool = (tb_string_pool_t*)self;
    tb_assert_and_check_return(pool && data);

    // done
    tb_hash_map_item_ref_t item = tb_null;
    if (pool->cache)
    {
        // exists?
        tb_size_t itor;
        if (    ((itor = tb_hash_map_find(pool->cache, data)) != tb_iterator_tail(pool->cache))
            &&  (item = (tb_hash_map_item_ref_t)tb_iterator_item(pool->cache, itor)))
        {
            // refn
            tb_size_t refn = (tb_size_t)item->data;

            // refn--
            if (refn > 1) tb_iterator_copy(pool->cache, itor, (tb_pointer_t)(refn - 1));
            // del it
            else tb_iterator_remove(pool->cache, itor);
        }
    }
}
#ifdef __tb_debug__
tb_void_t tb_string_pool_dump(tb_string_pool_ref_t self)
{
    // check
    tb_string_pool_t* pool = (tb_string_pool_t*)self;
    tb_assert_and_check_return(pool && pool->cache);

    // dump cache
    tb_for_all_if (tb_hash_map_item_ref_t, item, pool->cache, item)
    {
        // trace
        tb_trace_i("item: refn: %lu, cstr: %s", (tb_size_t)item->data, item->name);
    }
}
#endif
