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

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "lock"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "lock.h"
#include "semaphore.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_co_lock_ref_t tb_co_lock_init()
{
    // init lock
    return (tb_co_lock_ref_t)tb_co_semaphore_init(1);
}
tb_void_t tb_co_lock_exit(tb_co_lock_ref_t self)
{
    // exit lock
    tb_co_semaphore_exit((tb_co_semaphore_ref_t)self);
}
tb_void_t tb_co_lock_enter(tb_co_lock_ref_t self)
{
    // enter lock
    tb_co_semaphore_wait((tb_co_semaphore_ref_t)self, -1);
}
tb_bool_t tb_co_lock_enter_try(tb_co_lock_ref_t self)
{
    // try to enter lock
    return tb_co_semaphore_wait((tb_co_semaphore_ref_t)self, 0) > 0;
}
tb_void_t tb_co_lock_leave(tb_co_lock_ref_t self)
{
    // leave lock
    tb_co_semaphore_post((tb_co_semaphore_ref_t)self, 1);
}
