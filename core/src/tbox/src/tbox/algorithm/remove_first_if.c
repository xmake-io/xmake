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
 * @file        remove_first_if.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "remove_first_if.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_remove_first_if(tb_iterator_ref_t iterator, tb_predicate_ref_t pred, tb_cpointer_t value)
{
    // check
    tb_assert_and_check_return(iterator && pred);

    // the iterator mode
    tb_size_t mode = tb_iterator_mode(iterator);
    tb_assert_and_check_return((mode & TB_ITERATOR_MODE_FORWARD));
    tb_assert_and_check_return(!(mode & TB_ITERATOR_MODE_READONLY));

    // done
    tb_size_t itor = tb_iterator_head(iterator);
    while (itor != tb_iterator_tail(iterator))
    {
        // done predicate
        if (pred(iterator, tb_iterator_item(iterator, itor), value))
        {
            // remove it
            tb_iterator_remove(iterator, itor);
            break;
        }
    
        // next
        itor = tb_iterator_next(iterator, itor);
    }
}

