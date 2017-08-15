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
 * @file        ptr.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_size_t tb_iterator_ptr_size(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator);

    // the size
    return ((tb_array_iterator_ref_t)iterator)->count;
}
static tb_size_t tb_iterator_ptr_head(tb_iterator_ref_t iterator)
{
    return 0;
}
static tb_size_t tb_iterator_ptr_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator);

    // the tail
    return ((tb_array_iterator_ref_t)iterator)->count;
}
static tb_size_t tb_iterator_ptr_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // the next
    return itor + 1;
}
static tb_size_t tb_iterator_ptr_prev(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && itor);

    // the prev
    return itor - 1;
}
static tb_pointer_t tb_iterator_ptr_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // the item
    return ((tb_pointer_t*)((tb_array_iterator_ref_t)iterator)->items)[itor];
}
static tb_void_t tb_iterator_ptr_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // copy
    ((tb_cpointer_t*)((tb_array_iterator_ref_t)iterator)->items)[itor] = item;
}
static tb_long_t tb_iterator_ptr_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    return (litem < ritem)? -1 : (litem > ritem);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_iterator_ref_t tb_iterator_make_for_ptr(tb_array_iterator_ref_t iterator, tb_pointer_t* items, tb_size_t count)
{
    // check
    tb_assert(iterator && items && count);

    // init
    iterator->base.mode     = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_MUTABLE;
    iterator->base.priv     = tb_null;
    iterator->base.step     = sizeof(tb_pointer_t);
    iterator->base.size     = tb_iterator_ptr_size;
    iterator->base.head     = tb_iterator_ptr_head;
    iterator->base.tail     = tb_iterator_ptr_tail;
    iterator->base.prev     = tb_iterator_ptr_prev;
    iterator->base.next     = tb_iterator_ptr_next;
    iterator->base.item     = tb_iterator_ptr_item;
    iterator->base.copy     = tb_iterator_ptr_copy;
    iterator->base.comp     = tb_iterator_ptr_comp;
    iterator->items         = items;
    iterator->count         = count;

    // ok
    return (tb_iterator_ref_t)iterator;
}

