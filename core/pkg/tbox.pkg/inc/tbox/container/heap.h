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
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        heap.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_HEAP_H
#define TB_CONTAINER_HEAP_H

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
 * types
 */

/*! the head ref type
 *
 * <pre>
 * heap:    1      4      2      6       9       7       8       10       14       16
 *
 *                                          1(head)
 *                               -------------------------
 *                              |                         |
 *                              4                         2
 *                        --------------             -------------
 *                       |              |           |             |
 *                       6       (last / 2 - 1)9    7             8
 *                   ---------       ----
 *                  |         |     |
 *                  10        14    16(last - 1)
 * </pre>
 *
 * performance: 
 *
 * put: O(lgn)
 * pop: O(1)
 * top: O(1)
 * del: O(lgn) + find: O(n)
 *
 * iterator:
 *
 * next: fast
 * prev: fast
 *
 * </pre>
 *
 * @note the itor of the same item is mutable
 */
typedef tb_iterator_ref_t tb_heap_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init heap, default: minheap
 *
 * @param grow      the item grow, using the default grow if be zero
 * @param element   the element
 *
 * @return          the heap
 */
tb_heap_ref_t       tb_heap_init(tb_size_t grow, tb_element_t element);

/*! exit heap
 *
 * @param heap      the heap
 */
tb_void_t           tb_heap_exit(tb_heap_ref_t heap);

/*! clear the heap
 *
 * @param heap      the heap
 */
tb_void_t           tb_heap_clear(tb_heap_ref_t heap);

/*! the heap size
 *
 * @param heap      the heap
 *
 * @return          the heap size
 */
tb_size_t           tb_heap_size(tb_heap_ref_t heap);

/*! the heap maxn
 *
 * @param heap      the heap
 *
 * @return          the heap maxn
 */
tb_size_t           tb_heap_maxn(tb_heap_ref_t heap);

/*! the heap top item
 *
 * @param heap      the heap
 *
 * @return          the heap top item
 */
tb_pointer_t        tb_heap_top(tb_heap_ref_t heap);

/*! put the heap item
 *
 * @param heap      the heap
 * @param data      the item data
 */
tb_void_t           tb_heap_put(tb_heap_ref_t heap, tb_cpointer_t data);

/*! pop the heap item
 *
 * @param heap      the heap
 */
tb_void_t           tb_heap_pop(tb_heap_ref_t heap);

/*! remove the heap item using iterator only for algorithm(find, ...)
 *
 * @param heap      the heap
 * @param itor      the itor
 */
tb_void_t           tb_heap_remove(tb_heap_ref_t heap, tb_size_t itor);

#ifdef __tb_debug__
/*! dump heap
 *
 * @param heap      the heap
 */
tb_void_t           tb_heap_dump(tb_heap_ref_t heap);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

