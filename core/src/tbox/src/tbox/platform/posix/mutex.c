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
#include "prefix.h"
#include "../mutex.h"
#include "../../utils/utils.h"
#include <pthread.h>
#include <stdlib.h>
#include <errno.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_mutex_ref_t tb_mutex_init()
{
    // make mutex
    pthread_mutex_t* pmutex = tb_malloc0(sizeof(pthread_mutex_t));
    tb_assert_and_check_return_val(pmutex, tb_null);

    // init mutex
    if (pthread_mutex_init(pmutex, tb_null)) return tb_null;
    
    // ok
    return ((tb_mutex_ref_t)pmutex);
}
tb_void_t tb_mutex_exit(tb_mutex_ref_t mutex)
{
    // check
    tb_assert_and_check_return(mutex);

    // exit it
    pthread_mutex_t* pmutex = (pthread_mutex_t*)mutex;
    if (pmutex)
    {
        pthread_mutex_destroy(pmutex);
        tb_free((tb_pointer_t)pmutex);
    }
}
tb_bool_t tb_mutex_enter(tb_mutex_ref_t mutex)
{
    // check
    tb_assert_and_check_return_val(mutex, tb_false);

    // try to enter for profiler
#ifdef TB_LOCK_PROFILER_ENABLE
    if (tb_mutex_enter_try(mutex)) return tb_true;
#endif

    // enter
    if (pthread_mutex_lock((pthread_mutex_t*)mutex)) return tb_false;
    // ok
    else return tb_true;
}
tb_bool_t tb_mutex_enter_try(tb_mutex_ref_t mutex)
{
    // check
    tb_assert_and_check_return_val(mutex, tb_false);

    // try to enter
    if (pthread_mutex_trylock((pthread_mutex_t*)mutex))
    {
        // occupied
#ifdef TB_LOCK_PROFILER_ENABLE
        tb_lock_profiler_occupied(tb_lock_profiler(), (tb_handle_t)mutex);
#endif

        // failed
        return tb_false;
    }
    // ok
    else return tb_true;
}
tb_bool_t tb_mutex_leave(tb_mutex_ref_t mutex)
{
    // check
    tb_assert_and_check_return_val(mutex, tb_false);

    // leave
    if (pthread_mutex_unlock((pthread_mutex_t*)mutex)) return tb_false;
    else return tb_true;
}
