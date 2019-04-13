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
 * @file        insert_sort.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "insert_sort.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/*!the insertion sort
 *
 * <pre>
 * old:     5       2       6       2       8       6       1
 *
 *        (hole)
 * step1: ((5))     2       6       2       8       6       1
 *        (next) <=
 *
 *        (hole)  
 * step2: ((2))    (5)      6       2       8       6       1
 *                (next) <=
 *
 *                        (hole)
 * step3:   2       5     ((6))     2       8       6       1
 *                        (next) <=
 *
 *                 (hole)       
 * step4:   2      ((2))   (5)     (6)      8       6       1
 *                                (next) <=
 *
 *                                        (hole)
 * step5:   2       2       5       6     ((8))     6       1
 *                                        (next) <=
 *
 *                                        (hole) 
 * step6:   2       2       5       6     ((6))    (8)       1
 *                                                (next) <=
 *
 *        (hole)                                         
 * step7: ((1))    (2)     (2)     (5)     (6)     (6)      (8)       
 *                                                        (next)
 * </pre>
 */
tb_void_t tb_insert_sort(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_iterator_comp_t comp)
{   
    // check
    tb_assert_and_check_return(iterator);
    tb_assert_and_check_return((tb_iterator_mode(iterator) & TB_ITERATOR_MODE_FORWARD));
    tb_assert_and_check_return((tb_iterator_mode(iterator) & TB_ITERATOR_MODE_REVERSE));
    tb_check_return(head != tail);
    
    // init
    tb_size_t       step = tb_iterator_step(iterator);
    tb_pointer_t    temp = step > sizeof(tb_pointer_t)? tb_malloc(step) : tb_null;
    tb_assert_and_check_return(step <= sizeof(tb_pointer_t) || temp);

    // the comparer
    if (!comp) comp = tb_iterator_comp;

    // sort
    tb_size_t last, next;
    for (next = tb_iterator_next(iterator, head); next != tail; next = tb_iterator_next(iterator, next))
    {
        // save next
        if (step <= sizeof(tb_pointer_t)) temp = tb_iterator_item(iterator, next);
        else tb_memcpy(temp, tb_iterator_item(iterator, next), step);

        // look for hole and move elements[hole, next - 1] => [hole + 1, next]
        for (last = next; last != head && (last = tb_iterator_prev(iterator, last), comp(iterator, temp, tb_iterator_item(iterator, last)) < 0); next = last)
                tb_iterator_copy(iterator, next, tb_iterator_item(iterator, last));

        // item => hole
        tb_iterator_copy(iterator, next, temp);
    }

    // free
    if (temp && step > sizeof(tb_pointer_t)) tb_free(temp);
}
tb_void_t tb_insert_sort_all(tb_iterator_ref_t iterator, tb_iterator_comp_t comp)
{
    tb_insert_sort(iterator, tb_iterator_head(iterator), tb_iterator_tail(iterator), comp);
}

