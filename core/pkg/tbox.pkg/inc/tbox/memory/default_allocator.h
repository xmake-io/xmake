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
