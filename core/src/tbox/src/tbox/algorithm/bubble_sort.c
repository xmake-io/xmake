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
 * @file        bubble_sort.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "bubble_sort.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_void_t tb_bubble_sort(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_iterator_comp_t comp)
{
    // check
    tb_assert_and_check_return(iterator && (tb_iterator_mode(iterator) & TB_ITERATOR_MODE_FORWARD));
    tb_check_return(head != tail);

    // init
    tb_size_t       step = tb_iterator_step(iterator);
    tb_pointer_t    temp = step > sizeof(tb_pointer_t)? tb_malloc(step) : tb_null;
    tb_assert_and_check_return(step <= sizeof(tb_pointer_t) || temp);

    // the comparer
    if (!comp) comp = tb_iterator_comp;

    // bubble_sort
    tb_size_t itor1, itor2;
    for (itor1 = head; itor1 != tail; itor1 = tb_iterator_next(iterator, itor1))
    {
        for (itor2 = itor1, itor2 = tb_iterator_next(iterator, itor2); itor2 != tail; itor2 = tb_iterator_next(iterator, itor2))
        {
            if (comp(iterator, tb_iterator_item(iterator, itor2), tb_iterator_item(iterator, itor1)) < 0)
            {
                if (step <= sizeof(tb_pointer_t)) temp = tb_iterator_item(iterator, itor1);
                else tb_memcpy(temp, tb_iterator_item(iterator, itor1), step);
                tb_iterator_copy(iterator, itor1, tb_iterator_item(iterator, itor2));
                tb_iterator_copy(iterator, itor2, temp);
            }
        }
    }

    // free
    if (temp && step > sizeof(tb_pointer_t)) tb_free(temp);
}
tb_void_t tb_bubble_sort_all(tb_iterator_ref_t iterator, tb_iterator_comp_t comp)
{
    tb_bubble_sort(iterator, tb_iterator_head(iterator), tb_iterator_tail(iterator), comp);
}

