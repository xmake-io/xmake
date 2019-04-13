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
 * @file        hash_map.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "hash_map"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "hash_map.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../memory/memory.h"
#include "../stream/stream.h"
#include "../platform/platform.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// index
#if TB_CPU_BIT64
#   define tb_hash_map_index_make(buck, item)           (((tb_size_t)((item) & 0xffffffff) << 32) | ((buck) & 0xffffffff))
#   define tb_hash_map_index_buck(index)                ((index) & 0xffffffff)
#   define tb_hash_map_index_item(index)                (((index) >> 32) & 0xffffffff)
#else
#   define tb_hash_map_index_make(buck, item)           (((tb_size_t)((item) & 0xffff) << 16) | ((buck) & 0xffff))
#   define tb_hash_map_index_buck(index)                ((index) & 0xffff)
#   define tb_hash_map_index_item(index)                (((index) >> 16) & 0xffff)
#endif

// the self bucket default size
#ifdef __tb_small__
#   define TB_HASH_MAP_BUCKET_SIZE_DEFAULT              TB_HASH_MAP_BUCKET_SIZE_MICRO
#else
#   define TB_HASH_MAP_BUCKET_SIZE_DEFAULT              TB_HASH_MAP_BUCKET_SIZE_SMALL
#endif

// the self bucket maximum size
#define TB_HASH_MAP_BUCKET_MAXN                         (1 << 16)

// the self bucket item maximum size
#define TB_HASH_MAP_BUCKET_ITEM_MAXN                    (1 << 16)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the hash map item list type
typedef struct __tb_hash_map_item_list_t
{
    // the list size
    tb_size_t                       size;

    // the list maxn
    tb_size_t                       maxn;

}tb_hash_map_item_list_t;

// the hash map type
typedef struct __tb_hash_map_t
{
    // the item itor
    tb_iterator_t                   itor;

    // the hash list
    tb_hash_map_item_list_t**       hash_list;

    // the hash list size
    tb_size_t                       hash_size;

    // the current item for iterator
    tb_hash_map_item_t              item;

    // the item size
    tb_size_t                       item_size;

    // the item maxn
    tb_size_t                       item_maxn;

    // the item grow
    tb_size_t                       item_grow;

    // the element for name
    tb_element_t                    element_name;

    // the element for data
    tb_element_t                    element_data;

}tb_hash_map_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#if 0
// linear finder
static tb_bool_t tb_hash_map_item_find(tb_hash_map_t* hash_map, tb_cpointer_t name, tb_size_t* pbuck, tb_size_t* pitem)
{
    tb_assert_and_check_return_val(hash_map && hash_map->hash_list && hash_map->hash_size, tb_false);
    
    // get step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert_and_check_return_val(step, tb_false);

    // comupte hash_map from name
    tb_size_t buck = hash_map->element_name.hash(&hash_map->element_name, name, hash_map->hash_size - 1, 0);
    tb_assert_and_check_return_val(buck < hash_map->hash_size, tb_false);

    // update buck
    if (pbuck) *pbuck = buck;

    // get list
    tb_hash_map_item_list_t* list = hash_map->hash_list[buck];
    tb_check_return_val(list && list->size, tb_false);

    // find item
    tb_long_t   r = 1;
    tb_size_t   i = 0;
    tb_size_t   n = list->size;
    for (i = 0; i < n; i++)
    {
        // get item
        tb_byte_t const* item = ((tb_byte_t*)&list[1]) + i * step;

        // compare it
        r = hash_map->element_name.comp(&hash_map->element_name, name, hash_map->element_name.data(&hash_map->element_name, item));
        if (r <= 0) break;
    }

    // update item
    if (pitem) *pitem = i;

    // ok?
    return !r? tb_true : tb_false;
}
#else
// binary finder
static tb_bool_t tb_hash_map_item_find(tb_hash_map_t* hash_map, tb_cpointer_t name, tb_size_t* pbuck, tb_size_t* pitem)
{
    // check
    tb_assert_and_check_return_val(hash_map && hash_map->hash_list && hash_map->hash_size, tb_false);
    
    // get step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert_and_check_return_val(step, tb_false);

    // comupte hash_map from name
    tb_size_t buck = hash_map->element_name.hash(&hash_map->element_name, name, hash_map->hash_size - 1, 0);
    tb_assert_and_check_return_val(buck < hash_map->hash_size, tb_false);

    // update buck
    if (pbuck) *pbuck = buck;

    // get list
    tb_hash_map_item_list_t* list = hash_map->hash_list[buck];
    tb_check_return_val(list && list->size, tb_false);

    // find item
    tb_long_t   t = 1;
    tb_size_t   l = 0;
    tb_size_t   r = list->size;
    tb_size_t   m = (l + r) >> 1;
    while (l < r)
    {
        // get item
        tb_byte_t const* item = ((tb_byte_t*)&list[1]) + m * step;

        // compare it
        t = hash_map->element_name.comp(&hash_map->element_name, name, hash_map->element_name.data(&hash_map->element_name, item));
        if (t < 0) r = m;
        else if (t > 0) l = m + 1;
        else break;
    
        // next
        m = (l + r) >> 1;
    }

    /* update item
     *
     * @note: m is not the prev not same item if not finded and list has repeat items
     * but this hash_map not exists repeat
     *
     * @see tb_binary_pfind()
     */
    if (pitem) *pitem = m;

    // ok?
    return !t? tb_true : tb_false;
}
#endif
static tb_bool_t tb_hash_map_item_at(tb_hash_map_t* hash_map, tb_size_t buck, tb_size_t item, tb_pointer_t* pname, tb_pointer_t* pdata)
{
    // check
    tb_assert_and_check_return_val(hash_map && hash_map->hash_list && hash_map->hash_size && buck < hash_map->hash_size, tb_false);
    
    // get step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert_and_check_return_val(step, tb_false);

    // get list
    tb_hash_map_item_list_t* list = hash_map->hash_list[buck];
    tb_check_return_val(list && list->size && item < list->size, tb_false);

    // get name
    if (pname) *pname = hash_map->element_name.data(&hash_map->element_name, ((tb_byte_t*)&list[1]) + item * step);
    
    // get data
    if (pdata) *pdata = hash_map->element_data.data(&hash_map->element_data, ((tb_byte_t*)&list[1]) + item * step + hash_map->element_name.size);

    // ok
    return tb_true;
}
static tb_size_t tb_hash_map_itor_size(tb_iterator_ref_t iterator)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)iterator;
    tb_assert(hash_map);

    // the size
    return hash_map->item_size;
}
static tb_size_t tb_hash_map_itor_head(tb_iterator_ref_t iterator)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)iterator;
    tb_assert(hash_map);

    // find the head
    tb_size_t i = 0;
    tb_size_t n = hash_map->hash_size;
    for (i = 0; i < n; i++)
    {
        tb_hash_map_item_list_t* list = hash_map->hash_list[i];
        if (list && list->size) return tb_hash_map_index_make(i + 1, 1);
    }
    return 0;
}
static tb_size_t tb_hash_map_itor_tail(tb_iterator_ref_t iterator)
{
    return 0;
}
static tb_size_t tb_hash_map_itor_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)iterator;
    tb_assert(hash_map && hash_map->hash_list && hash_map->hash_size);

    // the current buck and item
    tb_size_t buck = tb_hash_map_index_buck(itor);
    tb_size_t item = tb_hash_map_index_item(itor);
    tb_assert(buck && item);

    // compute index
    buck--;
    item--;
    tb_assert(buck < hash_map->hash_size && (item + 1) < TB_HASH_MAP_BUCKET_ITEM_MAXN);

    // find the next from the current buck first
    if (hash_map->hash_list[buck] && item + 1 < hash_map->hash_list[buck]->size) return tb_hash_map_index_make(buck + 1, item + 2);

    // find the next from the next buckets
    tb_size_t i;
    tb_size_t n = hash_map->hash_size;
    for (i = buck + 1; i < n; i++)
    {
        tb_hash_map_item_list_t* list = hash_map->hash_list[i];
        if (list && list->size) return tb_hash_map_index_make(i + 1, 1);
    }

    // tail
    return 0;
}
static tb_pointer_t tb_hash_map_itor_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)iterator;
    tb_assert(hash_map && itor);

    // get the buck and item
    tb_size_t buck = tb_hash_map_index_buck(itor);
    tb_size_t item = tb_hash_map_index_item(itor);
    tb_assert_and_check_return_val(buck && item, tb_null);

    // get item
    if (tb_hash_map_item_at(hash_map, buck - 1, item - 1, &((tb_hash_map_t*)hash_map)->item.name, &((tb_hash_map_t*)hash_map)->item.data))
        return &(hash_map->item);
    return tb_null;
}
static tb_void_t tb_hash_map_itor_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)iterator;
    tb_assert(hash_map && hash_map->hash_list && hash_map->hash_size);
    
    // the buck and item
    tb_size_t b = tb_hash_map_index_buck(itor);
    tb_size_t i = tb_hash_map_index_item(itor);
    tb_assert(b && i); b--; i--;
    tb_assert(b < hash_map->hash_size);

    // step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert(step);

    // list
    tb_hash_map_item_list_t* list = hash_map->hash_list[b];
    tb_check_return(list && list->size && i < list->size);

    // note: copy data only, will destroy hash_map index if copy name
    hash_map->element_data.copy(&hash_map->element_data, ((tb_byte_t*)&list[1]) + i * step + hash_map->element_name.size, item);
}
static tb_long_t tb_hash_map_itor_comp(tb_iterator_ref_t iterator, tb_cpointer_t lelement, tb_cpointer_t relement)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)iterator;
    tb_assert(hash_map && hash_map->element_name.comp && lelement && relement);
    
    // done
    return hash_map->element_name.comp(&hash_map->element_name, ((tb_hash_map_item_ref_t)lelement)->name, ((tb_hash_map_item_ref_t)relement)->name);
}
static tb_void_t tb_hash_map_itor_remove(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)iterator;
    tb_assert(hash_map && hash_map->hash_list && hash_map->hash_size);
    
    // buck & item
    tb_size_t buck = tb_hash_map_index_buck(itor);
    tb_size_t item = tb_hash_map_index_item(itor);
    tb_assert(buck && item); buck--; item--;
    tb_assert(buck < hash_map->hash_size);

    // the step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert(step);

    // get list
    tb_hash_map_item_list_t* list = hash_map->hash_list[buck];
    tb_assert(list && list->size && item < list->size);

    // free item
    if (hash_map->element_name.free) hash_map->element_name.free(&hash_map->element_name, ((tb_byte_t*)&list[1]) + item * step);
    if (hash_map->element_data.free) hash_map->element_data.free(&hash_map->element_data, ((tb_byte_t*)&list[1]) + item * step + hash_map->element_name.size);

    // remove item from the list
    if (list->size > 1)
    {
        // move items
        if (item < list->size - 1) tb_memmov(((tb_byte_t*)&list[1]) + item * step, ((tb_byte_t*)&list[1]) + (item + 1) * step, (list->size - item - 1) * step);

        // update size
        list->size--;
    }
    // remove list
    else 
    {
        // free it
        tb_free(list);

        // reset
        hash_map->hash_list[buck] = tb_null;
    }

    // update the hash_map item size
    hash_map->item_size--;
}
static tb_void_t tb_hash_map_itor_nremove(tb_iterator_ref_t iterator, tb_size_t prev, tb_size_t next, tb_size_t size)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)iterator;
    tb_assert(hash_map && hash_map->hash_list && hash_map->hash_size);

    // no size
    tb_check_return(size);

    // the step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert(step);

    // the first itor
    tb_size_t itor = prev? tb_hash_map_itor_next(iterator, prev) : tb_hash_map_itor_head(iterator);

    // the head buck and item
    tb_size_t buck_head = tb_hash_map_index_buck(itor);
    tb_size_t item_head = tb_hash_map_index_item(itor);
    tb_assert(buck_head && item_head);

    // compute index
    buck_head--;
    item_head--;
    tb_assert(buck_head < hash_map->hash_size && item_head < TB_HASH_MAP_BUCKET_ITEM_MAXN);

    // the last buck and the tail item
    tb_size_t buck_last;
    tb_size_t item_tail;
    if (next)
    {
        // next => buck and item
        buck_last = tb_hash_map_index_buck(next);
        item_tail = tb_hash_map_index_item(next);
        tb_assert(buck_last && item_tail);

        // compute index
        buck_last--;
        item_tail--;
        tb_assert(buck_last < hash_map->hash_size && item_tail < TB_HASH_MAP_BUCKET_ITEM_MAXN);
    }
    else 
    {
        buck_last = hash_map->hash_size - 1;
        item_tail = -1;
    }

    // remove items: [itor, next)
    tb_size_t buck;
    tb_size_t item;
    tb_element_free_func_t name_free = hash_map->element_name.free;
    tb_element_free_func_t data_free = hash_map->element_data.free;
    for (buck = buck_head, item = item_head; buck <= buck_last; buck++, item = 0)
    {
        // the list
        tb_hash_map_item_list_t* list = hash_map->hash_list[buck];
        tb_check_continue(list && list->size);

        // the tail
        tb_size_t tail = (buck == buck_last && next)? item_tail : list->size;
        tb_assert(tail != -1);
        tb_check_continue(item < tail);

        // the data
        tb_byte_t* data = (tb_byte_t*)&list[1];

        // free items
        tb_size_t i = 0;
        for (i = item; i < tail; i++)
        {
            if (name_free) name_free(&hash_map->element_name, data + i * step);
            if (data_free) data_free(&hash_map->element_data, data + i * step + hash_map->element_name.size);
        }

        // move items
        if (buck == buck_last && tail < list->size) tb_memmov(data + item * step, data + tail * step, (list->size - tail) * step);

        // update the list size
        list->size -= tail - item;

        // update the item size
        hash_map->item_size -= tail - item;
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_hash_map_ref_t tb_hash_map_init(tb_size_t bucket_size, tb_element_t element_name, tb_element_t element_data)
{
    // check
    tb_assert_and_check_return_val(element_name.size && element_name.hash && element_name.comp && element_name.data && element_name.dupl, tb_null);
    tb_assert_and_check_return_val(element_data.data && element_data.dupl && element_data.repl, tb_null);

    // check bucket size
    if (!bucket_size) bucket_size = TB_HASH_MAP_BUCKET_SIZE_DEFAULT;
    tb_assert_and_check_return_val(bucket_size <= TB_HASH_MAP_BUCKET_SIZE_LARGE, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_hash_map_t*  hash_map = tb_null;
    do
    {
        // make self
        hash_map = tb_malloc0_type(tb_hash_map_t);
        tb_assert_and_check_break(hash_map);

        // init self func
        hash_map->element_name = element_name;
        hash_map->element_data = element_data;

        // init operation
        static tb_iterator_op_t op = 
        {
            tb_hash_map_itor_size
        ,   tb_hash_map_itor_head
        ,   tb_null
        ,   tb_hash_map_itor_tail
        ,   tb_null
        ,   tb_hash_map_itor_next
        ,   tb_hash_map_itor_item
        ,   tb_hash_map_itor_comp
        ,   tb_hash_map_itor_copy
        ,   tb_hash_map_itor_remove
        ,   tb_hash_map_itor_nremove
        };

        // init iterator
        hash_map->itor.priv = tb_null;
        hash_map->itor.step = sizeof(tb_hash_map_item_t);
        hash_map->itor.mode = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_MUTABLE;
        hash_map->itor.op   = &op;

        // init self size
        hash_map->hash_size = tb_align_pow2(bucket_size);
        tb_assert_and_check_break(hash_map->hash_size <= TB_HASH_MAP_BUCKET_MAXN);

        // init self list
        hash_map->hash_list = (tb_hash_map_item_list_t**)tb_nalloc0(hash_map->hash_size, sizeof(tb_size_t));
        tb_assert_and_check_break(hash_map->hash_list);

        // init item grow
        hash_map->item_grow = tb_isqrti((tb_uint32_t)bucket_size);
        if (hash_map->item_grow < 8) hash_map->item_grow = 8;
        hash_map->item_grow = tb_align_pow2(hash_map->item_grow);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (hash_map) tb_hash_map_exit((tb_hash_map_ref_t)hash_map);
        hash_map = tb_null;
    }

    // ok?
    return (tb_hash_map_ref_t)hash_map;
}
tb_void_t tb_hash_map_exit(tb_hash_map_ref_t self)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)self;
    tb_assert_and_check_return(hash_map);

    // clear it
    tb_hash_map_clear(self);

    // free hash_map list
    if (hash_map->hash_list) tb_free(hash_map->hash_list);

    // free it
    tb_free(hash_map);
}
tb_void_t tb_hash_map_clear(tb_hash_map_ref_t self)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)self;
    tb_assert_and_check_return(hash_map && hash_map->hash_list);

    // step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert_and_check_return(step);

    // clear hash_map
    tb_size_t i = 0;
    tb_size_t n = hash_map->hash_size;
    for (i = 0; i < n; i++)
    {
        tb_hash_map_item_list_t* list = hash_map->hash_list[i];
        if (list)
        {
            // free items
            if (hash_map->element_name.free || hash_map->element_data.free)
            {
                tb_size_t j = 0;
                tb_size_t m = list->size;
                for (j = 0; j < m; j++)
                {
                    tb_byte_t* item = ((tb_byte_t*)&list[1]) + j * step;
                    if (hash_map->element_name.free) hash_map->element_name.free(&hash_map->element_name, item);
                    if (hash_map->element_data.free) hash_map->element_data.free(&hash_map->element_data, item + hash_map->element_name.size);
                }
            }

            // free list
            tb_free(list);
        }
        hash_map->hash_list[i] = tb_null;
    }

    // reset info
    hash_map->item_size = 0;
    hash_map->item_maxn = 0;
    tb_memset(&hash_map->item, 0, sizeof(tb_hash_map_item_t));
}
tb_pointer_t tb_hash_map_get(tb_hash_map_ref_t self, tb_cpointer_t name)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)self;
    tb_assert_and_check_return_val(hash_map, tb_null);

    // find it
    tb_size_t buck = 0;
    tb_size_t item = 0;
    if (!tb_hash_map_item_find(hash_map, name, &buck, &item)) return tb_null;

    // get data
    tb_pointer_t data = tb_null;
    return tb_hash_map_item_at(hash_map, buck, item, tb_null, &data)? data : tb_null;
}
tb_size_t tb_hash_map_find(tb_hash_map_ref_t self, tb_cpointer_t name)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)self;
    tb_assert_and_check_return_val(hash_map, 0);

    // find
    tb_size_t buck = 0;
    tb_size_t item = 0;
    return tb_hash_map_item_find(hash_map, name, &buck, &item)? tb_hash_map_index_make(buck + 1, item + 1) : 0;
}
tb_size_t tb_hash_map_insert(tb_hash_map_ref_t self, tb_cpointer_t name, tb_cpointer_t data)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)self;
    tb_assert_and_check_return_val(hash_map, 0);

    // the step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert_and_check_return_val(step, 0);

    // find it
    tb_size_t buck = 0;
    tb_size_t item = 0;
    if (tb_hash_map_item_find(hash_map, name, &buck, &item))
    {
        // check
        tb_assert_and_check_return_val(buck < hash_map->hash_size, 0);

        // get list
        tb_hash_map_item_list_t* list = hash_map->hash_list[buck];
        tb_assert_and_check_return_val(list && list->size && item < list->size, 0);

        // replace data
        hash_map->element_data.repl(&hash_map->element_data, ((tb_byte_t*)&list[1]) + item * step + hash_map->element_name.size, data);
    }
    else
    {
        // check
        tb_assert_and_check_return_val(buck < hash_map->hash_size, 0);

        // get list
        tb_hash_map_item_list_t* list = hash_map->hash_list[buck];
        
        // insert item
        if (list)
        {
            // grow?
            if (list->size >= list->maxn)
            {
                // check
                tb_assert_and_check_return_val(hash_map->item_grow, 0);

                // resize maxn
                tb_size_t maxn = tb_align_pow2(list->maxn + hash_map->item_grow);
                tb_assert_and_check_return_val(maxn > list->maxn, 0);

                // realloc it
                list = (tb_hash_map_item_list_t*)tb_ralloc(list, sizeof(tb_hash_map_item_list_t) + maxn * step);  
                tb_assert_and_check_return_val(list, 0);

                // update the hash_map item maxn
                hash_map->item_maxn += maxn - list->maxn;

                // update maxn
                list->maxn = maxn;

                // reattach list
                hash_map->hash_list[buck] = list;
            }
            tb_assert_and_check_return_val(item <= list->size && list->size < list->maxn, 0);

            // move items
            if (item != list->size) tb_memmov(((tb_byte_t*)&list[1]) + (item + 1) * step, ((tb_byte_t*)&list[1]) + item * step, (list->size - item) * step);

            // dupl item
            list->size++;
            hash_map->element_name.dupl(&hash_map->element_name, ((tb_byte_t*)&list[1]) + item * step, name);
            hash_map->element_data.dupl(&hash_map->element_data, ((tb_byte_t*)&list[1]) + item * step + hash_map->element_name.size, data);

        }
        // create list for adding item
        else
        {
            // check
            tb_assert_and_check_return_val(hash_map->item_grow, 0);

            // make list
            list = (tb_hash_map_item_list_t*)tb_malloc0(sizeof(tb_hash_map_item_list_t) + hash_map->item_grow * step);
            tb_assert_and_check_return_val(list, 0);

            // init list
            list->size = 1;
            list->maxn = hash_map->item_grow;
            hash_map->element_name.dupl(&hash_map->element_name, ((tb_byte_t*)&list[1]), name);
            hash_map->element_data.dupl(&hash_map->element_data, ((tb_byte_t*)&list[1]) + hash_map->element_name.size, data);

            // attach list
            hash_map->hash_list[buck] = list;

            // update the hash_map item maxn
            hash_map->item_maxn += list->maxn;
        }

        // update the hash_map item size
        hash_map->item_size++;
    }

    // ok?
    return tb_hash_map_index_make(buck + 1, item + 1);
}
tb_void_t tb_hash_map_remove(tb_hash_map_ref_t self, tb_cpointer_t name)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)self;
    tb_assert_and_check_return(hash_map);

    // find it
    tb_size_t buck = 0;
    tb_size_t item = 0;
    if (tb_hash_map_item_find(hash_map, name, &buck, &item))
        tb_hash_map_itor_remove((tb_iterator_ref_t)hash_map, tb_hash_map_index_make(buck + 1, item + 1));
}
tb_size_t tb_hash_map_size(tb_hash_map_ref_t self)
{
    // check
    tb_hash_map_t const* hash_map = (tb_hash_map_t const*)self;
    tb_assert_and_check_return_val(hash_map, 0);

    // the size
    return hash_map->item_size;
}
tb_size_t tb_hash_map_maxn(tb_hash_map_ref_t self)
{
    // check
    tb_hash_map_t const* hash_map = (tb_hash_map_t const*)self;
    tb_assert_and_check_return_val(hash_map, 0);

    // the maxn
    return hash_map->item_maxn;
}
#ifdef __tb_debug__
tb_void_t tb_hash_map_dump(tb_hash_map_ref_t self)
{
    // check
    tb_hash_map_t* hash_map = (tb_hash_map_t*)self;
    tb_assert_and_check_return(hash_map && hash_map->hash_list);

    // the step
    tb_size_t step = hash_map->element_name.size + hash_map->element_data.size;
    tb_assert_and_check_return(step);

    // trace
    tb_trace_i("");
    tb_trace_i("self: size: %lu", tb_hash_map_size(self));

    // done
    tb_size_t i = 0;
    tb_char_t name[4096];
    tb_char_t data[4096];
    for (i = 0; i < hash_map->hash_size; i++)
    {
        // the list
        tb_hash_map_item_list_t* list = hash_map->hash_list[i];
        if (list)
        {
            // trace
            tb_trace_i("buck[%u]: size: %u, maxn: %u", i, list->size, list->maxn);

            // done 
            tb_size_t j = 0;
            for (j = 0; j < list->size; j++)
            {
                // the item
                tb_byte_t const* item = ((tb_byte_t*)&list[1]) + j * step;

                // the item name
                tb_pointer_t element_name = hash_map->element_name.data(&hash_map->element_name, item);

                // the item data
                tb_pointer_t element_data = hash_map->element_data.data(&hash_map->element_data, item + hash_map->element_name.size);

                // trace
                if (hash_map->element_name.cstr && hash_map->element_data.cstr)
                {
                    tb_trace_i("    %s => %s", hash_map->element_name.cstr(&hash_map->element_name, element_name, name, sizeof(name)), hash_map->element_data.cstr(&hash_map->element_data, element_data, data, sizeof(data)));
                }
                else if (hash_map->element_name.cstr) 
                {
                    tb_trace_i("    %s => %p", hash_map->element_name.cstr(&hash_map->element_name, element_name, name, sizeof(name)), element_data);
                }
                else if (hash_map->element_data.cstr) 
                {
                    tb_trace_i("    %x => %p", element_name, hash_map->element_data.cstr(&hash_map->element_data, element_data, data, sizeof(data)));
                }
                else 
                {
                    tb_trace_i("    %p => %p", element_name, element_data);
                }
            }
        }
    }
}
#endif
