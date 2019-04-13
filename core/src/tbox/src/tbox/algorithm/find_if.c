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
 * @file        find_if.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "find_if.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_find_if(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_predicate_ref_t pred, tb_cpointer_t value)
{
    // check
    tb_assert_and_check_return_val(pred && iterator && (tb_iterator_mode(iterator) & TB_ITERATOR_MODE_FORWARD), tb_iterator_tail(iterator));

    // null?
    tb_check_return_val(head != tail, tb_iterator_tail(iterator));

    // find
    tb_size_t itor = head;
    tb_bool_t find = tb_false;
    for (; itor != tail; itor = tb_iterator_next(iterator, itor)) 
        if ((find = pred(iterator, tb_iterator_item(iterator, itor), value))) break;

    // ok?
    return find? itor : tb_iterator_tail(iterator);
} 
tb_size_t tb_find_all_if(tb_iterator_ref_t iterator, tb_predicate_ref_t pred, tb_cpointer_t value)
{
    return tb_find_if(iterator, tb_iterator_head(iterator), tb_iterator_tail(iterator), pred, value);
}

