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
#include <stdio.h>
#include <stdlib.h>
#ifndef LUA_VERSION
#   include "luawrap/luaconf.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#define XMI_LUA_MULTRET  (-1)

// basic types
#define XMI_LUA_TNONE		    (-1)

#define XMI_LUA_TNIL		    0
#define XMI_LUA_TBOOLEAN		1
#define XMI_LUA_TLIGHTUSERDATA	2
#define XMI_LUA_TNUMBER		    3
#define XMI_LUA_TSTRING		    4
#define XMI_LUA_TTABLE		    5
#define XMI_LUA_TFUNCTION		6
#define XMI_LUA_TUSERDATA		7
#define XMI_LUA_TTHREAD		    8

#define LUA_NUMTYPES		9

// pseudo-indices
#ifdef XMI_USE_LUAJIT
#   define XMI_LUA_REGISTRYINDEX	(-10000)
#   define XMI_LUA_ENVIRONINDEX	    (-10001)
#   define XMI_LUA_GLOBALSINDEX	    (-10002)
#   define xmi_lua_upvalueindex(i)	(XMI_LUA_GLOBALSINDEX - (i))
#else
#   define XMI_LUA_REGISTRYINDEX	(-LUAI_MAXSTACK - 1000)
#   define xmi_lua_upvalueindex(i)	(XMI_LUA_REGISTRYINDEX - (i))
#endif

// lua interfaces
#define xmi_lua_createtable(lua, narr, nrec)        (g_lua_ops)->_lua_createtable(lua, narr, nrec)
#define xmi_lua_tointegerx(lua, idx, isnum)         (g_lua_ops)->_lua_tointegerx(lua, idx, isnum)
#define xmi_lua_toboolean(lua, idx)                 (g_lua_ops)->_lua_toboolean(lua, idx)
#define xmi_lua_touserdata(lua, idx)                (g_lua_ops)->_lua_touserdata(lua, idx)
#define xmi_lua_pushinteger(lua, n)                 (g_lua_ops)->_lua_pushinteger(lua, n)
#define xmi_lua_gettop(lua)                         (g_lua_ops)->_lua_gettop(lua)
#define xmi_lua_pushnil(lua)                        (g_lua_ops)->_lua_pushnil(lua)
#define xmi_lua_type(lua, idx)                      (g_lua_ops)->_lua_type(lua, idx)

// luaL interfaces
#define xmi_luaL_setfuncs(lua, narr, nrec)          (g_lua_ops)->_luaL_setfuncs(lua, narr, nrec)
#if defined(_MSC_VER)
#   define xmi_luaL_error(lua, fmt, ...)            (g_lua_ops)->_luaL_error(lua, fmt, __VA_ARGS__)
#else
#   define xmi_luaL_error(lua, fmt, arg ...)        (g_lua_ops)->_luaL_error(lua, fmt, ## arg)
#endif
#define xmi_luaL_argerror(lua, numarg, extramsg)    (g_lua_ops)->_luaL_argerror(lua, numarg, extramsg)
#define xmi_luaL_checkinteger(lua, idx)             (g_lua_ops)->_luaL_checkinteger(lua, idx)

// helper interfaces
#define xmi_lua_newtable(lua)		                xmi_lua_createtable(lua, 0, 0)
#define xmi_lua_tointeger(lua, i)                   xmi_lua_tointegerx(lua, (i), NULL)

#define xmi_lua_isfunction(lua, n)	                (xmi_lua_type(lua, (n)) == XMI_LUA_TFUNCTION)
#define xmi_lua_istable(lua, n)	                    (xmi_lua_type(lua, (n)) == XMI_LUA_TTABLE)
#define xmi_lua_islightuserdata(lua, n)	            (xmi_lua_type(lua, (n)) == XMI_LUA_TLIGHTUSERDATA)
#define xmi_lua_isnil(lua, n)                       (xmi_lua_type(lua, (n)) == XMI_LUA_TNIL)
#define xmi_lua_isboolean(lua, n)	                (xmi_lua_type(lua, (n)) == XMI_LUA_TBOOLEAN)
#define xmi_lua_isthread(lua, n)	                (xmi_lua_type(lua, (n)) == XMI_LUA_TTHREAD)
#define xmi_lua_isnone(lua, n)		                (xmi_lua_type(lua, (n)) == XMI_LUA_TNONE)
#define xmi_lua_isnoneornil(lua, n)	                (xmi_lua_type(lua, (n)) <= 0)

#define xmi_luaL_newlibtable(lua, l)	            xml_lua_createtable(lua, 0, sizeof(l)/sizeof((l)[0]) - 1)
#define xmi_luaL_newlib(lua, l) \
    (xmi_luaL_checkversion(lua), xmi_luaL_newlibtable(lua,l), xmi_luaL_setfuncs(lua,l,0))
#define xmi_luaL_argcheck(lua, cond, arg, extramsg)	\
    ((void)(luai_likely(cond) || xmi_luaL_argerror(lua, (arg), (extramsg))))
#define xmi_luaL_argexpected(lua, cond, arg, tname)	\
	((void)(luai_likely(cond) || xmi_luaL_typeerror(lua, (arg), (tname))))
#define xmi_luaL_checkstring(lua, n)	            (xmi_luaL_checklstring(lua, (n), NULL))
#define xmi_luaL_optstring(lua, n, d)	            (xmi_luaL_optlstring(lua, (n), (d), NULL))
#define xmi_luaL_typename(lua, i)	                xmi_lua_typename(lua, xmi_lua_type(lua,(i)))
#define xmi_luaL_dofile(lua, fn) \
	(xmi_luaL_loadfile(lua, fn) || xmi_lua_pcall(lua, 0, XMI_LUA_MULTRET, 0))
#define xmi_luaL_dostring(lua, s) \
	(xmi_luaL_loadstring(lua, s) || xmi_lua_pcall(lua, 0, XMI_LUA_MULTRET, 0))
#define xmi_luaL_getmetatable(lua, n)	            (xmi_lua_getfield(lua, XMI_LUA_REGISTRYINDEX, (n)))
#define xmi_luaL_opt(lua, f, n, d)	                (xmi_lua_isnoneornil(lua,(n)) ? (d) : f(lua,(n)))
#define xmi_luaL_loadbuffer(lua, s, sz, n)	        xmi_luaL_loadbufferx(lua, s, sz, n, NULL)
#define xmi_luaL_pushfail(lua)	                    xmi_lua_pushnil(lua)

/* we cannot redefine lua functions in loadxmi.c,
 * because original lua.h has been included
 */
#ifndef XM_PREFIX_H
#   define lua_upvalueindex         xmi_lua_upvalueindex

#   define lua_createtable          xmi_lua_createtable
#   define lua_tointegerx           xmi_lua_tointegerx
#   define lua_toboolean            xmi_lua_toboolean
#   define lua_touserdata           xmi_lua_touserdata
#   define lua_pushinteger          xmi_lua_pushinteger
#   define lua_gettop               xmi_lua_gettop
#   define lua_pushnil              xmi_lua_pushnil
#   define lua_type                 xmi_lua_type

#   define luaL_setfuncs            xmi_luaL_setfuncs
#   define luaL_error               xmi_luaL_error
#   define luaL_argerror            xmi_luaL_argerror
#   define luaL_checkinteger        xmi_luaL_checkinteger

#   define lua_newtable             xmi_lua_newtable
#   define lua_tointeger            xmi_lua_tointeger
#   define lua_isfunction           xmi_lua_isfunction
#   define lua_istable              xmi_lua_istable
#   define lua_islightuserdata      xmi_lua_islightuserdata
#   define lua_isnil                xmi_lua_isnil
#   define lua_isboolean            xmi_lua_isboolean
#   define lua_isthread             xmi_lua_isthread
#   define lua_isnone               xmi_lua_isnone
#   define lua_isnoneornil          xmi_lua_isnoneornil

#   define luaL_newlibtable         xmi_luaL_newlibtable
#   define luaL_newlib              xmi_luaL_newlib
#   define luaL_argcheck            xmi_luaL_argcheck
#   define luaL_argexpected         xmi_luaL_argexpected
#   define luaL_checkstring         xmi_luaL_checkstring
#   define luaL_optstring           xmi_luaL_optstring
#   define luaL_typename            xmi_luaL_typename
#   define luaL_dofile              xmi_luaL_dofile
#   define luaL_dostring            xmi_luaL_dostring
#   define luaL_getmetatable        xmi_luaL_getmetatable
#   define luaL_opt                 xmi_luaL_opt
#   define luaL_loadbuffer          xmi_luaL_loadbuffer
#   define luaL_pushfail            xmi_luaL_pushfail

#   define luaL_Reg                 xmi_luaL_Reg
#   define lua_State                xmi_lua_State
#   define lua_Integer              xmi_lua_Integer
#endif

// extern c
#ifdef __cplusplus
#   define xmi_extern_c_enter       extern "C" {
#   define xmi_extern_c_leave       }
#else
#   define xmi_extern_c_enter
#   define xmi_extern_c_leave
#endif

// define lua module entry function
#define luaopen(name, lua) \
__dummy = 1; \
xmi_lua_ops_t* g_lua_ops = NULL; \
xmi_extern_c_enter \
int xmiopen_##name(lua); \
xmi_extern_c_leave \
int xmisetup(xmi_lua_ops_t* ops) { \
    g_lua_ops = ops; \
    return __dummy; \
} \
int xmiopen_##name(lua)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
typedef LUA_INTEGER xmi_lua_Integer;

typedef struct xmi_lua_State_ {
    int dummy;
}xmi_lua_State;

typedef struct xmi_luaL_Reg_ {
    char const* name;
    int (*func)(lua_State* lua);
}xmi_luaL_Reg;

typedef struct xmi_lua_ops_t_ {
    void        (*_lua_createtable)(lua_State* lua, int narr, int nrec);
    lua_Integer (*_lua_tointegerx)(lua_State* lua, int idx, int* isnum);
    int         (*_lua_toboolean) (lua_State* lua, int idx);
    void*       (*_lua_touserdata)(lua_State* lua, int idx);
    void        (*_lua_pushinteger)(lua_State* lua, lua_Integer n);
    int         (*_lua_gettop)(lua_State* lua);
    void        (*_lua_pushnil)(lua_State* lua);
    int         (*_lua_type)(lua_State* lua, int idx);

    void        (*_luaL_setfuncs)(lua_State* lua, const luaL_Reg* l, int nup);
    int         (*_luaL_error)(lua_State* lua, const char* fmt, ...);
    int         (*_luaL_argerror)(lua_State* lua, int numarg, const char* extramsg);
    lua_Integer (*_luaL_checkinteger)(lua_State* lua, int idx);

}xmi_lua_ops_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
extern xmi_lua_ops_t* g_lua_ops;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
xmi_extern_c_enter

// setup lua interfaces
int xmisetup(xmi_lua_ops_t* ops);

xmi_extern_c_leave
#endif


