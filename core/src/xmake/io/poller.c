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
 * @file        poller.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "poller"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "poller.h"
#include "../engine.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_poller_ref_t xm_io_poller(lua_State *lua) {
    tb_poller_ref_t poller = tb_null;
    xm_engine_ref_t engine = xm_engine_get(lua);
    if (engine) {
        poller = xm_engine_poller(engine);
    }
    tb_assert(poller);
    return poller;
}
