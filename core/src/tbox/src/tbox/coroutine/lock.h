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
