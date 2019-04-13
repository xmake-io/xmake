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
 * @file        heap_sort.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "heap_sort.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * head
 */
#ifdef __tb_debug__
static __tb_inline__ tb_bool_t tb_heap_check(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_iterator_comp_t comp)
{
    // the comparer 
    if (!comp) comp = tb_iterator_comp;

    // walk
    if (head != tail)
    {
        tb_size_t root;
        for (root = head; ++head != tail; ++root)
        {
            // root < left?
            if (tb_iterator_comp(iterator, tb_iterator_item(iterator, root), tb_iterator_item(iterator, head)) < 0) return tb_false;
            // end?
            else if (++head == tail) break;
            // root < right?
            else if (tb_iterator_comp(iterator, tb_iterator_item(iterator, root), tb_iterator_item(iterator, head)) < 0) return tb_false;
        }
    }

    // ok
    return tb_true;
}
#endif

/*!push heap
 *
 * <pre>
 * hole: bottom => top
 * init:
 *                                          16(top)
 *                               -------------------------
 *                              |                         |
 *                              14                        10
 *                        --------------             -------------
 *                       |              |           |             |
 *                       8(parent)      7           9             3
 *                   ---------      
 *                  |         |     
 *                  2      (hole) <= 11(val)
 * after:
 *                                          16(top)
 *                               -------------------------
 *                              |                         |
 *                              14(parent)                10
 *                        --------------             -------------
 *                       |              |           |             |
 *                       11(hole)       7           9             3
 *                   ---------      
 *                  |         |    
 *                  2         8 
 * </pre>
 */
#if 0
static __tb_inline__ tb_void_t tb_heap_push(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t hole, tb_size_t top, tb_cpointer_t item, tb_iterator_comp_t comp)
{
    // check
    tb_assert_and_check_return(comp);

    // (hole - 1) / 2: the parent node of the hole
    // finds the final hole
    tb_size_t       parent = 0;
    tb_cpointer_t   parent_item = tb_null;
    for (parent = (hole - 1) >> 1; hole > top && (comp(iterator, (parent_item = tb_iterator_item(iterator, head + parent)), item) < 0); parent = (hole - 1) >> 1)
    {   
        // move item: parent => hole
//      tb_iterator_copy(iterator, head + parent, item);
        tb_iterator_copy(iterator, head + hole, parent_item);

        // move node: hole => parent
        hole = parent;
    }

    // copy item
    tb_iterator_copy(iterator, head + hole, item);
}
#endif

/*! adjust heap
 *
 * <pre>
 * init:
 *                                          16(head)
 *                               -------------------------
 *                              |                         |
 *                           (hole)                       10
 *                        --------------             -------------
 *                       |              |           |             |
 *                       8(larger)      7           9             3
 *                   ---------       ----
 *                  |         |     |
 *                  2         4     1(tail - 1)
 *
 * after:
 *                                          16(head)
 *                               -------------------------
 *                              |                         |
 *                              8                        10
 *                        --------------             -------------
 *                       |              |           |             |
 *                      (hole)          7           9             3
 *                   ---------       ----
 *                  |         |     |
 *                  2 (larger)4     1(tail - 1)
 *
 * after:
 *                                          16(head)
 *                               -------------------------
 *                              |                         |
 *                              8                        10
 *                        --------------             -------------
 *                       |              |           |             |
 *                       4              7           9             3
 *                   ---------       ----
 *                  |         |     |
 *                  2      (hole)   1(tail - 1)
 *
 * </pre>
 */
static __tb_inline__ tb_void_t tb_heap_adjust(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t hole, tb_size_t tail, tb_cpointer_t item, tb_iterator_comp_t comp)
{
    // the comparer 
    if (!comp) comp = tb_iterator_comp;

#if 0
    // save top position
    tb_size_t top = hole;

    // 2 * hole + 2: the right child node of hole
    tb_size_t child = (hole << 1) + 2;
    for (; child < tail; child = (child << 1) + 2)
    {   
        // the larger child node
        if (comp(iterator, tb_iterator_item(iterator, head + child), tb_iterator_item(iterator, head + child - 1)) < 0) child--;

        // the larger child node => hole
        tb_iterator_copy(iterator, head + hole, tb_iterator_item(iterator, head + child));

        // move the hole down to it's larger child node 
        hole = child;
    }

    // no right child node? 
    if (child == tail)
    {   
        // the last child => hole
        tb_iterator_copy(iterator, head + hole, tb_iterator_item(iterator, head + tail - 1));

        // move hole down to tail
        hole = tail - 1;
    }

    // push item into the hole
    tb_heap_push(iterator, head, hole, top, item, comp);
#else

    // walk, 2 * hole + 1: the left child node of hole
    tb_size_t       child = (hole << 1) + 1;
    tb_cpointer_t   child_item = tb_null;
    tb_cpointer_t   child_item_r = tb_null;
    for (; child < tail; child = (child << 1) + 1)
    {   
        // the larger child node
        child_item = tb_iterator_item(iterator, head + child);
        if (child + 1 < tail && comp(iterator, child_item, (child_item_r = tb_iterator_item(iterator, head + child + 1))) < 0) 
        {
            child++;
            child_item = child_item_r;
        }

        // end?
        if (comp(iterator, child_item, item) < 0) break;

        // the larger child node => hole
        tb_iterator_copy(iterator, head + hole, child_item);

        // move the hole down to it's larger child node 
        hole = child;
    }

    // copy item
    tb_iterator_copy(iterator, head + hole, item);

#endif
}
/*!make heap
 *
 * <pre>
 * heap:    16      14      10      8       7       9       3       2       4       1
 *
 *                                          16(head)
 *                               -------------------------
 *                              |                         |
 *                              14                        10
 *                        --------------             -------------
 *                       |              |           |             |
 *                       8       (tail / 2 - 1)7    9             3
 *                   ---------       ----
 *                  |         |     |
 *                  2         4     1(tail - 1)
 * </pre>
 */
static __tb_inline__ tb_void_t tb_heap_make(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_iterator_comp_t comp)
{
    // init
    tb_size_t       step = tb_iterator_step(iterator);
    tb_pointer_t    temp = step > sizeof(tb_pointer_t)? tb_malloc(step) : tb_null;
    tb_assert_and_check_return(step <= sizeof(tb_pointer_t) || temp);

    // make
    tb_size_t hole;
    tb_size_t bottom = tail - head;
    for (hole = (bottom >> 1); hole > 0; )
    {
        --hole;

        // save hole
        if (step <= sizeof(tb_pointer_t)) temp = tb_iterator_item(iterator, head + hole);
        else tb_memcpy(temp, tb_iterator_item(iterator, head + hole), step);

        // reheap top half, bottom to top
        tb_heap_adjust(iterator, head, hole, bottom, temp, comp);
    }

    // free
    if (temp && step > sizeof(tb_pointer_t)) tb_free(temp);

    // check
    tb_assert(tb_heap_check(iterator, head, tail, comp));
}
/*!pop the top of heap to last and reheap
 *
 * <pre>
 *                                          16(head) 
 *                               ----------------|--------
 *                              |                |        |
 *                              14               |        10
 *                        --------------         |   -------------
 *                       |              |        |  |             |
 *                       8              7        |  9             3
 *                   ---------       ----        |
 *                  |         |     |            |
 *                  2         4     1(last)<-----
 *                                (hole)
 * </pre>
 */   
static __tb_inline__ tb_void_t tb_heap_pop0(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_cpointer_t item, tb_iterator_comp_t comp)
{
    // top => last
    tb_iterator_copy(iterator, tail - 1, tb_iterator_item(iterator, head));

    // reheap it
    tb_heap_adjust(iterator, head, 0, tail - head - 1, item, comp);

    // check
//  tb_assert(tb_heap_check(iterator, head, tail - head - 1, comp));
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/*!the heap sort 
 * 
 * <pre>
 * init:
 *
 *                                           16(head)
 *                               -------------------------
 *                              |                         |
 *                              4                         10
 *                        --------------             -------------
 *                       |              |           |             |
 *                       14             7           9             3
 *                   ---------       ----
 *                  |         |     |
 *                  2         8     1(last - 1)
 * 
 * make_heap:
 *
 *                                           16(head)
 *                               -------------------------
 *                              |                         |
 *                              14                        10
 *                        --------------             -------------
 *                       |              |           |             |
 *                       8              7           9             3
 *                   ---------       ----
 *                  |         |     |
 *                  2         4     1(last - 1)
 * pop_heap:
 *
 *                                          16(head)--------------------------
 *                               -------------------------                     |
 *                              |                         |                    |
 *                              4                         10                   |
 *                        --------------             -------------             |
 *                       |              |           |             |            | 
 *                       14             7           9             3            |
 *                   ---------       ----                                      |
 *                  |         |     |                                          |
 *                  2         8     1(last - 1) <------------------------------ 
 *
 *                                          (hole)(head)
 *                               -------------------------               
 *                              |                         |                  
 *                              4                         10                 
 *                        --------------             -------------           
 *                       |              |           |             |          (val = 1)
 *                       14             7           9             3         
 *                   ---------       ----                                    
 *                  |         |     |                                       
 *                  2         8     16(last - 1)
 *                           
 * adjust_heap:
 *                                          14(head)
 *                               -------------------------               
 *                              |                         |                  
 *                              8                        10                 
 *                        --------------             -------------           
 *                       |              |           |             |           (val = 1)         
 *                       4              7           9             3         
 *                   ---------                                         
 *                  |         |                                            
 *                  2      (hole)(last - 1)   16
 *
 *
 * push_heap:
 *                                          14(head)
 *                               -------------------------               
 *                              |                         |                  
 *                              8                        10                 
 *                        --------------             -------------           
 *                       |              |           |             |           (val = 1)         
 *                       4              7           9             3              |
 *                   ---------                                                   |
 *                  |         | /-----------------------------------------------
 *                  2      (hole)(last - 1)   16
 *
 *                                          14(head)
 *                               -------------------------               
 *                              |                         |                  
 *                              8                        10                 
 *                        --------------             -------------           
 *                       |              |           |             |           (val = 1)         
 *                       4              7           9             3            
 *                   ---------                                                   
 *                  |         |  
 *                  2       1(last - 1)   16
 *
 * pop_heap adjust_heap push_heap ...
 *
 * final_heap:
 *                                           1(head)
 *                            
 *                         
 *                              2                         3               
 *                               
 *                              
 *                       4              7           8             9           
 *                                                            
 *             
 *                  10       14      16
 *     
 * result: 1 2 3 4 7 8 9 10 14 16
 * </pre>
 */
tb_void_t tb_heap_sort(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_iterator_comp_t comp)
{
    // check
    tb_assert_and_check_return(iterator && (tb_iterator_mode(iterator) & TB_ITERATOR_MODE_RACCESS));
    tb_check_return(head != tail);

    // make
    tb_heap_make(iterator, head, tail, comp);

    // init
    tb_size_t       step = tb_iterator_step(iterator);
    tb_pointer_t    last = step > sizeof(tb_pointer_t)? tb_malloc(step) : tb_null;
    tb_assert_and_check_return(step <= sizeof(tb_pointer_t) || last);

    // pop0 ...
    for (; tail > head + 1; tail--)
    {
        // save last
        if (step <= sizeof(tb_pointer_t)) last = tb_iterator_item(iterator, tail - 1);
        else tb_memcpy(last, tb_iterator_item(iterator, tail - 1), step);

        // pop0
        tb_heap_pop0(iterator, head, tail, last, comp);
    }

    // free
    if (last && step > sizeof(tb_pointer_t)) tb_free(last);
}
tb_void_t tb_heap_sort_all(tb_iterator_ref_t iterator, tb_iterator_comp_t comp)
{
    tb_heap_sort(iterator, tb_iterator_head(iterator), tb_iterator_tail(iterator), comp);
}
