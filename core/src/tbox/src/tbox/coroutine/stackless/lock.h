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
