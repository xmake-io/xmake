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

#define tb_allocator_malloc(allocator, size)                        tb_allocator_malloc_(allocator, size __tb_debug_vals__)
#define tb_allocator_malloc0(allocator, size)                       tb_allocator_malloc0_(allocator, size __tb_debug_vals__)

#define tb_allocator_nalloc(allocator, item, size)                  tb_allocator_nalloc_(allocator, item, size __tb_debug_vals__)
#define tb_allocator_nalloc0(allocator, item, size)                 tb_allocator_nalloc0_(allocator, item, size __tb_debug_vals__)

#define tb_allocator_ralloc(allocator, data, size)                  tb_allocator_ralloc_(allocator, (tb_pointer_t)(data), size __tb_debug_vals__)
#define tb_allocator_free(allocator, data)                          tb_allocator_free_(allocator, (tb_pointer_t)(data) __tb_debug_vals__)

#define tb_allocator_large_malloc(allocator, size, real)            tb_allocator_large_malloc_(allocator, size, real __tb_debug_vals__)
#define tb_allocator_large_malloc0(allocator, size, real)           tb_allocator_large_malloc0_(allocator, size, real __tb_debug_vals__)

#define tb_allocator_large_nalloc(allocator, item, size, real)      tb_allocator_large_nalloc_(allocator, item, size, real __tb_debug_vals__)
#define tb_allocator_large_nalloc0(allocator, item, size, real)     tb_allocator_large_nalloc0_(allocator, item, size, real __tb_debug_vals__)

#define tb_allocator_large_ralloc(allocator, data, size, real)      tb_allocator_large_ralloc_(allocator, (tb_pointer_t)(data), size, real __tb_debug_vals__)
#define tb_allocator_large_free(allocator, data)                    tb_allocator_large_free_(allocator, (tb_pointer_t)(data) __tb_debug_vals__)

#define tb_allocator_align_malloc(allocator, size, align)           tb_allocator_align_malloc_(allocator, size, align __tb_debug_vals__)
#define tb_allocator_align_malloc0(allocator, size, align)          tb_allocator_align_malloc0_(allocator, size, align __tb_debug_vals__)

#define tb_allocator_align_nalloc(allocator, item, size, align)     tb_allocator_align_nalloc_(allocator, item, size, align __tb_debug_vals__)
#define tb_allocator_align_nalloc0(allocator, item, size, align)    tb_allocator_align_nalloc0_(allocator, item, size, align __tb_debug_vals__)

#define tb_allocator_align_ralloc(allocator, data, size, align)     tb_allocator_align_ralloc_(allocator, (tb_pointer_t)(data), size, align __tb_debug_vals__)
#define tb_allocator_align_free(allocator, data)                    tb_allocator_align_free_(allocator, (tb_pointer_t)(data) __tb_debug_vals__)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the allocator type enum
typedef enum __tb_allocator_type_e
{
    TB_ALLOCATOR_NONE       = 0
,   TB_ALLOCATOR_DEFAULT    = 1
,   TB_ALLOCATOR_NATIVE     = 2
,   TB_ALLOCATOR_STATIC     = 4
,   TB_ALLOCATOR_LARGE      = 5
,   TB_ALLOCATOR_SMALL      = 6

}tb_allocator_type_e;

/// the allocator type
typedef struct __tb_allocator_t
{
    /// the type
    tb_size_t               type;

    /// the lock
    tb_spinlock_t           lock;

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

    /*! malloc large data
     *
     * @param allocator     the allocator 
     * @param size          the size
     * @param real          the real allocated size >= size, optional
     *
     * @return              the data address
     */
    tb_pointer_t            (*large_malloc)(struct __tb_allocator_t* allocator, tb_size_t size, tb_size_t* real __tb_debug_decl__);

    /*! realloc large data
     *
     * @param allocator     the allocator 
     * @param data          the data address
     * @param size          the data size
     * @param real          the real allocated size >= size, optional
     *
     * @return              the new data address
     */
    tb_pointer_t            (*large_ralloc)(struct __tb_allocator_t* allocator, tb_pointer_t data, tb_size_t size, tb_size_t* real __tb_debug_decl__);

    /*! free large data
     *
     * @param allocator     the allocator 
     * @param data          the data address
     *
     * @return              tb_true or tb_false
     */
    tb_bool_t               (*large_free)(struct __tb_allocator_t* allocator, tb_pointer_t data __tb_debug_decl__);

    /*! clear allocator
     *
     * @param allocator     the allocator 
     */
    tb_void_t               (*clear)(struct __tb_allocator_t* allocator);

    /*! exit allocator
     *
     * @param allocator     the allocator 
     */
    tb_void_t               (*exit)(struct __tb_allocator_t* allocator);

#ifdef __tb_debug__
    /*! dump allocator
     *
     * @param allocator     the allocator 
     */
    tb_void_t               (*dump)(struct __tb_allocator_t* allocator);

    /*! have this given data addess?
     *
     * @param allocator     the allocator 
     * @param data          the data address
     *
     * @return              tb_true or tb_false
     */
    tb_bool_t               (*have)(struct __tb_allocator_t* allocator, tb_cpointer_t data);
#endif

}tb_allocator_t, *tb_allocator_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the allocator
 *
 * @return              the allocator
 */
tb_allocator_ref_t      tb_allocator();

/*! the native allocator
 *
 * uses system memory directly 
 *
 * @return              the allocator
 */
tb_allocator_ref_t      tb_allocator_native(tb_noarg_t);

/*! the allocator type
 *
 * @param allocator     the allocator 
 *
 * @return              the allocator type
 */
tb_size_t               tb_allocator_type(tb_allocator_ref_t allocator);

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

/*! malloc large data
 *
 * @param allocator     the allocator 
 * @param size          the size
 * @param real          the real allocated size >= size, optional
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_large_malloc_(tb_allocator_ref_t allocator, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! malloc large data and fill zero 
 *
 * @param allocator     the allocator 
 * @param size          the size 
 * @param real          the real allocated size >= size, optional
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_large_malloc0_(tb_allocator_ref_t allocator, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! malloc large data with the item count
 *
 * @param allocator     the allocator 
 * @param item          the item count
 * @param size          the item size 
 * @param real          the real allocated size >= item * size, optional
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_large_nalloc_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! malloc large data with the item count and fill zero
 *
 * @param allocator     the allocator 
 * @param item          the item count
 * @param size          the item size 
 * @param real          the real allocated size >= item * size, optional
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_large_nalloc0_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! realloc large data
 *
 * @param allocator     the allocator 
 * @param data          the data address
 * @param size          the data size
 * @param real          the real allocated size >= size, optional
 *
 * @return              the new data address
 */
tb_pointer_t            tb_allocator_large_ralloc_(tb_allocator_ref_t allocator, tb_pointer_t data, tb_size_t size, tb_size_t* real __tb_debug_decl__);

/*! free large data
 *
 * @param allocator     the allocator 
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_allocator_large_free_(tb_allocator_ref_t allocator, tb_pointer_t data __tb_debug_decl__);

/*! align malloc data
 *
 * @param allocator     the allocator 
 * @param size          the size
 * @param align         the alignment bytes
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_align_malloc_(tb_allocator_ref_t allocator, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align malloc data and fill zero 
 *
 * @param allocator     the allocator 
 * @param size          the size 
 * @param align         the alignment bytes
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_align_malloc0_(tb_allocator_ref_t allocator, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align malloc data with the item count
 *
 * @param allocator     the allocator 
 * @param item          the item count
 * @param size          the item size 
 * @param align         the alignment bytes
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_align_nalloc_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align malloc data with the item count and fill zero
 *
 * @param allocator     the allocator 
 * @param item          the item count
 * @param size          the item size 
 * @param align         the alignment bytes
 *
 * @return              the data address
 */
tb_pointer_t            tb_allocator_align_nalloc0_(tb_allocator_ref_t allocator, tb_size_t item, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align realloc data
 *
 * @param allocator     the allocator 
 * @param data          the data address
 * @param size          the data size
 *
 * @return              the new data address
 */
tb_pointer_t            tb_allocator_align_ralloc_(tb_allocator_ref_t allocator, tb_pointer_t data, tb_size_t size, tb_size_t align __tb_debug_decl__);

/*! align free data
 *
 * @param allocator     the allocator 
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_allocator_align_free_(tb_allocator_ref_t allocator, tb_pointer_t data __tb_debug_decl__);

/*! clear it
 *
 * @param allocator     the allocator 
 */
tb_void_t               tb_allocator_clear(tb_allocator_ref_t allocator);

/*! exit it
 *
 * @param allocator     the allocator 
 */
tb_void_t               tb_allocator_exit(tb_allocator_ref_t allocator);

#ifdef __tb_debug__
/*! dump it
 *
 * @param allocator     the allocator 
 */
tb_void_t               tb_allocator_dump(tb_allocator_ref_t allocator);

/*! have this given data addess?
 *
 * @param allocator     the allocator 
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_allocator_have(tb_allocator_ref_t allocator, tb_cpointer_t data);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
