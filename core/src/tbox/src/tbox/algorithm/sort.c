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
 * @file        sort.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "sort.h"
#include "distance.h"
#include "heap_sort.h"
#include "quick_sort.h"
#include "insert_sort.h"
#include "bubble_sort.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_sort(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_iterator_comp_t comp)
{
    // check
    tb_assert_and_check_return(iterator);

    // no elements?
    tb_check_return(head != tail);

    // readonly?
    tb_assert_and_check_return(!(tb_iterator_mode(iterator) & TB_ITERATOR_MODE_READONLY));

#ifdef TB_CONFIG_MICRO_ENABLE
    // random access iterator?
    tb_assert_and_check_return(tb_iterator_mode(iterator) & TB_ITERATOR_MODE_RACCESS);

    // sort it
    tb_quick_sort(iterator, head, tail, comp);
#else
    // random access iterator? 
    if (tb_iterator_mode(iterator) & TB_ITERATOR_MODE_RACCESS) 
    {
        if (tb_distance(iterator, head, tail) > 100000) tb_heap_sort(iterator, head, tail, comp);
        else tb_quick_sort(iterator, head, tail, comp); //!< @note the recursive stack size is limit
    }
    else tb_insert_sort(iterator, head, tail, comp);
#endif
}
tb_void_t tb_sort_all(tb_iterator_ref_t iterator, tb_iterator_comp_t comp)
{
    tb_sort(iterator, tb_iterator_head(iterator), tb_iterator_tail(iterator), comp);
}

