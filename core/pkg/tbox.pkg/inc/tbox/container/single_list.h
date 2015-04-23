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
 * @file        single_list.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_SINGLE_LIST_H
#define TB_CONTAINER_SINGLE_LIST_H

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

/*! the double list ref type
 *
 *
 * <pre>
 * list: |-----| => |-------------------------------------------------=> |------| => |------| => tail
 *        head                                                                         last       
 *
 * performance: 
 *
 * insert:
 * insert midd: slow
 * insert head: fast
 * insert tail: fast
 * insert next: fast
 *
 * remove:
 * remove midd: slow
 * remove head: fast
 * remove last: fast
 * remove next: fast
 *
 * iterator:
 * next: fast
 * </pre>
 *
 */
typedef tb_iterator_ref_t   tb_single_list_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init list
 *
 * @param grow          the grow size
 * @param element       the element
 *
 * @return              the list
 */
tb_single_list_ref_t    tb_single_list_init(tb_size_t grow, tb_element_t element);

/*! exit list
 *
 * @param list          the list
 */
tb_void_t               tb_single_list_exit(tb_single_list_ref_t list);

/*! clear list
 *
 * @param list          the list
 */
tb_void_t               tb_single_list_clear(tb_single_list_ref_t list);

/*! the list head item
 *
 * @param list          the list
 *
 * @return              the head item
 */
tb_pointer_t            tb_single_list_head(tb_single_list_ref_t list);

/*! the list last item
 *
 * @param list          the list
 *
 * @return              the last item
 */
tb_pointer_t            tb_single_list_last(tb_single_list_ref_t list);

/*! insert the next item
 *
 * @param list          the list
 * @param itor          the item itor
 * @param data          the item data
 *
 * @return              the item itor
 */
tb_size_t               tb_single_list_insert_next(tb_single_list_ref_t list, tb_size_t itor, tb_cpointer_t data);

/*! insert the head item
 *
 * @param list          the list
 * @param data          the item data
 *
 * @return              the item itor
 */
tb_size_t               tb_single_list_insert_head(tb_single_list_ref_t list, tb_cpointer_t data);

/*! insert the tail item
 *
 * @param list          the list
 * @param data          the item data
 *
 * @return              the item itor
 */
tb_size_t               tb_single_list_insert_tail(tb_single_list_ref_t list, tb_cpointer_t data);

/*! replace the item
 *
 * @param list          the list
 * @param itor          the item itor
 * @param data          the item data
 */
tb_void_t               tb_single_list_replace(tb_single_list_ref_t list, tb_size_t itor, tb_cpointer_t data);

/*! replace the head item
 *
 * @param list          the list
 * @param data          the item data
 */
tb_void_t               tb_single_list_replace_head(tb_single_list_ref_t list, tb_cpointer_t data);

/*! replace the tail item
 *
 * @param list          the list
 * @param data          the item data
 */
tb_void_t               tb_single_list_replace_last(tb_single_list_ref_t list, tb_cpointer_t data);

/*! remove the next item
 *
 * @param list          the list
 * @param itor          the item itor
 */
tb_void_t               tb_single_list_remove_next(tb_single_list_ref_t list, tb_size_t itor);

/*! remove the head item
 *
 * @param list          the list
 */
tb_void_t               tb_single_list_remove_head(tb_single_list_ref_t list);

/*! the item count
 *
 * @param list          the list
 *
 * @return              the item count
 */
tb_size_t               tb_single_list_size(tb_single_list_ref_t list);

/*! the item max count
 *
 * @param list          the list
 *
 * @return              the item max count
 */
tb_size_t               tb_single_list_maxn(tb_single_list_ref_t list);

#ifdef __tb_debug__
/*! dump list
 *
 * @param list          the list
 */
tb_void_t               tb_single_list_dump(tb_single_list_ref_t list);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

