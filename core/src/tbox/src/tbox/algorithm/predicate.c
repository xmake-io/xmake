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
 * @file        predicate.c
 * @ingroup     algorithm
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "predicate.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_predicate_eq(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // check
    tb_assert(iterator);

    // item == value?
    return !tb_iterator_comp(iterator, item, value);
}
tb_bool_t tb_predicate_le(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // check
    tb_assert(iterator);

    // item < value?
    return tb_iterator_comp(iterator, item, value) < 0;
}
tb_bool_t tb_predicate_be(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // check
    tb_assert(iterator);

    // item > value?
    return tb_iterator_comp(iterator, item, value) > 0;
}
tb_bool_t tb_predicate_leq(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // check
    tb_assert(iterator);

    // item <= value?
    return tb_iterator_comp(iterator, item, value) <= 0;
}
tb_bool_t tb_predicate_beq(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // check
    tb_assert(iterator);

    // item >= value?
    return tb_iterator_comp(iterator, item, value) >= 0;
}
