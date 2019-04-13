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
 * @file        hash_map.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_HASH_MAP_H
#define TB_CONTAINER_HASH_MAP_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "element.h"
#include "iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the micro hash bucket size
#define TB_HASH_MAP_BUCKET_SIZE_MICRO                 (64)

/// the small hash bucket size
#define TB_HASH_MAP_BUCKET_SIZE_SMALL                 (256)

/// the large hash bucket size
#define TB_HASH_MAP_BUCKET_SIZE_LARGE                 (65536)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the hash map item type
typedef struct __tb_hash_map_item_t
{
    /// the item name
    tb_pointer_t        name;

    /// the item data
    tb_pointer_t        data;

}tb_hash_map_item_t, *tb_hash_map_item_ref_t;

/*! the hash map ref type
 *
 * <pre>
 *                 0        1        3       ...     ...                n       n + 1
 * hash_list: |--------|--------|--------|--------|--------|--------|--------|--------|
 *                         |
 *                       -----    
 * item_list:           |     |       key:0                                      
 *                       -----   
 *                      |     |       key:1                                              
 *                       -----               <= insert by binary search algorithm
 *                      |     |       key:2                                               
 *                       -----  
 *                      |     |       key:3                                               
 *                       -----   
 *                      |     |       key:4                                               
 *                       -----  
 *                      |     |                                              
 *                       -----  
 *                      |     |                                              
 *                       -----  
 *                      |     |                                              
 *                       -----  
 *
 * </pre>
 *
 * @note the itor of the same item is mutable
 */
typedef tb_iterator_ref_t tb_hash_map_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init hash map
 *
 * @param bucket_size   the hash bucket size, using the default size if be zero
 * @param element_name  the item for name
 * @param element_data  the item for data
 *
 * @return              the hash map
 */
tb_hash_map_ref_t       tb_hash_map_init(tb_size_t bucket_size, tb_element_t element_name, tb_element_t element_data);

/*! exit hash map
 *
 * @param hash_map      the hash map
 */
tb_void_t               tb_hash_map_exit(tb_hash_map_ref_t hash_map);

/*! clear hash map
 *
 * @param hash_map      the hash map
 */
tb_void_t               tb_hash_map_clear(tb_hash_map_ref_t hash_map);

/*! get item data from name
 *
 * @note 
 * the return value may be zero if the item type is integer
 * so we need call tb_hash_map_find for judging whether to get value successfully
 *
 * @code
 *
 * // find item and get item data
 * tb_xxxx_ref_t data = (tb_xxxx_ref_t)tb_hash_map_get(hash_map, name);
 * if (data)
 * {
 *      // ...
 * }
 * @endcode
 *
 * @param hash_map      the hash map
 * @param name          the item name
 *
 * @return              the item data
 */
tb_pointer_t            tb_hash_map_get(tb_hash_map_ref_t hash_map, tb_cpointer_t name);

/*! find item from name
 *
 * @code
 *
 * // find item
 * tb_size_t itor = tb_hash_map_find(hash_map, name);
 * if (itor != tb_iterator_tail(hash_map))
 * {
 *      // get data
 *      tb_xxxx_ref_t data = (tb_xxxx_ref_t)tb_iterator_item(hash_map, itor);
 *      tb_assert(data);
 *
 *      // remove it
 *      tb_iterator_remove(hash_map, itor);
 * }
 * @endcode
 *
 * @param hash_map      the hash map
 * @param name          the item name
 *
 * @return              the item itor, @note: the itor of the same item is mutable
 */
tb_size_t               tb_hash_map_find(tb_hash_map_ref_t hash_map, tb_cpointer_t name);

/*! insert item data from name
 *
 * @note the pair (name => data) is unique
 *
 * @param hash_map      the hash map
 * @param name          the item name
 * @param data          the item data
 *
 * @return              the item itor, @note: the itor of the same item is mutable
 */
tb_size_t               tb_hash_map_insert(tb_hash_map_ref_t hash_map, tb_cpointer_t name, tb_cpointer_t data);

/*! remove item from name
 *
 * @param hash_map      the hash map
 * @param name          the item name
 */
tb_void_t               tb_hash_map_remove(tb_hash_map_ref_t hash_map, tb_cpointer_t name);

/*! the hash map size
 *
 * @param hash_map      the hash map
 *
 * @return              the hash map size
 */
tb_size_t               tb_hash_map_size(tb_hash_map_ref_t hash_map);

/*! the hash map maxn
 *
 * @param hash_map      the hash map
 *
 * @return              the hash map maxn
 */
tb_size_t               tb_hash_map_maxn(tb_hash_map_ref_t hash_map);

#ifdef __tb_debug__
/*! dump hash
 *
 * @param hash_map      the hash map
 */
tb_void_t               tb_hash_map_dump(tb_hash_map_ref_t hash_map);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

