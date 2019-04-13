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
 * @file        small_allocator.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_SMALL_ALLOCATOR_H
#define TB_MEMORY_SMALL_ALLOCATOR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "large_allocator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the data size maximum
#define TB_SMALL_ALLOCATOR_DATA_MAXN        (3072)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the small allocator only for size <=3KB
 *
 * <pre>
 *
 *  --------------------------------------
 * |    fixed pool: 16B    |  1-16B       | 
 * |--------------------------------------|
 * |    fixed pool: 32B    |  17-32B      |  
 * |--------------------------------------|
 * |    fixed pool: 64B    |  33-64B      | 
 * |--------------------------------------|
 * |    fixed pool: 96B*   |  65-96B*     | 
 * |--------------------------------------|
 * |    fixed pool: 128B   |  97-128B     |  
 * |--------------------------------------|
 * |    fixed pool: 192B*  |  129-192B*   |  
 * |--------------------------------------|
 * |    fixed pool: 256B   |  193-256B    |  
 * |--------------------------------------|
 * |    fixed pool: 384B*  |  257-384B*   |  
 * |--------------------------------------|
 * |    fixed pool: 512B   |  385-512B    |  
 * |--------------------------------------|
 * |    fixed pool: 1024B  |  513-1024B   |  
 * |--------------------------------------|
 * |    fixed pool: 2048B  |  1025-2048B  |  
 * |--------------------------------------|
 * |    fixed pool: 3072B* |  2049-3072B* |  
 *  -------------------------------------- 
 *
 * </pre>
 * 
 * @param large_allocator   the large allocator, uses the global allocator if be null
 *
 * @return                  the pool 
 */
tb_allocator_ref_t          tb_small_allocator_init(tb_allocator_ref_t large_allocator);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
