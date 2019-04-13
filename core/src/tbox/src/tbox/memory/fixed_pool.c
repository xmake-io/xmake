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
 * @file        fixed_pool.c
 * @ingroup     memory
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "fixed_pool"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "fixed_pool.h"
#include "large_allocator.h"
#include "impl/static_fixed_pool.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the item belong to this slot?
#define tb_fixed_pool_slot_exists(slot, item)               (((tb_byte_t*)(item) > (tb_byte_t*)(slot)) && ((tb_byte_t*)(item) < (tb_byte_t*)slot + (slot)->size))

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the fixed pool slot type
typedef struct __tb_fixed_pool_slot_t
{
    // the size: sizeof(slot) + data
    tb_size_t                       size;

    // the pool
    tb_static_fixed_pool_ref_t      pool;

    // the list entry
    tb_list_entry_t                 entry;

}tb_fixed_pool_slot_t;

// the fixed pool type
typedef struct __tb_fixed_pool_impl_t
{
    // the large allocator
    tb_allocator_ref_t              large_allocator;

    // the slot size
    tb_size_t                       slot_size;

    // the item size
    tb_size_t                       item_size;

    // the item count
    tb_size_t                       item_count;

    // the init func
    tb_fixed_pool_item_init_func_t  func_init;

    // the exit func
    tb_fixed_pool_item_exit_func_t  func_exit;

    // the private data
    tb_cpointer_t                   func_priv;

    // the current slot
    tb_fixed_pool_slot_t*           current_slot;

    // the partial slot
    tb_list_entry_head_t            partial_slots;

    // the full slot
    tb_list_entry_head_t            full_slots;

    // the slot list
    tb_fixed_pool_slot_t**          slot_list;

    // the slot count
    tb_size_t                       slot_count;

    // the slot space
    tb_size_t                       slot_space;

    // for small allocator
    tb_bool_t                       for_small;

}tb_fixed_pool_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */
__tb_extern_c__ tb_fixed_pool_ref_t tb_fixed_pool_init_(tb_allocator_ref_t large_allocator, tb_size_t slot_size, tb_size_t item_size, tb_bool_t for_small, tb_fixed_pool_item_init_func_t item_init, tb_fixed_pool_item_exit_func_t item_exit, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t tb_fixed_pool_item_exit(tb_pointer_t data, tb_cpointer_t priv)
{
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)priv;
    tb_assert(pool && pool->func_exit);

    // done exit
    pool->func_exit(data, pool->func_priv);

    // continue
    return tb_true;
}
static tb_void_t tb_fixed_pool_slot_exit(tb_fixed_pool_t* pool, tb_fixed_pool_slot_t* slot)
{
    // check
    tb_assert_and_check_return(pool && pool->large_allocator && slot);
    tb_assert_and_check_return(pool->slot_list && pool->slot_count);

    // trace
    tb_trace_d("slot[%lu]: exit: size: %lu", pool->item_size, slot->size);

    // make the iterator
    tb_array_iterator_t array_iterator;
    tb_iterator_ref_t   iterator = tb_array_iterator_init_ptr(&array_iterator, (tb_pointer_t*)pool->slot_list, pool->slot_count);
    tb_assert(iterator);

    // find the slot from the slot list
    tb_size_t itor = tb_binary_find_all(iterator, (tb_cpointer_t)slot);
    tb_assert(itor != tb_iterator_tail(iterator) && itor < pool->slot_count && pool->slot_list[itor]);
    tb_check_return(itor != tb_iterator_tail(iterator) && itor < pool->slot_count && pool->slot_list[itor]);
    
    // remove the slot
    if (itor + 1 < pool->slot_count) tb_memmov_(pool->slot_list + itor, pool->slot_list + itor + 1, (pool->slot_count - itor - 1) * sizeof(tb_fixed_pool_slot_t*));

    // update the slot count
    pool->slot_count--;

    // exit slot
    tb_allocator_large_free(pool->large_allocator, slot);
}
static tb_fixed_pool_slot_t* tb_fixed_pool_slot_init(tb_fixed_pool_t* pool)
{
    // check
    tb_assert_and_check_return_val(pool && pool->large_allocator && pool->slot_size && pool->item_size, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_fixed_pool_slot_t*   slot = tb_null;
    do
    {
#ifdef __tb_debug__
        // init patch for checking underflow
        tb_size_t patch = 1;
#else
        tb_size_t patch = 0;
#endif

        // the item space
        tb_size_t item_space = sizeof(tb_pool_data_head_t) + pool->item_size + patch;

        // the need space
        tb_size_t need_space = sizeof(tb_fixed_pool_slot_t) + pool->slot_size * item_space;

        // make slot
        tb_size_t real_space = 0;
        slot = (tb_fixed_pool_slot_t*)tb_allocator_large_malloc(pool->large_allocator, need_space, &real_space);
        tb_assert_and_check_break(slot);
        tb_assert_and_check_break(real_space > sizeof(tb_fixed_pool_slot_t) + item_space);

        // init slot
        slot->size = real_space;
        slot->pool = tb_static_fixed_pool_init((tb_byte_t*)&slot[1], real_space - sizeof(tb_fixed_pool_slot_t), pool->item_size, pool->for_small); 
        tb_assert_and_check_break(slot->pool);

        // no list?
        if (!pool->slot_list)
        {
            // init the slot list
            tb_size_t size = 0;
            pool->slot_list = (tb_fixed_pool_slot_t**)tb_allocator_large_nalloc(pool->large_allocator, 64, sizeof(tb_fixed_pool_slot_t*), &size);
            tb_assert_and_check_break(pool->slot_list && size);

            // init the slot count
            pool->slot_count = 0;

            // init the slot space
            pool->slot_space = size / sizeof(tb_fixed_pool_slot_t*);
            tb_assert_and_check_break(pool->slot_space);
        }
        // no enough space?
        else if (pool->slot_count == pool->slot_space)
        {
            // grow the slot list
            tb_size_t size = 0;
            pool->slot_list = (tb_fixed_pool_slot_t**)tb_allocator_large_ralloc(pool->large_allocator, pool->slot_list, (pool->slot_space << 1) * sizeof(tb_fixed_pool_slot_t*), &size);
            tb_assert_and_check_break(pool->slot_list && size);

            // update the slot space
            pool->slot_space = size / sizeof(tb_fixed_pool_slot_t*);
            tb_assert_and_check_break(pool->slot_space);
        }

        // check
        tb_assert_and_check_break(pool->slot_count < pool->slot_space);

        // insert the slot to the slot list in the increasing order (TODO binary search)
        tb_size_t i = 0;
        tb_size_t n = pool->slot_count;
        for (i = 0; i < n; i++) if (slot <= pool->slot_list[i]) break;
        if (i < n) tb_memmov_(pool->slot_list + i + 1, pool->slot_list + i, (n - i) * sizeof(tb_fixed_pool_slot_t*));
        pool->slot_list[i] = slot;

        // update the slot count
        pool->slot_count++;

        // trace
        tb_trace_d("slot[%lu]: init: size: %lu => %lu, item: %lu => %lu", pool->item_size, need_space, real_space, pool->slot_size, tb_static_fixed_pool_maxn(slot->pool));

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (slot) tb_fixed_pool_slot_exit(pool, slot);
        slot = tb_null;
    }

    // ok?
    return slot;
}
#if 0
static tb_fixed_pool_slot_t* tb_fixed_pool_slot_find(tb_fixed_pool_t* pool, tb_pointer_t data)
{
    // check
    tb_assert_and_check_return_val(pool && data, tb_null);

    // done
    tb_fixed_pool_slot_t* slot = tb_null;
    do
    {
        // belong to the current slot?
        if (pool->current_slot && tb_fixed_pool_slot_exists(pool->current_slot, data))
        {
            slot = pool->current_slot;
            break;
        }
            
        // find the slot from the partial slots
        tb_for_all_if(tb_fixed_pool_slot_t*, partial_slot, tb_list_entry_itor(&pool->partial_slots), partial_slot)
        {
            // is this?
            if (tb_fixed_pool_slot_exists(partial_slot, data))
            {
                slot = partial_slot;
                break;
            }
        }
        
        // no found?
        tb_check_break(!slot);

        // find the slot from the full slots
        tb_for_all_if(tb_fixed_pool_slot_t*, full_slot, tb_list_entry_itor(&pool->full_slots), full_slot)
        {
            // is this?
            if (tb_fixed_pool_slot_exists(full_slot, data))
            {
                slot = full_slot;
                break;
            }
        }

    } while (0);

    // ok?
    return slot;
}
#else
static tb_long_t tb_fixed_pool_slot_comp(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t data)
{
    // the slot
    tb_fixed_pool_slot_t* slot = (tb_fixed_pool_slot_t*)item;
    tb_assert(slot);

    // comp
    return (tb_byte_t*)data < (tb_byte_t*)slot? 1 : ((tb_byte_t*)data >= (tb_byte_t*)slot + slot->size? -1 : 0);
}
static tb_fixed_pool_slot_t* tb_fixed_pool_slot_find(tb_fixed_pool_t* pool, tb_pointer_t data)
{
    // check
    tb_assert_and_check_return_val(pool && data, tb_null);

    // make the iterator
    tb_array_iterator_t array_iterator;
    tb_iterator_ref_t   iterator = tb_array_iterator_init_ptr(&array_iterator, (tb_pointer_t*)pool->slot_list, pool->slot_count);
    tb_assert(iterator);

    // find it
    tb_size_t itor = tb_binary_find_all_if(iterator, tb_fixed_pool_slot_comp, data);
    tb_check_return_val(itor != tb_iterator_tail(iterator), tb_null);

    // the slot
    tb_fixed_pool_slot_t* slot = pool->slot_list[itor];
    tb_assert_and_check_return_val(slot, tb_null);

    // check
    tb_assert(tb_fixed_pool_slot_exists(slot, data));

    // ok?
    return slot;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_fixed_pool_ref_t tb_fixed_pool_init_(tb_allocator_ref_t large_allocator, tb_size_t slot_size, tb_size_t item_size, tb_bool_t for_small, tb_fixed_pool_item_init_func_t item_init, tb_fixed_pool_item_exit_func_t item_exit, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(item_size, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_fixed_pool_t*    pool = tb_null;
    do
    {
        // no allocator? uses the global allocator
        if (!large_allocator) large_allocator = tb_allocator();
        tb_assert_and_check_break(large_allocator);

        // make pool
        pool = (tb_fixed_pool_t*)tb_allocator_large_malloc0(large_allocator, sizeof(tb_fixed_pool_t), tb_null);
        tb_assert_and_check_break(pool);

        // init pool
        pool->large_allocator   = large_allocator;
        pool->slot_size         = slot_size? slot_size : (tb_page_size() >> 4);
        pool->item_size         = item_size;
        pool->func_init         = item_init;
        pool->func_exit         = item_exit;
        pool->func_priv         = priv;
        pool->for_small         = for_small;
        tb_assert_and_check_break(pool->slot_size);

        // init partial slots
        tb_list_entry_init(&pool->partial_slots, tb_fixed_pool_slot_t, entry, tb_null);

        // init full slots
        tb_list_entry_init(&pool->full_slots, tb_fixed_pool_slot_t, entry, tb_null);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (pool) tb_fixed_pool_exit((tb_fixed_pool_ref_t)pool);
        pool = tb_null;
    }

    // ok?
    return (tb_fixed_pool_ref_t)pool;
}
tb_fixed_pool_ref_t tb_fixed_pool_init(tb_allocator_ref_t large_allocator, tb_size_t slot_size, tb_size_t item_size, tb_fixed_pool_item_init_func_t item_init, tb_fixed_pool_item_exit_func_t item_exit, tb_cpointer_t priv)
{
    return tb_fixed_pool_init_(large_allocator, slot_size, item_size, tb_false, item_init, item_exit, priv);
}
tb_void_t tb_fixed_pool_exit(tb_fixed_pool_ref_t self)
{
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return(pool);

    // clear it
    tb_fixed_pool_clear(self);

    // exit the current slot
    if (pool->current_slot) tb_fixed_pool_slot_exit(pool, pool->current_slot);
    pool->current_slot = tb_null;

    // exit the slot list
    if (pool->slot_list) tb_allocator_large_free(pool->large_allocator, pool->slot_list);
    pool->slot_list = tb_null;
    pool->slot_count = 0;
    pool->slot_space = 0;

    // exit it
    tb_allocator_large_free(pool->large_allocator, pool);
}
tb_size_t tb_fixed_pool_size(tb_fixed_pool_ref_t self)
{
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, 0);

    // the item count
    return pool->item_count;
}
tb_size_t tb_fixed_pool_item_size(tb_fixed_pool_ref_t self)
{
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, 0);

    // the item size
    return pool->item_size;
}
tb_void_t tb_fixed_pool_clear(tb_fixed_pool_ref_t self)
{
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return(pool);

    // exit items
    if (pool->func_exit) tb_fixed_pool_walk(self, tb_fixed_pool_item_exit, (tb_pointer_t)pool);

    // exit the partial slots 
    tb_iterator_ref_t partial_iterator = tb_list_entry_itor(&pool->partial_slots);
    if (partial_iterator)
    {
        // walk it
        tb_size_t itor = tb_iterator_head(partial_iterator);
        while (itor != tb_iterator_tail(partial_iterator))
        {
            // the slot
            tb_fixed_pool_slot_t* slot = (tb_fixed_pool_slot_t*)tb_iterator_item(partial_iterator, itor);
            tb_assert_and_check_break(slot);

            // check
            tb_assert(slot != pool->current_slot);

            // save next
            tb_size_t next = tb_iterator_next(partial_iterator, itor);

            // exit slot
            tb_fixed_pool_slot_exit(pool, slot);

            // next
            itor = next;
        }
    }

    // exit the full slots 
    tb_iterator_ref_t full_iterator = tb_list_entry_itor(&pool->full_slots);
    if (full_iterator)
    {
        // walk it
        tb_size_t itor = tb_iterator_head(full_iterator);
        while (itor != tb_iterator_tail(full_iterator))
        {
            // the slot
            tb_fixed_pool_slot_t* slot = (tb_fixed_pool_slot_t*)tb_iterator_item(full_iterator, itor);
            tb_assert_and_check_break(slot);

            // check
            tb_assert(slot != pool->current_slot);

            // save next
            tb_size_t next = tb_iterator_next(full_iterator, itor);

            // exit slot
            tb_fixed_pool_slot_exit(pool, slot);

            // next
            itor = next;
        }
    }

    // clear current slot
    if (pool->current_slot && pool->current_slot->pool)
        tb_static_fixed_pool_clear(pool->current_slot->pool);

    // clear item count
    pool->item_count = 0;

    // clear partial slots
    tb_list_entry_clear(&pool->partial_slots);

    // clear full slots
    tb_list_entry_clear(&pool->full_slots);
}
tb_pointer_t tb_fixed_pool_malloc_(tb_fixed_pool_ref_t self __tb_debug_decl__)
{
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_pointer_t    data = tb_null;
    do
    {
        // no current slot or the current slot is full? update the current slot
        if (!pool->current_slot || tb_static_fixed_pool_full(pool->current_slot->pool))
        {
            // move the current slot to the full slots if exists
            if (pool->current_slot) tb_list_entry_insert_tail(&pool->full_slots, &pool->current_slot->entry);

            // clear the current slot
            pool->current_slot = tb_null;

            // attempt to get a slot from the partial slots
            if (!tb_list_entry_is_null(&pool->partial_slots))
            {
                // the head entry
                tb_list_entry_ref_t entry = tb_list_entry_head(&pool->partial_slots);
                tb_assert_and_check_break(entry);

                // the head slot
                pool->current_slot = (tb_fixed_pool_slot_t*)tb_list_entry(&pool->partial_slots, entry);
                tb_assert_and_check_break(pool->current_slot);

                // remove this slot from the partial slots
                tb_list_entry_remove(&pool->partial_slots, entry);
            }
            // make a new slot
            else pool->current_slot = tb_fixed_pool_slot_init(pool);
        }

        // check
        tb_assert_and_check_break(pool->current_slot && pool->current_slot->pool);
        tb_assert_and_check_break(!tb_static_fixed_pool_full(pool->current_slot->pool));

        // make data from the current slot
        data = tb_static_fixed_pool_malloc(pool->current_slot->pool __tb_debug_args__);
        tb_assert_and_check_break(data);
        
        // done init
        if (pool->func_init && !pool->func_init(data, pool->func_priv)) break;

        // update the item count
        pool->item_count++;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit data
        if (data && pool->current_slot && pool->current_slot->pool) 
            tb_static_fixed_pool_free(pool->current_slot->pool, data __tb_debug_args__);
        data = tb_null;
    }

    // check
    tb_assertf(data, "malloc(%lu) failed!", pool->item_size);

    // ok?
    return data;
}
tb_pointer_t tb_fixed_pool_malloc0_(tb_fixed_pool_ref_t self __tb_debug_decl__)
{
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, tb_null);

    // done
    tb_pointer_t data = tb_fixed_pool_malloc_(self __tb_debug_args__);
    tb_assert_and_check_return_val(data, tb_null);

    // clear it
    tb_memset_(data, 0, pool->item_size);

    // ok
    return data;
}
tb_bool_t tb_fixed_pool_free_(tb_fixed_pool_ref_t self, tb_pointer_t data __tb_debug_decl__)
{ 
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // check
        tb_assertf_pass_and_check_break(pool->item_count, "double free data: %p", data);

        // find the slot 
        tb_fixed_pool_slot_t* slot = tb_fixed_pool_slot_find(pool, data);
        tb_assertf_pass_and_check_break(slot, "the data: %p not belong to pool: %p", data, self);
        tb_assert_pass_and_check_break(slot->pool);

        // the slot is full?
        tb_bool_t full = tb_static_fixed_pool_full(slot->pool);

        // done exit
        if (pool->func_exit) pool->func_exit(data, pool->func_priv);

        // free it
        if (!tb_static_fixed_pool_free(slot->pool, data __tb_debug_args__)) break;

        // not the current slot?
        if (slot != pool->current_slot)
        {
            // is full? move the slot to the partial slots
            if (full)
            {
                tb_list_entry_remove(&pool->full_slots, &slot->entry);
                tb_list_entry_insert_tail(&pool->partial_slots, &slot->entry);
            }
            // is null? exit the slot
            else if (tb_static_fixed_pool_null(slot->pool))
            {
                tb_list_entry_remove(&pool->partial_slots, &slot->entry);
                tb_fixed_pool_slot_exit(pool, slot);
            }
        }

        // update the item count
        pool->item_count--;
 
        // ok
        ok = tb_true;

    } while (0);

    // failed? dump it
#ifdef __tb_debug__
    if (!ok) 
    {
        // trace
        tb_trace_e("free(%p) failed! at %s(): %lu, %s", data, func_, line_, file_);

        // dump data
        tb_pool_data_dump((tb_byte_t const*)data, tb_true, "[fixed_pool]: [error]: ");

        // abort
        tb_abort();
    }
#endif

    // ok?
    return ok;
}
tb_void_t tb_fixed_pool_walk(tb_fixed_pool_ref_t self, tb_fixed_pool_item_walk_func_t func, tb_cpointer_t priv)
{
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return(pool && func);

    // walk the current slot first
    if (pool->current_slot && pool->current_slot->pool)
        tb_static_fixed_pool_walk(pool->current_slot->pool, func, priv);

    // walk the partial slots
    tb_for_all_if(tb_fixed_pool_slot_t*, partial_slot, tb_list_entry_itor(&pool->partial_slots), partial_slot && partial_slot->pool)
    {
        // check
        tb_assert(!tb_static_fixed_pool_full(partial_slot->pool));

        // walk
        tb_static_fixed_pool_walk(partial_slot->pool, func, priv);
    }

    // walk the full slots
    tb_for_all_if(tb_fixed_pool_slot_t*, full_slot, tb_list_entry_itor(&pool->full_slots), full_slot && full_slot->pool)
    {
        // check
        tb_assert(tb_static_fixed_pool_full(full_slot->pool));

        // walk
        tb_static_fixed_pool_walk(full_slot->pool, func, priv);
    }
}
#ifdef __tb_debug__
tb_void_t tb_fixed_pool_dump(tb_fixed_pool_ref_t self)
{ 
    // check
    tb_fixed_pool_t* pool = (tb_fixed_pool_t*)self;
    tb_assert_and_check_return(pool);

    // dump the current slot first
    if (pool->current_slot && pool->current_slot->pool)
        tb_static_fixed_pool_dump(pool->current_slot->pool);

    // dump the partial slots
    tb_for_all_if(tb_fixed_pool_slot_t*, partial_slot, tb_list_entry_itor(&pool->partial_slots), partial_slot && partial_slot->pool)
    {
        // check
        tb_assert(!tb_static_fixed_pool_full(partial_slot->pool));

        // dump
        tb_static_fixed_pool_dump(partial_slot->pool);
    }

    // dump the full slots
    tb_for_all_if(tb_fixed_pool_slot_t*, full_slot, tb_list_entry_itor(&pool->full_slots), full_slot && full_slot->pool)
    {
        // check
        tb_assert(tb_static_fixed_pool_full(full_slot->pool));

        // dump
        tb_static_fixed_pool_dump(full_slot->pool);
    }
}
#endif
