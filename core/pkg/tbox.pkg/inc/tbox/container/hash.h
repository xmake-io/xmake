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
 * @file        hash.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_HASH_H
#define TB_CONTAINER_HASH_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "item.h"
#include "iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the hash bulk size
#define TB_HASH_BULK_SIZE_MICRO                 (64)
#define TB_HASH_BULK_SIZE_SMALL                 (256)
#define TB_HASH_BULK_SIZE_LARGE                 (65536)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the hash item type
typedef struct __tb_hash_item_t
{
    /// the item name
    tb_pointer_t        name;

    /// the item data
    tb_pointer_t        data;

}tb_hash_item_t, *tb_hash_item_ref_t;

/*! the hash ref type
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
typedef tb_iterator_ref_t tb_hash_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init hash
 *
 * @param bulk_size     the hash bulk size, using the default size if be zero
 * @param name_func     the hash name func
 * @param data_func     the hash data func
 *
 * @return              the hash
 */
tb_hash_ref_t           tb_hash_init(tb_size_t bulk_size, tb_item_func_t name_func, tb_item_func_t data_func);

/*! exit hash
 *
 * @param hash          the hash
 */
tb_void_t               tb_hash_exit(tb_hash_ref_t hash);

/*! clear hash
 *
 * @param hash          the hash
 */
tb_void_t               tb_hash_clear(tb_hash_ref_t hash);

/*! get hash item itor
 *
 * @param hash          the hash
 * @param name          the hash item name
 *
 * @return              the hash itor, @note: itor => item maybe changed if insert or remove item
 */
tb_size_t               tb_hash_itor(tb_hash_ref_t hash, tb_cpointer_t name);

/*! get hash item data
 *
 * @param hash          the hash
 * @param name          the hash item name
 *
 * @return              the hash item data
 */
tb_pointer_t            tb_hash_get(tb_hash_ref_t hash, tb_cpointer_t name);

/*! del hash item
 *
 * @param hash          the hash
 * @param name          the hash item name
 */
tb_void_t               tb_hash_del(tb_hash_ref_t hash, tb_cpointer_t name);

/*! set hash item
 *
 * @param hash          the hash
 * @param name          the hash item name
 * @param data          the hash item data
 *
 * @return              the hash itor, @note: itor => item maybe changed if insert or remove item
 */
tb_size_t               tb_hash_set(tb_hash_ref_t hash, tb_cpointer_t name, tb_cpointer_t data);

/*! the hash size
 *
 * @param hash          the hash
 *
 * @return              the hash size
 */
tb_size_t               tb_hash_size(tb_hash_ref_t hash);

/*! the hash maxn
 *
 * @param hash          the hash
 *
 * @return              the hash maxn
 */
tb_size_t               tb_hash_maxn(tb_hash_ref_t hash);

#ifdef __tb_debug__
/*! dump hash
 *
 * @param hash          the hash
 */
tb_void_t               tb_hash_dump(tb_hash_ref_t hash);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

