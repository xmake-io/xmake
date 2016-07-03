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
 * @file        malloc.h
 *
 */
#ifndef TB_PREFIX_MALLOC_H
#define TB_PREFIX_MALLOC_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "keyword.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define tb_free(data)                               tb_allocator_free_(tb_allocator(), (tb_pointer_t)data __tb_debug_vals__)
#define tb_malloc(size)                             tb_allocator_malloc_(tb_allocator(), size __tb_debug_vals__)
#define tb_malloc0(size)                            tb_allocator_malloc0_(tb_allocator(), size __tb_debug_vals__)
#define tb_nalloc(item, size)                       tb_allocator_nalloc_(tb_allocator(), item, size __tb_debug_vals__)
#define tb_nalloc0(item, size)                      tb_allocator_nalloc0_(tb_allocator(), item, size __tb_debug_vals__)
#define tb_ralloc(data, size)                       tb_allocator_ralloc_(tb_allocator(), (tb_pointer_t)data, size __tb_debug_vals__)

#define tb_malloc_cstr(size)                        (tb_char_t*)tb_allocator_malloc_(tb_allocator(), size __tb_debug_vals__)
#define tb_malloc0_cstr(size)                       (tb_char_t*)tb_allocator_malloc0_(tb_allocator(), size __tb_debug_vals__)
#define tb_nalloc_cstr(item, size)                  (tb_char_t*)tb_allocator_nalloc_(tb_allocator(), item, size __tb_debug_vals__)
#define tb_nalloc0_cstr(item, size)                 (tb_char_t*)tb_allocator_nalloc0_(tb_allocator(), item, size __tb_debug_vals__)
#define tb_ralloc_cstr(data, size)                  (tb_char_t*)tb_allocator_ralloc_(tb_allocator(), (tb_pointer_t)data, size __tb_debug_vals__)

#define tb_malloc_bytes(size)                       (tb_byte_t*)tb_allocator_malloc_(tb_allocator(), size __tb_debug_vals__)
#define tb_malloc0_bytes(size)                      (tb_byte_t*)tb_allocator_malloc0_(tb_allocator(), size __tb_debug_vals__)
#define tb_nalloc_bytes(item, size)                 (tb_byte_t*)tb_allocator_nalloc_(tb_allocator(), item, size __tb_debug_vals__)
#define tb_nalloc0_bytes(item, size)                (tb_byte_t*)tb_allocator_nalloc0_(tb_allocator(), item, size __tb_debug_vals__)
#define tb_ralloc_bytes(data, size)                 (tb_byte_t*)tb_allocator_ralloc_(tb_allocator(), (tb_pointer_t)data, size __tb_debug_vals__)

#define tb_malloc_type(type)                        (type*)tb_allocator_malloc_(tb_allocator(), sizeof(type) __tb_debug_vals__)
#define tb_malloc0_type(type)                       (type*)tb_allocator_malloc0_(tb_allocator(), sizeof(type) __tb_debug_vals__)
#define tb_nalloc_type(item, type)                  (type*)tb_allocator_nalloc_(tb_allocator(), item, sizeof(type) __tb_debug_vals__)
#define tb_nalloc0_type(item, type)                 (type*)tb_allocator_nalloc0_(tb_allocator(), item, sizeof(type) __tb_debug_vals__)
#define tb_ralloc_type(data, item, type)            (type*)tb_allocator_ralloc_(tb_allocator(), (tb_pointer_t)data, ((item) * sizeof(type)) __tb_debug_vals__)

#define tb_align_free(data)                         tb_allocator_align_free_(tb_allocator(), (tb_pointer_t)data __tb_debug_vals__)
#define tb_align_malloc(size, align)                tb_allocator_align_malloc_(tb_allocator(), size, align __tb_debug_vals__)
#define tb_align_malloc0(size, align)               tb_allocator_align_malloc0_(tb_allocator(), size, align __tb_debug_vals__)
#define tb_align_nalloc(item, size, align)          tb_allocator_align_nalloc_(tb_allocator(), item, size, align __tb_debug_vals__)
#define tb_align_nalloc0(item, size, align)         tb_allocator_align_nalloc0_(tb_allocator(), item, size, align __tb_debug_vals__)
#define tb_align_ralloc(data, size, align)          tb_allocator_align_ralloc_(tb_allocator(), (tb_pointer_t)data, size, align __tb_debug_vals__)

#define tb_large_free(data)                         tb_allocator_large_free_(tb_allocator(), (tb_pointer_t)data __tb_debug_vals__)
#define tb_large_malloc(size, real)                 tb_allocator_large_malloc_(tb_allocator(), size, real __tb_debug_vals__)
#define tb_large_malloc0(size, real)                tb_allocator_large_malloc0_(tb_allocator(), size, real __tb_debug_vals__)
#define tb_large_nalloc(item, size, real)           tb_allocator_large_nalloc_(tb_allocator(), item, size, real __tb_debug_vals__)
#define tb_large_nalloc0(item, size, real)          tb_allocator_large_nalloc0_(tb_allocator(), item, size, real __tb_debug_vals__)
#define tb_large_ralloc(data, size, real)           tb_allocator_large_ralloc_(tb_allocator(), (tb_pointer_t)data, size, real __tb_debug_vals__)

#if TB_CPU_BIT64
#   define tb_align8_free(data)                     tb_free((tb_pointer_t)data)
#   define tb_align8_malloc(size)                   tb_malloc(size)
#   define tb_align8_malloc0(size)                  tb_malloc0(size)
#   define tb_align8_nalloc(item, size)             tb_nalloc(item, size)
#   define tb_align8_nalloc0(item, size)            tb_nalloc0(item, size)
#   define tb_align8_ralloc(data, size)             tb_ralloc((tb_pointer_t)data, size)
#else
#   define tb_align8_free(data)                     tb_align_free((tb_pointer_t)data)
#   define tb_align8_malloc(size)                   tb_align_malloc(size, 8)
#   define tb_align8_malloc0(size)                  tb_align_malloc0(size, 8)
#   define tb_align8_nalloc(item, size)             tb_align_nalloc(item, size, 8)
#   define tb_align8_nalloc0(item, size)            tb_align_nalloc0(item, size, 8)
#   define tb_align8_ralloc(data, size)             tb_align_ralloc((tb_pointer_t)data, size, 8)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */

struct __tb_allocator_t;
struct __tb_allocator_t*    tb_allocator();
tb_pointer_t                tb_allocator_malloc_(struct __tb_allocator_t* allocator, tb_size_t size __tb_debug_decl__);
tb_pointer_t                tb_allocator_malloc0_(struct __tb_allocator_t* allocator, tb_size_t size __tb_debug_decl__);
tb_pointer_t                tb_allocator_nalloc_(struct __tb_allocator_t* allocator, tb_size_t item, tb_size_t size __tb_debug_decl__);
tb_pointer_t                tb_allocator_nalloc0_(struct __tb_allocator_t* allocator, tb_size_t item, tb_size_t size __tb_debug_decl__);
tb_pointer_t                tb_allocator_ralloc_(struct __tb_allocator_t* allocator, tb_pointer_t data, tb_size_t size __tb_debug_decl__);
tb_bool_t                   tb_allocator_free_(struct __tb_allocator_t* allocator, tb_pointer_t data __tb_debug_decl__);
tb_pointer_t                tb_allocator_align_malloc_(struct __tb_allocator_t* allocator, tb_size_t size, tb_size_t align __tb_debug_decl__);
tb_pointer_t                tb_allocator_align_malloc0_(struct __tb_allocator_t* allocator, tb_size_t size, tb_size_t align __tb_debug_decl__);
tb_pointer_t                tb_allocator_align_nalloc_(struct __tb_allocator_t* allocator, tb_size_t item, tb_size_t size, tb_size_t align __tb_debug_decl__);
tb_pointer_t                tb_allocator_align_nalloc0_(struct __tb_allocator_t* allocator, tb_size_t item, tb_size_t size, tb_size_t align __tb_debug_decl__);
tb_pointer_t                tb_allocator_align_ralloc_(struct __tb_allocator_t* allocator, tb_pointer_t data, tb_size_t size, tb_size_t align __tb_debug_decl__);
tb_bool_t                   tb_allocator_align_free_(struct __tb_allocator_t* allocator, tb_pointer_t data __tb_debug_decl__);
tb_pointer_t                tb_allocator_large_malloc_(struct __tb_allocator_t* allocator, tb_size_t size, tb_size_t* real __tb_debug_decl__);
tb_pointer_t                tb_allocator_large_malloc0_(struct __tb_allocator_t* allocator, tb_size_t size, tb_size_t* real __tb_debug_decl__);
tb_pointer_t                tb_allocator_large_nalloc_(struct __tb_allocator_t* allocator, tb_size_t item, tb_size_t size, tb_size_t* real __tb_debug_decl__);
tb_pointer_t                tb_allocator_large_nalloc0_(struct __tb_allocator_t* allocator, tb_size_t item, tb_size_t size, tb_size_t* real __tb_debug_decl__);
tb_pointer_t                tb_allocator_large_ralloc_(struct __tb_allocator_t* allocator, tb_pointer_t data, tb_size_t size, tb_size_t* real __tb_debug_decl__);
tb_bool_t                   tb_allocator_large_free_(struct __tb_allocator_t* allocator, tb_pointer_t data __tb_debug_decl__);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif


