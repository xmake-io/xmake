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
 * @file        default_allocator.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_DEFAULT_ALLOCATOR_H
#define TB_MEMORY_DEFAULT_ALLOCATOR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "allocator.h"
#include "large_allocator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the global default allocator 
 * 
 * @param data              the buffer data, uses the native buffer if be null
 * @param size              the buffer size
 *
 * @return                  the allocator 
 */
tb_allocator_ref_t          tb_default_allocator(tb_byte_t* data, tb_size_t size);

/*! init the default allocator
 *
 * <pre>
 *
 *  ----------------      ------------------------------------------------------- 
 * | native memory  | or |                         data                          |
 *  ----------------      ------------------------------------------------------- 
 *         |             if data be null             |
 *         `---------------------------------------> |
 *                                                   |
 *  ----------------------------------------------------------------------------- 
 * |                                  large allocator                            |
 *  ----------------------------------------------------------------------------- 
 *                             |                     |                                 
 *                             |          ---------------------------------------  
 *                             |         |            small allocator            |
 *                             |          --------------------------------------- 
 *                             |                              |
 *  ----------------------------------------------------------------------------- 
 * |                         >3KB        |                 <=3KB                 |
 * |-----------------------------------------------------------------------------|
 * |                              default allocator                              |
 *  -----------------------------------------------------------------------------
 * 
 * @param large_allocator   the large allocator, cannot be null
 *
 * @return                  the allocator 
 */
tb_allocator_ref_t          tb_default_allocator_init(tb_allocator_ref_t large_allocator);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
