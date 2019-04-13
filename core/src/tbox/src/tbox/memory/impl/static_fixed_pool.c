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
 * @file        static_fixed_pool.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "static_fixed_pool"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "static_fixed_pool.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef TB_WORDS_BIGENDIAN

// allocate the index 
#   define tb_static_fixed_pool_used_set1(used, i)          do {(used)[(i) >> 3] |= (0x1 << (7 - ((i) & 7)));} while (0)

// free the index
#   define tb_static_fixed_pool_used_set0(used, i)          do {(used)[(i) >> 3] &= ~(0x1 << (7 - ((i) & 7)));} while (0)

// the index have been allocated?
#   define tb_static_fixed_pool_used_bset(used, i)          ((used)[(i) >> 3] & (0x1 << (7 - ((i) & 7))))

// find the first free index
#   define tb_static_fixed_pool_find_free(v)                tb_bits_fb0_be(v)

#else

// allocate the index 
#   define tb_static_fixed_pool_used_set1(used, i)          do {(used)[(i) >> 3] |= (0x1 << ((i) & 7));} while (0)

// free the index
#   define tb_static_fixed_pool_used_set0(used, i)          do {(used)[(i) >> 3] &= ~(0x1 << ((i) & 7));} while (0)

// the index have been allocated?
#   define tb_static_fixed_pool_used_bset(used, i)          ((used)[(i) >> 3] & (0x1 << ((i) & 7)))

// find the first free index
#   define tb_static_fixed_pool_find_free(v)                tb_bits_fb0_le(v)

#endif

// cache the predicted index
#define tb_static_fixed_pool_cache_pred(pool, i)            do { (pool)->pred_index = ((i) >> TB_CPU_SHIFT) + 1; } while (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the static fixed pool type
typedef __tb_pool_data_aligned__ struct __tb_static_fixed_pool_t
{
    // the real data address after the used_info info
    tb_byte_t*                  data;

    // the data tail
    tb_byte_t*                  tail;

    // the used info
    tb_byte_t*                  used_info;

    // the used info size
    tb_size_t                   info_size;

    // the predict index
    tb_size_t                   pred_index;

    // the item size
    tb_size_t                   item_size;

    // the item space: head + item_size
    tb_size_t                   item_space;

    // the item count
    tb_size_t                   item_count;

    // the item maximum count
    tb_size_t                   item_maxn;

    // the data head size
    tb_uint16_t                 data_head_size;

    // for small allocator?
    tb_uint16_t                 for_small;

#ifdef __tb_debug__

    // the peak size
    tb_size_t                   peak_size;

    // the total size
    tb_size_t                   total_size;

    // the real size
    tb_size_t                   real_size;

    // the occupied size
    tb_size_t                   occupied_size;

    // the malloc count
    tb_size_t                   malloc_count;

    // the free count
    tb_size_t                   free_count;

    // the predict failed count
    tb_size_t                   pred_failed;

#endif

}__tb_pool_data_aligned__ tb_static_fixed_pool_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_pool_data_empty_head_t* tb_static_fixed_pool_malloc_pred(tb_static_fixed_pool_t* pool)
{
    // check
    tb_assert_and_check_return_val(pool, tb_null);

    // done
    tb_pool_data_empty_head_t* data_head = tb_null;
    do
    {
        // exists the predict index?
        tb_check_break(pool->pred_index);

        // the predict index
        tb_size_t pred_index = pool->pred_index - 1;
        tb_assert((pred_index << TB_CPU_SHIFT) < pool->item_maxn);
    
        // the predict data
        tb_size_t* data = (tb_size_t*)pool->used_info + pred_index;

        // full?
        tb_check_break((*data) + 1);

        // the free bit index
        tb_size_t index = (pred_index << TB_CPU_SHIFT) + tb_static_fixed_pool_find_free(*data);
        
        // out of range?
        if (index >= pool->item_maxn)
        {
            // clear the pred index
            pool->pred_index = 0;
            break;
        }

        // check
        tb_assert(!tb_static_fixed_pool_used_bset(pool->used_info, index));

        // the data head
        data_head = (tb_pool_data_empty_head_t*)(pool->data + index * pool->item_space);

        // allocate it
        tb_static_fixed_pool_used_set1(pool->used_info, index);

        // the predict data is full
        if (!((*data) + 1)) 
        {
            // clear the predict index
            pool->pred_index = 0;

            // predict the next index
            if (index + 1 < pool->item_maxn && !tb_static_fixed_pool_used_bset(pool->used_info, index + 1))
                tb_static_fixed_pool_cache_pred(pool, index + 1);
        }

    } while (0);

#ifdef __tb_debug__
    // update the predict failed count
    if (!data_head) pool->pred_failed++;
#endif

    // ok?
    return data_head;
}

#if 1
static tb_pool_data_empty_head_t* tb_static_fixed_pool_malloc_find(tb_static_fixed_pool_t* pool)
{
    // check
    tb_assert_and_check_return_val(pool, tb_null);

    // init
    tb_size_t   i = 0;
    tb_size_t*  p = (tb_size_t*)pool->used_info;
    tb_size_t*  e = (tb_size_t*)(pool->used_info + pool->info_size);
    tb_byte_t*  d = tb_null;

    // check align
    tb_assert_and_check_return_val(!(((tb_size_t)p) & (TB_CPU_BITBYTE - 1)), tb_null);

    // find the free chunk, item_space * 32|64 items
#ifdef __tb_small__ 
//  while (p < e && *p == 0xffffffff) p++;
//  while (p < e && *p == 0xffffffffffffffffL) p++;
    while (p < e && !((*p) + 1)) p++;
#else
    while (p + 7 < e)
    {
        if (p[0] + 1) { p += 0; break; }
        if (p[1] + 1) { p += 1; break; }
        if (p[2] + 1) { p += 2; break; }
        if (p[3] + 1) { p += 3; break; }
        if (p[4] + 1) { p += 4; break; }
        if (p[5] + 1) { p += 5; break; }
        if (p[6] + 1) { p += 6; break; }
        if (p[7] + 1) { p += 7; break; }
        p += 8;
    }
    while (p < e && !(*p + 1)) p++; 
#endif
    tb_check_return_val(p < e, tb_null);

    // find the free bit index
    tb_size_t m = pool->item_maxn;
    i = (((tb_byte_t*)p - pool->used_info) << 3) + tb_static_fixed_pool_find_free(*p);
    tb_check_return_val(i < m, tb_null);

    // allocate it
    d = pool->data + i * pool->item_space;
    tb_static_fixed_pool_used_set1(pool->used_info, i);

    // predict this index if no full?
    if ((*p) + 1) tb_static_fixed_pool_cache_pred(pool, i);

    // ok?
    return (tb_pool_data_empty_head_t*)d;
}
#else
static tb_pool_data_empty_head_t* tb_static_fixed_pool_malloc_find(tb_static_fixed_pool_t* pool)
{
    // check
    tb_assert_and_check_return_val(pool, tb_null);

    // done
    tb_size_t   i = 0;
    tb_size_t   m = pool->item_maxn;
    tb_byte_t*  p = pool->used_info;
    tb_byte_t   u = *p;
    tb_byte_t   b = 0;
    tb_byte_t*  d = tb_null;
    for (i = 0; i < m; ++i)
    {
        // bit
        b = i & 0x07;

        // u++
        if (!b) 
        {
            u = *p++;
                
            // skip the non-free byte
            //if (u == 0xff)
            if (!(u + 1))
            {
                i += 7;
                continue ;
            }
        }

        // is free?
        // if (!tb_static_fixed_pool_used_bset(pool->used_info, i))
        if (!(u & (0x01 << b)))
        {
            // ok
            d = pool->data + i * pool->item_space;
            // tb_static_fixed_pool_used_set1(pool->used_info, i);
            *(p - 1) |= (0x01 << b);

            // predict the next block
            if (i + 1 < m && !tb_static_fixed_pool_used_bset(pool->used_info, i + 1))
                tb_static_fixed_pool_cache_pred(pool, i + 1);

            break;
        }
    }

    // ok?
    return (tb_pool_data_empty_head_t*)d;
}
#endif

#ifdef __tb_debug__
static tb_void_t tb_static_fixed_pool_check_data(tb_static_fixed_pool_t* pool, tb_pool_data_empty_head_t const* data_head)
{
    // check
    tb_assert_and_check_return(pool && data_head);

    // done
    tb_bool_t           ok = tb_false;
    tb_byte_t const*    data = (tb_byte_t const*)data_head + pool->data_head_size;
    do
    {
        // the index
        tb_size_t index = ((tb_byte_t*)data_head - pool->data) / pool->item_space;

        // check
        tb_assertf_pass_break(!(((tb_byte_t*)data_head - pool->data) % pool->item_space), "the invalid data: %p", data);
        tb_assertf_pass_break(tb_static_fixed_pool_used_bset(pool->used_info, index), "data have been freed: %p", data);
        tb_assertf_pass_break(data_head->debug.magic == (pool->for_small? TB_POOL_DATA_MAGIC : TB_POOL_DATA_EMPTY_MAGIC), "the invalid data: %p", data);
        tb_assertf_pass_break(((tb_byte_t*)data)[pool->item_size] == TB_POOL_DATA_PATCH, "data underflow");

        // ok
        ok = tb_true;

    } while (0);

    // failed? dump it
    if (!ok) 
    {
        // dump data
        tb_pool_data_dump(data, tb_true, "[static_fixed_pool]: [error]: ");

        // abort
        tb_abort();
    }
}
static tb_void_t tb_static_fixed_pool_check_next(tb_static_fixed_pool_t* pool, tb_pool_data_empty_head_t const* data_head)
{
    // check
    tb_assert_and_check_return(pool && data_head);

    // the index
    tb_size_t index = ((tb_byte_t*)data_head - pool->data) / pool->item_space;

    // check the next data
    if (index + 1 < pool->item_maxn && tb_static_fixed_pool_used_bset(pool->used_info, index + 1))
        tb_static_fixed_pool_check_data(pool, (tb_pool_data_empty_head_t*)((tb_byte_t*)data_head + pool->item_space));
}
static tb_void_t tb_static_fixed_pool_check_prev(tb_static_fixed_pool_t* pool, tb_pool_data_empty_head_t const* data_head)
{
    // check
    tb_assert_and_check_return(pool && data_head);

    // the index
    tb_size_t index = ((tb_byte_t*)data_head - pool->data) / pool->item_space;

    // check the prev data
    if (index && tb_static_fixed_pool_used_bset(pool->used_info, index - 1))
        tb_static_fixed_pool_check_data(pool, (tb_pool_data_empty_head_t*)((tb_byte_t*)data_head - pool->item_space));
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_static_fixed_pool_ref_t tb_static_fixed_pool_init(tb_byte_t* data, tb_size_t size, tb_size_t item_size, tb_bool_t for_small)
{
    // check
    tb_assert_and_check_return_val(data && size && item_size, tb_null);

    // align data and size
    tb_size_t diff = tb_align((tb_size_t)data, TB_POOL_DATA_ALIGN) - (tb_size_t)data;
    tb_assert_and_check_return_val(size > diff + sizeof(tb_static_fixed_pool_t), tb_null);
    size -= diff;
    data += diff;

    // init pool
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)data;
    tb_memset_(pool, 0, sizeof(tb_static_fixed_pool_t));

    // for small allocator?
    pool->for_small = !!for_small;
    pool->data_head_size = for_small? sizeof(tb_pool_data_head_t) : sizeof(tb_pool_data_empty_head_t);
#ifndef __tb_debug__
    // fix data alignment, because sizeof(tb_pool_data_empty_head_t) == 1 now.
    if (!for_small) pool->data_head_size = 0;
#endif
    tb_assert_and_check_return_val(!(pool->data_head_size & (TB_POOL_DATA_ALIGN - 1)), tb_null);

#ifdef __tb_debug__
    // init patch for checking underflow
    tb_size_t patch = 1;
#else
    tb_size_t patch = 0;
#endif

    // init the item space
    pool->item_space = pool->data_head_size + item_size + patch;
    pool->item_space = tb_align(pool->item_space, TB_POOL_DATA_ALIGN);
    tb_assert_and_check_return_val(pool->item_space > pool->data_head_size, tb_null);

    // init the used info
    pool->used_info = (tb_byte_t*)tb_align((tb_size_t)&pool[1], TB_POOL_DATA_ALIGN);
    tb_assert_and_check_return_val(data + size > pool->used_info, tb_null);

    /* init the item maxn
     *
     * used_info + maxn * item_space < left
     * align8(maxn) / 8 + maxn * item_space < left
     * (maxn + 7) / 8 + maxn * item_space < left
     * (maxn / 8) + (7 / 8) + maxn * item_space < left
     * maxn * (1 / 8 + item_space) < left - (7 / 8)
     * maxn < (left - (7 / 8)) / (1 / 8 + item_space)
     * maxn < (left * 8 - 7) / (1 + item_space * 8)
     */
    pool->item_maxn = (((data + size - pool->used_info) << 3) - 7) / (1 + (pool->item_space << 3));
    tb_assert_and_check_return_val(pool->item_maxn, tb_null);

    // init the used info size
    pool->info_size = tb_align(pool->item_maxn, TB_CPU_BITSIZE) >> 3;
    tb_assert_and_check_return_val(pool->info_size && !(pool->info_size & (TB_CPU_BITBYTE - 1)), tb_null);
 
    // clear the used info
    tb_memset_(pool->used_info, 0, pool->info_size);

    // init data
    pool->data = (tb_byte_t*)tb_align((tb_size_t)pool->used_info + pool->info_size, TB_POOL_DATA_ALIGN);
    tb_assert_and_check_return_val(data + size > pool->data, tb_null);
    tb_assert_and_check_return_val(pool->item_maxn * pool->item_space <= (tb_size_t)(data + size - pool->data + 1), tb_null);

    // init data tail
    pool->tail = pool->data + pool->item_maxn * pool->item_space;

    // init the item size
    pool->item_size = item_size;

    // init the item count
    pool->item_count = 0;

    // init the predict index
    pool->pred_index = 1;

    // trace
    tb_trace_d("init: data: %p, size: %lu, head_size: %lu, item_size: %lu, item_maxn: %lu, item_space: %lu", pool->data, size, pool->data - (tb_byte_t*)pool, item_size, pool->item_maxn, pool->item_space);

    // ok
    return (tb_static_fixed_pool_ref_t)pool;
}
tb_void_t tb_static_fixed_pool_exit(tb_static_fixed_pool_ref_t self)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return(pool);

    // clear it
    tb_static_fixed_pool_clear(self);

    // exit it
    tb_memset_(pool, 0, sizeof(tb_static_fixed_pool_t));
}
tb_size_t tb_static_fixed_pool_size(tb_static_fixed_pool_ref_t self)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, 0);

    // the item count
    return pool->item_count;
}
tb_size_t tb_static_fixed_pool_maxn(tb_static_fixed_pool_ref_t self)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, 0);

    // the item maximum count
    return pool->item_maxn;
}
tb_bool_t tb_static_fixed_pool_full(tb_static_fixed_pool_ref_t self)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, 0);

    // full?
    return pool->item_count == pool->item_maxn? tb_true : tb_false;
}
tb_bool_t tb_static_fixed_pool_null(tb_static_fixed_pool_ref_t self)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool, 0);

    // null?
    return !pool->item_count? tb_true : tb_false;
}
tb_void_t tb_static_fixed_pool_clear(tb_static_fixed_pool_ref_t self)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return(pool);

    // clear used_info
    if (pool->used_info) tb_memset_(pool->used_info, 0, pool->info_size);

    // clear size
    pool->item_count = 0;
   
    // init the predict index
    pool->pred_index = 1;

    // clear info
#ifdef __tb_debug__
    pool->peak_size     = 0;
    pool->total_size    = 0;
    pool->real_size     = 0;
    pool->occupied_size = 0;
    pool->malloc_count  = 0;
    pool->free_count    = 0;
    pool->pred_failed   = 0;
#endif
}
tb_pointer_t tb_static_fixed_pool_malloc(tb_static_fixed_pool_ref_t self __tb_debug_decl__)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool && pool->item_space, tb_null);

    // done
    tb_pointer_t                data = tb_null;
    tb_pool_data_empty_head_t*  data_head = tb_null;
    do
    {
        // full?
        tb_check_break(pool->item_count < pool->item_maxn);

        // predict it?
        data_head = tb_static_fixed_pool_malloc_pred(pool);

        // find it
        if (!data_head) data_head = tb_static_fixed_pool_malloc_find(pool);
        tb_check_break(data_head);

        // the real data
        data = (tb_byte_t*)data_head + pool->data_head_size;

        // save the real size
        if (pool->for_small) ((tb_pool_data_head_t*)data_head)->size = pool->item_size;

        // count++
        pool->item_count++;

#ifdef __tb_debug__

        // init the debug info
        data_head->debug.magic     = pool->for_small? TB_POOL_DATA_MAGIC : TB_POOL_DATA_EMPTY_MAGIC;
        data_head->debug.file      = file_;
        data_head->debug.func      = func_;
        data_head->debug.line      = (tb_uint16_t)line_;

        // save backtrace
        tb_pool_data_save_backtrace(&data_head->debug, 6);

        // make the dirty data and patch 0xcc for checking underflow
        tb_memset_(data, TB_POOL_DATA_PATCH, pool->item_space - pool->data_head_size);
 
        // update the real size
        pool->real_size     += pool->item_size;

        // update the occupied size
        pool->occupied_size += pool->item_space - TB_POOL_DATA_HEAD_DIFF_SIZE - 1;

        // update the total size
        pool->total_size    += pool->item_size;

        // update the peak size
        if (pool->total_size > pool->peak_size) pool->peak_size = pool->total_size;

        // update the malloc count
        pool->malloc_count++;
        
        // check the prev data
        tb_static_fixed_pool_check_prev(pool, data_head);

        // check the next data
        tb_static_fixed_pool_check_next(pool, data_head);
#endif

    } while (0);

    // check
    tb_assertf(data, "malloc(%lu) failed!", pool->item_size);
    tb_assertf(!(((tb_size_t)data) & (TB_POOL_DATA_ALIGN - 1)), "malloc(%lu): unaligned data: %p", pool->item_size, data);

    // ok?
    return data;
}
tb_bool_t tb_static_fixed_pool_free(tb_static_fixed_pool_ref_t self, tb_pointer_t data __tb_debug_decl__)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return_val(pool && pool->item_space, tb_false);

    // done
    tb_bool_t                   ok = tb_false;
    tb_pool_data_empty_head_t*  data_head = (tb_pool_data_empty_head_t*)((tb_byte_t*)data - pool->data_head_size);
    do
    {
        // the index
        tb_size_t index = ((tb_byte_t*)data_head - pool->data) / pool->item_space;

        // check
        tb_assertf_pass_and_check_break((tb_byte_t*)data_head >= pool->data && (tb_byte_t*)data_head + pool->item_space <= pool->tail, "the data: %p not belong to pool: %p", data, pool);
        tb_assertf_pass_break(!(((tb_byte_t*)data_head - pool->data) % pool->item_space), "free the invalid data: %p", data);
        tb_assertf_pass_and_check_break(pool->item_count, "double free data: %p", data);
        tb_assertf_pass_and_check_break(tb_static_fixed_pool_used_bset(pool->used_info, index), "double free data: %p", data);
        tb_assertf_pass_break(data_head->debug.magic == (pool->for_small? TB_POOL_DATA_MAGIC : TB_POOL_DATA_EMPTY_MAGIC), "the invalid data: %p", data);
        tb_assertf_pass_break(((tb_byte_t*)data)[pool->item_size] == TB_POOL_DATA_PATCH, "data underflow");

#ifdef __tb_debug__
        // check the prev data
        tb_static_fixed_pool_check_prev(pool, data_head);

        // check the next data
        tb_static_fixed_pool_check_next(pool, data_head);

        // update the total size
        pool->total_size -= pool->item_size;

        // update the free count
        pool->free_count++;
#endif

        // free it
        tb_static_fixed_pool_used_set0(pool->used_info, index);
        
        // predict it if no cache
        if (!pool->pred_index) tb_static_fixed_pool_cache_pred(pool, index);

        // size--
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
        tb_pool_data_dump((tb_byte_t const*)data, tb_true, "[static_fixed_pool]: [error]: ");

        // abort
        tb_abort();
    }
#endif

    // ok?
    return ok;
}
tb_void_t tb_static_fixed_pool_walk(tb_static_fixed_pool_ref_t self, tb_fixed_pool_item_walk_func_t func, tb_cpointer_t priv)
{
    // check 
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return(pool && pool->item_maxn && pool->item_space && func);

    // walk
    tb_size_t   i = 0;
    tb_size_t   m = pool->item_maxn;
    tb_byte_t*  p = pool->used_info;
    tb_byte_t*  d = pool->data + pool->data_head_size;
    tb_byte_t   u = *p;
    tb_byte_t   b = 0;
    for (i = 0; i < m; ++i)
    {
        // bit
        b = i & 0x07;

        // u++
        if (!b) 
        {
            u = *p++;
                
            // this byte is all occupied?
            //if (u == 0xff)
            if (!(u + 1))
            {
                // done func
                func(d + (i + 0) * pool->item_space, priv);
                func(d + (i + 1) * pool->item_space, priv);
                func(d + (i + 2) * pool->item_space, priv);
                func(d + (i + 3) * pool->item_space, priv);
                func(d + (i + 4) * pool->item_space, priv);
                func(d + (i + 5) * pool->item_space, priv);
                func(d + (i + 6) * pool->item_space, priv);
                func(d + (i + 7) * pool->item_space, priv);

                // skip this byte and continue it
                i += 7;
                continue ;
            }
        }

        // is occupied?
        // if (tb_static_fixed_pool_used_bset(pool->used_info, i))
        if ((u & (0x01 << b)))
        {
            // done func
            func(d + i * pool->item_space, priv);
        }
    }
}
#ifdef __tb_debug__
tb_void_t tb_static_fixed_pool_dump(tb_static_fixed_pool_ref_t self)
{
    // check
    tb_static_fixed_pool_t* pool = (tb_static_fixed_pool_t*)self;
    tb_assert_and_check_return(pool && pool->used_info);

    // dump 
    tb_size_t index = 0;
    for (index = 0; index < pool->item_maxn; ++index)
    {
        // leak?
        if (tb_static_fixed_pool_used_bset(pool->used_info, index)) 
        {
            // the data head
            tb_pool_data_empty_head_t* data_head = (tb_pool_data_empty_head_t*)(pool->data + index * pool->item_space);

            // check it
            tb_static_fixed_pool_check_data(pool, data_head);

            // the data
            tb_byte_t const* data = (tb_byte_t const*)data_head + pool->data_head_size;

            // trace
            tb_trace_e("leak: %p", data);

            // dump data
            tb_pool_data_dump(data, tb_false, "[static_fixed_pool]: [error]: ");
        }
    }

    // trace debug info
    tb_trace_i("[%lu]: peak_size: %lu, wast_rate: %llu/10000, pred_failed: %lu, item_maxn: %lu, free_count: %lu, malloc_count: %lu"
            ,   pool->item_size
            ,   pool->peak_size
            ,   pool->occupied_size? (((tb_hize_t)pool->occupied_size - pool->real_size) * 10000) / (tb_hize_t)pool->occupied_size : 0
            ,   pool->pred_failed
            ,   pool->item_maxn
            ,   pool->free_count
            ,   pool->malloc_count);

}
#endif
