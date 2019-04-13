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
 * @file        static_fixed_pool.h
 *
 */
#ifndef TB_MEMORY_IMPL_STATIC_FIXED_POOL_H
#define TB_MEMORY_IMPL_STATIC_FIXED_POOL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../fixed_pool.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the static fixed pool ref type
 *
 * <pre>
 *  ---------------------------------------------------------------------------
 * |  head   |      used       |                    data                       |
 *  ---------------------------------------------------------------------------
 *               |
 *              pred
 * </pre>
 */
typedef __tb_typeref__(static_fixed_pool);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init pool
 *
 * @param data              the data address
 * @param size              the data size
 * @param item_size         the item size
 * @param for_small         add data size field at head for the small allocator 
 *
 * @return                  the pool
 */
tb_static_fixed_pool_ref_t  tb_static_fixed_pool_init(tb_byte_t* data, tb_size_t size, tb_size_t item_size, tb_bool_t for_small);

/*! exit pool
 *
 * @param pool              the pool
 */
tb_void_t                   tb_static_fixed_pool_exit(tb_static_fixed_pool_ref_t pool);

/*! the item count
 *
 * @param pool              the pool
 *
 * @return                  the item count
 */
tb_size_t                   tb_static_fixed_pool_size(tb_static_fixed_pool_ref_t pool);

/*! the item maximum count
 *
 * @param pool              the pool
 *
 * @return                  the item maximum count
 */
tb_size_t                   tb_static_fixed_pool_maxn(tb_static_fixed_pool_ref_t pool);

/*! is full?
 *
 * @param pool              the pool
 *
 * @return                  tb_true or tb_false
 */
tb_bool_t                   tb_static_fixed_pool_full(tb_static_fixed_pool_ref_t pool);

/*! is null?
 *
 * @param pool              the pool
 *
 * @return                  tb_true or tb_false
 */
tb_bool_t                   tb_static_fixed_pool_null(tb_static_fixed_pool_ref_t pool);

/*! clear pool
 *
 * @param pool              the pool
 */
tb_void_t                   tb_static_fixed_pool_clear(tb_static_fixed_pool_ref_t pool);

/*! malloc data
 *
 * @param pool              the pool
 * 
 * @return                  the data
 */
tb_pointer_t                tb_static_fixed_pool_malloc(tb_static_fixed_pool_ref_t pool __tb_debug_decl__);

/*! free data
 *
 * @param pool              the pool
 * @param data              the data
 *
 * @return                  tb_true or tb_false
 */
tb_bool_t                   tb_static_fixed_pool_free(tb_static_fixed_pool_ref_t pool, tb_pointer_t data __tb_debug_decl__);

/*! walk data
 *
 * @code
 * tb_bool_t tb_static_fixed_pool_item_func(tb_pointer_t data, tb_cpointer_t priv)
 * {
 *      // ok or break
 *      return tb_true;
 * }
 * @endcode
 *
 * @param pool              the pool
 * @param func              the walk func
 * @param priv              the walk data
 *
 */
tb_void_t                   tb_static_fixed_pool_walk(tb_static_fixed_pool_ref_t pool, tb_fixed_pool_item_walk_func_t func, tb_cpointer_t priv);

#ifdef __tb_debug__
/*! dump pool
 *
 * @param pool              the pool
 */
tb_void_t                   tb_static_fixed_pool_dump(tb_static_fixed_pool_ref_t pool);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
