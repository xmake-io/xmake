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
 * @file        allocator.c
 * @ingroup     memory
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "allocator"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "allocator.h"
#include "impl/impl.h"
#include "../libc/libc.h"
#include "../utils/utils.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the allocator 
__tb_extern_c__ tb_allocator_ref_t  g_allocator = tb_null;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_allocator_ref_t tb_allocator()
{
    return g_allocator;
}
tb_size_t tb_allocator_type(tb_allocator_ref_t allocator)
{
    // check
    tb_assert_and_check_return_val(allocator, TB_ALLOCATOR_TYPE_DEFAULT);

    // get it
    return (tb_size_t)allocator->type;
}
tb_pointer_t tb_allocator_malloc_(tb_allocator_ref_t allocator, tb_size_t size __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // enter
    tb_bool_t lockit = !(allocator->flag & TB_ALLOCATOR_FLAG_NOLOCK);
    if (lockit) tb_spinlock_enter(&allocator->lock);

    // malloc it
    tb_pointer_t data = tb_null;
    if (allocator->malloc) data = allocator->malloc(allocator, size __tb_debug_args__);
    else if (allocator->large_malloc) data = allocator->large_malloc(allocator, size, tb_null __tb_debug_args__);

    // trace
    tb_trace_d("malloc(%lu): %p at %s(): %d, %s", size, data __tb_debug_args__);

    // check
    tb_assertf(data, "malloc(%lu) failed!", size);
    tb_assertf(!(((tb_size_t)data) & (TB_POOL_DATA_ALIGN - 1)), "malloc(%lu): unaligned data: %p", size, data);

    // leave
    if (lockit) tb_spinlock_leave(&allocator->lock);

    // ok?
    return data;
}
tb_pointer_t tb_allocator_malloc0_(tb_allocator_ref_t allocator, tb_size_t size __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // malloc it
    tb_pointer_t data = tb_allocator_malloc_(allocator, size __tb_debug_args__);

    // clear it
    if (data) tb_memset_(data, 0, size);

    // ok?
    return data;
}
tb_pointer_t tb_allocator_nalloc_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // nalloc it
    return tb_allocator_malloc_(allocator, item * size __tb_debug_args__);
}
tb_pointer_t tb_allocator_nalloc0_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // nalloc0 it
    tb_pointer_t data = tb_allocator_malloc_(allocator, item * size __tb_debug_args__);

    // clear it
    if (data) tb_memset_(data, 0, item * size);

    // ok?
    return data;
}
tb_pointer_t tb_allocator_ralloc_(tb_allocator_ref_t allocator, tb_pointer_t data, tb_size_t size __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // enter
    tb_bool_t lockit = !(allocator->flag & TB_ALLOCATOR_FLAG_NOLOCK);
    if (lockit) tb_spinlock_enter(&allocator->lock);

    // ralloc it
    tb_pointer_t data_new = tb_null;
    if (allocator->ralloc) data_new = allocator->ralloc(allocator, data, size __tb_debug_args__);
    else if (allocator->large_ralloc) data_new = allocator->large_ralloc(allocator, data, size, tb_null __tb_debug_args__);

    // trace
    tb_trace_d("ralloc(%p, %lu): %p at %s(): %d, %s", data, size, data_new __tb_debug_args__);

    // failed? dump it
#ifdef __tb_debug__
    if (!data_new) 
    {
        // trace
        tb_trace_e("ralloc(%p, %lu) failed! at %s(): %lu, %s", data, size, func_, line_, file_);

        // dump data
        tb_pool_data_dump((tb_byte_t const*)data, tb_true, "[large_allocator]: [error]: ");

        // abort
        tb_abort();
    }
#endif

    // check
    tb_assertf(!(((tb_size_t)data_new) & (TB_POOL_DATA_ALIGN - 1)), "ralloc(%lu): unaligned data: %p", size, data);

    // leave
    if (lockit) tb_spinlock_leave(&allocator->lock);

    // ok?
    return data_new;
}
tb_bool_t tb_allocator_free_(tb_allocator_ref_t allocator, tb_pointer_t data __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_false);

    // enter
    tb_bool_t lockit = !(allocator->flag & TB_ALLOCATOR_FLAG_NOLOCK);
    if (lockit) tb_spinlock_enter(&allocator->lock);

    // trace
    tb_trace_d("free(%p): at %s(): %d, %s", data __tb_debug_args__);

    // free it
    tb_bool_t ok = tb_false;
    if (allocator->free) ok = allocator->free(allocator, data __tb_debug_args__);
    else if (allocator->large_free) ok = allocator->large_free(allocator, data __tb_debug_args__);

    // failed? dump it
#ifdef __tb_debug__
    if (!ok) 
    {
        // trace
        tb_trace_e("free(%p) failed! at %s(): %lu, %s", data, func_, line_, file_);

        // dump data
        tb_pool_data_dump((tb_byte_t const*)data, tb_true, "[large_allocator]: [error]: ");

        // abort
        tb_abort();
    }
#endif

    // leave
    if (lockit) tb_spinlock_leave(&allocator->lock);

    // ok?
    return ok;
}
tb_pointer_t tb_allocator_large_malloc_(tb_allocator_ref_t allocator, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // enter
    tb_bool_t lockit = !(allocator->flag & TB_ALLOCATOR_FLAG_NOLOCK);
    if (lockit) tb_spinlock_enter(&allocator->lock);

    // malloc it
    tb_pointer_t data = tb_null;
    if (allocator->large_malloc) data = allocator->large_malloc(allocator, size, real __tb_debug_args__);
    else if (allocator->malloc)
    {
        // malloc it
        if (real) *real = size;
        data = allocator->malloc(allocator, size __tb_debug_args__);
    }

    // trace
    tb_trace_d("large_malloc(%lu): %p at %s(): %d, %s", size, data __tb_debug_args__);

    // check
    tb_assertf(data, "malloc(%lu) failed!", size);
    tb_assertf(!(((tb_size_t)data) & (TB_POOL_DATA_ALIGN - 1)), "malloc(%lu): unaligned data: %p", size, data);
    tb_assert(!real || *real >= size);

    // leave
    if (lockit) tb_spinlock_leave(&allocator->lock);

    // ok?
    return data;
}
tb_pointer_t tb_allocator_large_malloc0_(tb_allocator_ref_t allocator, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // malloc it
    tb_pointer_t data = tb_allocator_large_malloc_(allocator, size, real __tb_debug_args__);

    // clear it
    if (data) tb_memset_(data, 0, real? *real : size);

    // ok
    return data;
}
tb_pointer_t tb_allocator_large_nalloc_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // malloc it
    return tb_allocator_large_malloc_(allocator, item * size, real __tb_debug_args__);
}
tb_pointer_t tb_allocator_large_nalloc0_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // malloc it
    tb_pointer_t data = tb_allocator_large_malloc_(allocator, item * size, real __tb_debug_args__);

    // clear it
    if (data) tb_memset_(data, 0, real? *real : (item * size));

    // ok
    return data;
}
tb_pointer_t tb_allocator_large_ralloc_(tb_allocator_ref_t allocator, tb_pointer_t data, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_null);

    // enter
    tb_bool_t lockit = !(allocator->flag & TB_ALLOCATOR_FLAG_NOLOCK);
    if (lockit) tb_spinlock_enter(&allocator->lock);

    // ralloc it
    tb_pointer_t data_new = tb_null;
    if (allocator->large_ralloc) data_new = allocator->large_ralloc(allocator, data, size, real __tb_debug_args__);
    else if (allocator->ralloc)
    {
        // ralloc it
        if (real) *real = size;
        data_new = allocator->ralloc(allocator, data, size __tb_debug_args__);
    }

    // trace
    tb_trace_d("large_ralloc(%p, %lu): %p at %s(): %d, %s", data, size, data_new __tb_debug_args__);

    // failed? dump it
#ifdef __tb_debug__
    if (!data_new) 
    {
        // trace
        tb_trace_e("ralloc(%p, %lu) failed! at %s(): %lu, %s", data, size, func_, line_, file_);

        // dump data
        tb_pool_data_dump((tb_byte_t const*)data, tb_true, "[large_allocator]: [error]: ");

        // abort
        tb_abort();
    }
#endif

    // check
    tb_assert(!real || *real >= size);
    tb_assertf(!(((tb_size_t)data_new) & (TB_POOL_DATA_ALIGN - 1)), "ralloc(%lu): unaligned data: %p", size, data);

    // leave
    if (lockit) tb_spinlock_leave(&allocator->lock);

    // ok?
    return data_new;
}
tb_bool_t tb_allocator_large_free_(tb_allocator_ref_t allocator, tb_pointer_t data __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_false);

    // enter
    tb_bool_t lockit = !(allocator->flag & TB_ALLOCATOR_FLAG_NOLOCK);
    if (lockit) tb_spinlock_enter(&allocator->lock);

    // trace
    tb_trace_d("large_free(%p): at %s(): %d, %s", data __tb_debug_args__);

    // free it
    tb_bool_t ok = tb_false;
    if (allocator->large_free) ok = allocator->large_free(allocator, data __tb_debug_args__);
    else if (allocator->free) ok = allocator->free(allocator, data __tb_debug_args__);

    // failed? dump it
#ifdef __tb_debug__
    if (!ok) 
    {
        // trace
        tb_trace_e("free(%p) failed! at %s(): %lu, %s", data, func_, line_, file_);

        // dump data
        tb_pool_data_dump((tb_byte_t const*)data, tb_true, "[large_allocator]: [error]: ");

        // abort
        tb_abort();
    }
#endif

    // leave
    if (lockit) tb_spinlock_leave(&allocator->lock);

    // ok?
    return ok;
}
tb_pointer_t tb_allocator_align_malloc_(tb_allocator_ref_t allocator, tb_size_t size, tb_size_t align __tb_debug_decl__)
{
    // check
    tb_assertf(!(align & 3), "invalid alignment size: %lu", align);
    tb_check_return_val(!(align & 3), tb_null);

    // malloc it
    tb_byte_t* data = (tb_byte_t*)tb_allocator_malloc_(allocator, size + align __tb_debug_args__);
    tb_check_return_val(data, tb_null);

    // the different bytes
    tb_byte_t diff = (tb_byte_t)((~(tb_long_t)data) & (align - 1)) + 1;

    // adjust the address
    data += diff;

    // check
    tb_assert(!((tb_size_t)data & (align - 1)));

    // save the different bytes
    data[-1] = diff;

    // ok?
    return (tb_pointer_t)data;
}
tb_pointer_t tb_allocator_align_malloc0_(tb_allocator_ref_t allocator, tb_size_t size, tb_size_t align __tb_debug_decl__)
{
    // malloc it
    tb_pointer_t data = tb_allocator_align_malloc_(allocator, size, align __tb_debug_args__);
    tb_assert_and_check_return_val(data, tb_null);

    // clear it
    tb_memset(data, 0, size);

    // ok
    return data;
}
tb_pointer_t tb_allocator_align_nalloc_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size, tb_size_t align __tb_debug_decl__)
{
    return tb_allocator_align_malloc_(allocator, item * size, align __tb_debug_args__);
}
tb_pointer_t tb_allocator_align_nalloc0_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size, tb_size_t align __tb_debug_decl__)
{
    // nalloc it
    tb_pointer_t data = tb_allocator_align_nalloc_(allocator, item, size, align __tb_debug_args__);
    tb_assert_and_check_return_val(data, tb_null);

    // clear it
    tb_memset(data, 0, item * size);

    // ok
    return data;
}
tb_pointer_t tb_allocator_align_ralloc_(tb_allocator_ref_t allocator, tb_pointer_t data, tb_size_t size, tb_size_t align __tb_debug_decl__)
{
    // check align
    tb_assertf(!(align & 3), "invalid alignment size: %lu", align);
    tb_check_return_val(!(align & 3), tb_null);

    // ralloc?
    tb_byte_t diff = 0;
    if (data)
    {
        // check address 
        tb_assertf(!((tb_size_t)data & (align - 1)), "invalid address %p", data);
        tb_check_return_val(!((tb_size_t)data & (align - 1)), tb_null);

        // the different bytes
        diff = ((tb_byte_t*)data)[-1];

        // adjust the address
        data = (tb_byte_t*)data - diff;

        // ralloc it
        data = tb_allocator_ralloc_(allocator, data, size + align __tb_debug_args__);
        tb_check_return_val(data, tb_null);
    }
    // no data?
    else
    {
        // malloc it directly
        data = tb_allocator_malloc_(allocator, size + align __tb_debug_args__);
        tb_check_return_val(data, tb_null);
    }

    // the different bytes
    diff = (tb_byte_t)((~(tb_long_t)data) & (align - 1)) + 1;

    // adjust the address
    data = (tb_byte_t*)data + diff;

    // check
    tb_assert(!((tb_size_t)data & (align - 1)));

    // save the different bytes
    ((tb_byte_t*)data)[-1] = diff;

    // ok?
    return data;
}
tb_bool_t tb_allocator_align_free_(tb_allocator_ref_t allocator, tb_pointer_t data __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(data, tb_false);
    tb_assert(!((tb_size_t)data & 3));

    // the different bytes
    tb_byte_t diff = ((tb_byte_t*)data)[-1];

    // adjust the address
    data = (tb_byte_t*)data - diff;

    // free it
    return tb_allocator_free_(allocator, data __tb_debug_args__);
}
tb_void_t tb_allocator_clear(tb_allocator_ref_t allocator)
{
    // check
    tb_assert_and_check_return(allocator);

    // enter
    tb_bool_t lockit = !(allocator->flag & TB_ALLOCATOR_FLAG_NOLOCK);
    if (lockit) tb_spinlock_enter(&allocator->lock);

    // clear it
    if (allocator->clear) allocator->clear(allocator);

    // leave
    if (lockit) tb_spinlock_leave(&allocator->lock);
}
tb_void_t tb_allocator_exit(tb_allocator_ref_t allocator)
{
    // check
    tb_assert_and_check_return(allocator);

    // clear it first
    tb_allocator_clear(allocator);

    // exit it
    if (allocator->exit) allocator->exit(allocator);
}
#ifdef __tb_debug__
tb_void_t tb_allocator_dump(tb_allocator_ref_t allocator)
{
    // check
    tb_assert_and_check_return(allocator);

    // enter
    tb_bool_t lockit = !(allocator->flag & TB_ALLOCATOR_FLAG_NOLOCK);
    if (lockit) tb_spinlock_enter(&allocator->lock);

    // dump it
    if (allocator->dump) allocator->dump(allocator);

    // leave
    if (lockit) tb_spinlock_leave(&allocator->lock);
}
tb_bool_t tb_allocator_have(tb_allocator_ref_t allocator, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return_val(allocator, tb_false);

    /* have it?
     * 
     * @note cannot use locker and ensure thread safe
     */
    return allocator->have? allocator->have(allocator, data) : tb_false;
}
#endif
