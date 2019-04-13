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
 * @file        static_large_allocator.c
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "static_large_allocator"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "static_large_allocator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the static large allocator data size
#define tb_static_large_allocator_data_base(data_head)   (&(((tb_pool_data_head_t*)((tb_static_large_data_head_t*)(data_head) + 1))[-1]))

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the static large data head type
typedef __tb_pool_data_aligned__ struct __tb_static_large_data_head_t
{
    // the data space size: the allocated size + left size
    tb_uint32_t                     space : 31;

    // is free?
    tb_uint32_t                     bfree : 1;

    /* patch 4 bytes for align(8) for tinycc/x86_64
     * 
     * __tb_aligned__(8) struct doesn't seem to work 
     */
#if defined(TB_COMPILER_IS_TINYC) && defined(TB_CPU_BIT64)
    tb_uint32_t                     padding;
#endif

    // the data head base
    tb_byte_t                       base[sizeof(tb_pool_data_head_t)];

}__tb_pool_data_aligned__ tb_static_large_data_head_t;

// the static large data pred type
typedef struct __tb_static_large_data_pred_t
{
    // the data head
    tb_static_large_data_head_t*    data_head;

#ifdef __tb_debug__
    // the total count
    tb_size_t                       total_count;

    // the failed count
    tb_size_t                       failed_count;
#endif

}tb_static_large_data_pred_t;

/*! the static large allocator type
 *
 * <pre>
 *
 * .e.g page_size == 4KB
 *
 *        --------------------------------------------------------------------------
 *       |                                     data                                 |
 *        --------------------------------------------------------------------------
 *                                              |
 *        --------------------------------------------------------------------------
 *       | head | 4KB | 16KB | 8KB | 128KB | ... | 32KB |       ...       |  4KB*N  |
 *        --------------------------------------------------------------------------
 *                       |                       |               |
 *                       |                       `---------------`
 *                       |                        merge free space when alloc or free
 *                       |
 *        ------------------------------------------
 *       | tb_static_large_data_head_t | data space |
 *        ------------------------------------------
 *                                                
 *        --------------------------------------
 * pred: | >0KB :      4KB       | > 0*page     | 1
 *       |-----------------------|--------------
 *       | >4KB :      8KB       | > 1*page     | 2
 *       |-----------------------|--------------
 *       | >8KB :    12-16KB     | > 2*page     | 3-4
 *       |-----------------------|--------------
 *       | >16KB :   20-32KB     | > 4*page     | 5-8
 *       |-----------------------|--------------
 *       | >32KB :   36-64KB     | > 8*page     | 9-16
 *       |-----------------------|--------------
 *       | >64KB :   68-128KB    | > 16*page    | 17-32
 *       |-----------------------|--------------
 *       | >128KB :  132-256KB   | > 32*page    | 33-64
 *       |-----------------------|--------------
 *       | >256KB :  260-512KB   | > 64*page    | 65 - 128
 *       |-----------------------|--------------
 *       | >512KB :  516-1024KB  | > 128*page   | 129 - 256
 *       |-----------------------|--------------
 *       | >1024KB : 1028-...KB  | > 256*page   | 257 - ..
 *        --------------------------------------
 *
 * </pre>
 */
typedef __tb_pool_data_aligned__ struct __tb_static_large_allocator_t
{
    // the base
    tb_allocator_t                  base;

    // the page size
    tb_size_t                       page_size;

    // the data size
    tb_size_t                       data_size;

    // the data head
    tb_static_large_data_head_t*    data_head;

    // the data tail
    tb_static_large_data_head_t*    data_tail;

    // the data pred
#ifdef TB_CONFIG_MICRO_ENABLE
    tb_static_large_data_pred_t     data_pred[1];
#else
    tb_static_large_data_pred_t     data_pred[10];
#endif

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

}__tb_pool_data_aligned__ tb_static_large_allocator_t, *tb_static_large_allocator_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * checker implementation
 */
#ifdef __tb_debug__
static tb_void_t tb_static_large_allocator_check_data(tb_static_large_allocator_ref_t allocator, tb_static_large_data_head_t const* data_head)
{
    // check
    tb_assert_and_check_return(allocator && data_head);

    // done
    tb_bool_t           ok = tb_false;
    tb_byte_t const*    data = (tb_byte_t const*)&(data_head[1]);
    do
    {
        // the base head
        tb_pool_data_head_t* base_head = tb_static_large_allocator_data_base(data_head);

        // check
        tb_assertf_pass_break(!data_head->bfree, "data have been freed: %p", data);
        tb_assertf_pass_break(base_head->debug.magic == TB_POOL_DATA_MAGIC, "the invalid data: %p", data);
        tb_assertf_pass_break(((tb_byte_t*)data)[base_head->size] == TB_POOL_DATA_PATCH, "data underflow");

        // ok
        ok = tb_true;

    } while (0);

    // failed? dump it
    if (!ok) 
    {
        // dump data
        tb_pool_data_dump(data, tb_true, "[static_large_allocator]: [error]: ");

        // abort
        tb_abort();
    }
}
static tb_void_t tb_static_large_allocator_check_next(tb_static_large_allocator_ref_t allocator, tb_static_large_data_head_t const* data_head)
{
    // check
    tb_assert_and_check_return(allocator && data_head);

    // check the next data
    tb_static_large_data_head_t* next_head = (tb_static_large_data_head_t*)((tb_byte_t*)&(data_head[1]) + data_head->space);
    if (next_head < allocator->data_tail && !next_head->bfree) 
        tb_static_large_allocator_check_data(allocator, next_head);
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * malloc implementation
 */
static __tb_inline__ tb_size_t tb_static_large_allocator_pred_index(tb_static_large_allocator_ref_t allocator, tb_size_t space)
{
#ifndef TB_CONFIG_MICRO_ENABLE
    // the size
    tb_size_t size = sizeof(tb_static_large_data_head_t) + space;
    tb_assert(!(size & (allocator->page_size - 1)));

    // the page count
    size /= allocator->page_size;
 
    // the pred index
#if 0
    tb_size_t indx = tb_ilog2i(tb_align_pow2(size));
#else
    // faster
    tb_size_t indx = size > 1? (tb_ilog2i((tb_uint32_t)(size - 1)) + 1) : 0;
#endif
    if (indx >= tb_arrayn(allocator->data_pred)) indx = tb_arrayn(allocator->data_pred) - 1;
    return indx;
#else
    return 0;
#endif
}
static __tb_inline__ tb_void_t tb_static_large_allocator_pred_update(tb_static_large_allocator_ref_t allocator, tb_static_large_data_head_t* data_head)
{
    // check
    tb_assert(allocator && data_head && data_head->bfree);

    // cannot be tail
    tb_check_return(data_head != allocator->data_tail);

    // the pred index
    tb_size_t indx = tb_static_large_allocator_pred_index(allocator, data_head->space);

    // the pred head
    tb_static_large_data_head_t* pred_head = allocator->data_pred[indx].data_head;

    // cache this data head
    if (!pred_head || data_head->space > pred_head->space) allocator->data_pred[indx].data_head = data_head;
}
static __tb_inline__ tb_void_t tb_static_large_allocator_pred_remove(tb_static_large_allocator_ref_t allocator, tb_static_large_data_head_t* data_head)
{
    // check
    tb_assert(allocator && data_head);

    // the pred index
    tb_size_t indx = tb_static_large_allocator_pred_index(allocator, data_head->space);

    // clear this data head
    if (allocator->data_pred[indx].data_head == data_head) allocator->data_pred[indx].data_head = tb_null;
}
static tb_static_large_data_head_t* tb_static_large_allocator_malloc_find(tb_static_large_allocator_ref_t allocator, tb_static_large_data_head_t* data_head, tb_size_t walk_size, tb_size_t space)
{
    // check
    tb_assert_and_check_return_val(allocator && data_head && space, tb_null);

    // the data tail
    tb_static_large_data_head_t* data_tail = allocator->data_tail;
    tb_check_return_val(data_head < data_tail, tb_null);

    // find the free data 
    while ((data_head + 1) <= data_tail && walk_size)
    {
        // the data space size
        tb_size_t data_space = data_head->space;

        // check the space size
        tb_assert(!((sizeof(tb_static_large_data_head_t) + data_space) & (allocator->page_size - 1)));
            
#ifdef __tb_debug__
        // check the data
        if (!data_head->bfree) tb_static_large_allocator_check_data(allocator, data_head);
#endif

        // allocate if the data is free
        if (data_head->bfree)
        {
            // is enough?           
            if (data_space >= space)
            {
                // remove this free data from the pred cache
                tb_static_large_allocator_pred_remove(allocator, data_head);

                // split it if this free data is too large
                if (data_space > sizeof(tb_static_large_data_head_t) + space)
                {
                    // split this free data 
                    tb_static_large_data_head_t* next_head = (tb_static_large_data_head_t*)((tb_byte_t*)(data_head + 1) + space);
                    next_head->space = data_space - space - sizeof(tb_static_large_data_head_t);
                    next_head->bfree = 1;
                    data_head->space = space;
 
                    // add next free data to the pred cache
                    tb_static_large_allocator_pred_update(allocator, next_head);
                }
                else
                {
                    // the next data head
                    tb_static_large_data_head_t* next_head = (tb_static_large_data_head_t*)((tb_byte_t*)(data_head + 1) + data_space);
            
                    // the next data is free?
                    if (next_head + 1 < data_tail && next_head->bfree)
                    {
                        // add next free data to the pred cache
                        tb_static_large_allocator_pred_update(allocator, next_head);
                    }
                }

                // allocate the data 
                data_head->bfree = 0;

                // return the data head
                return data_head;
            }
            else // attempt to merge next free data if this free data is too small
            {
                // the next data head
                tb_static_large_data_head_t* next_head = (tb_static_large_data_head_t*)((tb_byte_t*)(data_head + 1) + data_space);
            
                // break if doesn't exist next data
                tb_check_break(next_head + 1 < data_tail);

                // the next data is free?
                if (next_head->bfree)
                {
                    // remove next free data from the pred cache
                    tb_static_large_allocator_pred_remove(allocator, next_head);

                    // remove this free data from the pred cache
                    tb_static_large_allocator_pred_remove(allocator, data_head);

                    // trace
                    tb_trace_d("malloc: find: merge: %lu", next_head->space);

                    // merge next data
                    data_head->space += sizeof(tb_static_large_data_head_t) + next_head->space;

                    // add this free data to the pred cache
                    tb_static_large_allocator_pred_update(allocator, data_head);

                    // continue handle this data 
                    continue ;
                }
            }
        }

        // walk_size--
        walk_size--;
    
        // skip it if the data is non-free or too small
        data_head = (tb_static_large_data_head_t*)((tb_byte_t*)(data_head + 1) + data_space);
    }

    // failed
    return tb_null;
}
static tb_static_large_data_head_t* tb_static_large_allocator_malloc_pred(tb_static_large_allocator_ref_t allocator, tb_size_t space)
{
    // check
    tb_assert_and_check_return_val(allocator && allocator->data_head, tb_null);

    // walk the pred cache
    tb_size_t                       indx = tb_static_large_allocator_pred_index(allocator, space);
    tb_size_t                       size = tb_arrayn(allocator->data_pred);
    tb_static_large_data_pred_t*    pred = allocator->data_pred;
    tb_static_large_data_head_t*    data_head = tb_null;
    tb_static_large_data_head_t*    pred_head = tb_null;
    for (; indx < size && !data_head; indx++)
    {
        // the pred data head
        pred_head = pred[indx].data_head;
        if (pred_head) 
        {
            // find the free data from the pred data head 
            data_head = tb_static_large_allocator_malloc_find(allocator, pred_head, 1, space);

#ifdef __tb_debug__
            // update the total count
            pred[indx].total_count++;

            // update the failed count
            if (!data_head) pred[indx].failed_count++;
#endif
        }
    }
   
    // trace
    tb_trace_d("malloc: pred: %lu: %s", space, data_head? "ok" : "no");

    // ok?
    return data_head;
}
static tb_static_large_data_head_t* tb_static_large_allocator_malloc_done(tb_static_large_allocator_ref_t allocator, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator && allocator->data_head, tb_null);

    // done
    tb_bool_t                       ok = tb_false;
    tb_static_large_data_head_t*    data_head = tb_null;
    do
    {
#ifdef __tb_debug__
        // patch 0xcc
        tb_size_t patch = 1;
#else
        tb_size_t patch = 0;
#endif

        // compile the need space for the page alignment
        tb_size_t need_space = tb_align(size + patch, allocator->page_size) - sizeof(tb_static_large_data_head_t);
        if (size + patch > need_space) need_space = tb_align(size + patch + allocator->page_size, allocator->page_size) - sizeof(tb_static_large_data_head_t);

        // attempt to predict the free data first
        data_head = tb_static_large_allocator_malloc_pred(allocator, need_space);
        if (!data_head)
        {
            // find the free data from the first data head 
            data_head = tb_static_large_allocator_malloc_find(allocator, allocator->data_head, -1, need_space);
            tb_check_break(data_head);
        }
        tb_assert(data_head->space >= size + patch);

        // the base head
        tb_pool_data_head_t* base_head = tb_static_large_allocator_data_base(data_head);

        // the real size
        tb_size_t size_real = real? (data_head->space - patch) : size;

        // save the real size
        if (real) *real = size_real;
        base_head->size = (tb_uint32_t)size_real;

#ifdef __tb_debug__
        // init the debug info
        base_head->debug.magic     = TB_POOL_DATA_MAGIC;
        base_head->debug.file      = file_;
        base_head->debug.func      = func_;
        base_head->debug.line      = (tb_uint16_t)line_;

        // calculate the skip frames
        tb_size_t skip_nframe = (tb_allocator() && tb_allocator_type(tb_allocator()) == TB_ALLOCATOR_TYPE_DEFAULT)? 6 : 3;

        // save backtrace
        tb_pool_data_save_backtrace(&base_head->debug, skip_nframe);

        // make the dirty data and patch 0xcc for checking underflow
        tb_memset_((tb_pointer_t)&(data_head[1]), TB_POOL_DATA_PATCH, size_real + patch);
 
        // update the real size
        allocator->real_size     += base_head->size;

        // update the occupied size
        allocator->occupied_size += sizeof(tb_static_large_data_head_t) + data_head->space - 1 - TB_POOL_DATA_HEAD_DIFF_SIZE;

        // update the total size
        allocator->total_size    += base_head->size;

        // update the peak size
        if (allocator->total_size > allocator->peak_size) allocator->peak_size = allocator->total_size;

        // update the malloc count
        allocator->malloc_count++;
#endif

        // ok
        ok = tb_true;

    } while (0);

    // trace
    tb_trace_d("malloc: %lu: %s", size, ok? "ok" : "no");

    // failed? clear it
    if (!ok) data_head = tb_null;

    // ok?
    return data_head;
}
static tb_static_large_data_head_t* tb_static_large_allocator_ralloc_fast(tb_static_large_allocator_ref_t allocator, tb_static_large_data_head_t* data_head, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_assert_and_check_return_val(allocator && data_head && size, tb_null);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // the base head
        tb_pool_data_head_t* base_head = tb_static_large_allocator_data_base(data_head);

#ifdef __tb_debug__
        // patch 0xcc
        tb_size_t patch = 1;

        // the prev size
        tb_size_t prev_size = base_head->size;

        // the prev space
        tb_size_t prev_space = data_head->space;

#else
        // no patch
        tb_size_t patch = 0;
#endif

        // compile the need space for the page alignment
        tb_size_t need_space = tb_align(size + patch, allocator->page_size) - sizeof(tb_static_large_data_head_t);
        if (size + patch > need_space) need_space = tb_align(size + patch + allocator->page_size, allocator->page_size) - sizeof(tb_static_large_data_head_t);

        // this data space is not enough?
        if (need_space > data_head->space)
        {
            // attempt to merge the next free data
            tb_static_large_data_head_t* data_tail = allocator->data_tail;
            tb_static_large_data_head_t* next_head = (tb_static_large_data_head_t*)((tb_byte_t*)&(data_head[1]) + data_head->space);
            while (next_head < data_tail && next_head->bfree) 
            {
                // remove next free data from the pred cache
                tb_static_large_allocator_pred_remove(allocator, next_head);

                // trace
                tb_trace_d("ralloc: fast: merge: %lu", next_head->space);

                // merge it
                data_head->space += sizeof(tb_static_large_data_head_t) + next_head->space;

                // the next data head
                next_head = (tb_static_large_data_head_t*)((tb_byte_t*)&(data_head[1]) + data_head->space);
            }
        }

        // enough?
        tb_check_break(need_space <= data_head->space);

        // split it if this data is too large after merging 
        if (data_head->space > sizeof(tb_static_large_data_head_t) + need_space)
        {
            // split this free data 
            tb_static_large_data_head_t* next_head = (tb_static_large_data_head_t*)((tb_byte_t*)(data_head + 1) + need_space);
            next_head->space = data_head->space - need_space - sizeof(tb_static_large_data_head_t);
            next_head->bfree = 1;
            data_head->space = need_space;

            // add next free data to the pred cache
            tb_static_large_allocator_pred_update(allocator, next_head);
        }

        // the real size
        tb_size_t size_real = real? (data_head->space - patch) : size;

        // save the real size
        if (real) *real = size_real;
        base_head->size = (tb_uint32_t)size_real;

#ifdef __tb_debug__
        // init the debug info
        base_head->debug.magic     = TB_POOL_DATA_MAGIC;
        base_head->debug.file      = file_;
        base_head->debug.func      = func_;
        base_head->debug.line      = (tb_uint16_t)line_;

        // calculate the skip frames
        tb_size_t skip_nframe = (tb_allocator() && tb_allocator_type(tb_allocator()) == TB_ALLOCATOR_TYPE_DEFAULT)? 6 : 3;

        // save backtrace
        tb_pool_data_save_backtrace(&base_head->debug, skip_nframe);

        // make the dirty data 
        if (size_real > prev_size) tb_memset_((tb_byte_t*)&(data_head[1]) + prev_size, TB_POOL_DATA_PATCH, size_real - prev_size);

        // patch 0xcc for checking underflow
        ((tb_byte_t*)&(data_head[1]))[size_real] = TB_POOL_DATA_PATCH;
 
        // update the real size
        allocator->real_size     += size_real;
        allocator->real_size     -= prev_size;

        // update the occupied size
        allocator->occupied_size += data_head->space;
        allocator->occupied_size -= prev_space;

        // update the total size
        allocator->total_size    += size_real;
        allocator->total_size    -= prev_size;

        // update the peak size
        if (allocator->total_size > allocator->peak_size) allocator->peak_size = allocator->total_size;
#endif

        // ok
        ok = tb_true;

    } while (0);

    // failed? clear it
    if (!ok) data_head = tb_null;

    // trace
    tb_trace_d("ralloc: fast: %lu: %s", size, ok? "ok" : "no");

    // ok?
    return data_head;
}
static tb_bool_t tb_static_large_allocator_free(tb_allocator_ref_t self, tb_pointer_t data __tb_debug_decl__)
{
    // check
    tb_static_large_allocator_ref_t allocator = (tb_static_large_allocator_t*)self;
    tb_assert_and_check_return_val(allocator && data, tb_false);

    // done
    tb_bool_t                       ok = tb_false;
    tb_static_large_data_head_t*    data_head = tb_null;
    do
    {
        // the data head
        data_head = &(((tb_static_large_data_head_t*)data)[-1]);

#ifdef __tb_debug__
        // the base head
        tb_pool_data_head_t* base_head = tb_static_large_allocator_data_base(data_head);
#endif

        // check
        tb_assertf_and_check_break(!data_head->bfree, "double free data: %p", data);
        tb_assertf(base_head->debug.magic == TB_POOL_DATA_MAGIC, "free invalid data: %p", data);
        tb_assertf_and_check_break(data_head >= allocator->data_head && data_head < allocator->data_tail, "the data: %p not belong to allocator: %p", data, allocator);
        tb_assertf(((tb_byte_t*)data)[base_head->size] == TB_POOL_DATA_PATCH, "data underflow");

#ifdef __tb_debug__
        // check the next data
        tb_static_large_allocator_check_next(allocator, data_head);

        // update the total size
        allocator->total_size -= base_head->size;

        // update the free count
        allocator->free_count++;
#endif

        // trace
        tb_trace_d("free: %lu: %s", base_head->size, ok? "ok" : "no");

        // attempt merge the next free data
        tb_static_large_data_head_t* next_head = (tb_static_large_data_head_t*)((tb_byte_t*)&(data_head[1]) + data_head->space);
        if (next_head < allocator->data_tail && next_head->bfree) 
        {
            // remove next free data from the pred cache
            tb_static_large_allocator_pred_remove(allocator, next_head);

            // trace
            tb_trace_d("free: merge: %lu", next_head->space);

            // merge it
            data_head->space += sizeof(tb_static_large_data_head_t) + next_head->space;
        }

        // free it
        data_head->bfree = 1;

        // add this free data to the pred cache
        tb_static_large_allocator_pred_update(allocator, data_head);

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
static tb_pointer_t tb_static_large_allocator_malloc(tb_allocator_ref_t self, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_static_large_allocator_ref_t allocator = (tb_static_large_allocator_t*)self;
    tb_assert_and_check_return_val(allocator && size, tb_null);

    // done
    tb_static_large_data_head_t* data_head = tb_static_large_allocator_malloc_done(allocator, size, real __tb_debug_args__);

    // ok
    return data_head? (tb_pointer_t)&(data_head[1]) : tb_null;
}
static tb_pointer_t tb_static_large_allocator_ralloc(tb_allocator_ref_t self, tb_pointer_t data, tb_size_t size, tb_size_t* real __tb_debug_decl__)
{
    // check
    tb_static_large_allocator_ref_t allocator = (tb_static_large_allocator_t*)self;
    tb_assert_and_check_return_val(allocator && data && size, tb_null);

    // done
    tb_bool_t                       ok = tb_false;
    tb_byte_t*                      data_real = tb_null;
    tb_static_large_data_head_t*    data_head = tb_null;
    tb_static_large_data_head_t*    aloc_head = tb_null;
    do
    {
        // the data head
        data_head = &(((tb_static_large_data_head_t*)data)[-1]);

#ifdef __tb_debug__
        // the base head
        tb_pool_data_head_t* base_head = tb_static_large_allocator_data_base(data_head);
#endif

        // check
        tb_assertf_and_check_break(!data_head->bfree, "ralloc freed data: %p", data);
        tb_assertf(base_head->debug.magic == TB_POOL_DATA_MAGIC, "ralloc invalid data: %p", data);
        tb_assertf_and_check_break(data_head >= allocator->data_head && data_head < allocator->data_tail, "the data: %p not belong to allocator: %p", data, allocator);
        tb_assertf(((tb_byte_t*)data)[base_head->size] == TB_POOL_DATA_PATCH, "data underflow");

#ifdef __tb_debug__
        // check the next data
        tb_static_large_allocator_check_next(allocator, data_head);
#endif

        // attempt to allocate it fastly if enough
        aloc_head = tb_static_large_allocator_ralloc_fast(allocator, data_head, size, real __tb_debug_args__);
        if (!aloc_head)
        {
            // allocate it
            aloc_head = tb_static_large_allocator_malloc_done(allocator, size, real __tb_debug_args__);
            tb_check_break(aloc_head);

            // not same?
            if (aloc_head != data_head)
            {
                // copy the real data
                tb_memcpy_((tb_pointer_t)&aloc_head[1], data, tb_min(size, (((tb_pool_data_head_t*)(data_head + 1))[-1]).size));
                
                // free the previous data
                tb_static_large_allocator_free(self, data __tb_debug_args__);
            }
        }

        // the real data
        data_real = (tb_byte_t*)&aloc_head[1];

#ifdef __tb_debug__
        // update the ralloc count
        allocator->ralloc_count++;
#endif

        // ok
        ok = tb_true;

    } while (0);

    // trace
    tb_trace_d("ralloc: %lu: %s", size, ok? "ok" : "no");

    // failed? clear it
    if (!ok) data_real = tb_null;

    // ok?
    return (tb_pointer_t)data_real;
}
static tb_void_t tb_static_large_allocator_clear(tb_allocator_ref_t self)
{
    // check
    tb_static_large_allocator_ref_t allocator = (tb_static_large_allocator_t*)self;
    tb_assert_and_check_return(allocator && allocator->data_head && allocator->data_size > sizeof(tb_static_large_data_head_t));

    // clear it
    allocator->data_head->bfree = 1;
    allocator->data_head->space = allocator->data_size - sizeof(tb_static_large_data_head_t);

    // clear the pred cache
    tb_memset_(allocator->data_pred, 0, sizeof(allocator->data_pred));
 
    // add this free data to the pred cache
    tb_static_large_allocator_pred_update(allocator, allocator->data_head);

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
static tb_void_t tb_static_large_allocator_exit(tb_allocator_ref_t self)
{
    // check
    tb_static_large_allocator_ref_t allocator = (tb_static_large_allocator_t*)self;
    tb_assert_and_check_return(allocator);

    // exit lock
    tb_spinlock_exit(&allocator->base.lock);
}
#ifdef __tb_debug__
static tb_void_t tb_static_large_allocator_dump(tb_allocator_ref_t self)
{
    // check
    tb_static_large_allocator_ref_t allocator = (tb_static_large_allocator_t*)self;
    tb_assert_and_check_return(allocator);

    // trace
    tb_trace_i("");

    // the data head
    tb_static_large_data_head_t* data_head = allocator->data_head;
    tb_assert_and_check_return(data_head);

    // the data tail
    tb_static_large_data_head_t* data_tail = allocator->data_tail;
    tb_assert_and_check_return(data_tail);

    // done
    tb_size_t frag_count = 0;
    while ((data_head + 1) <= data_tail)
    {
        // non-free?
        if (!data_head->bfree)
        {
            // check it
            tb_static_large_allocator_check_data(allocator, data_head);

            // trace
            tb_trace_e("leak: %p", &data_head[1]);

            // dump data
            tb_pool_data_dump((tb_byte_t const*)&data_head[1], tb_false, "[static_large_allocator]: [error]: ");
        }

        // fragment++
        frag_count++;

        // the next head
        data_head = (tb_static_large_data_head_t*)((tb_byte_t*)(data_head + 1) + data_head->space);
    }

    // trace
    tb_trace_i("");

    // trace pred info
    tb_size_t i = 0;
    tb_size_t pred_size = tb_arrayn(allocator->data_pred);
    for (i = 0; i < pred_size; i++)
    {
        // the pred info
        tb_static_large_data_pred_t const* pred = &allocator->data_pred[i];
        tb_assert_and_check_break(pred);

        // trace
        tb_trace_i("pred[>%04luKB]: data: %p, space: %lu, total_count: %lu, failed_count: %lu", ((allocator->page_size << (i - 1)) >> 10), pred->data_head? &pred->data_head[1] : tb_null, pred->data_head? pred->data_head->space : 0, pred->total_count, pred->failed_count);
    }

    // trace
    tb_trace_i("");

    // trace debug info
    tb_trace_i("peak_size: %lu",            allocator->peak_size);
    tb_trace_i("wast_rate: %llu/10000",     allocator->occupied_size? (((tb_hize_t)allocator->occupied_size - allocator->real_size) * 10000) / (tb_hize_t)allocator->occupied_size : 0);
    tb_trace_i("frag_count: %lu",           frag_count);
    tb_trace_i("free_count: %lu",           allocator->free_count);
    tb_trace_i("malloc_count: %lu",         allocator->malloc_count);
    tb_trace_i("ralloc_count: %lu",         allocator->ralloc_count);
}
static tb_bool_t tb_static_large_allocator_have(tb_allocator_ref_t self, tb_cpointer_t data)
{
    // check
    tb_static_large_allocator_ref_t allocator = (tb_static_large_allocator_t*)self;
    tb_assert_and_check_return_val(allocator, tb_false);

    // have it?
    return ((tb_byte_t const*)data > (tb_byte_t const*)allocator->data_head && (tb_byte_t const*)data < (tb_byte_t const*)allocator->data_head + allocator->data_size)? tb_true : tb_false;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_allocator_ref_t tb_static_large_allocator_init(tb_byte_t* data, tb_size_t size, tb_size_t pagesize)
{
    // check
    tb_assert_and_check_return_val(data && size, tb_null);
    tb_assert_static(!(sizeof(tb_static_large_data_head_t) & (TB_POOL_DATA_ALIGN - 1)));
    tb_assert_static(!(sizeof(tb_static_large_allocator_t) & (TB_POOL_DATA_ALIGN - 1)));

    // align data and size
    tb_size_t diff = tb_align((tb_size_t)data, TB_POOL_DATA_ALIGN) - (tb_size_t)data;
    tb_assert_and_check_return_val(size > diff + sizeof(tb_static_large_allocator_t), tb_null);
    size -= diff;
    data += diff;

    // init allocator
    tb_static_large_allocator_ref_t allocator = (tb_static_large_allocator_t*)data;
    tb_memset_(allocator, 0, sizeof(tb_static_large_allocator_t));

    // init base
    allocator->base.type             = TB_ALLOCATOR_TYPE_LARGE;
    allocator->base.flag             = TB_ALLOCATOR_FLAG_NONE;
    allocator->base.large_malloc     = tb_static_large_allocator_malloc;
    allocator->base.large_ralloc     = tb_static_large_allocator_ralloc;
    allocator->base.large_free       = tb_static_large_allocator_free;
    allocator->base.clear            = tb_static_large_allocator_clear;
    allocator->base.exit             = tb_static_large_allocator_exit;
#ifdef __tb_debug__
    allocator->base.dump             = tb_static_large_allocator_dump;
    allocator->base.have             = tb_static_large_allocator_have;
#endif

    // init lock
    if (!tb_spinlock_init(&allocator->base.lock)) return tb_null;

    // init page_size
    allocator->page_size = pagesize? pagesize : tb_page_size();

    // page_size must be larger than sizeof(tb_static_large_data_head_t)
    if (allocator->page_size < sizeof(tb_static_large_data_head_t))
        allocator->page_size += sizeof(tb_static_large_data_head_t);

    // page_size must be aligned 
    allocator->page_size = tb_align_pow2(allocator->page_size);
    tb_assert_and_check_return_val(allocator->page_size, tb_null);

    // init data size
    allocator->data_size = size - sizeof(tb_static_large_allocator_t);
    tb_assert_and_check_return_val(allocator->data_size > allocator->page_size, tb_null);

    // align data size
    allocator->data_size = tb_align(allocator->data_size - allocator->page_size, allocator->page_size);
    tb_assert_and_check_return_val(allocator->data_size > sizeof(tb_static_large_data_head_t), tb_null);

    // init data head 
    allocator->data_head = (tb_static_large_data_head_t*)&allocator[1];
    allocator->data_head->bfree = 1;
    allocator->data_head->space = allocator->data_size - sizeof(tb_static_large_data_head_t);
    tb_assert_and_check_return_val(!((tb_size_t)allocator->data_head & (TB_POOL_DATA_ALIGN - 1)), tb_null);
 
    // add this free data to the pred cache
    tb_static_large_allocator_pred_update(allocator, allocator->data_head);

    // init data tail
    allocator->data_tail = (tb_static_large_data_head_t*)((tb_byte_t*)&allocator->data_head[1] + allocator->data_head->space);

    // register lock profiler
#ifdef TB_LOCK_PROFILER_ENABLE
    tb_lock_profiler_register(tb_lock_profiler(), (tb_pointer_t)&allocator->base.lock, TB_TRACE_MODULE_NAME);
#endif

    // ok
    return (tb_allocator_ref_t)allocator;
}

