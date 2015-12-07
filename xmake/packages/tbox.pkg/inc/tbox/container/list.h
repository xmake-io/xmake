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
 * @file        list.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_LIST_H
#define TB_CONTAINER_LIST_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "element.h"
#include "iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the doubly-linked list ref type
 *
 *
 * <pre>
 * list: tail => |-----| => |-------------------------------------------------=> |------| => |------| => tail
 *        |       head                                                                         last       |
 *        |                                                                                               |
 *        <-----------------------------------------------------------------------------------------------
 *
 * performance: 
 *
 * insert:
 * insert midd: fast
 * insert head: fast
 * insert tail: fast
 * insert next: fast
 *
 * remove:
 * remove midd: fast
 * remove head: fast
 * remove last: fast
 * remove next: fast
 *
 * iterator:
 * next: fast
 * prev: fast
 * </pre>
 *
 */
typedef tb_iterator_ref_t   tb_list_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init list
 *
 * @param grow      the grow size
 * @param element   the element
 *
 * @return          the list
 */
tb_list_ref_t       tb_list_init(tb_size_t grow, tb_element_t element);

/*! exit list
 *
 * @param list      the list
 */
tb_void_t           tb_list_exit(tb_list_ref_t list);

/*! clear list
 *
 * @param list      the list
 */
tb_void_t           tb_list_clear(tb_list_ref_t list);

/*! the list head item
 *
 * @param list      the list
 *
 * @return          the head item
 */
tb_pointer_t        tb_list_head(tb_list_ref_t list);

/*! the list last item
 *
 * @param list      the list
 *
 * @return          the last item
 */
tb_pointer_t        tb_list_last(tb_list_ref_t list);

/*! insert the prev item
 *
 * @param list      the list
 * @param itor      the item itor
 * @param data      the item data
 *
 * @return          the item itor
 */
tb_size_t           tb_list_insert_prev(tb_list_ref_t list, tb_size_t itor, tb_cpointer_t data);

/*! insert the next item
 *
 * @param list      the list
 * @param itor      the item itor
 * @param data      the item data
 *
 * @return          the item itor
 */
tb_size_t           tb_list_insert_next(tb_list_ref_t list, tb_size_t itor, tb_cpointer_t data);

/*! insert the head item
 *
 * @param list      the list
 * @param data      the item data
 *
 * @return          the item itor
 */
tb_size_t           tb_list_insert_head(tb_list_ref_t list, tb_cpointer_t data);

/*! insert the tail item
 *
 * @param list      the list
 * @param data      the item data
 *
 * @return          the item itor
 */
tb_size_t           tb_list_insert_tail(tb_list_ref_t list, tb_cpointer_t data);

/*! replace the item
 *
 * @param list      the list
 * @param itor      the item itor
 * @param data      the item data
 */
tb_void_t           tb_list_replace(tb_list_ref_t list, tb_size_t itor, tb_cpointer_t data);

/*! replace the head item
 *
 * @param list      the list
 * @param data      the item data
 */
tb_void_t           tb_list_replace_head(tb_list_ref_t list, tb_cpointer_t data);

/*! replace the tail item
 *
 * @param list      the list
 * @param data      the item data
 */
tb_void_t           tb_list_replace_last(tb_list_ref_t list, tb_cpointer_t data);

/*! remove the item
 *
 * @param list      the list
 * @param itor      the item itor
 *
 * @return          the next item
 */
tb_size_t           tb_list_remove(tb_list_ref_t list, tb_size_t itor);

/*! remove the head item
 *
 * @param list      the list
 */
tb_void_t           tb_list_remove_head(tb_list_ref_t list);

/*! remove the last item
 *
 * @param list      the list
 */
tb_void_t           tb_list_remove_last(tb_list_ref_t list);

/*! moveto the prev item
 *
 * @param list      the list
 * @param itor      the item itor
 * @param move      the move itor
 */
tb_void_t           tb_list_moveto_prev(tb_list_ref_t list, tb_size_t itor, tb_size_t move);

/*! moveto the next item
 *
 * @param list      the list
 * @param itor      the item itor
 * @param move      the move itor
 */
tb_void_t           tb_list_moveto_next(tb_list_ref_t list, tb_size_t itor, tb_size_t move);

/*! moveto the head item
 *
 * @param list      the list
 * @param itor      the item itor
 */
tb_void_t           tb_list_moveto_head(tb_list_ref_t list, tb_size_t move);

/*! moveto the tail item
 *
 * @param list      the list
 * @param itor      the item itor
 */
tb_void_t           tb_list_moveto_tail(tb_list_ref_t list, tb_size_t move);

/*! the item count
 *
 * @param list      the list
 *
 * @return          the item count
 */
tb_size_t           tb_list_size(tb_list_ref_t list);

/*! the item max count
 *
 * @param list      the list
 *
 * @return          the item max count
 */
tb_size_t           tb_list_maxn(tb_list_ref_t list);

#ifdef __tb_debug__
/*! dump list
 *
 * @param list      the list
 */
tb_void_t           tb_list_dump(tb_list_ref_t list);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

