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
 * @file        lock_profiler.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_LOCK_PROFILER_H
#define TB_UTILS_LOCK_PROFILER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// enable lock profiler
#undef TB_LOCK_PROFILER_ENABLE
#ifdef __tb_debug__
#   define TB_LOCK_PROFILER_ENABLE
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the lock profiler instance
 *
 * @return              the lock profiler handle
 */
tb_handle_t             tb_lock_profiler(tb_noarg_t);

/*! init lock profiler
 *
 * @note be used for the debug mode generally 
 *
 * @return              the lock profiler handle
 */
tb_handle_t             tb_lock_profiler_init(tb_noarg_t);

/*! exit lock profiler
 *
 * @param profiler      the lock profiler handle
 */
tb_void_t               tb_lock_profiler_exit(tb_handle_t profiler);

/*! dump lock profiler
 *
 * @param profiler      the lock profiler handle
 */
tb_void_t               tb_lock_profiler_dump(tb_handle_t profiler);

/*! register the lock to the lock profiler
 *
 * @param profiler      the lock profiler handle
 * @param lock          the lock address
 * @param name          the lock name
 */
tb_void_t               tb_lock_profiler_register(tb_handle_t profiler, tb_pointer_t lock, tb_char_t const* name);

/*! the lock be occupied 
 *
 * @param profiler      the lock profiler handle
 * @param lock          the lock address
 */
tb_void_t               tb_lock_profiler_occupied(tb_handle_t profiler, tb_pointer_t lock);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

