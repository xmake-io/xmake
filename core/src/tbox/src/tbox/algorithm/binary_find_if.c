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
 * @file        binary_find_if.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "binary_find_if.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_binary_find_if(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_iterator_comp_t comp, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(comp && iterator && (tb_iterator_mode(iterator) & TB_ITERATOR_MODE_RACCESS), tb_iterator_tail(iterator));

    // null?
    tb_check_return_val(head != tail, tb_iterator_tail(iterator));

    // find
    tb_size_t l = head;
    tb_size_t r = tail;
    tb_size_t m = (l + r) >> 1;
    tb_long_t c = -1;
    while (l < r)
    {
        c = comp(iterator, tb_iterator_item(iterator, m), priv);
        if (c > 0) r = m;
        else if (c < 0) l = m + 1;
        else break;
        m = (l + r) >> 1;
    }

    // ok?
    return !c? m : tb_iterator_tail(iterator);
}
tb_size_t tb_binary_find_all_if(tb_iterator_ref_t iterator, tb_iterator_comp_t comp, tb_cpointer_t priv)
{
    return tb_binary_find_if(iterator, tb_iterator_head(iterator), tb_iterator_tail(iterator), comp, priv);
}

