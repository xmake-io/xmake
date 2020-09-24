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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      uael
 * @file        prefix.h
 *
 */
#ifndef XM_SEMVER_PREFIX_H
#define XM_SEMVER_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "semver.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* push struct semver
 *
 * @param lua       the lua context
 * @param semver    the semver struct
 *
 */
tb_void_t lua_pushsemver(lua_State *lua, semver_t const* semver);

/* //////////////////////////////////////////////////////////////////////////////////////
 * leave
 */
__tb_extern_c_leave__

#endif
