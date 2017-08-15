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
 * @file        semaphore.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_SEMAPHORE_H
#define TB_PLATFORM_SEMAPHORE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init semaphore
 *
 * @param value     the initial semaphore value
 * 
 * @return          the semaphore 
 */
tb_semaphore_ref_t  tb_semaphore_init(tb_size_t value);

/*! exit semaphore
 * 
 * @return          the semaphore 
 */
tb_void_t           tb_semaphore_exit(tb_semaphore_ref_t semaphore);

/*! post semaphore
 * 
 * @param semaphore the semaphore 
 * @param post      the post semaphore value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_semaphore_post(tb_semaphore_ref_t semaphore, tb_size_t post);

/*! the semaphore value
 * 
 * @param semaphore the semaphore 
 *
 * @return          >= 0: the semaphore value, -1: failed
 */
tb_long_t           tb_semaphore_value(tb_semaphore_ref_t semaphore);

/*! wait semaphore
 * 
 * @param semaphore the semaphore 
 * @param timeout   the timeout
 *
 * @return          ok: 1, timeout: 0, fail: -1
 */
tb_long_t           tb_semaphore_wait(tb_semaphore_ref_t semaphore, tb_long_t timeout);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

    
#endif
