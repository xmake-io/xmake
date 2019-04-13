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
 * @file        remove_if.h
 * @ingroup     algorithm
 *
 */
#ifndef TB_ALGORITHM_REMOVE_IF_H
#define TB_ALGORITHM_REMOVE_IF_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "predicate.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! remove items if pred(item, value)
 *
 * @param iterator  the iterator
 * @param pred      the predicate
 * @param value     the value of the predicate
 */
tb_void_t           tb_remove_if(tb_iterator_ref_t iterator, tb_predicate_ref_t pred, tb_cpointer_t value);

/*! remove items if pred(item, value, &is_break) until is_break == tb_true
 *
 * @param iterator  the iterator
 * @param pred      the predicate with break
 * @param value     the value of the predicate
 */
tb_void_t           tb_remove_if_until(tb_iterator_ref_t iterator, tb_predicate_break_ref_t pred, tb_cpointer_t value);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__
#endif
