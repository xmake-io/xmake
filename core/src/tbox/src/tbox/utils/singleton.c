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
 * @file        singleton.c
 * @ingroup     utils
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "singleton"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "singleton.h"
#include "../libc/libc.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the singleton type
typedef struct __tb_singleton_t
{
    // the exit func
    tb_singleton_exit_func_t        exit;

    // the kill func
    tb_singleton_kill_func_t        kill;

    // the priv data
    tb_cpointer_t                   priv;

    // the instance
    tb_atomic_t                     instance;

}tb_singleton_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the singletons
static tb_singleton_t g_singletons[TB_SINGLETON_TYPE_MAXN] = {{0}};

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_singleton_init()
{
    /* init it
     *
     * @note
     * this is thread safe, because tb_singleton_init() only will be called in/before the tb_init()
     */
    static tb_bool_t binited = tb_false;
    if (!binited)
    {
        // init it
        tb_memset(&g_singletons, 0, sizeof(g_singletons));

        // ok
        binited = tb_true;
    }

    // ok
    return tb_true;
}
tb_void_t tb_singleton_kill()
{
    tb_size_t i = TB_SINGLETON_TYPE_MAXN;
    while (i--)
    {
        if (g_singletons[i].kill) 
        {
            // the instance
            tb_handle_t instance = (tb_handle_t)tb_atomic_get(&g_singletons[i].instance);
            if (instance && instance != (tb_handle_t)1) 
            {   
                // trace
                tb_trace_d("instance: kill: %lu: ..", i);

                // kill it
                g_singletons[i].kill(instance, g_singletons[i].priv);
            }
        }
    }
}
tb_void_t tb_singleton_exit()
{
    // done
    tb_size_t i = TB_SINGLETON_TYPE_MAXN;
    while (i--)
    {
        if (g_singletons[i].exit) 
        {
            // the instance
            tb_handle_t instance = (tb_handle_t)tb_atomic_fetch_and_set0(&g_singletons[i].instance);
            if (instance && instance != (tb_handle_t)1) 
            {
                // trace
                tb_trace_d("instance: exit: %lu: ..", i);

                // exit it
                g_singletons[i].exit(instance, g_singletons[i].priv);
            }
        }
    }
 
    // clear it
    tb_memset(&g_singletons, 0, sizeof(g_singletons));
}
tb_handle_t tb_singleton_instance(tb_size_t type, tb_singleton_init_func_t init, tb_singleton_exit_func_t exit, tb_singleton_kill_func_t kill, tb_cpointer_t priv)
{
    // check, @note cannot use trace, assert and memory
    tb_check_return_val(type < TB_SINGLETON_TYPE_MAXN, tb_null);
    
    // the instance
    tb_handle_t instance = (tb_handle_t)tb_atomic_fetch_and_pset(&g_singletons[type].instance, 0, 1);

    // ok?
    if (instance && instance != (tb_handle_t)1) return instance;
    // null? init it
    else if (!instance)
    {
        // check
        tb_check_return_val(init && exit, tb_null);

        // init priv
        g_singletons[type].priv = priv;

        // init it
        instance = init(&g_singletons[type].priv);
        tb_check_return_val(instance, tb_null);

        // init func
        g_singletons[type].exit = exit;
        g_singletons[type].kill = kill;

        // register instance 
        tb_atomic_set(&g_singletons[type].instance, (tb_long_t)instance);
    }
    // initing? wait it
    else
    {
        // try getting it
        tb_size_t tryn = 50;
        while ((instance = (tb_handle_t)tb_atomic_get(&g_singletons[type].instance)) && (instance == (tb_handle_t)1) && tryn--)
        {
            // wait some time
            tb_msleep(100);
        }

        // failed?
        if (instance == (tb_handle_t)1 || !instance)
            return tb_null;
    }

    // ok?
    return instance;
}
tb_bool_t tb_singleton_static_init(tb_atomic_t* binited, tb_handle_t instance, tb_singleton_static_init_func_t init, tb_cpointer_t priv)
{
    // check
    tb_check_return_val(binited && instance, tb_false);

    // inited?
    tb_atomic_t inited = tb_atomic_fetch_and_pset(binited, 0, 1);

    // ok?
    if (inited && inited != 1) return tb_true;
    // null? init it
    else if (!inited)
    {
        // check
        tb_check_return_val(init, tb_false);

        // init it
        if (!init(instance, priv)) return tb_false;

        // init ok
        tb_atomic_set(binited, 2);
    }
    // initing? wait it
    else
    {
        // try getting it
        tb_size_t tryn = 50;
        while ((1 == tb_atomic_get(binited)) && tryn--)
        {
            // wait some time
            tb_msleep(100);
        }

        // failed?
        if (tb_atomic_get(binited) == 1 || !instance)
            return tb_false;
    }

    // ok?
    return tb_true;
}

