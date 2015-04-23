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
 * @file        pool.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_POOL_H
#define TB_MEMORY_POOL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "large_pool.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#define tb_pool_malloc(pool, size)              tb_pool_malloc_(pool, size __tb_debug_vals__)
#define tb_pool_malloc0(pool, size)             tb_pool_malloc0_(pool, size __tb_debug_vals__)

#define tb_pool_nalloc(pool, item, size)        tb_pool_nalloc_(pool, item, size __tb_debug_vals__)
#define tb_pool_nalloc0(pool, item, size)       tb_pool_nalloc0_(pool, item, size __tb_debug_vals__)

#define tb_pool_ralloc(pool, data, size)        tb_pool_ralloc_(pool, (tb_pointer_t)(data), size __tb_debug_vals__)
#define tb_pool_free(pool, data)                tb_pool_free_(pool, (tb_pointer_t)(data) __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the pool
 *
 * <pre>
 *
 *  ----------------      ------------------------------------------------------- 
 * | native memory  | or |                         data                          |
 *  ----------------      ------------------------------------------------------- 
 *         |             if data be null             |
 *         `---------------------------------------> |
 *                                                   |
 *  ----------------------------------------------------------------------------- 
 * |                                large pool[lock]                             |
 *  ----------------------------------------------------------------------------- 
 *                             |                     |                                 
 *                             |          ---------------------------------------  
 *                             |         |               small pool              |
 *                             |          --------------------------------------- 
 *                             |                              |
 *  ----------------------------------------------------------------------------- 
 * |                         >3KB        |                 <=3KB                 |
 * |-----------------------------------------------------------------------------|
 * |                                  pool[lock]                                 |
 *  -----------------------------------------------------------------------------
 *
 * </pre>
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the pool instance
 * 
 * @return              the pool 
 */
tb_pool_ref_t           tb_pool();

/*! init the pool
 * 
 * @param large_pool    the large pool, using the default large pool if be null
 *
 * @return              the pool 
 */
tb_pool_ref_t           tb_pool_init(tb_large_pool_ref_t large_pool);

/*! exit the pool
 *
 * @param pool          the pool 
 */
tb_void_t               tb_pool_exit(tb_pool_ref_t pool);

/*! malloc data
 *
 * @param pool          the pool 
 * @param size          the size
 *
 * @return              the data address
 */
tb_pointer_t            tb_pool_malloc_(tb_pool_ref_t pool, tb_size_t size __tb_debug_decl__);

/*! malloc data and fill zero 
 *
 * @param pool          the pool 
 * @param size          the size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_pool_malloc0_(tb_pool_ref_t pool, tb_size_t size __tb_debug_decl__);

/*! malloc data with the item count
 *
 * @param pool          the pool 
 * @param item          the item count
 * @param size          the item size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_pool_nalloc_(tb_pool_ref_t pool, tb_size_t item, tb_size_t size __tb_debug_decl__);

/*! malloc data with the item count and fill zero
 *
 * @param pool          the pool 
 * @param item          the item count
 * @param size          the item size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_pool_nalloc0_(tb_pool_ref_t pool, tb_size_t item, tb_size_t size __tb_debug_decl__);

/*! realloc data
 *
 * @param pool          the pool 
 * @param data          the data address
 * @param size          the data size
 *
 * @return              the new data address
 */
tb_pointer_t            tb_pool_ralloc_(tb_pool_ref_t pool, tb_pointer_t data, tb_size_t size __tb_debug_decl__);

/*! free data
 *
 * @param pool          the pool 
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_pool_free_(tb_pool_ref_t pool, tb_pointer_t data __tb_debug_decl__);

/*! align malloc data
 *
 * @param pool          the pool 
 * @param size          the size
 * @param align         the alignment bytes
 *
 * @return              the data address
 */
tb_pointer_t            tb_pool_align_malloc_(tb_pool_ref_t pool, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align malloc data and fill zero 
 *
 * @param pool          the pool 
 * @param size          the size 
 * @param align         the alignment bytes
 *
 * @return              the data address
 */
tb_pointer_t            tb_pool_align_malloc0_(tb_pool_ref_t pool, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align malloc data with the item count
 *
 * @param pool          the pool 
 * @param item          the item count
 * @param size          the item size 
 * @param align         the alignment bytes
 *
 * @return              the data address
 */
tb_pointer_t            tb_pool_align_nalloc_(tb_pool_ref_t pool, tb_size_t item, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align malloc data with the item count and fill zero
 *
 * @param pool          the pool 
 * @param item          the item count
 * @param size          the item size 
 * @param align         the alignment bytes
 *
 * @return              the data address
 */
tb_pointer_t            tb_pool_align_nalloc0_(tb_pool_ref_t pool, tb_size_t item, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align realloc data
 *
 * @param pool          the pool 
 * @param data          the data address
 * @param size          the data size
 *
 * @return              the new data address
 */
tb_pointer_t            tb_pool_align_ralloc_(tb_pool_ref_t pool, tb_pointer_t data, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align free data
 *
 * @param pool          the pool 
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_pool_align_free_(tb_pool_ref_t pool, tb_pointer_t data __tb_debug_decl__);

#ifdef __tb_debug__
/*! dump the pool
 *
 * @param pool          the pool
 * @param prefix        the trace prefix
 */
tb_void_t               tb_pool_dump(tb_pool_ref_t pool);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
