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
 * @file        rwalk.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "rwalk.h"
#include "rfor.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_rwalk(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_rwalk_func_t func, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(iterator && (tb_iterator_mode(iterator) & TB_ITERATOR_MODE_REVERSE) && func, 0);

    // null?
    tb_check_return_val(head != tail, 0);

    // rwalk
    tb_size_t count = 0;
    tb_rfor (tb_pointer_t, item, head, tail, iterator)
    {
        // done
        if (!func(iterator, item, priv)) break;

        // count++
        count++;
    }

    // ok?
    return count;
}
tb_size_t tb_rwalk_all(tb_iterator_ref_t iterator, tb_rwalk_func_t func, tb_cpointer_t priv)
{
    return tb_rwalk(iterator, tb_iterator_head(iterator), tb_iterator_tail(iterator), func, priv);
}
