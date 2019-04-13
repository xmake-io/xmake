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
 * @file        hash_set.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_HASH_SET_H
#define TB_CONTAINER_HASH_SET_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "hash_map.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the micro hash bucket size
#define TB_HASH_SET_BUCKET_SIZE_MICRO                 TB_HASH_MAP_BUCKET_SIZE_MICRO

/// the small hash bucket size
#define TB_HASH_SET_BUCKET_SIZE_SMALL                 TB_HASH_MAP_BUCKET_SIZE_SMALL

/// the large hash bucket size
#define TB_HASH_SET_BUCKET_SIZE_LARGE                 TB_HASH_MAP_BUCKET_SIZE_LARGE

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the hash set ref type
 *
 * @note the itor of the same item is mutable
 */
typedef tb_iterator_ref_t tb_hash_set_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init hash set
 *
 * @param bucket_size   the hash bucket size, using the default size if be zero
 * @param element       the element
 *
 * @return              the hash set
 */
tb_hash_set_ref_t       tb_hash_set_init(tb_size_t bucket_size, tb_element_t element);

/*! exit hash set
 *
 * @param hash_set      the hash set
 */
tb_void_t               tb_hash_set_exit(tb_hash_set_ref_t hash_set);

/*! clear hash set
 *
 * @param hash_set      the hash set
 */
tb_void_t               tb_hash_set_clear(tb_hash_set_ref_t hash_set);

/*! get item?
 *
 * @code
 * if (tb_hash_set_get(hash_set, name))
 * {
 * }
 * @endcode
 *
 * @param hash_set      the hash set
 * @param data          the item data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_hash_set_get(tb_hash_set_ref_t hash_set, tb_cpointer_t data);

/*! find item 
 *
 * @code
 *
 * // find item
 * tb_size_t itor = tb_hash_set_find(hash_set, data);
 * if (itor != tb_iterator_tail(hash_set))
 * {
 *      // remove it
 *      tb_iterator_remove(hash_set, itor);
 * }
 * @endcode
 *
 * @param hash_set      the hash set
 * @param data          the item data
 *
 * @return              the item itor, @note: the itor of the same item is mutable
 */
tb_size_t               tb_hash_set_find(tb_hash_set_ref_t hash_set, tb_cpointer_t data);

/*! insert item
 *
 * @note each item is unique
 *
 * @param hash_set      the hash set
 * @param data          the item data
 *
 * @return              the item itor, @note: the itor of the same item is mutable
 */
tb_size_t               tb_hash_set_insert(tb_hash_set_ref_t hash_set, tb_cpointer_t data);

/*! remove item
 *
 * @param hash_set      the hash set
 * @param data          the item data
 */
tb_void_t               tb_hash_set_remove(tb_hash_set_ref_t hash_set, tb_cpointer_t data);

/*! the hash set size
 *
 * @param hash_set      the hash set
 *
 * @return              the hash set size
 */
tb_size_t               tb_hash_set_size(tb_hash_set_ref_t hash_set);

/*! the hash set maxn
 *
 * @param hash_set      the hash set
 *
 * @return              the hash set maxn
 */
tb_size_t               tb_hash_set_maxn(tb_hash_set_ref_t hash_set);

#ifdef __tb_debug__
/*! dump hash
 *
 * @param hash_set      the hash set
 */
tb_void_t               tb_hash_set_dump(tb_hash_set_ref_t hash_set);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

