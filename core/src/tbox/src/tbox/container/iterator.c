/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        iterator.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "iterator.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_iterator_mode(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator);

    // mode
    return iterator->mode;
}
tb_size_t tb_iterator_step(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator);

    // step
    return iterator->step;
}
tb_size_t tb_iterator_size(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator && iterator->size);

    // size
    return iterator->size(iterator);
}
tb_size_t tb_iterator_head(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator && iterator->head);
    
    // head
    return iterator->head(iterator);
}
tb_size_t tb_iterator_last(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator && iterator->last);
    
    // last
    return iterator->last(iterator);
}
tb_size_t tb_iterator_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator && iterator->tail);

    // tail
    return iterator->tail(iterator);
}
tb_size_t tb_iterator_prev(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && iterator->prev);

    // prev
    return iterator->prev(iterator, itor);
}
tb_size_t tb_iterator_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && iterator->next);

    // next
    return iterator->next(iterator, itor);
}
tb_pointer_t tb_iterator_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && iterator->item);

    // item
    return iterator->item(iterator, itor);
}
tb_void_t tb_iterator_remove(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && iterator->remove);

    // remove
    return iterator->remove(iterator, itor);
}
tb_void_t tb_iterator_remove_range(tb_iterator_ref_t iterator, tb_size_t prev, tb_size_t next, tb_size_t size)
{
    // check
    tb_assert(iterator && iterator->remove_range);

    // remove range
    return iterator->remove_range(iterator, prev, next, size);
}
tb_void_t tb_iterator_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_assert(iterator && iterator->copy);

    // copy
    return iterator->copy(iterator, itor, item);
}
tb_long_t tb_iterator_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_assert(iterator && iterator->comp);

    // comp
    return iterator->comp(iterator, litem, ritem);
}

