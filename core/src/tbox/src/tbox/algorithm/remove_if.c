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
 * @file        remove_if.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "remove_if.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t tb_remove_if_pred(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value, tb_bool_t* pbreak)
{
    // check
    tb_value_ref_t tuple = (tb_value_ref_t)value;
    tb_assert(tuple && tuple[0].cptr);

    // the pred
    return ((tb_predicate_ref_t)tuple[0].cptr)(iterator, item, tuple[1].cptr);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_remove_if(tb_iterator_ref_t iterator, tb_predicate_ref_t pred, tb_cpointer_t value)
{
    // init tuple
    tb_value_t tuple[2];
    tuple[0].cptr = pred;
    tuple[1].cptr = value;

    // remove it
    tb_remove_if_until(iterator, tb_remove_if_pred, tuple);
}
tb_void_t tb_remove_if_until(tb_iterator_ref_t iterator, tb_predicate_break_ref_t pred, tb_cpointer_t value)
{
    // check
    tb_assert_and_check_return(iterator && pred);

    // the iterator mode
    tb_size_t mode = tb_iterator_mode(iterator);
    tb_assert_and_check_return((mode & TB_ITERATOR_MODE_FORWARD));
    tb_assert_and_check_return(!(mode & TB_ITERATOR_MODE_READONLY));

    // done
    tb_size_t next;
    tb_size_t size = 0;
    tb_bool_t ok = tb_false;
    tb_bool_t need = tb_false;
    tb_bool_t is_break = tb_false;
    tb_size_t prev = tb_iterator_tail(iterator);
    tb_size_t itor = tb_iterator_head(iterator);
    tb_size_t base = tb_iterator_tail(iterator);
    tb_bool_t bmutable = (mode & TB_ITERATOR_MODE_MUTABLE)? tb_true : tb_false;
    while (itor != tb_iterator_tail(iterator))
    {
        // save next
        next = tb_iterator_next(iterator, itor);

        // done predicate
        ok = pred(iterator, tb_iterator_item(iterator, itor), value, &is_break);

        // remove it? 
        if (ok)
        {
            // is the first removed item?
            if (!need)
            {
                // save the removed range base
                base = prev;

                // need remove items
                need = tb_true;
            }

            // update size
            size++;
        }
       
        // the removed range have been passed or stop or end?
        if (!ok || next == tb_iterator_tail(iterator))
        {
            // need remove items?
            if (need) 
            {
                // check
                tb_assert(size);

                // the previous tail
                tb_size_t prev_tail = tb_iterator_tail(iterator);

                // remove items
                tb_iterator_nremove(iterator, base, ok? next : itor, size);

                // reset state
                need = tb_false;
                size = 0;

                // is the mutable iterator?
                if (bmutable)
                {
                    // update itor
                    prev = base;

                    // the body items are removed?
                    if (base != prev_tail) itor = tb_iterator_next(iterator, base);
                    // the head items are removed?
                    else itor = tb_iterator_head(iterator);

                    // the last item be not removed? skip the last walked item
                    if (!ok)
                    {
                        prev = itor;
                        itor = tb_iterator_next(iterator, itor);
                    }

                    // break?
                    tb_check_break(!is_break);

                    // continue?
                    continue ;
                }
            }

            // break?
            tb_check_break(!is_break);
        }
    
        // next
        prev = itor;
        itor = next;
    }
}
