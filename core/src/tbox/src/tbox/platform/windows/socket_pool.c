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
 * @file        socket_pool.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "socket_pool"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "socket_pool.h"
#include "../spinlock.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef __tb_small__
#   define TB_SOCKET_POOL_GROW              (128)
#   define TB_SOCKET_POOL_MAXN              (1 << 12)
#else
#   define TB_SOCKET_POOL_GROW              (256)
#   define TB_SOCKET_POOL_MAXN              (1 << 16)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the pool
static tb_socket_ref_t*     g_pool = tb_null;

// the size
static tb_size_t            g_size = 0;

// the maxn
static tb_size_t            g_maxn = 0;

// the lock
static tb_spinlock_t        g_lock = TB_SPINLOCK_INIT;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_socket_pool_init()
{
    // register lock profiler
#ifdef TB_LOCK_PROFILER_ENABLE
    tb_lock_profiler_register(tb_lock_profiler(), (tb_pointer_t)&g_lock, TB_TRACE_MODULE_NAME);
#endif

    // ok
    return tb_true;
}
tb_void_t tb_socket_pool_exit()
{
    // enter
    tb_spinlock_enter(&g_lock);

    // exit pool
    if (g_pool)
    {
        tb_size_t i = 0;
        tb_size_t n = g_size;
        for (i = 0; i < n; i++)
        {
            // exit it
            if (g_pool[i]) tb_socket_exit(g_pool[i]);
            g_pool[i] = tb_null;
        }

        // exit it
        tb_free(g_pool);
        g_pool = tb_null;
    }

    // clear pool
    g_size = 0;
    g_maxn = 0;

    // leave
    tb_spinlock_leave(&g_lock);

    // exit lock
    tb_spinlock_exit(&g_lock);
}
tb_bool_t tb_socket_pool_put(tb_socket_ref_t sock)
{
    // check
    tb_assert_and_check_return_val(sock, tb_false);

    // enter
    tb_spinlock_enter(&g_lock);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // init?
        if (!g_pool)
        {
            // init maxn
            g_maxn = TB_SOCKET_POOL_GROW;

            // make pool
            g_pool = tb_nalloc_type(g_maxn, tb_socket_ref_t);
            tb_assert_and_check_break(g_pool);
        }
        // grow?
        else if (g_size >= g_maxn && g_maxn < TB_SOCKET_POOL_MAXN)
        {
            // grow maxn
            g_maxn += TB_SOCKET_POOL_GROW;

            // limit it
            if (g_maxn > TB_SOCKET_POOL_MAXN) g_maxn = TB_SOCKET_POOL_MAXN;

            // grow pool
            g_pool = tb_ralloc_type(g_pool, g_maxn, tb_socket_ref_t);
            tb_assert_and_check_break(g_pool);
        }

        // full?
        tb_assert_and_check_break(g_size < g_maxn);

        // save it
        g_pool[g_size++] = sock;

        // trace
        tb_trace_d("put: %p, size: %lu", sock, g_size);

        // ok
        ok = tb_true;

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return ok;
}
tb_socket_ref_t tb_socket_pool_get()
{
    // enter
    tb_spinlock_enter(&g_lock);

    // get it
    tb_socket_ref_t sock = (g_pool && g_size && g_size <= g_maxn)? g_pool[--g_size] : tb_null;

    // trace
    tb_trace_d("get: %p, size: %lu", sock, g_size);

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return sock;
}
