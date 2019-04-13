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
 * @file        single_list.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "single_list"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "single_list.h"
#include "single_list_entry.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../memory/memory.h"
#include "../stream/stream.h"
#include "../platform/platform.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the self grow
#ifdef __tb_small__ 
#   define TB_SINGLE_LIST_GROW             (128)
#else
#   define TB_SINGLE_LIST_GROW             (256)
#endif

// the self maxn
#ifdef __tb_small__
#   define TB_SINGLE_LIST_MAXN             (1 << 16)
#else
#   define TB_SINGLE_LIST_MAXN             (1 << 30)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the single list type
typedef struct __tb_single_list_t
{
    // the itor
    tb_iterator_t                   itor;

    // the pool
    tb_fixed_pool_ref_t             pool;

    // the head
    tb_single_list_entry_head_t     head;

    // the element
    tb_element_t                    element;

}tb_single_list_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_size_t tb_single_list_itor_size(tb_iterator_ref_t iterator)
{
    // the size
    return tb_single_list_size((tb_single_list_ref_t)iterator);
}
static tb_size_t tb_single_list_itor_head(tb_iterator_ref_t iterator)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)iterator;
    tb_assert(list);

    // head
    return (tb_size_t)tb_single_list_entry_head(&list->head);
}
static tb_size_t tb_single_list_itor_last(tb_iterator_ref_t iterator)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)iterator;
    tb_assert(list);

    // last
    return (tb_size_t)tb_single_list_entry_last(&list->head);
}
static tb_size_t tb_single_list_itor_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)iterator;
    tb_assert(list);

    // tail
    return (tb_size_t)tb_single_list_entry_tail(&list->head);
}
static tb_size_t tb_single_list_itor_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(itor);

    // next
    return (tb_size_t)tb_single_list_entry_next((tb_single_list_entry_t*)itor);
}
static tb_pointer_t tb_single_list_itor_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)iterator;
    tb_assert(list && itor);

    // data
    return list->element.data(&list->element, (tb_cpointer_t)(((tb_single_list_entry_t*)itor) + 1));
}
static tb_void_t tb_single_list_itor_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)iterator;
    tb_assert(list && itor);

    // copy
    list->element.copy(&list->element, (tb_pointer_t)(((tb_single_list_entry_t*)itor) + 1), item);
}
static tb_long_t tb_single_list_itor_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)iterator;
    tb_assert(list && list->element.comp);

    // comp
    return list->element.comp(&list->element, litem, ritem);
}
static tb_void_t tb_single_list_itor_nremove(tb_iterator_ref_t iterator, tb_size_t prev, tb_size_t next, tb_size_t size)
{
    // no size?
    tb_check_return(size);

    // the self size
    tb_size_t single_list_size = tb_single_list_size((tb_single_list_ref_t)iterator);
    tb_check_return(single_list_size);

    // limit size
    if (size > single_list_size) size = single_list_size;

    // remove the body items
    if (prev) 
    {
        // done
        tb_bool_t end = tb_false;
        while (size-- && !end) 
        {
            // end?
            end = (tb_iterator_next((tb_single_list_ref_t)iterator, prev) == next)? tb_true : tb_false;

            // remove next
            tb_single_list_remove_next((tb_single_list_ref_t)iterator, prev);
        }
    }
    // remove the head items
    else 
    {
        while (size--) tb_single_list_remove_head((tb_single_list_ref_t)iterator);
    }
}
static tb_void_t tb_single_list_item_exit(tb_pointer_t data, tb_cpointer_t priv)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)priv;
    tb_assert_and_check_return(list);

    // free data
    if (list->element.free) list->element.free(&list->element, (tb_pointer_t)(((tb_single_list_entry_t*)data) + 1));
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_single_list_ref_t tb_single_list_init(tb_size_t grow, tb_element_t element)
{
    // check
    tb_assert_and_check_return_val(element.size && element.data && element.dupl && element.repl, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_single_list_t*   list = tb_null;
    do
    {
        // using the default grow
        if (!grow) grow = TB_SINGLE_LIST_GROW;

        // make self
        list = tb_malloc0_type(tb_single_list_t);
        tb_assert_and_check_break(list);

        // init element
        list->element = element;

        // init operation
        static tb_iterator_op_t op = 
        {
            tb_single_list_itor_size
        ,   tb_single_list_itor_head
        ,   tb_single_list_itor_last
        ,   tb_single_list_itor_tail
        ,   tb_null
        ,   tb_single_list_itor_next
        ,   tb_single_list_itor_item
        ,   tb_single_list_itor_comp
        ,   tb_single_list_itor_copy
        ,   tb_null
        ,   tb_single_list_itor_nremove
        };

        // init iterator
        list->itor.priv = tb_null;
        list->itor.step = element.size;
        list->itor.mode = TB_ITERATOR_MODE_FORWARD;
        list->itor.op   = &op;

        // init pool, item = entry + data
        list->pool = tb_fixed_pool_init(tb_null, grow, sizeof(tb_single_list_entry_t) + element.size, tb_null, tb_single_list_item_exit, (tb_cpointer_t)list);
        tb_assert_and_check_break(list->pool);

        // init head
        tb_single_list_entry_init_(&list->head, 0, sizeof(tb_single_list_entry_t) + element.size, tb_null);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (list) tb_single_list_exit((tb_single_list_ref_t)list);
        list = tb_null;
    }

    // ok?
    return (tb_single_list_ref_t)list;
}
tb_void_t tb_single_list_exit(tb_single_list_ref_t self)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return(list);
   
    // clear data
    tb_single_list_clear((tb_single_list_ref_t)list);

    // free pool
    if (list->pool) tb_fixed_pool_exit(list->pool);

    // free it
    tb_free(list);
}
tb_void_t tb_single_list_clear(tb_single_list_ref_t self)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return(list);

    // clear pool
    if (list->pool) tb_fixed_pool_clear(list->pool);

    // clear head
    tb_single_list_entry_clear(&list->head);
}
tb_pointer_t tb_single_list_head(tb_single_list_ref_t self)
{
    return tb_iterator_item(self, tb_iterator_head(self));
}
tb_pointer_t tb_single_list_last(tb_single_list_ref_t self)
{
    return tb_iterator_item(self, tb_iterator_last(self));
}
tb_size_t tb_single_list_size(tb_single_list_ref_t self)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return_val(list && list->pool, 0);
    tb_assert(tb_single_list_entry_size(&list->head) == tb_fixed_pool_size(list->pool));

    // the size
    return tb_single_list_entry_size(&list->head);
}
tb_size_t tb_single_list_maxn(tb_single_list_ref_t self)
{
    // the item maxn
    return TB_SINGLE_LIST_MAXN;
}
tb_size_t tb_single_list_insert_next(tb_single_list_ref_t self, tb_size_t itor, tb_cpointer_t data)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return_val(list && list->element.dupl && list->pool, 0);

    // full?
    tb_assert_and_check_return_val(tb_single_list_size(self) < tb_single_list_maxn(self), tb_iterator_tail(self));

    // the node
    tb_single_list_entry_ref_t node = (tb_single_list_entry_ref_t)itor;
    tb_assert_and_check_return_val(node, tb_iterator_tail(self));

    // make entry
    tb_single_list_entry_ref_t entry = (tb_single_list_entry_ref_t)tb_fixed_pool_malloc(list->pool);
    tb_assert_and_check_return_val(entry, tb_iterator_tail(self));

    // init entry data
    list->element.dupl(&list->element, (tb_pointer_t)(((tb_single_list_entry_t*)entry) + 1), data);

    // insert it
    tb_single_list_entry_insert_next(&list->head, node, entry);

    // ok
    return (tb_size_t)entry;
}
tb_size_t tb_single_list_insert_head(tb_single_list_ref_t self, tb_cpointer_t data)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return_val(list && list->element.dupl && list->pool, 0);

    // full?
    tb_assert_and_check_return_val(tb_single_list_size(self) < tb_single_list_maxn(self), tb_iterator_tail(self));

    // make entry
    tb_single_list_entry_ref_t entry = (tb_single_list_entry_ref_t)tb_fixed_pool_malloc(list->pool);
    tb_assert_and_check_return_val(entry, tb_iterator_tail(self));

    // init entry data
    list->element.dupl(&list->element, (tb_pointer_t)(((tb_single_list_entry_t*)entry) + 1), data);

    // insert it
    tb_single_list_entry_insert_head(&list->head, entry);

    // ok
    return (tb_size_t)entry;
}
tb_size_t tb_single_list_insert_tail(tb_single_list_ref_t self, tb_cpointer_t data)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return_val(list && list->element.dupl && list->pool, 0);

    // full?
    tb_assert_and_check_return_val(tb_single_list_size(self) < tb_single_list_maxn(self), tb_iterator_tail(self));

    // make entry
    tb_single_list_entry_ref_t entry = (tb_single_list_entry_ref_t)tb_fixed_pool_malloc(list->pool);
    tb_assert_and_check_return_val(entry, tb_iterator_tail(self));

    // init entry data
    list->element.dupl(&list->element, (tb_pointer_t)(((tb_single_list_entry_t*)entry) + 1), data);

    // insert it
    tb_single_list_entry_insert_tail(&list->head, entry);

    // ok
    return (tb_size_t)entry;
}
tb_void_t tb_single_list_replace(tb_single_list_ref_t self, tb_size_t itor, tb_cpointer_t data)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return(list && list->element.repl && itor);

    // the node
    tb_single_list_entry_ref_t node = (tb_single_list_entry_ref_t)itor;
    tb_assert_and_check_return(node);

    // replace data
    list->element.repl(&list->element, (tb_pointer_t)(((tb_single_list_entry_t*)node) + 1), data);
}
tb_void_t tb_single_list_replace_head(tb_single_list_ref_t self, tb_cpointer_t data)
{
    tb_single_list_replace(self, tb_iterator_head(self), data);
}
tb_void_t tb_single_list_replace_last(tb_single_list_ref_t self, tb_cpointer_t data)
{
    tb_single_list_replace(self, tb_iterator_last(self), data);
}
tb_void_t tb_single_list_remove_next(tb_single_list_ref_t self, tb_size_t itor)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return(list && list->pool && itor);

    // the node
    tb_single_list_entry_ref_t node = (tb_single_list_entry_ref_t)itor;
    tb_assert_and_check_return(node);

    // the next node
    tb_single_list_entry_ref_t next = tb_single_list_entry_next(node);
    tb_assert_and_check_return(next);

    // remove next node
    tb_single_list_entry_remove_next(&list->head, node);

    // free next node
    tb_fixed_pool_free(list->pool, next);
}
tb_void_t tb_single_list_remove_head(tb_single_list_ref_t self)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return(list && list->pool);

    // the node
    tb_single_list_entry_ref_t node = tb_single_list_entry_head(&list->head);
    tb_assert_and_check_return(node);

    // remove next node
    tb_single_list_entry_remove_head(&list->head);

    // free head node
    tb_fixed_pool_free(list->pool, node);
}
#ifdef __tb_debug__
tb_void_t tb_single_list_dump(tb_single_list_ref_t self)
{
    // check
    tb_single_list_t* list = (tb_single_list_t*)self;
    tb_assert_and_check_return(list);

    // trace
    tb_trace_i("single_list: size: %lu", tb_single_list_size(self));

    // done
    tb_char_t cstr[4096];
    tb_for_all (tb_pointer_t, data, self)
    {
        // trace
        if (list->element.cstr) 
        {
            tb_trace_i("    %s", list->element.cstr(&list->element, data, cstr, sizeof(cstr)));
        }
        else
        {
            tb_trace_i("    %p", data);
        }
    }
}
#endif
