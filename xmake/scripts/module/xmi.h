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

// lua interfaces
#define xmi_lua_createtable(lua, narr, nrec)    (g_lua_ops)->_lua_createtable(lua, narr, nrec)
#define xmi_lua_newtable(lua)		            xmi_lua_createtable(lua, 0, 0)

// luaL interfaces
#define xmi_luaL_setfuncs(lua, narr, nrec)    (g_lua_ops)->_luaL_setfuncs(lua, narr, nrec)

/* we cannot redefine lua functions in loadxmi.c,
 * because original lua.h has been included
 */
#ifndef LUA_VERSION
#   define lua_createtable          xmi_lua_createtable
#   define lua_newtable             xmi_lua_newtable

#   define luaL_setfuncs            xmi_luaL_setfuncs

#   define luaL_Reg                 xmi_luaL_Reg
#   define lua_State                xmi_lua_State
#endif

// define lua module entry function
#define luaopen(name, lua) \
__dummy = 1; \
xmi_lua_ops_t* g_lua_ops; \
int xmisetup(xmi_lua_ops_t* ops) { \
    g_lua_ops = ops; \
    return __dummy; \
} \
int xmiopen_##name(lua)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

typedef struct xmi_lua_State_ {
    int dummy;
}xmi_lua_State;

typedef struct xmi_luaL_Reg_ {
    char const* name;
    int (*func)(struct xmi_lua_State_* lua);
}xmi_luaL_Reg;

typedef struct xmi_lua_ops_t_ {
    void (*_lua_createtable)(lua_State* lua, int narr, int nrec);
    void (*_luaL_setfuncs)(lua_State* lua, const luaL_Reg* l, int nup);
}xmi_lua_ops_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#ifdef __cplusplus
extern "C" {
#endif

// setup lua interfaces
int xmisetup(xmi_lua_ops_t* ops);

#ifdef __cplusplus
}
#endif

#endif


