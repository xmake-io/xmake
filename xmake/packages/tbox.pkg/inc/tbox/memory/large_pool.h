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
 * @file        large_pool.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_LARGE_POOL_H
#define TB_MEMORY_LARGE_POOL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define tb_large_pool_malloc(pool, size, real)             tb_large_pool_malloc_(pool, size, real __tb_debug_vals__)
#define tb_large_pool_malloc0(pool, size, real)            tb_large_pool_malloc0_(pool, size, real __tb_debug_vals__)

#define tb_large_pool_nalloc(pool, item, size, real)       tb_large_pool_nalloc_(pool, item, size, real __tb_debug_vals__)
#define tb_large_pool_nalloc0(pool, item, size, real)      tb_large_pool_nalloc0_(pool, item, size, real __tb_debug_vals__)

#define tb_large_pool_ralloc(pool, data, size, real)       tb_large_pool_ralloc_(pool, (tb_pointer_t)(data), size, real __tb_debug_vals__)
#define tb_large_pool_free(pool, data)                     tb_large_pool_free_(pool, (tb_pointer_t)(data) __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the large pool ref type
 *
 * <pre>
 *
 *  -------------------------      ----------------------
 * |       native memory     |    |         data         |
 *  -------------------------      ---------------------- 
 *              |                             |
 *  -------------------------      ----------------------
 * |       native pool       |    |      static pool     |
 *  -------------------------      ---------------------- 
 *              |                             |
 *  -----------------------------------------------------
 * |  if (pool address & 1)     |           else         |
 * |-----------------------------------------------------|
 * |                       large pool                    |
 *  ----------------------------------------------------- 
 *
 *  </pre>
 *
 */
typedef struct{}*       tb_large_pool_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the large pool instance
 * 
 * @return              the pool 
 */
tb_large_pool_ref_t     tb_large_pool(tb_noarg_t);

/*! init the large pool
 * 
 * @param data          the pool data, using the native memory if be null
 * @param size          the pool size
 *
 * @return              the pool 
 */
tb_large_pool_ref_t     tb_large_pool_init(tb_byte_t* data, tb_size_t size);

/*! exit the pool
 *
 * @param pool          the pool 
 */
tb_void_t               tb_large_pool_exit(tb_large_pool_ref_t pool);

/*! clear the pool
 *
 * @param pool          the pool 
 */
tb_void_t               tb_large_pool_clear(tb_large_pool_ref_t pool);

/*! malloc data
 *
 * @param pool          the pool 
 * @param size          the size
 * @param real          the real allocated size >= size, optional
 *
 * @return              the data address
 */
tb_pointer_t            tb_large_pool_malloc_(tb_large_pool_ref_t pool, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! malloc data and fill zero 
 *
 * @param pool          the pool 
 * @param size          the size 
 * @param real          the real allocated size >= size, optional
 *
 * @return              the data address
 */
tb_pointer_t            tb_large_pool_malloc0_(tb_large_pool_ref_t pool, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! malloc data with the item count
 *
 * @param pool          the pool 
 * @param item          the item count
 * @param size          the item size 
 * @param real          the real allocated size >= item * size, optional
 *
 * @return              the data address
 */
tb_pointer_t            tb_large_pool_nalloc_(tb_large_pool_ref_t pool, tb_size_t item, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! malloc data with the item count and fill zero
 *
 * @param pool          the pool 
 * @param item          the item count
 * @param size          the item size 
 * @param real          the real allocated size >= item * size, optional
 *
 * @return              the data address
 */
tb_pointer_t            tb_large_pool_nalloc0_(tb_large_pool_ref_t pool, tb_size_t item, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! realloc data
 *
 * @param pool          the pool 
 * @param data          the data address
 * @param size          the data size
 * @param real          the real allocated size >= size, optional
 *
 * @return              the new data address
 */
tb_pointer_t            tb_large_pool_ralloc_(tb_large_pool_ref_t pool, tb_pointer_t data, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! free data
 *
 * @param pool          the pool 
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_large_pool_free_(tb_large_pool_ref_t pool, tb_pointer_t data __tb_debug_decl__);

#ifdef __tb_debug__
/*! dump the pool
 *
 * @param pool          the pool
 */
tb_void_t               tb_large_pool_dump(tb_large_pool_ref_t pool);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
