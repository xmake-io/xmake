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
 * @file        vector.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_VECTOR_H
#define TB_CONTAINER_VECTOR_H

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

/*! the vector ref type
 *
 * <pre>
 * vector: |-----|--------------------------------------------------------|------|
 *       head                                                           last    tail
 *
 * performance: 
 *
 * insert:
 * insert midd: slow
 * insert head: slow
 * insert tail: fast
 *
 * ninsert:
 * ninsert midd: fast
 * ninsert head: fast
 * ninsert tail: fast
 *
 * remove:
 * remove midd: slow
 * remove head: slow
 * remove last: fast
 *
 * nremove:
 * nremove midd: fast
 * nremove head: fast
 * nremove last: fast
 *
 * iterator:
 * next: fast
 * prev: fast
 * </pre>
 *
 * @note the itor of the same item is mutable
 *
 */
typedef tb_iterator_ref_t tb_vector_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init vector
 * 
 * @code
 *
    // init vector
    tb_vector_ref_t vector = tb_vector_init(0, tb_element_str(tb_true));
    if (vector)
    {
        // insert elements into head
        tb_vector_insert_head(vector, "hi!");

        // insert elements into tail
        tb_vector_insert_tail(vector, "how");
        tb_vector_insert_tail(vector, "are");
        tb_vector_insert_tail(vector, "you");

        // dump elements
        tb_for_all (tb_char_t const*, cstr, vector)
        {
            // trace
            tb_trace_d("%s", cstr);
        }

        // exit vector
        tb_vector_exit(vector);
    }
 * @endcode
 *
 * @param grow      the item grow
 * @param element   the element
 *
 * @return          the vector
 */
tb_vector_ref_t     tb_vector_init(tb_size_t grow, tb_element_t element);

/*! exist vector
 *
 * @param vector    the vector
 */
tb_void_t           tb_vector_exit(tb_vector_ref_t vector);

/*! the vector data
 *
 * @param vector    the vector
 *
 * @return          the vector data
 */
tb_pointer_t        tb_vector_data(tb_vector_ref_t vector);

/*! the vector head item
 *
 * @param vector    the vector
 *
 * @return          the vector head item
 */
tb_pointer_t        tb_vector_head(tb_vector_ref_t vector);

/*! the vector last item
 *
 * @param vector    the vector
 *
 * @return          the vector last item
 */
tb_pointer_t        tb_vector_last(tb_vector_ref_t vector);

/*! resize the vector
 *
 * @param vector    the vector
 * @param size      the vector size
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_vector_resize(tb_vector_ref_t vector, tb_size_t size);

/*! clear the vector
 *
 * @param vector    the vector
 */
tb_void_t           tb_vector_clear(tb_vector_ref_t vector);

/*! copy the vector
 *
 * @param vector    the vector
 * @param copy      the copied vector
 */
tb_void_t           tb_vector_copy(tb_vector_ref_t vector, tb_vector_ref_t copy);

/*! insert the vector prev item
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 */
tb_void_t           tb_vector_insert_prev(tb_vector_ref_t vector, tb_size_t itor, tb_cpointer_t data);

/*! insert the vector next item
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 */
tb_void_t           tb_vector_insert_next(tb_vector_ref_t vector, tb_size_t itor, tb_cpointer_t data);

/*! insert the vector head item
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 */
tb_void_t           tb_vector_insert_head(tb_vector_ref_t vector, tb_cpointer_t data);

/*! insert the vector tail item
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 */
tb_void_t           tb_vector_insert_tail(tb_vector_ref_t vector, tb_cpointer_t data);

/*! insert the vector prev items
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 * @param size      the item count
 */
tb_void_t           tb_vector_ninsert_prev(tb_vector_ref_t vector, tb_size_t itor, tb_cpointer_t data, tb_size_t size);

/*! insert the vector next items
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 * @param size      the item count
 */
tb_void_t           tb_vector_ninsert_next(tb_vector_ref_t vector, tb_size_t itor, tb_cpointer_t data, tb_size_t size);

/*! insert the vector head items
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 * @param size      the item count
 */
tb_void_t           tb_vector_ninsert_head(tb_vector_ref_t vector, tb_cpointer_t data, tb_size_t size);

/*! insert the vector tail items
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 * @param size      the item count
 */
tb_void_t           tb_vector_ninsert_tail(tb_vector_ref_t vector, tb_cpointer_t data, tb_size_t size);

/*! replace the vector item
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 */
tb_void_t           tb_vector_replace(tb_vector_ref_t vector, tb_size_t itor, tb_cpointer_t data);

/*! replace the vector head item
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 */
tb_void_t           tb_vector_replace_head(tb_vector_ref_t vector, tb_cpointer_t data);

/*! replace the vector last item
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 */
tb_void_t           tb_vector_replace_last(tb_vector_ref_t vector, tb_cpointer_t data);

/*! replace the vector items
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 * @param size      the item count
 */
tb_void_t           tb_vector_nreplace(tb_vector_ref_t vector, tb_size_t itor, tb_cpointer_t data, tb_size_t size);

/*! replace the vector head items
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 * @param size      the item count
 */
tb_void_t           tb_vector_nreplace_head(tb_vector_ref_t vector, tb_cpointer_t data, tb_size_t size);

/*! replace the vector last items
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param data      the item data
 * @param size      the item count
 */
tb_void_t           tb_vector_nreplace_last(tb_vector_ref_t vector, tb_cpointer_t data, tb_size_t size);

/*! remove the vector item
 *
 * @param vector    the vector
 * @param itor      the item itor
 */
tb_void_t           tb_vector_remove(tb_vector_ref_t vector, tb_size_t itor);

/*! remove the vector head item
 *
 * @param vector    the vector
 */
tb_void_t           tb_vector_remove_head(tb_vector_ref_t vector);

/*! remove the vector last item
 *
 * @param vector    the vector
 */
tb_void_t           tb_vector_remove_last(tb_vector_ref_t vector);

/*! remove the vector items
 *
 * @param vector    the vector
 * @param itor      the item itor
 * @param size      the item count
 */
tb_void_t           tb_vector_nremove(tb_vector_ref_t vector, tb_size_t itor, tb_size_t size);

/*! remove the vector head items
 *
 * @param vector    the vector
 * @param size      the item count
 */
tb_void_t           tb_vector_nremove_head(tb_vector_ref_t vector, tb_size_t size);

/*! remove the vector last items
 *
 * @param vector    the vector
 * @param size      the item count
 */
tb_void_t           tb_vector_nremove_last(tb_vector_ref_t vector, tb_size_t size);

/*! the vector size
 *
 * @param vector    the vector
 *
 * @return          the vector size
 */
tb_size_t           tb_vector_size(tb_vector_ref_t vector);

/*! the vector grow
 *
 * @param vector    the vector
 *
 * @return          the vector grow
 */
tb_size_t           tb_vector_grow(tb_vector_ref_t vector);

/*! the vector maxn
 *
 * @param vector    the vector
 *
 * @return          the vector maxn
 */
tb_size_t           tb_vector_maxn(tb_vector_ref_t vector);

#ifdef __tb_debug__
/*! dump vector
 *
 * @param vector    the vector
 */
tb_void_t           tb_vector_dump(tb_vector_ref_t vector);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

