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
 * @file        lock_profiler.c
 * @ingroup     utils
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "lock_profiler"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "lock_profiler.h"
#include "singleton.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the lock profiler maxn
#ifdef __tb_small__
#   define TB_LOCK_PROFILER_MAXN            (256)
#else
#   define TB_LOCK_PROFILER_MAXN            (512)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the lock profiler item type
typedef struct __tb_lock_profiler_item_t
{
    // the lock address
    tb_atomic_t                     lock;

    // the occupied count
    tb_atomic_t                     size;

    // the lock name
    tb_atomic_t                     name;

}tb_lock_profiler_item_t;

// the lock profiler type
typedef struct __tb_lock_profiler_t
{
    // the list
    tb_lock_profiler_item_t         list[TB_LOCK_PROFILER_MAXN];

}tb_lock_profiler_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * instance implementation
 */
static tb_handle_t tb_lock_profiler_instance_init(tb_cpointer_t* ppriv)
{
    return tb_lock_profiler_init();
}
static tb_void_t tb_lock_profiler_instance_exit(tb_handle_t handle, tb_cpointer_t priv)
{
    // dump it
    tb_lock_profiler_dump(handle);

    // exit it
    tb_lock_profiler_exit(handle);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_handle_t tb_lock_profiler()
{
    return tb_singleton_instance(TB_SINGLETON_TYPE_LOCK_PROFILER, tb_lock_profiler_instance_init, tb_lock_profiler_instance_exit, tb_null, tb_null);
}
tb_handle_t tb_lock_profiler_init()
{
    // init profiler
    return (tb_handle_t)tb_native_memory_malloc0(sizeof(tb_lock_profiler_t));
}
tb_void_t tb_lock_profiler_exit(tb_handle_t handle)
{
    // exit profiler
    if (handle) tb_native_memory_free(handle);
}
tb_void_t tb_lock_profiler_dump(tb_handle_t handle)
{
    // check
    tb_lock_profiler_t* profiler = (tb_lock_profiler_t*)handle;
    tb_assert_and_check_return(profiler);

    // trace
    tb_trace_i("");

    // walk
    tb_size_t i = 0;
    tb_size_t n = tb_arrayn(profiler->list);
    for (i = 0; i < n; i++)
    {
        // the item
        tb_lock_profiler_item_t* item = &profiler->list[i];

        // the lock
        tb_pointer_t lock = tb_null;
        if ((lock = (tb_pointer_t)tb_atomic_get(&item->lock)))
        {
            // dump lock
            tb_trace_i("lock: %p, name: %s, occupied: %ld", lock, (tb_char_t const*)tb_atomic_get(&item->name), tb_atomic_get(&item->size));
        }
    }
}
tb_void_t tb_lock_profiler_register(tb_handle_t handle, tb_pointer_t lock, tb_char_t const* name)
{
    // check
    tb_lock_profiler_t* profiler = (tb_lock_profiler_t*)handle;
    tb_assert_and_check_return(profiler && lock);

    // trace
    tb_trace_d("register: lock: %p, name: %s: ..", lock, name);

    // the lock address
    tb_size_t addr = (tb_size_t)lock;

    // compile the hash value
    addr ^= (addr >> 8) ^ (addr >> 16);

    // walk
    tb_size_t i = 0;
    for (i = 0; i < 16; i++, addr++)
    {
        // the item
        tb_lock_profiler_item_t* item = &profiler->list[addr & (TB_LOCK_PROFILER_MAXN - 1)];

        // try to register the lock
        if (!tb_atomic_fetch_and_pset(&item->lock, 0, (tb_long_t)lock))
        {
            // init name
            tb_atomic_set(&item->name, (tb_long_t)name);

            // trace
            tb_trace_d("register: lock: %p, name: %s, index: %lu: ok", lock, name, addr & (TB_LOCK_PROFILER_MAXN - 1));

            // ok
            break;
        }
    }

    // full?
    if (i == 16)
    {
        // trace
        tb_trace_w("register: lock: %p, name: %s: no", lock, name);
    }
}
tb_void_t tb_lock_profiler_occupied(tb_handle_t handle, tb_pointer_t lock)
{
    // check
    tb_lock_profiler_t* profiler = (tb_lock_profiler_t*)handle;
    tb_check_return(profiler && lock);

    // the lock address
    tb_size_t addr = (tb_size_t)lock;

    // compile the hash value
    addr ^= (addr >> 8) ^ (addr >> 16);

    // walk
    tb_size_t i = 0;
    for (i = 0; i < 16; i++, addr++)
    {
        // the item
        tb_lock_profiler_item_t* item = &profiler->list[addr & (TB_LOCK_PROFILER_MAXN - 1)];

        // is this lock?
        if (lock == (tb_pointer_t)tb_atomic_get(&item->lock))
        {
            // occupied++
            tb_atomic_fetch_and_inc(&item->size);

            // ok
            break;
        }
    }
}

