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
