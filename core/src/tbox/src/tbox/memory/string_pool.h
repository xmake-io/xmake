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
typedef __tb_typeref__(string_pool);

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
