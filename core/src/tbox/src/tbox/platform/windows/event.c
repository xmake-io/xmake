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
 * @file        event.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../event.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_event_ref_t tb_event_init()
{
    // create event
    HANDLE event = CreateEventA(tb_null, FALSE, FALSE, tb_null);

    // ok?
    return ((event != INVALID_HANDLE_VALUE)? (tb_event_ref_t)event : tb_null);
}
tb_void_t tb_event_exit(tb_event_ref_t event)
{
    if (event) CloseHandle((HANDLE)event);
}
tb_bool_t tb_event_post(tb_event_ref_t event)
{
    // check
    tb_assert_and_check_return_val(event, tb_false);
    
    // post
    return SetEvent((HANDLE)event)? tb_true : tb_false;
}
tb_long_t tb_event_wait(tb_event_ref_t event, tb_long_t timeout)
{
    // check
    tb_assert_and_check_return_val(event, -1);

    // wait
    tb_long_t r = WaitForSingleObject((HANDLE)event, (DWORD)(timeout >= 0? timeout : INFINITE));
    tb_assert_and_check_return_val(r != WAIT_FAILED, -1);

    // timeout?
    tb_check_return_val(r != WAIT_TIMEOUT, 0);

    // error?
    tb_check_return_val(r >= WAIT_OBJECT_0, -1);

    // ok
    return 1;
}


