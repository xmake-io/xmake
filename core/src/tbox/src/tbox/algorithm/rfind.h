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
 * @file        rfind.h
 * @ingroup     algorithm
 *
 */
#ifndef TB_ALGORITHM_RFIND_H
#define TB_ALGORITHM_RFIND_H

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

/*! reverse find item
 *
 * @param iterator  the iterator
 * @param head      the iterator head
 * @param tail      the iterator tail
 * @param value     the value of the predicate
 *
 * @return          the iterator itor, return tb_iterator_tail(iterator) if not found
 */
tb_size_t           tb_rfind(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_cpointer_t value);

/*! reverse find item for all
 *
 * @param iterator  the iterator
 * @param value     the value of the predicate
 *
 * @return          the iterator itor, return tb_iterator_tail(iterator) if not found
 */
tb_size_t           tb_rfind_all(tb_iterator_ref_t iterator, tb_cpointer_t value);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__
#endif
