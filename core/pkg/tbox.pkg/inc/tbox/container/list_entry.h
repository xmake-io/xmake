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
 * @file        list_entry.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_LIST_ENTRY_H
#define TB_CONTAINER_LIST_ENTRY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the list entry
#define tb_list_entry(head, entry)   ((((tb_byte_t*)(entry)) - (head)->eoff))

/*! init the list entry 
 *
 * @code
 *
    // the xxxx entry type
    typedef struct __tb_xxxx_entry_t 
    {
        // the list entry
        tb_list_entry_t     entry;

        // the data
        tb_size_t           data;

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
    tb_list_entry_head_t list;
    tb_list_entry_init(&list, tb_xxxx_entry_t, entry, tb_xxxx_entry_copy);

 * @endcode
 */
#define tb_list_entry_init(list, type, entry, copy)     tb_list_entry_init_(list, tb_offsetof(type, entry), sizeof(type), copy)

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the doubly-linked list entry type
 * 
 * <pre>
 * list: list => ... => last
 *        |               |
 *        <---------------
 *
 * </pre>
 */
typedef struct __tb_list_entry_t 
{
    /// the next entry
    struct __tb_list_entry_t*   next;

    /// the prev entry
    struct __tb_list_entry_t*   prev;

}tb_list_entry_t, *tb_list_entry_ref_t;

/// the list entry head type
typedef struct __tb_list_entry_head_t 
{
    /// the next entry
    struct __tb_list_entry_t*   next;

    /// the prev entry
    struct __tb_list_entry_t*   prev;

    /// the list size
    tb_size_t                   size;

    /// the iterator 
    tb_iterator_t               itor;

    /// the entry offset
    tb_size_t                   eoff;

    /// the entry copy func
    tb_entry_copy_t             copy;

}tb_list_entry_head_t, *tb_list_entry_head_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the list iterator
 *
 * @param list                              the list
 *
 * @return                                  the list iterator
 */
tb_iterator_ref_t                           tb_list_entry_itor(tb_list_entry_head_ref_t list);

/*! init list
 *
 * @param list                              the list
 * @param entry_offset                      the entry offset 
 * @param entry_size                        the entry size 
 * @param copy                              the copy func of the entry for algorithm, .e.g sort
 */
tb_void_t                                   tb_list_entry_init_(tb_list_entry_head_ref_t list, tb_size_t entry_offset, tb_size_t entry_size, tb_entry_copy_t copy);

/*! exit list
 *
 * @param list                              the list
 */ 
tb_void_t                                   tb_list_entry_exit(tb_list_entry_head_ref_t list);

/*! clear list
 *
 * @param list                              the list
 */
static __tb_inline__ tb_void_t              tb_list_entry_clear(tb_list_entry_head_ref_t list)
{
    // check
    tb_assert(list);

    // clear it
    list->next = (tb_list_entry_ref_t)list;
    list->prev = (tb_list_entry_ref_t)list;
    list->size = 0;
}

/*! the list entry count
 *
 * @param list                              the list
 *
 * @return                                  the list entry count
 */
static __tb_inline__ tb_size_t              tb_list_entry_size(tb_list_entry_head_ref_t list)
{ 
    // check
    tb_assert(list);

    // done
    return list->size;
}

/*! the list next entry
 *
 * @param list                              the list
 * @param entry                             the entry
 *
 * @return                                  the next entry
 */
static __tb_inline__ tb_list_entry_ref_t    tb_list_entry_next(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(entry);

    // done
    return entry->next;
}

/*! the list prev entry
 *
 * @param list                              the list
 * @param entry                             the entry
 *
 * @return                                  the prev entry
 */
static __tb_inline__ tb_list_entry_ref_t    tb_list_entry_prev(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{ 
    // check
    tb_assert(entry);

    // done
    return entry->prev;
}

/*! the list head entry
 *
 * @param list                              the list
 *
 * @return                                  the head entry
 */
static __tb_inline__ tb_list_entry_ref_t    tb_list_entry_head(tb_list_entry_head_ref_t list)
{
    // check
    tb_assert(list);

    // done
    return list->next;
}

/*! the list last entry
 *
 * @param list                              the list
 *
 * @return                                  the last entry
 */
static __tb_inline__ tb_list_entry_ref_t    tb_list_entry_last(tb_list_entry_head_ref_t list)
{ 
    // check
    tb_assert(list);

    // done
    return list->prev;
}

/*! the list tail entry
 *
 * @param list                              the list
 *
 * @return                                  the tail entry
 */
static __tb_inline__ tb_list_entry_ref_t    tb_list_entry_tail(tb_list_entry_head_ref_t list)
{ 
    // done
    return (tb_list_entry_ref_t)list;
}

/*! the list is null?
 *
 * @param list                              the list
 *
 * @return                                  tb_true or tb_false
 */
static __tb_inline__ tb_bool_t              tb_list_entry_is_null(tb_list_entry_head_ref_t list)
{ 
    // check
    tb_assert(list);

    // done
    return !list->size;
}

/*! is the list head entry?
 *
 * @param list                              the list
 * @param entry                             the entry
 *
 * @return                                  tb_true or tb_false
 */
static __tb_inline__ tb_bool_t              tb_list_entry_is_head(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(list);

    // done
    return list->next == entry;
}

/*! is the list last entry?
 *
 * @param list                              the list
 * @param entry                             the entry
 *
 * @return                                  tb_true or tb_false
 */
static __tb_inline__ tb_bool_t              tb_list_entry_is_last(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(list);

    // done
    return list->prev == entry;
}

/*! the list is valid?
 *
 * @param list                              the list
 *
 * @return                                  tb_true or tb_false
 */
static __tb_inline__ tb_bool_t              tb_list_entry_is_valid(tb_list_entry_head_ref_t list)
{ 
    // check
    tb_assert(list);

    // done
    return (list->next && list->next->prev == (tb_list_entry_ref_t)list) && (list->prev && list->prev->next == (tb_list_entry_ref_t)list);
}

/*! splice the spliced_list to list[prev, next]
 *
 * @param list                              the list
 * @param prev                              the prev
 * @param next                              the next
 * @param spliced_list                      the spliced list
 */
static __tb_inline__ tb_void_t              tb_list_entry_splice(tb_list_entry_head_ref_t list, tb_list_entry_ref_t prev, tb_list_entry_ref_t next, tb_list_entry_head_ref_t spliced_list)
{
    // check
    tb_assert(list && prev && next);
    tb_assert(spliced_list && spliced_list->next && spliced_list->prev);

    // valid?
    tb_assert(tb_list_entry_is_valid(list));
    tb_assert(tb_list_entry_is_valid(spliced_list));

    // empty?
    tb_check_return(!tb_list_entry_is_null(spliced_list));

    // done
    spliced_list->next->prev    = prev;
    prev->next                  = spliced_list->next;
    spliced_list->prev->next    = next;
    next->prev                  = spliced_list->prev;

    // update size
    list->size += spliced_list->size;
    
    // clear the spliced list
    tb_list_entry_clear(spliced_list);
}

/*! splice the spliced_list at the list head
 *
 * @param list                              the list
 * @param spliced_list                      the spliced list
 */
static __tb_inline__ tb_void_t              tb_list_entry_splice_head(tb_list_entry_head_ref_t list, tb_list_entry_head_ref_t spliced_list)
{
    // check
    tb_assert(list);

    // done
    tb_list_entry_splice(list, (tb_list_entry_ref_t)list, list->next, spliced_list);
}

/*! splice the spliced_list at the list tail
 *
 * @param list                              the list
 * @param spliced_list                      the spliced list
 */
static __tb_inline__ tb_void_t              tb_list_entry_splice_tail(tb_list_entry_head_ref_t list, tb_list_entry_head_ref_t spliced_list)
{
    // check
    tb_assert(list);

    // done
    tb_list_entry_splice(list, list->prev, (tb_list_entry_ref_t)list, spliced_list);
}

/*! insert entry to the next
 *
 * @param list                              the list
 * @param node                              the list node
 * @param entry                             the inserted list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_insert_next(tb_list_entry_head_ref_t list, tb_list_entry_ref_t node, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(list && node && node->next && entry);
    tb_assert(node != entry);

    // valid?
    tb_assert(tb_list_entry_is_valid(list));

    // insert entry
    node->next->prev    = entry;
    entry->next         = node->next;
    entry->prev         = node;
    node->next          = entry;

    // size++
    list->size++;
}

/*! insert entry to the prev
 *
 * @param list                              the list
 * @param node                              the list node
 * @param entry                             the inserted list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_insert_prev(tb_list_entry_head_ref_t list, tb_list_entry_ref_t node, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(list && node);

    // insert it
    tb_list_entry_insert_next(list, node->prev, entry);
}

/*! insert entry to the head 
 *
 * @param list                              the list
 * @param entry                             the inserted list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_insert_head(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    tb_list_entry_insert_next(list, (tb_list_entry_ref_t)list, entry);
}

/*! insert entry to the tail 
 *
 * @param list                              the list
 * @param entry                             the inserted list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_insert_tail(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(list && entry);

    // insert it
    tb_list_entry_insert_next(list, list->prev, entry);
}

/*! replace the entry
 *
 * @param list                              the list
 * @param node                              the replaced list node
 * @param entry                             the new list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_replace(tb_list_entry_head_ref_t list, tb_list_entry_ref_t node, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(node && node->next && node->prev && entry);
    tb_assert(node != entry);

    // valid?
    tb_assert(tb_list_entry_is_valid(list));

    // replace it
    entry->next         = node->next;
    entry->next->prev   = entry;
    entry->prev         = node->prev;
    entry->prev->next   = entry;
}

/*! replace the next entry
 *
 * @param list                              the list
 * @param node                              the list node
 * @param entry                             the new list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_replace_next(tb_list_entry_head_ref_t list, tb_list_entry_ref_t node, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(node);

    // replace it
    tb_list_entry_replace(list, node->next, entry);
}

/*! replace the prev entry
 *
 * @param list                              the list
 * @param node                              the list node
 * @param entry                             the new list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_replace_prev(tb_list_entry_head_ref_t list, tb_list_entry_ref_t node, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(node);

    // replace it
    tb_list_entry_replace(list, node->prev, entry);
}

/*! replace the head entry
 *
 * @param list                              the list
 * @param entry                             the new list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_replace_head(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(list);

    // replace it
    tb_list_entry_replace(list, list->next, entry);
}

/*! replace the last entry
 *
 * @param list                              the list
 * @param entry                             the new list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_replace_last(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(list);

    // replace it
    tb_list_entry_replace(list, list->prev, entry);
}

/*! remove the entry safely
 *
 * @param list                              the list
 * @param prev                              the prev entry
 * @param next                              the next entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_remove_safe(tb_list_entry_head_ref_t list, tb_list_entry_ref_t prev, tb_list_entry_ref_t next)
{
    // check
    tb_assert(list && list->size && prev && next);

    // valid?
    tb_assert(tb_list_entry_is_valid(list));

    // remove entries
    prev->next = next;
    next->prev = prev;

    // update size
    list->size--;
}

/*! remove the entry
 *
 * @param list                              the list
 * @param entry                             the removed list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_remove(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(entry);

    // remove it
    tb_list_entry_remove_safe(list, entry->prev, entry->next);
}

/*! remove the next entry
 *
 * @param list                              the list
 * @param prev                              the prev entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_remove_next(tb_list_entry_head_ref_t list, tb_list_entry_ref_t prev)
{
    // check
    tb_assert(prev && prev->next);

    // remove it
    tb_list_entry_remove_safe(list, prev, prev->next->next);
}

/*! remove the prev entry
 *
 * @param list                              the list
 * @param next                              the next entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_remove_prev(tb_list_entry_head_ref_t list, tb_list_entry_ref_t next)
{
    // check
    tb_assert(next && next->prev);

    // remove it
    tb_list_entry_remove_safe(list, next->prev->prev, next);
}

/*! remove the head entry
 *
 * @param list                              the list
 */
static __tb_inline__ tb_void_t              tb_list_entry_remove_head(tb_list_entry_head_ref_t list)
{
    // check
    tb_assert(list && list->next);

    // remove it
    tb_list_entry_remove_safe(list, (tb_list_entry_ref_t)list, list->next->next);
}

/*! remove the last entry
 *
 * @param list                              the list
 */
static __tb_inline__ tb_void_t              tb_list_entry_remove_last(tb_list_entry_head_ref_t list)
{
    // check
    tb_assert(list && list->prev);

    // remove it
    tb_list_entry_remove_safe(list, list->prev->prev, (tb_list_entry_ref_t)list);
}

/*! moveto the next entry
 *
 * @param list                              the list
 * @param node                              the list node
 * @param entry                             the moved list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_moveto_next(tb_list_entry_head_ref_t list, tb_list_entry_ref_t node, tb_list_entry_ref_t entry)
{
    // check
    tb_check_return(node != entry);

    // move it
    tb_list_entry_remove(list, entry);
    tb_list_entry_insert_next(list, node, entry);
}

/*! moveto the prev entry
 *
 * @param list                              the list
 * @param node                              the list node
 * @param entry                             the moved list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_moveto_prev(tb_list_entry_head_ref_t list, tb_list_entry_ref_t node, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(node);

    // move it
    tb_list_entry_moveto_next(list, node->prev, entry);
}

/*! moveto the head entry
 *
 * @param list                              the list
 * @param entry                             the moved list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_moveto_head(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // move it
    tb_list_entry_moveto_next(list, (tb_list_entry_ref_t)list, entry);
}

/*! moveto the tail entry
 *
 * @param list                              the list
 * @param entry                             the moved list entry
 */
static __tb_inline__ tb_void_t              tb_list_entry_moveto_tail(tb_list_entry_head_ref_t list, tb_list_entry_ref_t entry)
{
    // check
    tb_assert(list);

    // move it
    tb_list_entry_moveto_next(list, list->prev, entry);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

