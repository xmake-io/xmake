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
 * @file        large_allocator.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_LARGE_ALLOCATOR_H
#define TB_MEMORY_LARGE_ALLOCATOR_H

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

/*! init the large allocator
 *
 * <pre>
 *
 *  -------------------------      ------------------------
 * |       native memory     |    |         data           |
 *  -------------------------      ------------------------ 
 *              |                             |
 *  -------------------------      ------------------------
 * |  native large allocator |    | static large allocator |
 *  -------------------------      ------------------------
 *              |                             |
 *  ------------------------------------------------------
 * |                     large allocator                  |
 *  ------------------------------------------------------ 
 *
 * </pre>
 * 
 * @param data          the data, uses the native memory if be null
 * @param size          the size
 *
 * @return              the allocator 
 */
tb_allocator_ref_t      tb_large_allocator_init(tb_byte_t* data, tb_size_t size);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
