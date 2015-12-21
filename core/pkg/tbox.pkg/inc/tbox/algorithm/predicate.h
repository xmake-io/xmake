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
 * @file        predicate.h
 * @ingroup     algorithm
 */
#ifndef TB_ALGORITHM_PREDICATE_H
#define TB_ALGORITHM_PREDICATE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the predicate ref type
 *
 * @param iterator  the iterator
 * @param item      the inner item of the container
 * @param value     the outer value
 *
 * @return          tb_true or tb_false
 */
typedef tb_bool_t   (*tb_predicate_ref_t)(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value);

/*! the predicate break ref type
 *
 * @param iterator  the iterator
 * @param item      the inner item of the container
 * @param value     the outer value
 * @param is_break  is break now?
 *
 * @return          tb_true or tb_false
 */
typedef tb_bool_t   (*tb_predicate_break_ref_t)(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value, tb_bool_t* is_break);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the predicate: if (item == value)?
 *
 * @param iterator  the iterator
 * @param item      the inner item of the container
 * @param value     the outer value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_predicate_eq(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value);

/*! the predicate: if (item < value)?
 *
 * @param iterator  the iterator
 * @param item      the inner item of the container
 * @param value     the outer value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_predicate_le(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value);

/*! the predicate: if (item > value)?
 *
 * @param iterator  the iterator
 * @param item      the inner item of the container
 * @param value     the outer value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_predicate_be(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value);

/*! the predicate: if (item <= value)?
 *
 * @param iterator  the iterator
 * @param item      the inner item of the container
 * @param value     the outer value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_predicate_leq(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value);

/*! the predicate: if (item >= value)?
 *
 * @param iterator  the iterator
 * @param item      the inner item of the container
 * @param value     the outer value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_predicate_beq(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__
#endif
