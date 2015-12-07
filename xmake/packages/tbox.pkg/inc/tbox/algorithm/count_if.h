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
 * @file        count_if.h
 * @ingroup     algorithm
 *
 */
#ifndef TB_ALGORITHM_COUNT_IF_H
#define TB_ALGORITHM_COUNT_IF_H

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

/*! count items if pred(item, value)
 *
 * @param iterator  the iterator
 * @param head      the iterator head
 * @param tail      the iterator tail
 * @param pred      the predicate
 * @param value     the value of the predicate
 *
 * @return          the real count
 */
tb_size_t           tb_count_if(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_predicate_ref_t pred, tb_cpointer_t value);

/*! count items for all if pred(item, value)
 *
 * @param iterator  the iterator
 * @param pred      the predicate
 * @param value     the value of the predicate
 *
 * @return          the real count
 */
tb_size_t           tb_count_all_if(tb_iterator_ref_t iterator, tb_predicate_ref_t pred, tb_cpointer_t value);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__
#endif
