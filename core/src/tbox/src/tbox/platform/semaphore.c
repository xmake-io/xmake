/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        semaphore.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "semaphore.h"
#include "time.h"
#include "cache_time.h"
#include "atomic.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if defined(TB_CONFIG_OS_WINDOWS)
#   include "windows/semaphore.c"
#elif defined(TB_CONFIG_OS_MACOSX) || defined(TB_CONFIG_OS_IOS)
#   include "mach/semaphore.c"
#elif defined(TB_CONFIG_POSIX_HAVE_SEM_INIT)
#   include "posix/semaphore.c"
#elif defined(TB_CONFIG_SYSTEMV_HAVE_SEMGET) \
    && defined(TB_CONFIG_SYSTEMV_HAVE_SEMTIMEDOP)
#   include "systemv/semaphore.c"
#else 
tb_semaphore_ref_t tb_semaphore_init(tb_size_t value)
{
    // make
    tb_atomic_t* semaphore = tb_malloc0_type(tb_atomic_t);
    tb_assert_and_check_return_val(semaphore, tb_null);

    // init
    *semaphore = value;

    // ok
    return (tb_semaphore_ref_t)semaphore;
}
tb_void_t tb_semaphore_exit(tb_semaphore_ref_t self)
{
    // check
    tb_atomic_t* semaphore = (tb_atomic_t*)self;
    tb_assert_and_check_return(semaphore);

    // free it
    tb_free(semaphore);
}
tb_bool_t tb_semaphore_post(tb_semaphore_ref_t self, tb_size_t post)
{
    // check
    tb_atomic_t* semaphore = (tb_atomic_t*)self;
    tb_assert_and_check_return_val(semaphore && post, tb_false);

    // post it
    tb_long_t value = tb_atomic_fetch_and_add(semaphore, post);

    // ok
    return value >= 0? tb_true : tb_false;
}
tb_long_t tb_semaphore_value(tb_semaphore_ref_t self)
{
    // check
    tb_atomic_t* semaphore = (tb_atomic_t*)self;
    tb_assert_and_check_return_val(semaphore, tb_false);

    // get value
    return (tb_long_t)tb_atomic_get(semaphore);
}
tb_long_t tb_semaphore_wait(tb_semaphore_ref_t self, tb_long_t timeout)
{
    // check
    tb_atomic_t* semaphore = (tb_atomic_t*)self;
    tb_assert_and_check_return_val(semaphore, -1);

    // init
    tb_long_t   r = 0;
    tb_hong_t   base = tb_cache_time_spak();

    // wait 
    while (1)
    {
        // get post
        tb_long_t post = (tb_long_t)tb_atomic_get(semaphore);

        // has signal?
        if (post > 0) 
        {
            // semaphore--
            tb_atomic_fetch_and_dec(semaphore);

            // ok
            r = post;
            break;
        }
        // no signal?
        else if (!post)
        {
            // timeout?
            if (timeout >= 0 && tb_cache_time_spak() - base >= timeout) break;
            else tb_msleep(200);
        }
        // error
        else
        {
            r = -1;
            break;
        }
    }

    return r;
}
#endif

