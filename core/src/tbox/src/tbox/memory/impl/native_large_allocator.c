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
 * @file        native_large_allocator.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "native_large_allocator"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "native_large_allocator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the native large allocator data size
#define tb_native_large_allocator_data_base(data_head)   (&(((tb_pool_data_head_t*)((tb_native_large_data_head_t*)(data_head) + 1))[-1]))

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the native large data head type
typedef __tb_pool_data_aligned__ struct __tb_native_large_data_head_t
{
    // the allocator reference
    tb_pointer_t                    allocator;

    // the entry
    tb_list_entry_t                 entry;

    // the data head base
    tb_byte_t                       base[sizeof(tb_pool_data_head_t)];

}__tb_pool_data_aligned__ tb_native_large_data_head_t;

/*! the native large allocator type
 *
 * <pre>
 *        -----------       -----------               -----------
 *       |||  data   | <=> |||  data   | <=> ... <=> |||  data   | <=> |
 *        -----------       -----------               -----------      |
 *              |                                                      |
 *              `------------------------------------------------------`
 * </pre>
 */
typedef struct __tb_native_large_allocator_t
{
    // the base
    tb_allocator_t                  base;

    // the data list
    tb_list_entry_head_t            data_list;

#ifdef __tb_debug__
    // the peak size
    tb_size_t                       peak_size;

    // the total size
    tb_size_t                       total_size;

    // the real size
    tb_size_t                       real_size;

    // the occupied size
    tb_size_t                       occupied_size;

    // the malloc count
    tb_size_t                       malloc_count;

    // the ralloc count
    tb_size_t                       ralloc_count;

    // the free count
    tb_size_t                       free_count;
#endif

}tb_native_large_allocator_t, *tb_native_large_allocator_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#ifdef __tb_debug__
static tb_void_t tb_native_large_allocator_check_data(tb_native_large_allocator_ref_t allocator, tb_native_large_data_head_t const* data_head)
{
    // check
    tb_assert_and_check_return(allocator && data_head);

    // done
    tb_bool_t           ok = tb_false;
    tb_byte_t const*    data = (tb_byte_t const*)&(data_head[1]);
    do
    {
        // the base head
        tb_pool_data_head_t* base_head = tb_native_large_allocator_data_base(data_head);

        // check
        tb_assertf_pass_break(base_head->debug.magic != (tb_uint16_t)~TB_POOL_DATA_MAGIC, "data have been freed: %p", data);
        tb_assertf_pass_break(base_head->debug.magic == TB_POOL_DATA_MAGIC, "the invalid data: %p", data);
        tb_assertf_pass_break(((tb_byte_t*)data)[base_head->size] == TB_POOL_DATA_PATCH, "data underflow");

        // ok
        ok = tb_true;

    } while (0);

    // failed? dump it
#ifdef __tb_debug__
    if (!ok) 
    {
        // dump data
        tb_pool_data_dump(data, tb_true, "[native_large_allocator]: [error]: ");

        // abort
        tb_abort();
    }
#endif
}
static tb_void_t tb_native_large_allocator_check_last(tb_native_large_allocator_ref_t allocator)
{
    // check
    tb_assert_and_check_return(allocator);

    // non-empty?
    if (!tb_list_entry_is_null(&allocator->data_list))
    {
        // the last entry
        tb_list_entry_ref_t data_last = tb_list_entry_last(&allocator->data_list);
        tb_assert_and_check_return(data_last);

        // check it
        tb_native_large_allocator_check_data(allocator, (tb_native_large_data_head_t*)tb_list_entry(&allocator->data_list, data_last));
    }
}
static tb_void_t tb_native_large_allocator_check_prev(tb_native_large_allocator_ref_t allocator, tb_native_large_data_head_t const* data_head)
{
    // check
    tb_assert_and_check_return(allocator && data_head);

    // non-empty?
    if (!tb_list_entry_is_null(&allocator->data_list))
    {
        // the prev entry
        tb_list_entry_ref_t data_prev = tb_list_entry_prev((tb_list_entry_ref_t)&data_head->entry);
        tb_assert_and_check_return(data_prev);

        // not tail entry
        tb_check_return(data_prev != tb_list_entry_tail(&allocator->data_list));

        // check it
        tb_native_large_allocator_check_data(allocator, (tb_native_large_data_head_t*)tb_list_entry(&allocator->data_list, data_prev));
    }
}
static tb_void_t tb_native_large_allocator_check_next(tb_native_large_allocator_ref_t allocator, tb_native_large_data_head_t const* data_head)
{
    // check
    tb_assert_and_check_return(allocator && data_head);

    // non-empty?
    if (!tb_list_entry_is_null(&allocator->data_list))
    {
        // the next entry
        tb_list_entry_ref_t data_next = tb_list_entry_next((tb_list_entry_ref_t)&data_head->entry);
        tb_assert_and_check_return(data_next);

        // not tail entry
        tb_check_return(data_next != tb_list_entry_tail(&allocator->data_list));

        // check it
        tb_native_large_allocator_check_data(allocator, (tb_native_large_data_head_t*)tb_list_entry(&allocator->data_list, data_next));
    }
}
#endif
static tb_pointer_t tb_native_large_allocator_malloc(tb_allocator_ref_t self, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_native_large_allocator_ref_t allocator = (tb_native_large_allocator_ref_t)self;
    tb_assert_and_check_return_val(allocator, tb_null);

    // done 
#ifdef __tb_debug__
    tb_size_t                       patch = 1; // patch 0xcc
#else
    tb_size_t                       patch = 0;
#endif
    tb_bool_t                       ok = tb_false;
    tb_size_t                       need = sizeof(tb_native_large_data_head_t) + size + patch;
    tb_byte_t*                      data = tb_null;
    tb_byte_t*                      data_real = tb_null;
    tb_native_large_data_head_t*    data_head = tb_null;
    do
    {
#ifdef __tb_debug__
        // check the last data
        tb_native_large_allocator_check_last(allocator);
#endif

        // make data
        data = (tb_byte_t*)tb_native_memory_malloc(need);
        tb_assert_and_check_break(data);
        tb_assert_and_check_break(!(((tb_size_t)data) & 0x1));

        // make the real data
        data_real = data + sizeof(tb_native_large_data_head_t);

        // init the data head
        data_head = (tb_native_large_data_head_t*)data;

        // the base head
        tb_pool_data_head_t* base_head = tb_native_large_allocator_data_base(data_head);

        // save the real size
        base_head->size = (tb_uint32_t)size;

#ifdef __tb_debug__
        base_head->debug.magic     = TB_POOL_DATA_MAGIC;
        base_head->debug.file      = file_;
        base_head->debug.func      = func_;
        base_head->debug.line      = (tb_uint16_t)line_;

        // save backtrace
        tb_pool_data_save_backtrace(&base_head->debug, 5);

        // make the dirty data and patch 0xcc for checking underflow
        tb_memset_(data_real, TB_POOL_DATA_PATCH, size + patch);
#endif

        // save allocator reference for checking data range
        data_head->allocator = (tb_pointer_t)allocator;

        // save the data to the data_list
        tb_list_entry_insert_tail(&allocator->data_list, &data_head->entry);

        // save the real size
        if (real) *real = size;

#ifdef __tb_debug__
        // update the real size
        allocator->real_size     += size;

        // update the occupied size
        allocator->occupied_size += need - TB_POOL_DATA_HEAD_DIFF_SIZE - patch;

        // update the total size
        allocator->total_size    += size;

        // update the peak size
        if (allocator->total_size > allocator->peak_size) allocator->peak_size = allocator->total_size;

        // update the malloc count
        allocator->malloc_count++;
#endif

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit the data
        if (data) tb_native_memory_free(data);
        data = tb_null;
        data_real = tb_null;
    }

    // ok?
    return (tb_pointer_t)data_real;
}
static tb_pointer_t tb_native_large_allocator_ralloc(tb_allocator_ref_t self, tb_pointer_t data, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_native_large_allocator_ref_t allocator = (tb_native_large_allocator_ref_t)self;
    tb_assert_and_check_return_val(allocator, tb_null);

    // done 
#ifdef __tb_debug__
    tb_size_t                       patch = 1; // patch 0xcc
#else
    tb_size_t                       patch = 0;
#endif
    tb_bool_t                       ok = tb_false;
    tb_bool_t                       removed = tb_false;
    tb_size_t                       need = sizeof(tb_native_large_data_head_t) + size + patch;
    tb_byte_t*                      data_real = tb_null;
    tb_native_large_data_head_t*    data_head = tb_null;
    do
    {
        // the data head
        data_head = &(((tb_native_large_data_head_t*)data)[-1]);

        // the base head
        tb_pool_data_head_t* base_head = tb_native_large_allocator_data_base(data_head);

        // check
        tb_assertf(base_head->debug.magic != (tb_uint16_t)~TB_POOL_DATA_MAGIC, "ralloc freed data: %p", data);
        tb_assertf(base_head->debug.magic == TB_POOL_DATA_MAGIC, "ralloc invalid data: %p", data);
        tb_assertf_and_check_break(data_head->allocator == (tb_pointer_t)allocator, "the data: %p not belong to allocator: %p", data, allocator);
        tb_assertf(((tb_byte_t*)data)[base_head->size] == TB_POOL_DATA_PATCH, "data underflow");

#ifdef __tb_debug__
        // check the last data
        tb_native_large_allocator_check_last(allocator);

        // check the prev data
        tb_native_large_allocator_check_prev(allocator, data_head);

        // check the next data
        tb_native_large_allocator_check_next(allocator, data_head);
 
        // update the real size
        allocator->real_size -= base_head->size;

        // update the occupied size
        allocator->occupied_size -= base_head->size;
 
        // update the total size
        allocator->total_size -= base_head->size;

        // the previous size
        tb_size_t prev_size = base_head->size;
#endif

        // remove the data from the data_list
        tb_list_entry_remove(&allocator->data_list, &data_head->entry);
        removed = tb_true;

        // ralloc data
        data = (tb_byte_t*)tb_native_memory_ralloc(data_head, need);
        tb_assert_and_check_break(data);
        tb_assert_and_check_break(!(((tb_size_t)data) & 0x1));

        // update the real data
        data_real = (tb_byte_t*)data + sizeof(tb_native_large_data_head_t);

        // update the data head
        data_head = (tb_native_large_data_head_t*)data;

        // update the base head
        base_head = tb_native_large_allocator_data_base(data_head);

        // save the real size
        base_head->size = (tb_uint32_t)size;

#ifdef __tb_debug__
        base_head->debug.file      = file_;
        base_head->debug.func      = func_;
        base_head->debug.line      = (tb_uint16_t)line_;

        // check
        tb_assertf(base_head->debug.magic == TB_POOL_DATA_MAGIC, "ralloc data have been changed: %p", data);

        // update backtrace
        tb_pool_data_save_backtrace(&base_head->debug, 5);

        // make the dirty data 
        if (size > prev_size) tb_memset_(data_real + prev_size, TB_POOL_DATA_PATCH, size - prev_size);

        // patch 0xcc for checking underflow
        data_real[size] = TB_POOL_DATA_PATCH;
#endif

        // save the data to the data_list
        tb_list_entry_insert_tail(&allocator->data_list, &data_head->entry);
        removed = tb_false;

        // save the real size
        if (real) *real = size;

#ifdef __tb_debug__
        // update the real size
        allocator->real_size     += size;

        // update the occupied size
        allocator->occupied_size += size;

        // update the total size
        allocator->total_size    += size;

        // update the peak size
        if (allocator->total_size > allocator->peak_size) allocator->peak_size = allocator->total_size;

        // update the ralloc count
        allocator->ralloc_count++;
#endif

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // restore data to data_list
        if (data_head && removed) tb_list_entry_insert_tail(&allocator->data_list, &data_head->entry);

        // clear it
        data = tb_null;
        data_real = tb_null;
    }

    // ok?
    return (tb_pointer_t)data_real;
}
static tb_bool_t tb_native_large_allocator_free(tb_allocator_ref_t self, tb_pointer_t data __tb_debug_decl__)
{
    // check
    tb_native_large_allocator_ref_t allocator = (tb_native_large_allocator_ref_t)self;
    tb_assert_and_check_return_val(allocator && data, tb_false);

    // done
    tb_bool_t                       ok = tb_false;
    tb_native_large_data_head_t*    data_head = tb_null;
    do
    {
        // the data head
        data_head = &(((tb_native_large_data_head_t*)data)[-1]);

#ifdef __tb_debug__
        // the base head
        tb_pool_data_head_t* base_head = tb_native_large_allocator_data_base(data_head);
#endif

        // check
        tb_assertf(base_head->debug.magic != (tb_uint16_t)~TB_POOL_DATA_MAGIC, "double free data: %p", data);
        tb_assertf(base_head->debug.magic == TB_POOL_DATA_MAGIC, "free invalid data: %p", data);
        tb_assertf_and_check_break(data_head->allocator == (tb_pointer_t)allocator, "the data: %p not belong to allocator: %p", data, allocator);
        tb_assertf(((tb_byte_t*)data)[base_head->size] == TB_POOL_DATA_PATCH, "data underflow");

#ifdef __tb_debug__
        // check the last data
        tb_native_large_allocator_check_last(allocator);

        // check the prev data
        tb_native_large_allocator_check_prev(allocator, data_head);

        // check the next data
        tb_native_large_allocator_check_next(allocator, data_head);

        // for checking double-free
        base_head->debug.magic = (tb_uint16_t)~TB_POOL_DATA_MAGIC;

        // update the total size
        allocator->total_size    -= base_head->size;
   
        // update the free count
        allocator->free_count++;
#endif

        // remove the data from the data_list
        tb_list_entry_remove(&allocator->data_list, &data_head->entry);

        // free it
        tb_native_memory_free(data_head);

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
static tb_void_t tb_native_large_allocator_clear(tb_allocator_ref_t self)
{
    // check
    tb_native_large_allocator_ref_t allocator = (tb_native_large_allocator_ref_t)self;
    tb_assert_and_check_return(allocator);

    // done
    do
    {
        // the iterator
        tb_iterator_ref_t iterator = tb_list_entry_itor(&allocator->data_list);
        tb_assert_and_check_break(iterator);

        // walk it
        tb_size_t itor = tb_iterator_head(iterator);
        while (itor != tb_iterator_tail(iterator))
        {
            // the data head
            tb_native_large_data_head_t* data_head = (tb_native_large_data_head_t*)tb_iterator_item(iterator, itor);
            tb_assert_and_check_break(data_head);

            // save next
            tb_size_t next = tb_iterator_next(iterator, itor);

            // exit data
            tb_native_large_allocator_free(self, (tb_pointer_t)&data_head[1] __tb_debug_vals__);

            // next
            itor = next;
        }

    } while (0);

    // clear info
#ifdef __tb_debug__
    allocator->peak_size     = 0;
    allocator->total_size    = 0;
    allocator->real_size     = 0;
    allocator->occupied_size = 0;
    allocator->malloc_count  = 0;
    allocator->ralloc_count  = 0;
    allocator->free_count    = 0;
#endif
}
static tb_void_t tb_native_large_allocator_exit(tb_allocator_ref_t self)
{
    // check
    tb_native_large_allocator_ref_t allocator = (tb_native_large_allocator_ref_t)self;
    tb_assert_and_check_return(allocator);

    // exit lock
    tb_spinlock_exit(&allocator->base.lock);

    // exit it
    tb_native_memory_free(allocator);
}
#ifdef __tb_debug__
static tb_void_t tb_native_large_allocator_dump(tb_allocator_ref_t self)
{
    // check
    tb_native_large_allocator_ref_t allocator = (tb_native_large_allocator_ref_t)self;
    tb_assert_and_check_return(allocator);

    // trace
    tb_trace_i("");

    // exit all data_list
    tb_for_all_if (tb_native_large_data_head_t*, data_head, tb_list_entry_itor(&allocator->data_list), data_head)
    {
        // check it
        tb_native_large_allocator_check_data(allocator, data_head);

        // trace
        tb_trace_e("leak: %p", &data_head[1]);

        // dump data
        tb_pool_data_dump((tb_byte_t const*)&data_head[1], tb_false, "[native_large_allocator]: [error]: ");
    }

    // trace debug info
    tb_trace_i("peak_size: %lu",            allocator->peak_size);
    tb_trace_i("wast_rate: %llu/10000",     allocator->occupied_size? (((tb_hize_t)allocator->occupied_size - allocator->real_size) * 10000) / (tb_hize_t)allocator->occupied_size : 0);
    tb_trace_i("free_count: %lu",           allocator->free_count);
    tb_trace_i("malloc_count: %lu",         allocator->malloc_count);
    tb_trace_i("ralloc_count: %lu",         allocator->ralloc_count);
}
static tb_bool_t tb_native_large_allocator_have(tb_allocator_ref_t self, tb_cpointer_t data)
{
    // check
    tb_native_large_allocator_ref_t allocator = (tb_native_large_allocator_ref_t)self;
    tb_assert_and_check_return_val(allocator, tb_false);

    /* always ok for checking memory
     *
     * TODO: need better implementation for distinguishing it
     */
    return tb_true;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_allocator_ref_t tb_native_large_allocator_init()
{
    // done
    tb_bool_t                           ok = tb_false;
    tb_native_large_allocator_ref_t     allocator = tb_null;
    do
    {
        // check
        tb_assert_static(!(sizeof(tb_native_large_data_head_t) & (TB_POOL_DATA_ALIGN - 1)));

        // make allocator
        allocator = (tb_native_large_allocator_ref_t)tb_native_memory_malloc0(sizeof(tb_native_large_allocator_t));
        tb_assert_and_check_break(allocator);

        // init base
        allocator->base.type             = TB_ALLOCATOR_TYPE_LARGE;
        allocator->base.flag             = TB_ALLOCATOR_FLAG_NONE;
        allocator->base.large_malloc     = tb_native_large_allocator_malloc;
        allocator->base.large_ralloc     = tb_native_large_allocator_ralloc;
        allocator->base.large_free       = tb_native_large_allocator_free;
        allocator->base.clear            = tb_native_large_allocator_clear;
        allocator->base.exit             = tb_native_large_allocator_exit;
#ifdef __tb_debug__
        allocator->base.dump             = tb_native_large_allocator_dump;
        allocator->base.have             = tb_native_large_allocator_have;
#endif

        // init lock
        if (!tb_spinlock_init(&allocator->base.lock)) break;

        // init data_list
        tb_list_entry_init(&allocator->data_list, tb_native_large_data_head_t, entry, tb_null);

        // register lock profiler
#ifdef TB_LOCK_PROFILER_ENABLE
        tb_lock_profiler_register(tb_lock_profiler(), (tb_pointer_t)&allocator->base.lock, TB_TRACE_MODULE_NAME);
#endif

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (allocator) tb_native_large_allocator_exit((tb_allocator_ref_t)allocator);
        allocator = tb_null;
    }

    // ok?
    return (tb_allocator_ref_t)allocator;
}

