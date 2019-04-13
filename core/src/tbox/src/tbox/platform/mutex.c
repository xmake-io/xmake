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
 * @file        mutex.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "mutex.h"
#include "spinlock.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_OS_WINDOWS
#   include "windows/mutex.c"
#elif defined(TB_CONFIG_POSIX_HAVE_PTHREAD_MUTEX_INIT)
#   include "posix/mutex.c"
#else
tb_mutex_ref_t tb_mutex_init()
{
    // done
    tb_bool_t           ok = tb_false;
    tb_spinlock_ref_t   lock = tb_null;
    do
    {
        // make lock
        lock = tb_malloc0_type(tb_spinlock_t);
        tb_assert_and_check_break(lock);

        // init lock
        if (!tb_spinlock_init(lock)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        tb_free(lock);
        lock = tb_null;
    }

    // ok?
    return (tb_mutex_ref_t)lock;
}
tb_void_t tb_mutex_exit(tb_mutex_ref_t mutex)
{
    // check
    tb_assert_and_check_return(mutex);

    // exit it
    tb_spinlock_ref_t lock = (tb_spinlock_ref_t)mutex;
    if (lock)
    {
        // exit lock
        tb_spinlock_exit(lock);

        // free it
        tb_free(lock);
    }
}
tb_bool_t tb_mutex_enter(tb_mutex_ref_t mutex)
{
    // check
    tb_assert_and_check_return_val(mutex, tb_false);

    // enter
    tb_spinlock_enter((tb_spinlock_ref_t)mutex);

    // ok
    return tb_true;
}
tb_bool_t tb_mutex_enter_try(tb_mutex_ref_t mutex)
{
    // check
    tb_assert_and_check_return_val(mutex, tb_false);

    // try to enter
    return tb_spinlock_enter_try((tb_spinlock_ref_t)mutex);
}
tb_bool_t tb_mutex_leave(tb_mutex_ref_t mutex)
{
    // check
    tb_assert_and_check_return_val(mutex, tb_false);

    // leave
    tb_spinlock_leave((tb_spinlock_ref_t)mutex);

    // ok
    return tb_true;
}
#endif
