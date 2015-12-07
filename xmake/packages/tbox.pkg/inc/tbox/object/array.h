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
 * @file        array.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_ARRAY_H
#define TB_OBJECT_ARRAY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init array
 *
 * @param grow      the array grow
 * @param incr      is increase refn?
 *
 * @return          the array object
 */
tb_object_ref_t     tb_object_array_init(tb_size_t grow, tb_bool_t incr);

/*! the array size
 *
 * @param array     the array object
 *
 * @return          the array size
 */
tb_size_t           tb_object_array_size(tb_object_ref_t array);

/*! the array item at index
 *
 * @param array     the array object
 * @param index     the array index
 *
 * @return          the array item
 */
tb_object_ref_t     tb_object_array_item(tb_object_ref_t array, tb_size_t index);

/*! set the array incr
 *
 * @param array     the array object
 * @param incr      is increase refn?
 */
tb_void_t           tb_object_array_incr(tb_object_ref_t array, tb_bool_t incr);

/*! the array iterator
 *
 * @param array     the array object
 *
 * @return          the array iterator
 *
 * @code
 * tb_for_all (tb_object_ref_t, item, tb_object_array_itor(array))
 * {
 *      if (item)
 *      {
 *          // ...
 *      }
 * }
 * @endcode
 */
tb_iterator_ref_t   tb_object_array_itor(tb_object_ref_t array);

/*! remove the item from index
 *
 * @param array     the array object
 * @param index     the array index
 */
tb_void_t           tb_object_array_remove(tb_object_ref_t array, tb_size_t index);

/*! append item to array
 *
 * @param array     the array object
 * @param index     the array index
 */
tb_void_t           tb_object_array_append(tb_object_ref_t array, tb_object_ref_t item);

/*! insert item to array
 *
 * @param array     the array object
 * @param index     the array index
 * @param item      the array item
 */
tb_void_t           tb_object_array_insert(tb_object_ref_t array, tb_size_t index, tb_object_ref_t item);

/*! replace item to array
 *
 * @param array     the array object
 * @param index     the array index
 * @param item      the array item
 */
tb_void_t           tb_object_array_replace(tb_object_ref_t array, tb_size_t index, tb_object_ref_t item);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

