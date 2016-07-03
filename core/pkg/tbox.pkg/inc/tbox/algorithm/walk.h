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
 * @file        walk.h
 * @ingroup     algorithm
 *
 */
#ifndef TB_ALGORITHM_WALK_H
#define TB_ALGORITHM_WALK_H

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

/// the walk func type
typedef tb_bool_t   (*tb_walk_func_t)(tb_iterator_ref_t iterator, tb_pointer_t item, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the walker
 *
 * @param iterator  the iterator
 * @param head      the iterator head
 * @param tail      the iterator tail
 * @param func      the walker func
 * @param priv      the func private data
 *
 * @return          the item count
 */
tb_size_t           tb_walk(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_walk_func_t func, tb_cpointer_t priv);

/*! the walker for all
 *
 * @param iterator  the iterator
 * @param func      the walker func
 * @param priv      the func private data
 *
 * @return          the item count
 */
tb_size_t           tb_walk_all(tb_iterator_ref_t iterator, tb_walk_func_t func, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__
#endif
