/*!A cross-platform build utility based on Lua
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
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        poller.h
 *
 */
#ifndef XM_IO_POLLER_H
#define XM_IO_POLLER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the poller state in wait events
typedef struct __xm_poller_state_t
{
    lua_State*      lua;
    tb_int_t        events_count;

}xm_poller_state_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* get io poller
 *
 * @return          the io poller
 */
tb_poller_ref_t     xm_io_poller(lua_State* lua);

#endif


