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
 * @file        lock_profiler.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_LOCK_PROFILER_H
#define TB_UTILS_LOCK_PROFILER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// enable lock profiler
#undef TB_LOCK_PROFILER_ENABLE
#if defined(__tb_debug__) && !defined(TB_CONFIG_MICRO_ENABLE)
#   define TB_LOCK_PROFILER_ENABLE
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the lock profiler instance
 *
 * @return              the lock profiler handle
 */
tb_handle_t             tb_lock_profiler(tb_noarg_t);

/*! init lock profiler
 *
 * @note be used for the debug mode generally 
 *
 * @return              the lock profiler handle
 */
tb_handle_t             tb_lock_profiler_init(tb_noarg_t);

/*! exit lock profiler
 *
 * @param profiler      the lock profiler handle
 */
tb_void_t               tb_lock_profiler_exit(tb_handle_t profiler);

/*! dump lock profiler
 *
 * @param profiler      the lock profiler handle
 */
tb_void_t               tb_lock_profiler_dump(tb_handle_t profiler);

/*! register the lock to the lock profiler
 *
 * @param profiler      the lock profiler handle
 * @param lock          the lock address
 * @param name          the lock name
 */
tb_void_t               tb_lock_profiler_register(tb_handle_t profiler, tb_pointer_t lock, tb_char_t const* name);

/*! the lock be occupied 
 *
 * @param profiler      the lock profiler handle
 * @param lock          the lock address
 */
tb_void_t               tb_lock_profiler_occupied(tb_handle_t profiler, tb_pointer_t lock);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

