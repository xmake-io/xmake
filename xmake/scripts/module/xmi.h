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
 * macros
 */
#define xmi_lua_createtable(lua, narr, nrec)    lua->_lua_createtable(lua->_lua, narr, nrec)
#define xmi_lua_newtable(lua)		            xmi_lua_createtable(lua, 0, 0)

#ifndef LUA_VERSION
#   define lua_createtable          xmi_lua_createtable
#   define lua_newtable             xmi_lua_newtable

#   define luaL_Reg                 xmi_luaL_Reg
#   define lua_State                struct xmi_lua_State_
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

struct xmi_lua_State_;
typedef struct xmi_luaL_Reg_ {
    char const* name;
    int (*func)(struct xmi_lua_State_* lua);
}xmi_luaL_Reg;

typedef struct xmi_lua_State_ {
    void* _lua;
    void  (*_lua_createtable)(lua_State* lua, int narr, int nrec);
}xmi_lua_State;


#endif


