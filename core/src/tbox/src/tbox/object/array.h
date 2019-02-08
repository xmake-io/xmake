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
 * @file        array.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_ARRAY_H
#define TB_OBJECT_ARRAY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init array
 *
 * @param grow      the array grow
 * @param incr      is increase refn?
 *
 * @return          the array object
 */
tb_object_ref_t     tb_oc_array_init(tb_size_t grow, tb_bool_t incr);

/*! the array size
 *
 * @param array     the array object
 *
 * @return          the array size
 */
tb_size_t           tb_oc_array_size(tb_object_ref_t array);

/*! the array item at index
 *
 * @param array     the array object
 * @param index     the array index
 *
 * @return          the array item
 */
tb_object_ref_t     tb_oc_array_item(tb_object_ref_t array, tb_size_t index);

/*! set the array incr
 *
 * @param array     the array object
 * @param incr      is increase refn?
 */
tb_void_t           tb_oc_array_incr(tb_object_ref_t array, tb_bool_t incr);

/*! the array iterator
 *
 * @param array     the array object
 *
 * @return          the array iterator
 *
 * @code
 * tb_for_all (tb_object_ref_t, item, tb_oc_array_itor(array))
 * {
 *      if (item)
 *      {
 *          // ...
 *      }
 * }
 * @endcode
 */
tb_iterator_ref_t   tb_oc_array_itor(tb_object_ref_t array);

/*! remove the item from index
 *
 * @param array     the array object
 * @param index     the array index
 */
tb_void_t           tb_oc_array_remove(tb_object_ref_t array, tb_size_t index);

/*! append item to array
 *
 * @param array     the array object
 * @param index     the array index
 */
tb_void_t           tb_oc_array_append(tb_object_ref_t array, tb_object_ref_t item);

/*! insert item to array
 *
 * @param array     the array object
 * @param index     the array index
 * @param item      the array item
 */
tb_void_t           tb_oc_array_insert(tb_object_ref_t array, tb_size_t index, tb_object_ref_t item);

/*! replace item to array
 *
 * @param array     the array object
 * @param index     the array index
 * @param item      the array item
 */
tb_void_t           tb_oc_array_replace(tb_object_ref_t array, tb_size_t index, tb_object_ref_t item);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

