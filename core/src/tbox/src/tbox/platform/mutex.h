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
 * @file        mutex.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_MUTEX_H
#define TB_PLATFORM_MUTEX_H

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

/*! init mutex
 *
 * @return          the mutex 
 */
tb_mutex_ref_t      tb_mutex_init(tb_noarg_t);

/* exit mutex
 *
 * @param mutex     the mutex 
 */
tb_void_t           tb_mutex_exit(tb_mutex_ref_t mutex);

/* enter mutex
 *
 * @param mutex     the mutex 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_mutex_enter(tb_mutex_ref_t mutex);

/* try to enter mutex
 *
 * @param mutex     the mutex 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_mutex_enter_try(tb_mutex_ref_t mutex);

/* leave mutex
 *
 * @param mutex     the mutex 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_mutex_leave(tb_mutex_ref_t mutex);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
