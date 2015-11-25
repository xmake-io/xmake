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
 * @file        string_pool.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_STRING_POOL_H
#define TB_MEMORY_STRING_POOL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the string pool ref type
typedef struct{}*           tb_string_pool_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init string pool for small, readonly and repeat strings
 *
 * readonly, strip repeat strings and decrease memory fragmens
 *
 * @param bcase             is case?
 *
 * @return                  the string pool
 */
tb_string_pool_ref_t        tb_string_pool_init(tb_bool_t bcase);

/*! exit the string pool
 *
 * @param pool              the string pool
 */
tb_void_t                   tb_string_pool_exit(tb_string_pool_ref_t pool);

/*! clear the string pool
 *
 * @param pool              the string pool
 */
tb_void_t                   tb_string_pool_clear(tb_string_pool_ref_t pool);

/*! insert string to the pool and increase the reference count
 *
 * @param pool              the string pool
 * @param data              the string data
 *
 * @return                  the string data
 */
tb_char_t const*            tb_string_pool_insert(tb_string_pool_ref_t pool, tb_char_t const* data);

/*! remove string from the pool if the reference count be zero
 *
 * @param pool              the string pool
 * @param data              the string data
 */
tb_void_t                   tb_string_pool_remove(tb_string_pool_ref_t pool, tb_char_t const* data);

#ifdef __tb_debug__
/*! dump the string pool
 *
 * @param pool              the string pool
 */
tb_void_t                   tb_string_pool_dump(tb_string_pool_ref_t pool);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
