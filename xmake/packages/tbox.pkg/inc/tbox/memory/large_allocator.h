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
