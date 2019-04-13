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
 * @file        single_list_entry.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "single_list_entry.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * iterator implementation
 */
static tb_size_t tb_single_list_entry_itor_size(tb_iterator_ref_t iterator)
{
    // check
    tb_single_list_entry_head_ref_t list = tb_container_of(tb_single_list_entry_head_t, itor, iterator);
    tb_assert(list);

    // the size
    return list->size;
}
static tb_size_t tb_single_list_entry_itor_head(tb_iterator_ref_t iterator)
{
    // check
    tb_single_list_entry_head_ref_t list = tb_container_of(tb_single_list_entry_head_t, itor, iterator);
    tb_assert(list);

    // head
    return (tb_size_t)list->next;
}
static tb_size_t tb_single_list_entry_itor_last(tb_iterator_ref_t iterator)
{
    // check
    tb_single_list_entry_head_ref_t list = tb_container_of(tb_single_list_entry_head_t, itor, iterator);
    tb_assert(list);

    // last
    return (tb_size_t)list->last;
}
static tb_size_t tb_single_list_entry_itor_tail(tb_iterator_ref_t iterator)
{
    // tail
    return (tb_size_t)0;
}
static tb_size_t tb_single_list_entry_itor_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(itor);

    // next
    return (tb_size_t)((tb_single_list_entry_ref_t)itor)->next;
}
static tb_pointer_t tb_single_list_entry_itor_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_single_list_entry_head_ref_t list = tb_container_of(tb_single_list_entry_head_t, itor, iterator);
    tb_assert(list && list->eoff < itor);

    // data
    return (tb_pointer_t)(itor - list->eoff);
}
static tb_void_t tb_single_list_entry_itor_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_single_list_entry_head_ref_t list = tb_container_of(tb_single_list_entry_head_t, itor, iterator);
    tb_assert(list && list->copy);
    tb_assert(list->eoff < itor && item);

    // copy it
    list->copy((tb_pointer_t)(itor - list->eoff), (tb_pointer_t)item);
}
static tb_void_t tb_single_list_entry_itor_nremove(tb_iterator_ref_t iterator, tb_size_t prev, tb_size_t next, tb_size_t size)
{
    // check
    tb_single_list_entry_head_ref_t list = tb_container_of(tb_single_list_entry_head_t, itor, iterator);
    tb_assert(list && prev && next);

    // no size?
    tb_check_return(size);

    // the entry
    tb_single_list_entry_ref_t prev_entry = (tb_single_list_entry_ref_t)prev;
    tb_single_list_entry_ref_t next_entry = (tb_single_list_entry_ref_t)next;

    // remove entries
    prev_entry->next = next_entry;

    // update size
    list->size -= size;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_iterator_ref_t tb_single_list_entry_itor(tb_single_list_entry_head_ref_t list)
{
    // check
    tb_assert_and_check_return_val(list, tb_null);

    // the iterator
    return &list->itor;
}
tb_void_t tb_single_list_entry_init_(tb_single_list_entry_head_ref_t list, tb_size_t entry_offset, tb_size_t entry_size, tb_entry_copy_t copy)
{
    // check
    tb_assert_and_check_return(list && entry_size > sizeof(tb_single_list_entry_t));

    // init list
    list->next = tb_null;
    list->last = tb_null;
    list->size = 0;
    list->eoff = entry_offset;
    list->copy = copy;

    // init operation
    static tb_iterator_op_t op = 
    {
        tb_single_list_entry_itor_size
    ,   tb_single_list_entry_itor_head
    ,   tb_single_list_entry_itor_last
    ,   tb_single_list_entry_itor_tail
    ,   tb_null
    ,   tb_single_list_entry_itor_next
    ,   tb_single_list_entry_itor_item
    ,   tb_null
    ,   tb_single_list_entry_itor_copy
    ,   tb_null
    ,   tb_single_list_entry_itor_nremove
    };

    // init iterator
    list->itor.priv = tb_null;
    list->itor.step = entry_size;
    list->itor.mode = TB_ITERATOR_MODE_FORWARD;
    list->itor.op   = &op;
}
tb_void_t tb_single_list_entry_exit(tb_single_list_entry_head_ref_t list)
{
    // check
    tb_assert_and_check_return(list);

    // exit it
    list->next          = tb_null;
    list->last          = tb_null;
    list->size = 0;
}


