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
 * @file        linear.c
 * @ingroup     math
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "random_linear"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "linear.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the value
static tb_size_t        g_value = 2166136261ul;

// the lock
static tb_spinlock_t    g_lock = TB_SPINLOCK_INIT;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_random_linear_seed(tb_size_t seed)
{
    // enter 
    tb_spinlock_enter(&g_lock);

    // update value
    g_value = seed;

    // leave
    tb_spinlock_leave(&g_lock);
}
tb_long_t tb_random_linear_value()
{
    // enter 
    tb_spinlock_enter(&g_lock);

    // generate the next value
    g_value = (g_value * 10807 + 1) & 0xffffffff;

    // leave 
    tb_spinlock_leave(&g_lock);

    // ok
    return (tb_long_t)g_value;
}
