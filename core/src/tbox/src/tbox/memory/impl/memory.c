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
 * @ingroup     memory
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "memory"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "memory.h"
#include "../memory.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the allocator 
__tb_extern_c__ extern tb_allocator_ref_t   g_allocator;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_memory_init_env(tb_allocator_ref_t allocator)
{
    // done
    tb_bool_t ok = tb_false;
    do
    {   
        // init page
        if (!tb_page_init()) break;

        // init the native memory
        if (!tb_native_memory_init()) break;

        // init the allocator
#if defined(TB_CONFIG_MICRO_ENABLE) || \
        (defined(__tb_small__) && !defined(__tb_debug__))
        g_allocator = allocator? allocator : tb_native_allocator();
#else
        g_allocator = allocator? allocator : tb_default_allocator(tb_null, 0);
#endif
        tb_assert_and_check_break(g_allocator);

        // ok
        ok = tb_true;

    } while (0);

    // failed? exit it
    if (!ok) tb_memory_exit_env();
    
    // ok?
    return ok;
}
tb_void_t tb_memory_exit_env()
{
    // exit the native memory
    tb_native_memory_exit();

    // exit page
    tb_page_exit();
}
