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
