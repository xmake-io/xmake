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
