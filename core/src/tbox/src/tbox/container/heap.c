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
 * @file        heap.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "heap"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "heap.h"
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

// the self grow
#ifdef __tb_small__ 
#   define TB_HEAP_GROW             (128)
#else
#   define TB_HEAP_GROW             (256)
#endif

// the self maxn
#ifdef __tb_small__
#   define TB_HEAP_MAXN             (1 << 16)
#else
#   define TB_HEAP_MAXN             (1 << 30)
#endif

// enable check
#ifdef __tb_debug__
#   define TB_HEAP_CHECK_ENABLE     (0)
#else
#   define TB_HEAP_CHECK_ENABLE     (0)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the self type
typedef struct __tb_heap_t
{
    // the itor
    tb_iterator_t           itor;

    // the data
    tb_byte_t*              data;

    // the size
    tb_size_t               size;

    // the maxn
    tb_size_t               maxn;

    // the grow
    tb_size_t               grow;

    // the element
    tb_element_t            element;

}tb_heap_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#if TB_HEAP_CHECK_ENABLE
static tb_void_t tb_heap_check(tb_heap_t* heap)
{
    // init
    tb_byte_t*  data = heap->data;
    tb_size_t   tail = heap->size;
    tb_size_t   step = heap->element.size;
    tb_size_t   parent = 0;

    // done
    for (; parent < tail; parent++)
    {   
        // the left child node
        tb_size_t lchild = (parent << 1) + 1;
        tb_check_break(lchild < tail);

        // the parent data
        tb_pointer_t parent_data = heap->element.data(&heap->element, data + parent * step);

        // check?
        if (heap->element.comp(&heap->element, heap->element.data(&heap->element, data + lchild * step), parent_data) < 0) 
        {
            // dump self
            tb_heap_dump((tb_heap_ref_t)heap);

            // abort
            tb_assertf(0, "lchild[%lu]: invalid, parent: %lu, tail: %lu", lchild, parent, tail);
        }

        // the right child node
        tb_size_t rchild = lchild + 1;
        tb_check_break(rchild < tail);

        // check?
        if (heap->element.comp(&heap->element, heap->element.data(&heap->element, data + rchild * step), parent_data) < 0) 
        {
            // dump self
            tb_heap_dump((tb_heap_ref_t)heap);

            // abort
            tb_assertf(0, "rchild[%lu]: invalid, parent: %lu, tail: %lu", rchild, parent, tail);
        }
    }
}
#endif
/*! shift up the self
 *
 * <pre>
 *
 * before:
 * 
 *                                          1(head)
 *                               -------------------------
 *                              |                         |
 *                              4                         2
 *                        --------------             -------------
 *                       |              |           |             |
 *                       6(parent)      9           7             8
 *                   ---------       
 *                  |         |     
 *                  10      5(hole) <------ data
 * after:
 *
 *                                          1(head)
 *                               -------------------------
 *                              |                         |
 *                              4                         2
 *                        --------------             -------------
 *                       |              |           |             |
 *         data -------> 5(hole)        9           7             8
 *                   ---------       
 *                  |         |     
 *                  10        6
 * </pre>
 */
static tb_pointer_t tb_heap_shift_up(tb_heap_t* heap, tb_size_t hole, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return_val(heap && heap->data, tb_null);

    // the element function
    tb_element_comp_func_t func_comp = heap->element.comp;
    tb_element_data_func_t func_data = heap->element.data;
    tb_assert(func_comp && func_data);

    // (hole - 1) / 2: the parent node of the hole
    tb_size_t   parent = 0;
    tb_byte_t*  head = heap->data;
    tb_size_t   step = heap->element.size;
    switch (step)
    {
    case sizeof(tb_size_t):
        {
            for (parent = (hole - 1) >> 1; hole && (func_comp(&heap->element, func_data(&heap->element, head + parent * step), data) > 0); parent = (hole - 1) >> 1)
            {
                // move item: parent => hole
                *((tb_size_t*)(head + hole * step)) = *((tb_size_t*)(head + parent * step));

                // move node: hole => parent
                hole = parent;
            }
        }
        break;
    default:
        for (parent = (hole - 1) >> 1; hole && (func_comp(&heap->element, func_data(&heap->element, head + parent * step), data) > 0); parent = (hole - 1) >> 1)
        {
            // move item: parent => hole
            tb_memcpy(head + hole * step, head + parent * step, step);

            // move node: hole => parent
            hole = parent;
        }
        break;
    }

    // ok?
    return head + hole * step;
}
/*! shift down the self
 *
 * <pre>
 * 
 * before:
 *                                          1(head)
 *                               -------------------------
 *                              |                         |
 *                           (hole)                       2
 *                        --------------             -------------
 *                       |              |           |             |
 *            lchild --> 6(smaller)     7           7             8
 *                   ---------     ------
 *                  |         |   |          
 *                 11        16  10          
 *
 *
 * move hole:
 *                                          1(head)
 *                               -------------------------
 *                              |                         |
 *                              6                         2
 *                        --------------             -------------
 *                       |              |           |             |
 *                     (hole)           7           7             8
 *                   ---------      -----                                                   
 *                  |         |    |                                                  
 *      lchild --> 11(smaller)16  10                                                   
 *
 * 11 >= data: 9? break it
 *
 * move data to hole:
 *                                          1(head)
 *                               -------------------------
 *                              |                         |
 *                              6                         2
 *                        --------------             -------------
 *                       |              |           |             |
 *    data ------------> 9              7           7             8
 *                   ---------       ---                                                   
 *                  |         |     |                                                        
 *                 11        16    10
 * 
 * </pre>
 */
static tb_pointer_t tb_heap_shift_down(tb_heap_t* heap, tb_size_t hole, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return_val(heap && heap->data, tb_null);

    // init element
    tb_element_comp_func_t func_comp = heap->element.comp;
    tb_element_data_func_t func_data = heap->element.data;
    tb_assert(func_comp && func_data);

    // 2 * hole + 1: the left child node of hole
    tb_size_t       step = heap->element.size;
    tb_byte_t*      head = heap->data;
    tb_byte_t*      tail = head + heap->size * step;
    tb_byte_t*      phole = head + hole * step;
    tb_byte_t*      lchild = head + ((hole << 1) + 1) * step;
    tb_pointer_t    data_lchild = tb_null;
    tb_pointer_t    data_rchild = tb_null;
    switch (step)
    {
    case sizeof(tb_size_t):
        {
            for (; lchild < tail; lchild = head + (((lchild - head) << 1) + step))
            {   
                // the smaller child node
                data_lchild = func_data(&heap->element, lchild);
                if (lchild + step < tail && func_comp(&heap->element, data_lchild, (data_rchild = func_data(&heap->element, lchild + step))) > 0) 
                {
                    lchild += step;
                    data_lchild = data_rchild;
                }

                // end?
                if (func_comp(&heap->element, data_lchild, data) >= 0) break;

                // the smaller child node => hole
                *((tb_size_t*)phole) = *((tb_size_t*)lchild);

                // move the hole down to it's smaller child node 
                phole = lchild;
            }
        }
        break;
    default:
        {
            for (; lchild < tail; lchild = head + (((lchild - head) << 1) + step))
            {   
                // the smaller child node
                data_lchild = func_data(&heap->element, lchild);
                if (lchild + step < tail && func_comp(&heap->element, data_lchild, (data_rchild = func_data(&heap->element, lchild + step))) > 0) 
                {
                    lchild += step;
                    data_lchild = data_rchild;
                }

                // end?
                if (func_comp(&heap->element, data_lchild, data) >= 0) break;

                // the smaller child node => hole
                tb_memcpy(phole, lchild, step);

                // move the hole down to it's smaller child node 
                phole = lchild;
            }
        }
        break;
    }

    // ok?
    return phole;
}
static tb_size_t tb_heap_itor_size(tb_iterator_ref_t iterator)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return_val(heap, 0);

    // size
    return heap->size;
}
static tb_size_t tb_heap_itor_head(tb_iterator_ref_t iterator)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return_val(heap, 0);

    // head
    return 0;
}
static tb_size_t tb_heap_itor_last(tb_iterator_ref_t iterator)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return_val(heap, 0);

    // last
    return heap->size? heap->size - 1 : 0;
}
static tb_size_t tb_heap_itor_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return_val(heap, 0);

    // tail
    return heap->size;
}
static tb_size_t tb_heap_itor_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return_val(heap, 0);
    tb_assert_and_check_return_val(itor < heap->size, heap->size);

    // next
    return itor + 1;
}
static tb_size_t tb_heap_itor_prev(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return_val(heap, 0);
    tb_assert_and_check_return_val(itor && itor < heap->size, 0);

    // prev
    return itor - 1;
}
static tb_pointer_t tb_heap_itor_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return_val(heap && itor < heap->size, tb_null);
    
    // data
    return heap->element.data(&heap->element, heap->data + itor * iterator->step);
}
static tb_void_t tb_heap_itor_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return(heap);

    // copy
    heap->element.copy(&heap->element, heap->data + itor * iterator->step, item);
}
static tb_long_t tb_heap_itor_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return_val(heap && heap->element.comp, 0);

    // comp
    return heap->element.comp(&heap->element, litem, ritem);
}
static tb_void_t tb_heap_itor_remove(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)iterator;
    tb_assert_and_check_return(heap && heap->data && heap->size && itor < heap->size);

    // check the element function
    tb_assert(heap->element.comp && heap->element.data);

    // the step
    tb_size_t step = heap->element.size;
    tb_assert(step);

    // free the item first
    if (heap->element.free) heap->element.free(&heap->element, heap->data + itor * step);

    // the removed item is not the last item?
    if (itor != heap->size - 1)
    {
        // the last and parent
        tb_pointer_t last = heap->data + (heap->size - 1) * step;
        tb_pointer_t parent = heap->data + ((itor - 1) >> 1) * step;

        // the last and parent data
        tb_pointer_t data_last = heap->element.data(&heap->element, last);
        tb_pointer_t data_parent = heap->element.data(&heap->element, parent);

        /* we might need to shift it upward if it is less than its parent, 
         * or downward if it is greater than one or both its children. 
         *
         * since the children are known to be less than the parent, 
         * it can't need to shift both up and down.
         */
        tb_pointer_t hole = tb_null;
        if (itor && heap->element.comp(&heap->element, data_parent, data_last) > 0) 
        {
            // shift up the self from the given hole
            hole = tb_heap_shift_up(heap, itor, data_last);
        }
        // shift down the self from the given hole
        else hole = tb_heap_shift_down(heap, itor, data_last);
        tb_assert(hole);

        // copy the last data to the hole
        if (hole != last) tb_memcpy(hole, last, step);
    }

    // size--
    heap->size--;

    // check
#if TB_HEAP_CHECK_ENABLE
    tb_heap_check(heap);
#endif
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_heap_ref_t tb_heap_init(tb_size_t grow, tb_element_t element)
{
    // check
    tb_assert_and_check_return_val(element.size && element.data && element.dupl && element.repl, tb_null);

    // done
    tb_bool_t   ok = tb_false;
    tb_heap_t*  heap = tb_null;
    do
    {
        // using the default grow
        if (!grow) grow = TB_HEAP_GROW;

        // make heap
        heap = tb_malloc0_type(tb_heap_t);
        tb_assert_and_check_break(heap);

        // init heap
        heap->size      = 0;
        heap->grow      = grow;
        heap->maxn      = grow;
        heap->element   = element;
        tb_assert_and_check_break(heap->maxn < TB_HEAP_MAXN);

        // init operation
        static tb_iterator_op_t op = 
        {
            tb_heap_itor_size
        ,   tb_heap_itor_head
        ,   tb_heap_itor_last
        ,   tb_heap_itor_tail
        ,   tb_heap_itor_prev
        ,   tb_heap_itor_next
        ,   tb_heap_itor_item
        ,   tb_heap_itor_comp
        ,   tb_heap_itor_copy
        ,   tb_heap_itor_remove
        ,   tb_null
        };

        // init iterator
        heap->itor.priv = tb_null;
        heap->itor.step = element.size;
        heap->itor.mode = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_MUTABLE;
        heap->itor.op   = &op;

        // make data
        heap->data = (tb_byte_t*)tb_nalloc0(heap->maxn, element.size);
        tb_assert_and_check_break(heap->data);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (heap) tb_heap_exit((tb_heap_ref_t)heap);
        heap = tb_null;
    }

    // ok?
    return (tb_heap_ref_t)heap;
}
tb_void_t tb_heap_exit(tb_heap_ref_t self)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)self;
    tb_assert_and_check_return(heap);

    // clear data
    tb_heap_clear(self);

    // free data
    if (heap->data) tb_free(heap->data);
    heap->data = tb_null;

    // free it
    tb_free(heap);
}
tb_void_t tb_heap_clear(tb_heap_ref_t self)
{   
    // check
    tb_heap_t* heap = (tb_heap_t*)self;
    tb_assert_and_check_return(heap);

    // free data
    if (heap->element.nfree)
        heap->element.nfree(&heap->element, heap->data, heap->size);

    // reset size 
    heap->size = 0;
}
tb_size_t tb_heap_size(tb_heap_ref_t self)
{
    // check
    tb_heap_t const* heap = (tb_heap_t const*)self;
    tb_assert_and_check_return_val(heap, 0);

    // size
    return heap->size;
}
tb_size_t tb_heap_maxn(tb_heap_ref_t self)
{
    // check
    tb_heap_t const* heap = (tb_heap_t const*)self;
    tb_assert_and_check_return_val(heap, 0);

    // maxn
    return heap->maxn;
}
tb_pointer_t tb_heap_top(tb_heap_ref_t self)
{
    return tb_iterator_item(self, tb_iterator_head(self));
}
tb_void_t tb_heap_put(tb_heap_ref_t self, tb_cpointer_t data)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)self;
    tb_assert_and_check_return(heap && heap->element.dupl && heap->data);

    // no enough? grow it
    if (heap->size == heap->maxn)
    {
        // the maxn
        tb_size_t maxn = tb_align4(heap->maxn + heap->grow);
        tb_assert_and_check_return(maxn < TB_HEAP_MAXN);

        // realloc data
        heap->data = (tb_byte_t*)tb_ralloc(heap->data, maxn * heap->element.size);
        tb_assert_and_check_return(heap->data);

        // must be align by 4-bytes
        tb_assert_and_check_return(!(((tb_size_t)(heap->data)) & 3));

        // clear the grow data
        tb_memset(heap->data + heap->size * heap->element.size, 0, (maxn - heap->maxn) * heap->element.size);

        // save maxn
        heap->maxn = maxn;
    }

    // check
    tb_assert_and_check_return(heap->size < heap->maxn);
    
    // shift up the self from the tail hole
    tb_pointer_t hole = tb_heap_shift_up(heap, heap->size, data);
    tb_assert(hole);
        
    // save data to the hole
    if (hole) heap->element.dupl(&heap->element, hole, data);

    // update the size
    heap->size++;

    // check
#if TB_HEAP_CHECK_ENABLE
    tb_heap_check(heap);
#endif
}
tb_void_t tb_heap_pop(tb_heap_ref_t self)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)self;
    tb_assert_and_check_return(heap && heap->data && heap->size);

    // free the top item first
    if (heap->element.free) heap->element.free(&heap->element, heap->data);

    // the last item is not in top 
    if (heap->size > 1)
    {
        // check the element function
        tb_assert(heap->element.data);

        // the step
        tb_size_t step = heap->element.size;
        tb_assert(step);

        // the last 
        tb_pointer_t last = heap->data + (heap->size - 1) * step;

        // shift down the self from the top hole
        tb_pointer_t hole = tb_heap_shift_down(heap, 0, heap->element.data(&heap->element, last));
        tb_assert(hole);

        // copy the last data to the hole
        if (hole != last) tb_memcpy(hole, last, step);
    }

    // update the size
    heap->size--;

    // check
#if TB_HEAP_CHECK_ENABLE
    tb_heap_check(heap);
#endif
}
tb_void_t tb_heap_remove(tb_heap_ref_t self, tb_size_t itor)
{
    tb_heap_itor_remove(self, itor);
}
#ifdef __tb_debug__
tb_void_t tb_heap_dump(tb_heap_ref_t self)
{
    // check
    tb_heap_t* heap = (tb_heap_t*)self;
    tb_assert_and_check_return(heap);

    // trace
    tb_trace_i("self: size: %lu", tb_heap_size(self));

    // done
    tb_char_t cstr[4096];
    tb_for_all (tb_pointer_t, data, self)
    {
        // trace
        if (heap->element.cstr) 
        {
#if TB_HEAP_CHECK_ENABLE
            tb_trace_i("    [%lu]: %s", data_itor, heap->element.cstr(&heap->element, data, cstr, sizeof(cstr)));
#else
            tb_trace_i("    %s", heap->element.cstr(&heap->element, data, cstr, sizeof(cstr)));
#endif
        }
        else
        {
            tb_trace_i("    %p", data);
        }
    }
}
#endif
