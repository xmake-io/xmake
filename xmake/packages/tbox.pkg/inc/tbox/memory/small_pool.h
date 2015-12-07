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
 * @file        small_pool.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_SMALL_POOL_H
#define TB_MEMORY_SMALL_POOL_H

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

// the data size maximum
#define TB_SMALL_POOL_DATA_SIZE_MAXN                        (3072)

#define tb_small_pool_malloc(pool, size)                    tb_small_pool_malloc_(pool, size __tb_debug_vals__)
#define tb_small_pool_malloc0(pool, size)                   tb_small_pool_malloc0_(pool, size __tb_debug_vals__)

#define tb_small_pool_nalloc(pool, item, size)              tb_small_pool_nalloc_(pool, item, size __tb_debug_vals__)
#define tb_small_pool_nalloc0(pool, item, size)             tb_small_pool_nalloc0_(pool, item, size __tb_debug_vals__)

#define tb_small_pool_ralloc(pool, data, size)              tb_small_pool_ralloc_(pool, (tb_pointer_t)(data), size __tb_debug_vals__)
#define tb_small_pool_free(pool, data)                      tb_small_pool_free_(pool, (tb_pointer_t)(data) __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the small pool ref type
 *
 * <pre>
 *
 *  --------------------------------------
 * |    fixed pool: 16B    |  1-16B       | 
 * |--------------------------------------|
 * |    fixed pool: 32B    |  17-32B      |  
 * |--------------------------------------|
 * |    fixed pool: 64B    |  33-64B      | 
 * |--------------------------------------|
 * |    fixed pool: 96B*   |  65-96B*     | 
 * |--------------------------------------|
 * |    fixed pool: 128B   |  97-128B     |  
 * |--------------------------------------|
 * |    fixed pool: 192B*  |  129-192B*   |  
 * |--------------------------------------|
 * |    fixed pool: 256B   |  193-256B    |  
 * |--------------------------------------|
 * |    fixed pool: 384B*  |  257-384B*   |  
 * |--------------------------------------|
 * |    fixed pool: 512B   |  385-512B    |  
 * |--------------------------------------|
 * |    fixed pool: 1024B  |  513-1024B   |  
 * |--------------------------------------|
 * |    fixed pool: 2048B  |  1025-2048B  |  
 * |--------------------------------------|
 * |    fixed pool: 3072B* |  2049-3072B* |  
 *  -------------------------------------- 
 *
 * </pre>
 */
typedef struct{}*       tb_small_pool_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the small pool only for size <=3KB
 * 
 * @param large_pool    the large pool, using the default large pool if be null
 *
 * @return              the pool 
 */
tb_small_pool_ref_t     tb_small_pool_init(tb_large_pool_ref_t large_pool);

/*! exit the pool
 *
 * @param pool          the pool 
 */
tb_void_t               tb_small_pool_exit(tb_small_pool_ref_t pool);

/*! clear the pool
 *
 * @param pool          the pool 
 */
tb_void_t               tb_small_pool_clear(tb_small_pool_ref_t pool);

/*! malloc data
 *
 * @param pool          the pool 
 * @param size          the size
 *
 * @return              the data address
 */
tb_pointer_t            tb_small_pool_malloc_(tb_small_pool_ref_t pool, tb_size_t size __tb_debug_decl__);

/*! malloc data and fill zero 
 *
 * @param pool          the pool 
 * @param size          the size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_small_pool_malloc0_(tb_small_pool_ref_t pool, tb_size_t size __tb_debug_decl__);

/*! malloc data with the item count
 *
 * @param pool          the pool 
 * @param item          the item count
 * @param size          the item size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_small_pool_nalloc_(tb_small_pool_ref_t pool, tb_size_t item, tb_size_t size __tb_debug_decl__);

/*! malloc data with the item count and fill zero
 *
 * @param pool          the pool 
 * @param item          the item count
 * @param size          the item size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_small_pool_nalloc0_(tb_small_pool_ref_t pool, tb_size_t item, tb_size_t size __tb_debug_decl__);

/*! realloc data
 *
 * @param pool          the pool 
 * @param data          the data address
 * @param size          the data size
 *
 * @return              the new data address
 */
tb_pointer_t            tb_small_pool_ralloc_(tb_small_pool_ref_t pool, tb_pointer_t data, tb_size_t size __tb_debug_decl__);

/*! free data
 *
 * @param pool          the pool 
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_small_pool_free_(tb_small_pool_ref_t pool, tb_pointer_t data __tb_debug_decl__);

#ifdef __tb_debug__
/*! dump the pool
 *
 * @param pool        the pool
 * @param prefix        the trace prefix
 */
tb_void_t               tb_small_pool_dump(tb_small_pool_ref_t pool);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
