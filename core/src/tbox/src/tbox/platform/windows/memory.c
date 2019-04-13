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
 * @file        memory.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../sched.h"
#include "../memory.h"
#include "../atomic.h"
#include "../spinlock.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the heap
static tb_handle_t      g_heap = tb_null;

// the lock
static tb_spinlock_t    g_lock = TB_SPINLOCK_INIT; 

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_native_memory_init()
{   
    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // have been inited?
        tb_check_break_state(!g_heap, ok, tb_true);

        // make heap
        g_heap = (tb_handle_t)HeapCreate(0, 0, 0);
        tb_check_break(g_heap);

        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return ok;
}
tb_void_t tb_native_memory_exit()
{   
    // enter 
    tb_spinlock_enter_without_profiler(&g_lock);

    // exit heap
    if (g_heap) HeapDestroy(g_heap);
    g_heap = tb_null;

    // leave
    tb_spinlock_leave(&g_lock);

    // exit lock
    tb_spinlock_exit(&g_lock);
}
tb_pointer_t tb_native_memory_malloc(tb_size_t size)
{
    // check
    tb_check_return_val(size, tb_null);

    // init data
    tb_pointer_t data = tb_null;

    // enter 
    tb_spinlock_enter_without_profiler(&g_lock);

    // alloc data
    if (g_heap) data = HeapAlloc((HANDLE)g_heap, 0, (SIZE_T)size);

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return data;
}
tb_pointer_t tb_native_memory_malloc0(tb_size_t size)
{
    // check
    tb_check_return_val(size, tb_null);

    // init data
    tb_pointer_t data = tb_null;

    // enter 
    tb_spinlock_enter_without_profiler(&g_lock);

    // alloc data
    if (g_heap) data = HeapAlloc((HANDLE)g_heap, HEAP_ZERO_MEMORY, (SIZE_T)size);

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return data;
}
tb_pointer_t tb_native_memory_nalloc(tb_size_t item, tb_size_t size)
{
    // check
    tb_check_return_val(item && size, tb_null); 

    // nalloc
    return tb_native_memory_malloc(item * size);
}
tb_pointer_t tb_native_memory_nalloc0(tb_size_t item, tb_size_t size)
{
    // check
    tb_check_return_val(item && size, tb_null);     

    // nalloc0
    return tb_native_memory_malloc0(item * size);
}
tb_pointer_t tb_native_memory_ralloc(tb_pointer_t data, tb_size_t size)
{
    // no size? free it
    if (!size) 
    {
        tb_native_memory_free(data);
        return tb_null;
    }
    // no data? malloc it
    else if (!data) return tb_native_memory_malloc(size);
    // realloc it
    else 
    {
        // enter 
        tb_spinlock_enter_without_profiler(&g_lock);

        // realloc
        if (g_heap) data = (tb_pointer_t)HeapReAlloc((HANDLE)g_heap, 0, data, (SIZE_T)size);

        // leave
        tb_spinlock_leave(&g_lock);

        // ok?
        return data;
    }
}
tb_bool_t tb_native_memory_free(tb_pointer_t data)
{
    // check
    tb_check_return_val(data, tb_true);

    // enter 
    tb_spinlock_enter_without_profiler(&g_lock);

    // free data
    tb_bool_t ok = tb_false;
    if (g_heap) ok = HeapFree((HANDLE)g_heap, 0, data)? tb_true : tb_false;

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return ok;
}

