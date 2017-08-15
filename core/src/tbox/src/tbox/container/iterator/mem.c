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
 * @file        mem.c
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
static tb_pointer_t tb_iterator_mem_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // the item
    return (tb_pointer_t)((tb_byte_t*)((tb_array_iterator_ref_t)iterator)->items + itor * iterator->step);
}
static tb_void_t tb_iterator_mem_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // copy
    tb_memcpy((tb_byte_t*)((tb_array_iterator_ref_t)iterator)->items + itor * iterator->step, item, iterator->step);
}
static tb_long_t tb_iterator_mem_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_assert(litem && ritem);

    // compare it
    return tb_memcmp(litem, ritem, iterator->step);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_iterator_ref_t tb_iterator_make_for_mem(tb_array_iterator_ref_t iterator, tb_pointer_t items, tb_size_t count, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(size, tb_null);

    // make iterator for the pointer array
    if (!tb_iterator_make_for_ptr(iterator, (tb_pointer_t*)items, count)) return tb_null;

    // init
    iterator->base.step = size;
    iterator->base.item = tb_iterator_mem_item;
    iterator->base.copy = tb_iterator_mem_copy;
    iterator->base.comp = tb_iterator_mem_comp;

    // ok
    return (tb_iterator_ref_t)iterator;
}
