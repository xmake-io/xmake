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
 * @file        small_allocator.c
 * @ingroup     memory
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "small_allocator"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "small_allocator.h"
#include "large_allocator.h"
#include "fixed_pool.h"
#include "impl/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the small allocator type
typedef struct __tb_small_allocator_t
{
    // the base
    tb_allocator_t          base;

    // the large allocator
    tb_allocator_ref_t      large_allocator;

    // the fixed pool
    tb_fixed_pool_ref_t     fixed_pool[12];

}tb_small_allocator_t, *tb_small_allocator_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */
__tb_extern_c__ tb_fixed_pool_ref_t tb_fixed_pool_init_(tb_allocator_ref_t large_allocator, tb_size_t slot_size, tb_size_t item_size, tb_bool_t for_small_allocator, tb_fixed_pool_item_init_func_t item_init, tb_fixed_pool_item_exit_func_t item_exit, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_fixed_pool_ref_t tb_small_allocator_find_fixed(tb_small_allocator_ref_t allocator, tb_size_t size)
{
    // check
    tb_assert(allocator && size && size <= TB_SMALL_ALLOCATOR_DATA_MAXN);

    // done
    tb_fixed_pool_ref_t fixed_pool = tb_null;
    do
    {
        // the fixed pool index
        tb_size_t index = 0;
        tb_size_t space = 0;
        if (size > 64 && size < 193)
        {
            if (size < 97)
            {
                index = 3;
                space = 96;
            }
            else if (size > 128)
            {
                index = 5;
                space = 192;
            }
            else 
            {
                index = 4;
                space = 128;
            }
        }
        else if (size > 192 && size < 513)
        {
            if (size < 257)
            {
                index = 6;
                space = 256;
            }
            else if (size > 384)
            {
                index = 8;
                space = 512;
            }
            else 
            {
                index = 7;
                space = 384;
            }
        }
        else if (size < 65)
        {
            if (size < 17)
            {
                index = 0;
                space = 16;
            }
            else if (size > 32)
            {
                index = 2;
                space = 64;
            }
            else 
            {
                index = 1;
                space = 32;
            }
        }
        else 
        {
            if (size < 1025)
            {
                index = 9;
                space = 1024;
            }
            else if (size > 2048)
            {
                index = 11;
                space = 3072;
            }
            else 
            {
                index = 10;
                space = 2048;
            }
        }

        // trace
        tb_trace_d("find: size: %lu => index: %lu, space: %lu", size, index, space);

        // make fixed pool if not exists
        if (!allocator->fixed_pool[index]) allocator->fixed_pool[index] = tb_fixed_pool_init_(allocator->large_allocator, 0, space, tb_true, tb_null, tb_null, tb_null);
        tb_assert_and_check_break(allocator->fixed_pool[index]);

        // ok
        fixed_pool = allocator->fixed_pool[index];

    } while (0);

    // ok?
    return fixed_pool;
}
#ifdef __tb_debug__
static tb_bool_t tb_small_allocator_item_check(tb_pointer_t data, tb_cpointer_t priv)
{
    // check
    tb_fixed_pool_ref_t fixed_pool = (tb_fixed_pool_ref_t)priv;
    tb_assert(fixed_pool && data);

    // done 
    tb_bool_t ok = tb_false;
    do
    {
        // the data head
        tb_pool_data_head_t* data_head = &(((tb_pool_data_head_t*)data)[-1]);
        tb_assertf(data_head->debug.magic == TB_POOL_DATA_MAGIC, "invalid data: %p", data);

        // the data space
        tb_size_t space = tb_fixed_pool_item_size(fixed_pool);
        tb_assert_and_check_break(space >= data_head->size);

        // check underflow
        tb_assertf(space == data_head->size || ((tb_byte_t*)data)[data_head->size] == TB_POOL_DATA_PATCH, "data underflow");

        // ok
        ok = tb_true;

    } while (0);

    // continue?
    return ok;
}
#endif
static tb_void_t tb_small_allocator_exit(tb_allocator_ref_t self)
{
    // check
    tb_small_allocator_ref_t allocator = (tb_small_allocator_ref_t)self;
    tb_assert_and_check_return(allocator && allocator->large_allocator);

    // enter
    tb_spinlock_enter(&allocator->base.lock);

    // exit fixed pool
    tb_size_t i = 0;
    tb_size_t n = tb_arrayn(allocator->fixed_pool);
    for (i = 0; i < n; i++)
    {
        // exit it
        if (allocator->fixed_pool[i]) tb_fixed_pool_exit(allocator->fixed_pool[i]);
        allocator->fixed_pool[i] = tb_null;
    }

    // leave
    tb_spinlock_leave(&allocator->base.lock);

    // exit lock
    tb_spinlock_exit(&allocator->base.lock);

    // exit pool
    tb_allocator_large_free(allocator->large_allocator, allocator);
}
static tb_void_t tb_small_allocator_clear(tb_allocator_ref_t self)
{
    // check
    tb_small_allocator_ref_t allocator = (tb_small_allocator_ref_t)self;
    tb_assert_and_check_return(allocator && allocator->large_allocator);

    // clear fixed pool
    tb_size_t i = 0;
    tb_size_t n = tb_arrayn(allocator->fixed_pool);
    for (i = 0; i < n; i++)
    {
        // clear it
        if (allocator->fixed_pool[i]) tb_fixed_pool_clear(allocator->fixed_pool[i]);
    }
}
static tb_pointer_t tb_small_allocator_malloc(tb_allocator_ref_t self, tb_size_t size __tb_debug_decl__)
{
    // check
    tb_small_allocator_ref_t allocator = (tb_small_allocator_ref_t)self;
    tb_assert_and_check_return_val(allocator && allocator->large_allocator && size, tb_null);
    tb_assert_and_check_return_val(size <= TB_SMALL_ALLOCATOR_DATA_MAXN, tb_null);

    // done
    tb_pointer_t data = tb_null;
    do
    {
        // the fixed pool
        tb_fixed_pool_ref_t fixed_pool = tb_small_allocator_find_fixed(allocator, size);
        tb_assert_and_check_break(fixed_pool);

        // done
        data = tb_fixed_pool_malloc_(fixed_pool __tb_debug_args__);
        tb_assert_and_check_break(data);

        // the data head
        tb_pool_data_head_t* data_head = &(((tb_pool_data_head_t*)data)[-1]);
        tb_assert(data_head->debug.magic == TB_POOL_DATA_MAGIC);

#ifdef __tb_debug__
        // fill the patch bytes
        if (data_head->size > size) tb_memset_((tb_byte_t*)data + size, TB_POOL_DATA_PATCH, data_head->size - size);
#endif

        // update size
        data_head->size = size;

    } while (0);

    // check
    tb_assertf(data, "malloc(%lu) failed!", size);

    // ok?
    return data;
}
static tb_pointer_t tb_small_allocator_ralloc(tb_allocator_ref_t self, tb_pointer_t data, tb_size_t size __tb_debug_decl__)
{
    // check
    tb_small_allocator_ref_t allocator = (tb_small_allocator_ref_t)self;
    tb_assert_and_check_return_val(allocator && allocator->large_allocator && data && size, tb_null);
    tb_assert_and_check_return_val(size <= TB_SMALL_ALLOCATOR_DATA_MAXN, tb_null);

    // done
    tb_pointer_t data_new = tb_null;
    do
    {
        // the old data head
        tb_pool_data_head_t* data_head_old = &(((tb_pool_data_head_t*)data)[-1]);
        tb_assertf(data_head_old->debug.magic == TB_POOL_DATA_MAGIC, "ralloc invalid data: %p", data);

        // the old fixed pool
        tb_fixed_pool_ref_t fixed_pool_old = tb_small_allocator_find_fixed(allocator, data_head_old->size);
        tb_assert_and_check_break(fixed_pool_old);

        // the old data space
        tb_size_t space_old = tb_fixed_pool_item_size(fixed_pool_old);
        tb_assert_and_check_break(space_old >= data_head_old->size);

        // check underflow
        tb_assertf(space_old == data_head_old->size || ((tb_byte_t*)data)[data_head_old->size] == TB_POOL_DATA_PATCH, "data underflow");

        // the new fixed pool
        tb_fixed_pool_ref_t fixed_pool_new = tb_small_allocator_find_fixed(allocator, size);
        tb_assert_and_check_break(fixed_pool_new);

        // same space?
        if (fixed_pool_old == fixed_pool_new) 
        {
#ifdef __tb_debug__
            // fill the patch bytes
            if (data_head_old->size > size) tb_memset_((tb_byte_t*)data + size, TB_POOL_DATA_PATCH, data_head_old->size - size);
#endif
            // only update size
            data_head_old->size = size;

            // ok
            data_new = data;
            break;
        }

        // make the new data
        data_new = tb_fixed_pool_malloc_(fixed_pool_new __tb_debug_args__);
        tb_assert_and_check_break(data_new);

        // the new data head
        tb_pool_data_head_t* data_head_new = &(((tb_pool_data_head_t*)data_new)[-1]);
        tb_assert(data_head_new->debug.magic == TB_POOL_DATA_MAGIC);

#ifdef __tb_debug__
        // fill the patch bytes
        if (data_head_new->size > size) tb_memset_((tb_byte_t*)data_new + size, TB_POOL_DATA_PATCH, data_head_new->size - size);
#endif

        // update size
        data_head_new->size = size;

        // copy the old data
        tb_memcpy_(data_new, data, tb_min(data_head_old->size, size));

        // free the old data
        tb_fixed_pool_free_(fixed_pool_old, data __tb_debug_args__);

    } while (0);

    // ok
    return data_new;
}
static tb_bool_t tb_small_allocator_free(tb_allocator_ref_t self, tb_pointer_t data __tb_debug_decl__)
{
    // check
    tb_small_allocator_ref_t allocator = (tb_small_allocator_ref_t)self;
    tb_assert_and_check_return_val(allocator && allocator->large_allocator && data, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // the data head
        tb_pool_data_head_t* data_head = &(((tb_pool_data_head_t*)data)[-1]);
        tb_assertf(data_head->debug.magic == TB_POOL_DATA_MAGIC, "free invalid data: %p", data);

        // the fixed pool
        tb_fixed_pool_ref_t fixed_pool = tb_small_allocator_find_fixed(allocator, data_head->size);
        tb_assert_and_check_break(fixed_pool);

        // the data space
        tb_size_t space = tb_fixed_pool_item_size(fixed_pool);
        tb_assert_and_check_break(space >= data_head->size);

        // check underflow
        tb_assertf(space == data_head->size || ((tb_byte_t*)data)[data_head->size] == TB_POOL_DATA_PATCH, "data underflow");

        // done
        ok = tb_fixed_pool_free_(fixed_pool, data __tb_debug_args__);

    } while (0);

    // ok?
    return ok;
}
#ifdef __tb_debug__
static tb_void_t tb_small_allocator_dump(tb_allocator_ref_t self)
{
    // check
    tb_small_allocator_ref_t allocator = (tb_small_allocator_ref_t)self;
    tb_assert_and_check_return(allocator && allocator->large_allocator);

    // trace
    tb_trace_i("");

    // dump fixed pool
    tb_size_t i = 0;
    tb_size_t n = tb_arrayn(allocator->fixed_pool);
    for (i = 0; i < n; i++)
    {
        // exists?
        if (allocator->fixed_pool[i]) 
        {
            // check it
            tb_fixed_pool_walk(allocator->fixed_pool[i], tb_small_allocator_item_check, (tb_cpointer_t)allocator->fixed_pool[i]);

            // dump it
            tb_fixed_pool_dump(allocator->fixed_pool[i]);
        }
    }
}static tb_bool_t tb_small_allocator_have(tb_allocator_ref_t self, tb_cpointer_t data)
{
    // check
    tb_small_allocator_ref_t allocator = (tb_small_allocator_ref_t)self;
    tb_assert_and_check_return_val(allocator && allocator->large_allocator, tb_false);

    // have it?
    return tb_allocator_have(allocator->large_allocator, data);
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_allocator_ref_t tb_small_allocator_init(tb_allocator_ref_t large_allocator)
{
    // done
    tb_bool_t                   ok = tb_false;
    tb_small_allocator_ref_t    allocator = tb_null;
    do
    {
        // no allocator? uses the global allocator
        if (!large_allocator) large_allocator = tb_allocator();
        tb_assert_and_check_break(large_allocator);

        // make allocator
        allocator = (tb_small_allocator_ref_t)tb_allocator_large_malloc0(large_allocator, sizeof(tb_small_allocator_t), tb_null);
        tb_assert_and_check_break(allocator);

        // init large allocator
        allocator->large_allocator      = large_allocator;

        // init base
        allocator->base.type            = TB_ALLOCATOR_TYPE_SMALL;
        allocator->base.flag            = TB_ALLOCATOR_FLAG_NONE;
        allocator->base.malloc          = tb_small_allocator_malloc;
        allocator->base.ralloc          = tb_small_allocator_ralloc;
        allocator->base.free            = tb_small_allocator_free;
        allocator->base.clear           = tb_small_allocator_clear;
        allocator->base.exit            = tb_small_allocator_exit;
#ifdef __tb_debug__
        allocator->base.dump            = tb_small_allocator_dump;
        allocator->base.have            = tb_small_allocator_have;
#endif

        // init lock
        if (!tb_spinlock_init(&allocator->base.lock)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        if (allocator) tb_small_allocator_exit((tb_allocator_ref_t)allocator);
        allocator = tb_null;
    }

    // ok?
    return (tb_allocator_ref_t)allocator;
}

