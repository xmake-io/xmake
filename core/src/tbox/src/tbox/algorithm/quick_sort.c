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
 * @file        quick_sort.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "quick_sort.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_quick_sort(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_iterator_comp_t comp)
{   
    // check
    tb_assert_and_check_return(iterator && (tb_iterator_mode(iterator) & TB_ITERATOR_MODE_RACCESS));
    tb_check_return(head != tail);

    // init
    tb_size_t       step = tb_iterator_step(iterator);
    tb_pointer_t    key = step > sizeof(tb_pointer_t)? tb_malloc(step) : tb_null;
    tb_assert_and_check_return(step <= sizeof(tb_pointer_t) || key);

    // the comparer
    if (!comp) comp = tb_iterator_comp;

    // hole => key
    if (step <= sizeof(tb_pointer_t)) key = tb_iterator_item(iterator, head);
    else tb_memcpy(key, tb_iterator_item(iterator, head), step);

    // quick_sort
    tb_size_t l = head;
    tb_size_t r = tail - 1;
    while (r > l)
    {
        // find: <= 
        for (; r != l; r--)
            if (comp(iterator, tb_iterator_item(iterator, r), key) < 0) break;
        if (r != l) 
        {
            tb_iterator_copy(iterator, l, tb_iterator_item(iterator, r));
            l++;
        }

        // find: =>
        for (; l != r; l++)
            if (comp(iterator, tb_iterator_item(iterator, l), key) > 0) break;
        if (l != r) 
        {
            tb_iterator_copy(iterator, r, tb_iterator_item(iterator, l));
            r--;
        }
    }

    // key => hole
    tb_iterator_copy(iterator, l, key);

    // quick_sort [head, hole - 1]
    tb_quick_sort(iterator, head, l, comp);

    // quick_sort [hole + 1, tail]
    tb_quick_sort(iterator, ++l, tail, comp);

    // free
    if (key && step > sizeof(tb_pointer_t)) tb_free(key);
}
tb_void_t tb_quick_sort_all(tb_iterator_ref_t iterator, tb_iterator_comp_t comp)
{
    tb_quick_sort(iterator, tb_iterator_head(iterator), tb_iterator_tail(iterator), comp);
}

