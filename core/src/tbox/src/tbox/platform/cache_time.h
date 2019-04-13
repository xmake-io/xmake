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
 * @file        cache_time.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_CACHE_TIME_H
#define TB_PLATFORM_CACHE_TIME_H

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

/*! the cached time, like tb_time
 *
 * lower accuracy and faster
 *
 * @return          the now time, s
 */
tb_time_t           tb_cache_time(tb_noarg_t);

/*! spak cached time 
 *
 * update the cached time for the external loop thread
 *
 * @return          the now ms-clock
 */
tb_hong_t           tb_cache_time_spak(tb_noarg_t);

/*! the cached ms-clock
 *
 * lower accuracy and faster
 *
 * @return          the now ms-clock
 */
tb_hong_t           tb_cache_time_mclock(tb_noarg_t);

/*! the cached s-clock
 *
 * lower accuracy and faster
 *
 * @return          the now s-clock
 */
tb_hong_t           tb_cache_time_clock(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
