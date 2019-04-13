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
 * @file        android.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "android.h"
#include "../atomic.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
static tb_atomic_t g_jvm = 0;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_android_init_env(JavaVM* jvm)
{
    // check
    if (!jvm)
    {
        // warning
        tb_trace_w("the java machine be not inited, please pass it to the tb_init function!");
    }

    // init it
    tb_atomic_set(&g_jvm, (tb_size_t)jvm);

    // ok
    return tb_true;
}
tb_void_t tb_android_exit_env()
{
    // clear it
    tb_atomic_set(&g_jvm, 0);
}
JavaVM* tb_android_jvm()
{
    // get it
    return (JavaVM*)tb_atomic_get(&g_jvm);
}

