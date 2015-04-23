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
 * @file        memory.h
 * @defgroup    memory
 *
 */
#ifndef TB_MEMORY_H
#define TB_MEMORY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "pool.h"
#include "fixed_pool.h"
#include "large_pool.h"
#include "small_pool.h"
#include "string_pool.h"
#include "buffer.h"
#include "queue_buffer.h"
#include "static_buffer.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * description
 */

/*!architecture
 *
 * <pre>
 *
 *  ----------------      ------------------------------------------------------- 
 * | native memory  | or |                         data                          |
 *  ----------------      ------------------------------------------------------- 
 *         |             if data be null             |
 *         `---------------------------------------> |
 *                                                   |
 *  -----------------------------------------------------------------------------      ----------------------      ------      ------
 * |                                large pool[lock]                             | -> |    fixed pool:NB     | -> | slot | -> | slot | -> ...
 *  -----------------------------------------------------------------------------      ----------------------      ------      ------
 *                             |                     |                                 
 *                             |          ---------------------------------------      ----------------------      ------      ------
 *                             |         |               small pool              | -> |    fixed pool:16B    | -> | slot | -> | slot | -> ...
 *                             |          ---------------------------------------     |----------------------|     ------      ------
 *                             |                              |                       |    fixed pool:32B    | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:64B    | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:96B*   | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:128B   | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:192B*  | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:256B   | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:384B*  | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:512B   | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:1024B  | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:2048B  | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:3072B* | -> ...
 *                             |                              |                        ---------------------- 
 *                             |                              |
 *                             |                              |
 *  ------------------------------------------------------------------------------ 
 * |                         >3KB        |                 <=3KB                  |
 * |------------------------------------------------------------------------------|
 * |                                  pool[lock]                                  |
 *  ------------------------------------------------------------------------------
 *                                       |                                                  
 *  ------------------------------------------------------------------------------         
 * |                        malloc, nalloc, strdup, free ...                      |
 *  ------------------------------------------------------------------------------ 
 *                                                                     |
 *                                                          ---------------------- 
 *                                                         |     string pool      |
 *                                                          ----------------------
 *
 * </pre>
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init memory
 *
 * @param data          the memory pool data
 * @param size          the memory pool size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_memory_init(tb_byte_t* data, tb_size_t size);

/// exit memory
tb_void_t               tb_memory_exit(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

