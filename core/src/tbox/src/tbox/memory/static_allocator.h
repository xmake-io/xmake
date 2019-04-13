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
 * @file        static_allocator.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_STATIC_ALLOCATOR_H
#define TB_MEMORY_STATIC_ALLOCATOR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "allocator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the global static allocator 
 *
 * @note
 * this allocator may be called before tb_init()
 *
 * @param data          the allocator data
 * @param size          the allocator size
 *
 * @return              the allocator 
 */
tb_allocator_ref_t      tb_static_allocator(tb_byte_t* data, tb_size_t size);

/*! init the static allocator
 *
 * <pre>
 *
 *  -----------------------------------------------------
 * |                         data                        |
 *  ----------------------------------------------------- 
 *                             |           
 *  ----------------------------------------------------- 
 * |                    static allocator                 |
 *  ----------------------------------------------------- 
 *
 * </pre>
 * 
 * @param data          the allocator data
 * @param size          the allocator size
 *
 * @return              the allocator 
 */
tb_allocator_ref_t      tb_static_allocator_init(tb_byte_t* data, tb_size_t size);

/*! exit the allocator
 *
 * @param allocator     the allocator 
 */
tb_void_t               tb_static_allocator_exit(tb_allocator_ref_t allocator);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
