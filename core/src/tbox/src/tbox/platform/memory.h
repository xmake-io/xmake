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
 * @file        memory.h
 * @defgroup    platform
 *
 */
#ifndef TB_PLATFORM_MEMORY_H
#define TB_PLATFORM_MEMORY_H

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

/*! init native memory
 *
 * @note 
 * need support to be called repeatly
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_native_memory_init(tb_noarg_t);

/// exit native memory
tb_void_t               tb_native_memory_exit(tb_noarg_t);

/*! malloc the native memory
 *
 * @param size          the size
 *
 * @return              the data address
 */
tb_pointer_t            tb_native_memory_malloc(tb_size_t size);

/*! malloc the native memory and fill zero 
 *
 * @param size          the size
 *
 * @return              the data address
 */
tb_pointer_t            tb_native_memory_malloc0(tb_size_t size);

/*! malloc the native memory with the item count
 *
 * @param item          the item count
 * @param size          the item size
 *
 * @return              the data address
 */
tb_pointer_t            tb_native_memory_nalloc(tb_size_t item, tb_size_t size);

/*! malloc the native memory with the item count and fill zero
 *
 * @param item          the item count
 * @param size          the item size
 *
 * @return              the data address
 */
tb_pointer_t            tb_native_memory_nalloc0(tb_size_t item, tb_size_t size);

/*! realloc the native memory
 *
 * @param data          the data address
 * @param size          the size
 *
 * @return              the new data address
 */
tb_pointer_t            tb_native_memory_ralloc(tb_pointer_t data, tb_size_t size);

/*! free the native memory
 *
 * @param data          the data address
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_native_memory_free(tb_pointer_t data);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

