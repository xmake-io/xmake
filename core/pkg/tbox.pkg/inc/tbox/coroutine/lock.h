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
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        lock.h
 * @ingroup     coroutine
 *
 */
#ifndef TB_COROUTINE_LOCK_H
#define TB_COROUTINE_LOCK_H

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

/// the coroutine lock ref type
typedef __tb_typeref__(co_lock);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init lock 
 *
 * @return              the lock 
 */
tb_co_lock_ref_t        tb_co_lock_init(tb_noarg_t);

/*! exit lock
 *
 * @param lock          the lock
 */
tb_void_t               tb_co_lock_exit(tb_co_lock_ref_t lock);

/*! enter lock
 *
 * @param lock          the lock
 */
tb_void_t               tb_co_lock_enter(tb_co_lock_ref_t lock);

/*! try to enter lock
 *
 * @param lock          the lock
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_co_lock_enter_try(tb_co_lock_ref_t lock);

/*! leave lock
 *
 * @param lock          the lock
 */
tb_void_t               tb_co_lock_leave(tb_co_lock_ref_t lock);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
