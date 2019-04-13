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
 * @file        rwalk.h
 * @ingroup     algorithm
 *
 */
#ifndef TB_ALGORITHM_RWALK_H
#define TB_ALGORITHM_RWALK_H

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

/// the reverse walk func type
typedef tb_bool_t   (*tb_rwalk_func_t)(tb_iterator_ref_t iterator, tb_pointer_t item, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the reverse walker
 *
 * @param iterator  the iterator
 * @param head      the iterator head
 * @param tail      the iterator tail
 * @param func      the walker func
 * @param priv      the func private data
 *
 * @return          the item count
 */
tb_size_t           tb_rwalk(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_rwalk_func_t func, tb_cpointer_t priv);

/*! the reverse walker for all
 *
 * @param iterator  the iterator
 * @param func      the walker func
 * @param priv      the func private data
 *
 * @return          the item count
 */
tb_size_t           tb_rwalk_all(tb_iterator_ref_t iterator, tb_rwalk_func_t func, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__
#endif
