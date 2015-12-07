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
 * @file        fixed_pool.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_FIXED_POOL_H
#define TB_MEMORY_FIXED_POOL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "large_pool.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define tb_fixed_pool_malloc(pool)              tb_fixed_pool_malloc_(pool __tb_debug_vals__)
#define tb_fixed_pool_malloc0(pool)             tb_fixed_pool_malloc0_(pool __tb_debug_vals__)
#define tb_fixed_pool_free(pool, item)          tb_fixed_pool_free_(pool, (tb_pointer_t)(item) __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the fixed pool ref type
 * 
 * <pre>
 *
 * current:
 *         -----------
 *        |           |
 *  --------------    |
 * |     slot     |<--
 * |--------------|
 * ||||||||||||||||  
 * |--------------| 
 * |              | 
 * |--------------| 
 * |              | 
 * |--------------| 
 * ||||||||||||||||  
 * |--------------| 
 * |||||||||||||||| 
 * |--------------| 
 * |              | 
 *  --------------  
 *
 * partial:
 *
 *  --------------       --------------               --------------
 * |     slot     | <=> |     slot     | <=> ... <=> |     slot     |
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     |              |             |              |
 * |--------------|     |--------------|             |--------------|
 * |              |     ||||||||||||||||             |              |
 * |--------------|     |--------------|             |--------------|
 * |              |     ||||||||||||||||             ||||||||||||||||
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     ||||||||||||||||             |              |
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     |              |             |              |
 * |--------------|     |--------------|             |--------------|
 * |              |     |              |             ||||||||||||||||
 *  --------------       --------------               --------------
 *
 * full:
 *
 *  --------------       --------------               --------------
 * |     slot     | <=> |     slot     | <=> ... <=> |     slot     |
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     ||||||||||||||||             ||||||||||||||||
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     ||||||||||||||||             ||||||||||||||||
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     ||||||||||||||||             ||||||||||||||||
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     ||||||||||||||||             ||||||||||||||||
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     ||||||||||||||||             ||||||||||||||||
 * |--------------|     |--------------|             |--------------|
 * ||||||||||||||||     ||||||||||||||||             ||||||||||||||||
 *  --------------       --------------               --------------
 *
 * slot:
 *
 *  -------------- ------------------------>|
 * |     head     |                         |
 * |--------------|                         |
 * |||   item     |                         |  
 * |--------------|                         |
 * |||   item     |                         |  
 * |--------------|                         | data
 * |||   item     |                         |  
 * |--------------|                         | 
 * |      ...     |                         |  
 * |--------------|                         | 
 * |||   item     |                         | 
 *  -------------- ------------------------>|
 *
 * </pre>
 */
typedef struct{}*       tb_fixed_pool_ref_t;

/// the item init func type
typedef tb_bool_t       (*tb_fixed_pool_item_init_func_t)(tb_pointer_t data, tb_cpointer_t priv);

/// the item exit func type
typedef tb_void_t       (*tb_fixed_pool_item_exit_func_t)(tb_pointer_t data, tb_cpointer_t priv);

/// the item walk func type
typedef tb_bool_t       (*tb_fixed_pool_item_walk_func_t)(tb_pointer_t data, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init fixed pool
 *
 * @param large_pool    the large pool, using the default large pool if be null
 * @param slot_size     the item count per-slot, using the default size if be zero
 * @param item_size     the item size
 * @param item_init     the item init func
 * @param item_exit     the item exit func
 * @param priv          the private data
 *
 * @return              the pool 
 */
tb_fixed_pool_ref_t     tb_fixed_pool_init(tb_large_pool_ref_t large_pool, tb_size_t slot_size, tb_size_t item_size, tb_fixed_pool_item_init_func_t item_init, tb_fixed_pool_item_exit_func_t item_exit, tb_cpointer_t priv);

/*! exit pool
 *
 * @param pool          the pool 
 */
tb_void_t               tb_fixed_pool_exit(tb_fixed_pool_ref_t pool);

/*! the item count
 *
 * @param pool          the pool 
 *
 * @return              the item count
 */
tb_size_t               tb_fixed_pool_size(tb_fixed_pool_ref_t pool);

/*! the item size
 *
 * @param pool          the pool 
 *
 * @return              the item size
 */
tb_size_t               tb_fixed_pool_item_size(tb_fixed_pool_ref_t pool);

/*! clear pool
 *
 * @param pool          the pool 
 */
tb_void_t               tb_fixed_pool_clear(tb_fixed_pool_ref_t pool);

/*! malloc data
 *
 * @param pool          the pool 
 * 
 * @return              the data
 */
tb_pointer_t            tb_fixed_pool_malloc_(tb_fixed_pool_ref_t pool __tb_debug_decl__);

/*! malloc data and clear it
 *
 * @param pool          the pool 
 *
 * @return              the data
 */
tb_pointer_t            tb_fixed_pool_malloc0_(tb_fixed_pool_ref_t pool __tb_debug_decl__);

/*! free data
 *
 * @param pool          the pool 
 * @param data          the data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_fixed_pool_free_(tb_fixed_pool_ref_t pool, tb_pointer_t data __tb_debug_decl__);

/*! walk item
 *
 * @code
    tb_bool_t tb_fixed_pool_item_func(tb_pointer_t data, tb_cpointer_t priv)
    {
        // ok or break
        return tb_true;
    }
 * @endcode
 *
 * @param pool          the pool 
 * @param func          the walk func
 * @param priv          the private data
 */
tb_void_t               tb_fixed_pool_walk(tb_fixed_pool_ref_t pool, tb_fixed_pool_item_walk_func_t func, tb_cpointer_t priv);

#ifdef __tb_debug__
/*! dump pool
 *
 * @param pool          the pool 
 */
tb_void_t               tb_fixed_pool_dump(tb_fixed_pool_ref_t pool);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
