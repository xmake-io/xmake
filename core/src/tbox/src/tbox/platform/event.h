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
 * @file        event.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_EVENT_H
#define TB_PLATFORM_EVENT_H

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

/*! init event
 * 
 * @return          the event 
 */
tb_event_ref_t      tb_event_init(tb_noarg_t);

/*! exit event
 * 
 * @param event     the event 
 */
tb_void_t           tb_event_exit(tb_event_ref_t event);

/*! post event
 * 
 * @param event     the event 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_event_post(tb_event_ref_t event);

/*! wait event
 * 
 * @param event     the event 
 * @param timeout   the timeout
 *
 * @return          ok: 1, timeout: 0, fail: -1
 */
tb_long_t           tb_event_wait(tb_event_ref_t event, tb_long_t timeout);

 
/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__
   
#endif
