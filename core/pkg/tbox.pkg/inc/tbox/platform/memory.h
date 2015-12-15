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

