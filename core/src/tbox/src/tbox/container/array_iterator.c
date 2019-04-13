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
 * @file        array_iterator.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../libc/libc.h"
#include "../utils/utils.h"
#include "../memory/memory.h"
#include "../object/object.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * iterator implementation for pointer element
 */
static tb_size_t tb_array_iterator_ptr_size(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator);

    // the size
    return ((tb_array_iterator_ref_t)iterator)->count;
}
static tb_size_t tb_array_iterator_ptr_head(tb_iterator_ref_t iterator)
{
    return 0;
}
static tb_size_t tb_array_iterator_ptr_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_assert(iterator);

    // the tail
    return ((tb_array_iterator_ref_t)iterator)->count;
}
static tb_size_t tb_array_iterator_ptr_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // the next
    return itor + 1;
}
static tb_size_t tb_array_iterator_ptr_prev(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && itor);

    // the prev
    return itor - 1;
}
static tb_pointer_t tb_array_iterator_ptr_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // the item
    return ((tb_pointer_t*)((tb_array_iterator_ref_t)iterator)->items)[itor];
}
static tb_void_t tb_array_iterator_ptr_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // copy
    ((tb_cpointer_t*)((tb_array_iterator_ref_t)iterator)->items)[itor] = item;
}
static tb_long_t tb_array_iterator_ptr_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    return (litem < ritem)? -1 : (litem > ritem);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * iterator implementation for memory element
 */
static tb_pointer_t tb_array_iterator_mem_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // the item
    return (tb_pointer_t)((tb_byte_t*)((tb_array_iterator_ref_t)iterator)->items + itor * iterator->step);
}
static tb_void_t tb_array_iterator_mem_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_assert(iterator && itor < ((tb_array_iterator_ref_t)iterator)->count);

    // copy
    tb_memcpy((tb_byte_t*)((tb_array_iterator_ref_t)iterator)->items + itor * iterator->step, item, iterator->step);
}
static tb_long_t tb_array_iterator_mem_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_assert(litem && ritem);

    // compare it
    return tb_memcmp(litem, ritem, iterator->step);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * iterator implementation for c-string element
 */
static tb_long_t tb_array_iterator_str_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_assert(litem && ritem);

    // compare it
    return tb_strcmp((tb_char_t const*)litem, (tb_char_t const*)ritem);
}
static tb_long_t tb_array_iterator_istr_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_assert(litem && ritem);

    // compare it
    return tb_stricmp((tb_char_t const*)litem, (tb_char_t const*)ritem);
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * iterator implementation for long element
 */
static tb_long_t tb_array_iterator_long_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    return ((tb_long_t)litem < (tb_long_t)ritem)? -1 : ((tb_long_t)litem > (tb_long_t)ritem);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_iterator_ref_t tb_array_iterator_init_ptr(tb_array_iterator_ref_t iterator, tb_pointer_t* items, tb_size_t count)
{
    // check
    tb_assert(iterator && items && count);

    // init operation
    static tb_iterator_op_t op = 
    {
        tb_array_iterator_ptr_size
    ,   tb_array_iterator_ptr_head
    ,   tb_null
    ,   tb_array_iterator_ptr_tail
    ,   tb_array_iterator_ptr_prev
    ,   tb_array_iterator_ptr_next
    ,   tb_array_iterator_ptr_item
    ,   tb_array_iterator_ptr_comp
    ,   tb_array_iterator_ptr_copy
    ,   tb_null
    ,   tb_null
    };

    // init iterator
    iterator->base.priv     = tb_null;
    iterator->base.step     = sizeof(tb_pointer_t);
    iterator->base.mode     = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_MUTABLE;
    iterator->base.op       = &op;
    iterator->items         = items;
    iterator->count         = count;

    // ok
    return (tb_iterator_ref_t)iterator;
}
tb_iterator_ref_t tb_array_iterator_init_mem(tb_array_iterator_ref_t iterator, tb_pointer_t items, tb_size_t count, tb_size_t size)
{
    // check
    tb_assert(iterator && items && count && size);

    // init operation
    static tb_iterator_op_t op = 
    {
        tb_array_iterator_ptr_size
    ,   tb_array_iterator_ptr_head
    ,   tb_null
    ,   tb_array_iterator_ptr_tail
    ,   tb_array_iterator_ptr_prev
    ,   tb_array_iterator_ptr_next
    ,   tb_array_iterator_mem_item
    ,   tb_array_iterator_mem_comp
    ,   tb_array_iterator_mem_copy
    ,   tb_null
    ,   tb_null
    };

    // init
    iterator->base.priv     = tb_null;
    iterator->base.step     = size;
    iterator->base.mode     = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_MUTABLE;
    iterator->base.op       = &op;
    iterator->items         = items;
    iterator->count         = count;

    // ok
    return (tb_iterator_ref_t)iterator;
}
tb_iterator_ref_t tb_array_iterator_init_str(tb_array_iterator_ref_t iterator, tb_char_t** items, tb_size_t count)
{
    // check
    tb_assert(iterator && items && count);

    // init operation
    static tb_iterator_op_t op = 
    {
        tb_array_iterator_ptr_size
    ,   tb_array_iterator_ptr_head
    ,   tb_null
    ,   tb_array_iterator_ptr_tail
    ,   tb_array_iterator_ptr_prev
    ,   tb_array_iterator_ptr_next
    ,   tb_array_iterator_ptr_item
    ,   tb_array_iterator_str_comp
    ,   tb_array_iterator_ptr_copy
    ,   tb_null
    ,   tb_null
    };

    // init iterator
    iterator->base.priv     = tb_null;
    iterator->base.step     = sizeof(tb_char_t const*);
    iterator->base.mode     = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_MUTABLE;
    iterator->base.op       = &op;
    iterator->items         = items;
    iterator->count         = count;

    // ok
    return (tb_iterator_ref_t)iterator;
}
tb_iterator_ref_t tb_array_iterator_init_istr(tb_array_iterator_ref_t iterator, tb_char_t** items, tb_size_t count)
{
    // check
    tb_assert(iterator && items && count);

    // init operation
    static tb_iterator_op_t op = 
    {
        tb_array_iterator_ptr_size
    ,   tb_array_iterator_ptr_head
    ,   tb_null
    ,   tb_array_iterator_ptr_tail
    ,   tb_array_iterator_ptr_prev
    ,   tb_array_iterator_ptr_next
    ,   tb_array_iterator_ptr_item
    ,   tb_array_iterator_istr_comp
    ,   tb_array_iterator_ptr_copy
    ,   tb_null
    ,   tb_null
    };

    // init iterator
    iterator->base.priv     = tb_null;
    iterator->base.step     = sizeof(tb_char_t const*);
    iterator->base.mode     = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_MUTABLE;
    iterator->base.op       = &op;
    iterator->items         = items;
    iterator->count         = count;

    // ok
    return (tb_iterator_ref_t)iterator;
}
tb_iterator_ref_t tb_array_iterator_init_size(tb_array_iterator_ref_t iterator, tb_size_t* items, tb_size_t count)
{
    return tb_array_iterator_init_ptr(iterator, (tb_pointer_t*)items, count);
}
tb_iterator_ref_t tb_array_iterator_init_long(tb_array_iterator_ref_t iterator, tb_long_t* items, tb_size_t count)
{

    // check
    tb_assert(iterator && items && count);

    // init operation
    static tb_iterator_op_t op = 
    {
        tb_array_iterator_ptr_size
    ,   tb_array_iterator_ptr_head
    ,   tb_null
    ,   tb_array_iterator_ptr_tail
    ,   tb_array_iterator_ptr_prev
    ,   tb_array_iterator_ptr_next
    ,   tb_array_iterator_ptr_item
    ,   tb_array_iterator_long_comp
    ,   tb_array_iterator_ptr_copy
    ,   tb_null
    ,   tb_null
    };

    // init iterator
    iterator->base.priv     = tb_null;
    iterator->base.step     = sizeof(tb_long_t);
    iterator->base.mode     = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_MUTABLE;
    iterator->base.op       = &op;
    iterator->items         = items;
    iterator->count         = count;

    // ok
    return (tb_iterator_ref_t)iterator;
}
