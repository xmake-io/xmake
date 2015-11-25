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
 * @file        allocator.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_ALLOCATOR_H
#define TB_MEMORY_ALLOCATOR_H

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

#define tb_allocator_malloc(allocator, size)              tb_allocator_malloc_(allocator, size __tb_debug_vals__)
#define tb_allocator_malloc0(allocator, size)             tb_allocator_malloc0_(allocator, size __tb_debug_vals__)

#define tb_allocator_nalloc(allocator, item, size)        tb_allocator_nalloc_(allocator, item, size __tb_debug_vals__)
#define tb_allocator_nalloc0(allocator, item, size)       tb_allocator_nalloc0_(allocator, item, size __tb_debug_vals__)

#define tb_allocator_ralloc(allocator, data, size)        tb_allocator_ralloc_(allocator, (tb_pointer_t)(data), size __tb_debug_vals__)
#define tb_allocator_free(allocator, data)                tb_allocator_free_(allocator, (tb_pointer_t)(data) __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the allocator type
typedef struct __tb_allocator_t
{
    /*! malloc data
     *
     * @param allocator     the allocator 
     * @param size          the size
     *
     * @return              the data address
     */
    tb_pointer_t            (*malloc)(struct __tb_allocator_t* allocator, tb_size_t size __tb_debug_decl__);

    /*! realloc data
     *
     * @param allocator     the allocator 
     * @param data          the data address
     * @param size          the data size
     *
     * @return              the new data address
     */
    tb_pointer_t            (*ralloc)(struct __tb_allocator_t* allocator, tb_pointer_t data, tb_size_t size __tb_debug_decl__);

    /*! free data
     *
     * @param allocator     the allocator 
     * @param data          the data address
     *
     * @return              tb_true or tb_false
     */
    tb_bool_t               (*free)(struct __tb_allocator_t* allocator, tb_pointer_t data __tb_debug_decl__);

#ifdef __tb_debug__
    /*! dump allocator
     *
     * @param allocator     the allocator 
     */
    tb_void_t               (*dump)(struct __tb_allocator_t* allocator);
#endif

}tb_allocator_t, *tb_allocator_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the native allocator
 *
 * @return              the allocator
 */
tb_allocator_ref_t      tb_allocator_native(tb_noarg_t);

/*! malloc data
 *
 * @param allocator     the allocator 
 * @param size          the size
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_malloc_(tb_allocator_ref_t allocator, tb_size_t size __tb_debug_decl__);

/*! malloc data and fill zero 
 *
 * @param allocator     the allocator 
 * @param size          the size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_malloc0_(tb_allocator_ref_t allocator, tb_size_t size __tb_debug_decl__);

/*! malloc data with the item count
 *
 * @param allocator     the allocator 
 * @param item          the item count
 * @param size          the item size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_nalloc_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size __tb_debug_decl__);

/*! malloc data with the item count and fill zero
 *
 * @param allocator     the allocator 
 * @param item          the item count
 * @param size          the item size 
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_nalloc0_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size __tb_debug_decl__);

/*! realloc data
 *
 * @param allocator     the allocator 
 * @param data          the data address
 * @param size          the data size
 *
 * @return              the new data address
 */
tb_pointer_t            tb_allocator_ralloc_(tb_allocator_ref_t allocator, tb_pointer_t data, tb_size_t size __tb_debug_decl__);

/*! free data
 *
 * @param allocator     the allocator 
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_allocator_free_(tb_allocator_ref_t allocator, tb_pointer_t data __tb_debug_decl__);

#ifdef __tb_debug__
/*! dump it
 *
 * @param allocator     the allocator 
 */
tb_void_t               tb_allocator_dump(tb_allocator_ref_t allocator);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
