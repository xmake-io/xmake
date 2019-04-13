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
 * @file        distance.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "distance.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_distance(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail)
{
    // check
    tb_assert_and_check_return_val(iterator, 0);

    // zero distance?
    tb_check_return_val(head != tail, 0);

    // the iterator mode
    tb_size_t mode = tb_iterator_mode(iterator);

    // random access iterator? 
    tb_size_t distance = 0;
    if (mode & TB_ITERATOR_MODE_RACCESS) 
    {
        // compute it fastly
        distance = tail - head;
    }
    // forward iterator?
    else if (mode & TB_ITERATOR_MODE_FORWARD) 
    {
        // whole container?
        if (tb_iterator_head(iterator) == head && tb_iterator_tail(iterator) == tail)
            distance = tb_iterator_size(iterator);
        else
        {
            // done
            tb_size_t itor = head;
            for (; itor != tail; itor = tb_iterator_next(iterator, itor)) distance++;
        }
    }
    // reverse iterator?
    else if (mode & TB_ITERATOR_MODE_REVERSE) 
    {
        // whole container?
        if (tb_iterator_head(iterator) == head && tb_iterator_tail(iterator) == tail)
            distance = tb_iterator_size(iterator);
        else
        {
            // done
            tb_size_t itor = tail;
            do
            {
                // update the distance
                distance++;

                // the previous 
                itor = tb_iterator_prev(iterator, itor);

            } while (itor != head);
        }
    }
    // unknown mode?
    else
    {
        // abort
        tb_assert(0);
    }

    // ok?
    return distance;
}
