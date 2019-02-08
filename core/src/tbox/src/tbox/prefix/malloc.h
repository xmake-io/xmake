/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
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


