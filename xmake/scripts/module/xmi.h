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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        xmi.h
 *
 */
#ifndef XMI_H
#define XMI_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include <stdlib.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

struct lua_State_;
typedef struct luaL_Reg_ {
    char const* name;
    int (*func)(struct lua_State_* lua);
}luaL_Reg;

typedef struct lua_State_ {
    void* ctx;
}lua_State;

#endif


