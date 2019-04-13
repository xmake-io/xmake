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
 * @file        thread_local.h
 *
 */
#ifndef TB_PLATFORM_IMPL_THREAD_LOCAL_H
#define TB_PLATFORM_IMPL_THREAD_LOCAL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* init the thread local envirnoment
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_thread_local_init_env(tb_noarg_t);

// exit the thread local envirnoment
tb_void_t           tb_thread_local_exit_env(tb_noarg_t);

/* walk all thread locals
 *
 * @param func      the walk function
 * @param priv      the user private data
 */
tb_void_t           tb_thread_local_walk(tb_walk_func_t func, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
