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
 * @tlocal      thread_local.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include <windows.h>
#include "../thread.h"
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

// the once function
static tb_bool_t tb_thread_local_once(tb_cpointer_t priv)
{
    // check
    tb_value_ref_t tuple = (tb_value_ref_t)priv;
    tb_check_return_val(tuple, tb_false);

    // the thread local
    tb_thread_local_ref_t local = (tb_thread_local_ref_t)tuple[0].ptr;
    tb_check_return_val(local, tb_false);

    // save the free function
    local->free = (tb_thread_local_free_t)tuple[1].ptr;

    // check the pthread key space size
    tb_assert_static(sizeof(DWORD) * 2 <= sizeof(local->priv));

    // init data key
    DWORD key_data = TlsAlloc();
    tb_check_return_val(key_data != TLS_OUT_OF_INDEXES, tb_false);

    // init mark key
    DWORD key_mark = TlsAlloc();
    if (key_mark == TLS_OUT_OF_INDEXES)
    {
        // free the data key
        TlsFree(key_data);
        return tb_false;
    }

    // save keys
    ((DWORD*)local->priv)[0] = key_data;
    ((DWORD*)local->priv)[1] = key_mark;

    // save this thread local to list
    tb_spinlock_enter(&g_thread_local_lock);
    tb_single_list_entry_insert_tail(&g_thread_local_list, &local->entry);
    tb_spinlock_leave(&g_thread_local_lock);

    // init ok
    local->inited = tb_true;

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_thread_local_init(tb_thread_local_ref_t local, tb_thread_local_free_t func)
{
    // check
    tb_assert_and_check_return_val(local, tb_false);

    // run the once function
    tb_value_t tuple[2];
    tuple[0].ptr = (tb_pointer_t)local;
    tuple[1].ptr = (tb_pointer_t)func;
    return tb_thread_once(&local->once, tb_thread_local_once, tuple);
}
tb_void_t tb_thread_local_exit(tb_thread_local_ref_t local)
{
    // check
    tb_assert(local);

    // exit it
    TlsFree(*((DWORD*)local->priv));
}
tb_bool_t tb_thread_local_has(tb_thread_local_ref_t local)
{
    // check
    tb_assert(local);

    // have been not initialized?
    tb_check_return_val(local->inited, tb_false);

    // get it
    return TlsGetValue(((DWORD*)local->priv)[1]) != tb_null;
}
tb_pointer_t tb_thread_local_get(tb_thread_local_ref_t local)
{
    // check
    tb_assert(local);

    // have been not initialized?
    tb_check_return_val(local->inited, tb_null);

    // get it
    return TlsGetValue(((DWORD*)local->priv)[0]);
}
tb_bool_t tb_thread_local_set(tb_thread_local_ref_t local, tb_cpointer_t priv)
{
    // check
    tb_assert(local);

    // have been not initialized?
    tb_assert_and_check_return_val(local->inited, tb_false);

    // free the previous data first
    if (local->free && tb_thread_local_has(local))
        local->free(tb_thread_local_get(local));

    // set it
    tb_bool_t ok = TlsSetValue(((DWORD*)local->priv)[0], (LPVOID)priv);
    if (ok)
    {
        // mark exists
        ok = TlsSetValue(((DWORD*)local->priv)[1], (LPVOID)tb_true);
    }

    // ok?
    return ok;
}

