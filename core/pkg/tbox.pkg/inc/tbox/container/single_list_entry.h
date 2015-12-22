/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        single_list_entry.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_SINGLE_LIST_ENTRY_H
#define TB_CONTAINER_SINGLE_LIST_ENTRY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the list entry
#define tb_single_list_entry(head, entry)   ((((tb_byte_t*)(entry)) - (head)->eoff))

/*! init the list entry 
 *
 * @code
 *
    // the xxxx entry type
    typedef struct __tb_xxxx_entry_t 
    {
        // the list entry
        tb_single_list_entry_t      entry;

        // the data
        tb_size_t                   data;

    }tb_xxxx_entry_t;

    // the xxxx entry copy func
    static tb_void_t tb_xxxx_entry_copy(tb_pointer_t litem, tb_pointer_t ritem)
    {
        // check
        tb_assert(litem && ritem);

        // copy it
        ((tb_xxxx_entry_t*)litem)->data = ((tb_xxxx_entry_t*)ritem)->data;
    }

    // init the list
    tb_single_list_entry_head_t list;
    tb_single_list_entry_init(&list, tb_xxxx_entry_t, entry, tb_xxxx_entry_copy);

 * @endcode
 */
#define tb_single_list_entry_init(list, type, entry, copy)     tb_single_list_entry_init_(list, tb_offsetof(type, entry), sizeof(type), copy)

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the single-linked list entry type
 * 
 * <pre>
 * list: head => ... => last => null
 *
 * </pre>
 */
typedef struct __tb_single_list_entry_t 
{
    /// the next entry
    struct __tb_single_list_entry_t*    next;

}tb_single_list_entry_t, *tb_single_list_entry_ref_t;

/// the single-linked list entry head type
typedef struct __tb_single_list_entry_head_t 
{
    /// the next entry
    struct __tb_single_list_entry_t*    next;

    /// the last entry
    struct __tb_single_list_entry_t*    last;

    /// the list size
    tb_size_t                           size;

    /// the iterator 
    tb_iterator_t                       itor;

    /// the entry offset
    tb_size_t                           eoff;

    /// the entry copy func
    tb_entry_copy_t                     copy;

}tb_single_list_entry_head_t, *tb_single_list_entry_head_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the list iterator
 *
 * @param list                                  the list
 *
 * @return                                      the list iterator
 */
tb_iterator_ref_t                               tb_single_list_entry_itor(tb_single_list_entry_head_ref_t list);

/*! init list
 *
 * @param list                                  the list
 * @param entry_offset                          the entry offset 
 * @param entry_size                            the entry size 
 * @param copy                                  the copy func of the entry for algorithm, .e.g sort
 */
tb_void_t                                       tb_single_list_entry_init_(tb_single_list_entry_head_ref_t list, tb_size_t entry_offset, tb_size_t entry_size, tb_entry_copy_t copy);

/*! exit list
 *
 * @param list                                  the list
 */ 
tb_void_t                                       tb_single_list_entry_exit(tb_single_list_entry_head_ref_t list);

/*! clear list
 *
 * @param list                                  the list
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_clear(tb_single_list_entry_head_ref_t list)
{
    // check
    tb_assert(list);

    // clear it
    list->next = tb_null;
    list->last = tb_null;
    list->size = 0;
}

/*! the list entry count
 *
 * @param list                                  the list
 *
 * @return                                      the list entry count
 */
static __tb_inline__ tb_size_t                  tb_single_list_entry_size(tb_single_list_entry_head_ref_t list)
{ 
    // check
    tb_assert(list);

    // done
    return list->size;
}

/*! the list next entry
 *
 * @param list                                  the list
 * @param entry                                 the entry
 *
 * @return                                      the next entry
 */
static __tb_inline__ tb_single_list_entry_ref_t tb_single_list_entry_next(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t entry)
{
    // check
    tb_assert(entry);

    // done
    return entry->next;
}

/*! the list head entry
 *
 * @param list                                  the list
 *
 * @return                                      the head entry
 */
static __tb_inline__ tb_single_list_entry_ref_t tb_single_list_entry_head(tb_single_list_entry_head_ref_t list)
{
    // check
    tb_assert(list);

    // done
    return list->next;
}

/*! the list last entry
 *
 * @param list                                  the list
 *
 * @return                                      the last entry
 */
static __tb_inline__ tb_single_list_entry_ref_t tb_single_list_entry_last(tb_single_list_entry_head_ref_t list)
{ 
    // check
    tb_assert(list);

    // done
    return list->last;
}

/*! the list tail entry
 *
 * @param list                                  the list
 *
 * @return                                      the tail entry
 */
static __tb_inline__ tb_single_list_entry_ref_t tb_single_list_entry_tail(tb_single_list_entry_head_ref_t list)
{ 
    return tb_null;
}

/*! the list is null?
 *
 * @param list                                  the list
 *
 * @return                                      tb_true or tb_false
 */
static __tb_inline__ tb_bool_t                  tb_single_list_entry_is_null(tb_single_list_entry_head_ref_t list)
{ 
    // check
    tb_assert(list);

    // done
    return !list->size;
}
/*! is the list head entry?
 *
 * @param list                                  the list
 * @param entry                                 the entry
 *
 * @return                                      tb_true or tb_false
 */
static __tb_inline__ tb_bool_t                  tb_single_list_entry_is_head(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t entry)
{
    // check
    tb_assert(list);

    // done
    return list->next == entry;
}

/*! is the list last entry?
 *
 * @param list                                  the list
 * @param entry                                 the entry
 *
 * @return                                      tb_true or tb_false
 */
static __tb_inline__ tb_bool_t                  tb_single_list_entry_is_last(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t entry)
{
    // check
    tb_assert(list);

    // done
    return list->last == entry;
}

/*! insert entry to the next
 *
 * @param list                                  the list
 * @param node                                  the list node
 * @param entry                                 the inserted list entry
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_insert_next(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t node, tb_single_list_entry_ref_t entry)
{
    // check
    tb_assert(list && node && entry);
    tb_assert(node != entry);

    // update last
    if (node == list->last || !list->next) list->last = entry;

    // insert entry
    entry->next = node->next;
    node->next = entry;

    // size++
    list->size++;
}

/*! insert entry to the head 
 *
 * @param list                                  the list
 * @param entry                                 the inserted list entry
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_insert_head(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t entry)
{
    // insert it
    tb_single_list_entry_insert_next(list, (tb_single_list_entry_ref_t)list, entry);
}

/*! insert entry to the tail 
 *
 * @param list                                  the list
 * @param entry                                 the inserted list entry
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_insert_tail(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t entry)
{
    // check
    tb_assert(list && entry);

    // insert it
    if (list->last) tb_single_list_entry_insert_next(list, list->last, entry);
    else tb_single_list_entry_insert_head(list, entry);
}

/*! replace the next entry
 *
 * @param list                                  the list
 * @param node                                  the list node
 * @param entry                                 the new list entry
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_replace_next(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t node, tb_single_list_entry_ref_t entry)
{
    // check
    tb_assert(node && node->next);
    tb_assert(node != entry);

    // update last
    if (node->next == list->last) list->last = entry;

    // replace it
    entry->next = node->next->next;
    node->next = entry;
}

/*! replace the head entry
 *
 * @param list                                  the list
 * @param entry                                 the new list entry
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_replace_head(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t entry)
{
    // replace it
    tb_single_list_entry_replace_next(list, (tb_single_list_entry_ref_t)list, entry);
}

/*! remove the entry safely
 *
 * @param list                                  the list
 * @param prev                                  the prev entry
 * @param next                                  the next entry
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_remove_safe(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t prev, tb_single_list_entry_ref_t next)
{
    // check
    tb_assert(list && list->size && prev);

    // update last
    if (prev->next == list->last) list->last = next;

    // remove entries
    prev->next = next;

    // update size
    list->size--;
}

/*! remove the next entry
 *
 * @param list                                  the list
 * @param entry                                 the prev entry
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_remove_next(tb_single_list_entry_head_ref_t list, tb_single_list_entry_ref_t prev)
{
    // check
    tb_assert(prev && prev->next);

    // remove it
    tb_single_list_entry_remove_safe(list, prev, prev->next->next);
}

/*! remove the head entry
 *
 * @param list                                  the list
 */
static __tb_inline__ tb_void_t                  tb_single_list_entry_remove_head(tb_single_list_entry_head_ref_t list)
{
    // check
    tb_assert(list->next);

    // remove it
    tb_single_list_entry_remove_safe(list, (tb_single_list_entry_ref_t)list, list->next->next);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

