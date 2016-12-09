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
#ifndef TB_COROUTINE_STACKLESS_LOCK_H
#define TB_COROUTINE_STACKLESS_LOCK_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "semaphore.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/*! init lock
 *
 * @param lock          the lock pointer
 */
#define tb_lo_lock_init(lock)           tb_lo_semaphore_init(lock, 1)

/*! exit lock
 * 
 * @param lock          the lock pointer
 */
#define tb_lo_lock_exit(lock)           tb_lo_semaphore_exit(lock)

/*! enter lock
 * 
 * @param lock          the lock pointer
 */
#define tb_lo_lock_enter(lock)          tb_lo_semaphore_wait(lock)

/*! try to enter lock
 * 
 * @param lock          the lock pointer
 *
 * @return              tb_true or tb_false
 */
#define tb_lo_lock_enter_try(lock)      tb_lo_semaphore_wait_try(lock)

/*! leave lock
 * 
 * @param lock          the lock pointer
 */
#define tb_lo_lock_leave(lock)          tb_lo_semaphore_post(lock, 1)


/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the stackless lock type
typedef tb_lo_semaphore_t       tb_lo_lock_t;

/// the stackless lock ref type
typedef tb_lo_semaphore_ref_t   tb_lo_lock_ref_t;

#endif
