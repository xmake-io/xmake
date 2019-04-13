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
 * @file        semaphore.h
 * @ingroup     coroutine
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "semaphore"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "semaphore.h"
#include "coroutine.h"
#include "scheduler.h"
#include "impl/impl.h"
#include "../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the coroutine semaphore type
typedef struct __tb_co_semaphore_t
{
    // the semaphore value
    tb_size_t                       value;

    // the waiting coroutines
    tb_single_list_entry_head_t     waiting;

}tb_co_semaphore_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_co_semaphore_ref_t tb_co_semaphore_init(tb_size_t value)
{
    // done
    tb_bool_t           ok = tb_false;
    tb_co_semaphore_t*  semaphore = tb_null;
    do
    {
        // make semaphore
        semaphore = tb_malloc0_type(tb_co_semaphore_t);
        tb_assert_and_check_break(semaphore);

        // init value
        semaphore->value = value;

        // init waiting coroutines
        tb_single_list_entry_init(&semaphore->waiting, tb_coroutine_t, rs.single_entry, tb_null);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (semaphore) tb_co_semaphore_exit((tb_co_semaphore_ref_t)semaphore);
        semaphore = tb_null;
    }

    // ok?
    return (tb_co_semaphore_ref_t)semaphore;
}
tb_void_t tb_co_semaphore_exit(tb_co_semaphore_ref_t self)
{
    // check
    tb_co_semaphore_t* semaphore = (tb_co_semaphore_t*)self;
    tb_assert_and_check_return(semaphore);

    // check waiting coroutines
    tb_assert(!tb_single_list_entry_size(&semaphore->waiting));

    // exit waiting coroutines
    tb_single_list_entry_exit(&semaphore->waiting);

    // exit the semaphore
    tb_free(semaphore);
}
tb_void_t tb_co_semaphore_post(tb_co_semaphore_ref_t self, tb_size_t post)
{
    // check
    tb_co_semaphore_t* semaphore = (tb_co_semaphore_t*)self;
    tb_assert_and_check_return(semaphore);

    // add the semaphore value
    tb_size_t value = semaphore->value + post;

    // resume the waiting coroutines
    while (value && tb_single_list_entry_size(&semaphore->waiting))
    {
        // get the next entry from head
        tb_single_list_entry_ref_t entry = tb_single_list_entry_head(&semaphore->waiting);
        tb_assert_and_check_break(entry);

        // remove it from the waiting coroutines
        tb_single_list_entry_remove_head(&semaphore->waiting);

        // get the waiting coroutine
        tb_coroutine_ref_t coroutine = (tb_coroutine_ref_t)tb_single_list_entry(&semaphore->waiting, entry);

        // resume this coroutine
        tb_coroutine_resume(coroutine, (tb_cpointer_t)tb_true);

        // decrease the semaphore value
        value--;
    }

    // update the semaphore value
    semaphore->value = value;
}
tb_size_t tb_co_semaphore_value(tb_co_semaphore_ref_t self)
{
    // check
    tb_co_semaphore_t* semaphore = (tb_co_semaphore_t*)self;
    tb_assert_and_check_return_val(semaphore, 0);

    // get the semaphore value
    return semaphore->value;
}
tb_long_t tb_co_semaphore_wait(tb_co_semaphore_ref_t self, tb_long_t timeout)
{
    // check
    tb_co_semaphore_t* semaphore = (tb_co_semaphore_t*)self;
    tb_assert_and_check_return_val(semaphore, -1);

    // attempt to get the semaphore value
    tb_long_t ok = 1;
    if (semaphore->value) semaphore->value--;
    // no semaphore? 
    else if (timeout)
    {
        // get the running coroutine 
        tb_coroutine_t* running = (tb_coroutine_t*)tb_coroutine_self();
        tb_assert(running);

        // save this coroutine to the waiting coroutines
        tb_single_list_entry_insert_tail(&semaphore->waiting, &running->rs.single_entry);

        // wait semaphore 
        ok = (tb_long_t)tb_coroutine_sleep(timeout);
    }
    // timeout and no waiting
    else ok = 0;

    // ok?
    return ok;
}
