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
#include <stdarg.h>
#ifndef LUA_VERSION
#   include "luawrap/luaconf.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#define XMI_LUA_MULTRET  (-1)

// thread status
#define XMI_LUA_OK              0
#define XMI_LUA_YIELD           1
#define XMI_LUA_ERRRUN          2
#define XMI_LUA_ERRSYNTAX       3
#define XMI_LUA_ERRMEM          4
#define XMI_LUA_ERRERR          5

// basic types
#define XMI_LUA_TNONE           (-1)

#define XMI_LUA_TNIL            0
#define XMI_LUA_TBOOLEAN        1
#define XMI_LUA_TLIGHTUSERDATA  2
#define XMI_LUA_TNUMBER         3
#define XMI_LUA_TSTRING         4
#define XMI_LUA_TTABLE          5
#define XMI_LUA_TFUNCTION       6
#define XMI_LUA_TUSERDATA       7
#define XMI_LUA_TTHREAD         8

#define XMI_LUA_NUMTYPES        9

// pseudo-indices
#ifdef XMI_USE_LUAJIT
#   define XMI_LUA_REGISTRYINDEX    (-10000)
#   define XMI_LUA_ENVIRONINDEX     (-10001)
#   define XMI_LUA_GLOBALSINDEX     (-10002)
#   define xmi_lua_upvalueindex(i)  (XMI_LUA_GLOBALSINDEX - (i))
#else
#   define XMI_LUA_REGISTRYINDEX    (-LUAI_MAXSTACK - 1000)
#   define xmi_lua_upvalueindex(i)  (XMI_LUA_REGISTRYINDEX - (i))
#endif

// get macros
#ifdef XMI_USE_LUAJIT
#   define xmi_lua_getglobal(lua, s)                xmi_lua_getfield(lua, LUA_GLOBALSINDEX, (s))
#   define xmi_lua_newuserdata(lua, s)              (g_lua_ops)->_lua_newuserdata(lua, s)
#else
#   define xmi_lua_getglobal(lua, name)             (g_lua_ops)->_lua_getglobal(lua, name)
#   define xmi_lua_geti(lua, idx, n)                (g_lua_ops)->_lua_geti(lua, idx, n)
#   define xmi_lua_rawgetp(lua, idx, p)             (g_lua_ops)->_lua_rawgetp(lua, idx, p)
#   define xmi_lua_getiuservalue(lua, idx, n)       (g_lua_ops)->_lua_getiuservalue(lua, idx, n)
#   define xmi_lua_newuserdatauv(lua, sz, nuvalue)  (g_lua_ops)->_lua_newuserdatauv(lua, sz, nuvalue)
#   define xmi_lua_newuserdata(lua, s)              xmi_lua_newuserdatauv(lua, s, 1)
#endif
#define xmi_lua_gettable(lua, idx)                  (g_lua_ops)->_lua_gettable(lua, idx)
#define xmi_lua_getfield(lua, idx, k)               (g_lua_ops)->_lua_getfield(lua, idx, k)
#define xmi_lua_rawget(lua, idx)                    (g_lua_ops)->_lua_rawget(lua, idx)
#define xmi_lua_rawgeti(lua, idx, n)                (g_lua_ops)->_lua_rawgeti(lua, idx, n)
#define xmi_lua_createtable(lua, narr, nrec)        (g_lua_ops)->_lua_createtable(lua, narr, nrec)
#define xmi_lua_getmetatable(lua, objindex)         (g_lua_ops)->_lua_getmetatable(lua, objindex)
#define xmi_lua_newtable(lua)                       xmi_lua_createtable(lua, 0, 0)
#define xmi_lua_pop(lua, n)                         xmi_lua_settop(lua, -(n)-1)
#define xmi_lua_getuservalue(lua, idx)              xmi_lua_getiuservalue(lua, idx, 1)

// set macros
#ifdef XMI_USE_LUAJIT
#   define xmi_lua_setglobal(lua, s)                xmi_lua_setfield(lua, LUA_GLOBALSINDEX, (s))
#else
#   define xmi_lua_setglobal(lua, name)             (g_lua_ops)->_lua_setglobal(lua, name)
#   define xmi_lua_seti(lua, idx, n)                (g_lua_ops)->_lua_seti(lua, idx, n)
#   define xmi_lua_rawsetp(lua, idx, p)             (g_lua_ops)->_lua_rawsetp(lua, idx, p)
#   define xmi_lua_setiuservalue(lua, idx, n)       (g_lua_ops)->_lua_setiuservalue(lua, idx, n)
#endif
#define xmi_lua_settable(lua, idx)                  (g_lua_ops)->_lua_settable(lua, idx)
#define xmi_lua_setfield(lua, idx, k)               (g_lua_ops)->_lua_setfield(lua, idx, k)
#define xmi_lua_rawset(lua, idx)                    (g_lua_ops)->_lua_rawset(lua, idx)
#define xmi_lua_rawseti(lua, idx, n)                (g_lua_ops)->_lua_rawseti(lua, idx, n)
#define xmi_lua_setmetatable(lua, objidx)           (g_lua_ops)->_lua_setmetatable(lua, objidx)
#define xmi_lua_setuservalue(lua, idx)              xmi_lua_setiuservalue(lua, idx, 1)

// access macros
#define xmi_lua_isnumber(lua, idx)                  (g_lua_ops)->_lua_isnumber(lua, idx)
#define xmi_lua_isstring(lua, idx)                  (g_lua_ops)->_lua_isstring(lua, idx)
#define xmi_lua_iscfunction(lua, idx)               (g_lua_ops)->_lua_iscfunction(lua, idx)
#define xmi_lua_isuserdata(lua, idx)                (g_lua_ops)->_lua_isuserdata(lua, idx)
#define xmi_lua_type(lua, idx)                      (g_lua_ops)->_lua_type(lua, idx)
#define xmi_lua_typename(lua, idx)                  (g_lua_ops)->_lua_typename(lua, idx)
#ifndef XMI_USE_LUAJIT
#   define xmi_lua_isinteger(lua, idx)              (g_lua_ops)->_lua_isinteger(lua, idx)
#endif

#define xmi_lua_isfunction(lua, n)                  (xmi_lua_type(lua, (n)) == XMI_LUA_TFUNCTION)
#define xmi_lua_istable(lua, n)                     (xmi_lua_type(lua, (n)) == XMI_LUA_TTABLE)
#define xmi_lua_islightuserdata(lua, n)             (xmi_lua_type(lua, (n)) == XMI_LUA_TLIGHTUSERDATA)
#define xmi_lua_isnil(lua, n)                       (xmi_lua_type(lua, (n)) == XMI_LUA_TNIL)
#define xmi_lua_isboolean(lua, n)                   (xmi_lua_type(lua, (n)) == XMI_LUA_TBOOLEAN)
#define xmi_lua_isthread(lua, n)                    (xmi_lua_type(lua, (n)) == XMI_LUA_TTHREAD)
#define xmi_lua_isnone(lua, n)                      (xmi_lua_type(lua, (n)) == XMI_LUA_TNONE)
#define xmi_lua_isnoneornil(lua, n)                 (xmi_lua_type(lua, (n)) <= 0)

#define xmi_lua_tonumberx(lua, idx, isnum)          (g_lua_ops)->_lua_tonumberx(lua, idx, isnum)
#define xmi_lua_tointegerx(lua, idx, isnum)         (g_lua_ops)->_lua_tointegerx(lua, idx, isnum)
#define xmi_lua_toboolean(lua, idx)                 (g_lua_ops)->_lua_toboolean(lua, idx)
#define xmi_lua_tolstring(lua, idx, len)            (g_lua_ops)->_lua_tolstring(lua, idx, len)
#define xmi_lua_rawlen(lua, idx)                    (g_lua_ops)->_lua_rawlen(lua, idx)
#define xmi_lua_tocfunction(lua, idx)               (g_lua_ops)->_lua_tocfunction(lua, idx)
#define xmi_lua_touserdata(lua, idx)                (g_lua_ops)->_lua_touserdata(lua, idx)
#define xmi_lua_tothread(lua, idx)                  (g_lua_ops)->_lua_tothread(lua, idx)
#define xmi_lua_topointer(lua, idx)                 (g_lua_ops)->_lua_topointer(lua, idx)
#define xmi_lua_tonumber(lua, idx)                  xmi_lua_tonumberx(lua, (idx), NULL)
#define xmi_lua_tostring(lua, idx)                  xmi_lua_tolstring(lua, (idx), NULL)
#define xmi_lua_tointeger(lua, idx)                 xmi_lua_tointegerx(lua, (idx), NULL)

// push macros
#define xmi_lua_pushnil(lua)                        (g_lua_ops)->_lua_pushnil(lua)
#define xmi_lua_pushinteger(lua, n)                 (g_lua_ops)->_lua_pushinteger(lua, n)
#define xmi_lua_pushboolean(lua, b)                 (g_lua_ops)->_lua_pushboolean(lua, b)
#define xmi_lua_pushnumber(lua, n)                  (g_lua_ops)->_lua_pushnumber(lua, n)
#define xmi_lua_pushlstring(lua, s, len)            (g_lua_ops)->_lua_pushlstring(lua, s, len)
#define xmi_lua_pushstring(lua, s)                  (g_lua_ops)->_lua_pushstring(lua, s)
#define xmi_lua_pushvfstring(lua, fmt, argp)        (g_lua_ops)->_lua_pushvfstring(lua, fmt, argp)
#if defined(_MSC_VER)
#   define xmi_lua_pushfstring(lua, fmt, ...)       (g_lua_ops)->_lua_pushfstring(lua, fmt, __VA_ARGS__)
#else
#   define xmi_lua_pushfstring(lua, fmt, arg ...)   (g_lua_ops)->_lua_pushfstring(lua, fmt, ## arg)
#endif
#define xmi_lua_pushcclosure(lua, fn, n)            (g_lua_ops)->_lua_pushcclosure(lua, fn, n)
#define xmi_lua_pushlightuserdata(lua, p)           (g_lua_ops)->_lua_pushlightuserdata(lua, p)
#define xmi_lua_pushthread(lua)                     (g_lua_ops)->_lua_pushthread(lua)
#define xmi_lua_pushcfunction(lua, f)               xmi_lua_pushcclosure(lua, (f), 0)
#define xmi_lua_pushliteral(lua, s)                 xmi_lua_pushstring(lua, "" s)

// stack functions
#ifdef XMI_USE_LUAJIT
#   define xmi_lua_insert(lua, idx)                 (g_lua_ops)->_lua_insert(lua, idx)
#   define xmi_lua_remove(lua, idx)                 (g_lua_ops)->_lua_remove(lua, idx)
#   define xmi_lua_replace(lua, idx)                (g_lua_ops)->_lua_replace(lua, idx)
#else
#   define xmi_lua_absindex(lua, idx)               (g_lua_ops)->_lua_absindex(lua, idx)
#   define xmi_lua_rotate(lua, idx, n)              (g_lua_ops)->_lua_rotate(lua, idx, n)
#   define xmi_lua_insert(lua, idx)	                xmi_lua_rotate(lua, (idx), 1)
#   define xmi_lua_remove(lua, idx)	                (xmi_lua_rotate(lua, (idx), -1), xmi_lua_pop(lua, 1))
#   define xmi_lua_replace(lua, idx)	            (xmi_lua_copy(lua, -1, (idx)), xmi_lua_pop(lua, 1))
#endif
#define xmi_lua_gettop(lua)                         (g_lua_ops)->_lua_gettop(lua)
#define xmi_lua_settop(lua, idx)                    (g_lua_ops)->_lua_settop(lua, idx)
#define xmi_lua_pushvalue(lua, idx)                 (g_lua_ops)->_lua_pushvalue(lua, idx)
#define xmi_lua_copy(lua, fromidx, toidx)           (g_lua_ops)->_lua_copy(lua, fromidx, toidx)
#define xmi_lua_checkstack(lua, n)                  (g_lua_ops)->_lua_checkstack(lua, n)
#define xmi_lua_xmove(from, to, n)                  (g_lua_ops)->_lua_xmove(from, to, n)

// miscellaneous functions
#define xmi_lua_error(lua)                          (g_lua_ops)->_lua_error(lua)
#define xmi_lua_next(lua, idx)                      (g_lua_ops)->_lua_next(lua, idx)
#define xmi_lua_concat(lua, n)                      (g_lua_ops)->_lua_concat(lua, n)
#define xmi_lua_getallocf(lua, ud)                  (g_lua_ops)->_lua_getallocf(lua, ud)
#define xmi_lua_setallocf(lua, f, ud)               (g_lua_ops)->_lua_setallocf(lua, f, ud)
#ifndef XMI_USE_LUAJIT
#   define xmi_lua_len(lua, idx)                    (g_lua_ops)->_lua_len(lua, idx)
#   define xmi_lua_toclose(lua, idx)                (g_lua_ops)->_lua_toclose(lua, idx)
#   define xmi_lua_closeslot(lua, idx)              (g_lua_ops)->_lua_closeslot(lua, idx)
#   define xmi_lua_stringtonumber(lua, s)           (g_lua_ops)->_lua_stringtonumber(lua, s)
#endif

// 'load' and 'call' functions
#ifdef XMI_USE_LUAJIT
#   define xmi_lua_call(lua, n, nr)                 (g_lua_ops)->_lua_call(lua, n, nr)
#   define xmi_lua_pcall(lua, n, nr, ef)            (g_lua_ops)->_lua_pcall(lua, n, nr, ef)
#   define xmi_lua_load(lua, r, dt, ch)             (g_lua_ops)->_lua_load(lua, r, dt, ch)
#   define xmi_lua_dump(lua, w, d)                  (g_lua_ops)->_lua_dump(lua, r, d)
#else
#   define xmi_lua_callk(lua, n, nr, ctx, k)        (g_lua_ops)->_lua_callk(lua, n, nr, ctx, k)
#   define xmi_lua_pcallk(lua, n, nr, ef, ctx, k)   (g_lua_ops)->_lua_pcallk(lua, n, nr, ef, ctx, k)
#   define xmi_lua_call(lua, n, r)                  xmi_lua_callk(lua, (n), (r), 0, NULL)
#   define xmi_lua_pcall(lua, n, r, f)              xmi_lua_pcallk(lua, (n), (r), (f), 0, NULL)
#   define xmi_lua_load(lua, r, dt, ch, mode)       (g_lua_ops)->_lua_load(lua, r, dt, ch, mode)
#   define xmi_lua_dump(lua, w, d, strip)           (g_lua_ops)->_lua_dump(lua, r, d, strip)
#endif

// luaL macros
#ifndef XMI_USE_LUAJIT
#   define xmi_luaL_tolstring(lua, idx, len)        (g_lua_ops)->_luaL_tolstring(lua, idx, len)
#   define xmi_luaL_typeerror(lua, arg, tname)      (g_lua_ops)->_luaL_typeerror(lua, arg, tname)
#endif
#define xmi_luaL_getmetafield(lua, obj, e)          (g_lua_ops)->_luaL_getmetafield(lua, obj, e)
#define xmi_luaL_callmeta(lua, obj, e)              (g_lua_ops)->_luaL_callmeta(lua, obj, e)
#define xmi_luaL_argerror(lua, numarg, extramsg)    (g_lua_ops)->_luaL_argerror(lua, numarg, extramsg)
#define xmi_luaL_checklstring(lua, arg, l)          (g_lua_ops)->_luaL_checklstring(lua, arg, l)
#define xmi_luaL_optlstring(lua, arg, def, l)       (g_lua_ops)->_luaL_optlstring(lua, arg, def, l)
#define xmi_luaL_checknumber(lua, arg)              (g_lua_ops)->_luaL_checknumber(lua, arg)
#define xmi_luaL_optnumber(lua, arg, def)           (g_lua_ops)->_luaL_optnumber(lua, arg, def)
#define xmi_luaL_checkinteger(lua, idx)             (g_lua_ops)->_luaL_checkinteger(lua, idx)
#define xmi_luaL_optinteger(lua, arg, def)          (g_lua_ops)->_luaL_optinteger(lua, arg, def)
#define xmi_luaL_checkstack(lua, sz, msg)           (g_lua_ops)->_luaL_checkstack(lua, sz, msg)
#define xmi_luaL_checktype(lua, arg, t)             (g_lua_ops)->_luaL_checktype(lua, arg, t)
#define xmi_luaL_checkany(lua, arg)                 (g_lua_ops)->_luaL_checkany(lua, arg)
#define xmi_luaL_newmetatable(lua, tname)           (g_lua_ops)->_luaL_newmetatable(lua, tname)
#define xmi_luaL_setmetatable(lua, tname)           (g_lua_ops)->_luaL_setmetatable(lua, tname)
#define xmi_luaL_testudata(lua, tname)              (g_lua_ops)->_luaL_testudata(lua, tname)
#define xmi_luaL_checkudata(lua, tname)             (g_lua_ops)->_luaL_checkudata(lua, tname)
#define xmi_luaL_where(lua, lvl)                    (g_lua_ops)->_luaL_where(lua, lvl)
#if defined(_MSC_VER)
#   define xmi_luaL_error(lua, fmt, ...)            (g_lua_ops)->_luaL_error(lua, fmt, __VA_ARGS__)
#else
#   define xmi_luaL_error(lua, fmt, arg ...)        (g_lua_ops)->_luaL_error(lua, fmt, ## arg)
#endif
#define xmi_luaL_checkoption(lua, arg, def, lst)    (g_lua_ops)->_luaL_checkoption(lua, arg, def, lst)
#define xmi_luaL_fileresult(lua, stat, fname)       (g_lua_ops)->_luaL_fileresult(lua, stat, fname)
#define xmi_luaL_execresult(lua, stat)              (g_lua_ops)->_luaL_execresult(lua, stat)
#define xmi_luaL_setfuncs(lua, l, nup)              (g_lua_ops)->_luaL_setfuncs(lua, l, nup)
#define xmi_luaL_loadfilex(lua, fn, mode)           (g_lua_ops)->_luaL_loadfilex(lua, fn, mode)
#define xmi_luaL_loadfile(lua, fn)                  xmi_luaL_loadfilex(lua, fn, NULL)
#define xmi_luaL_loadstring(lua, s)                 (g_lua_ops)->_luaL_loadstring(lua, s)

#define xmi_luaL_newlibtable(lua, l)                xml_lua_createtable(lua, 0, sizeof(l)/sizeof((l)[0]) - 1)
#define xmi_luaL_newlib(lua, l) \
    (xmi_luaL_checkversion(lua), xmi_luaL_newlibtable(lua,l), xmi_luaL_setfuncs(lua,l,0))
#define xmi_luaL_argcheck(lua, cond, arg, extramsg) \
    ((void)(luai_likely(cond) || xmi_luaL_argerror(lua, (arg), (extramsg))))
#define xmi_luaL_argexpected(lua, cond, arg, tname) \
    ((void)(luai_likely(cond) || xmi_luaL_typeerror(lua, (arg), (tname))))
#define xmi_luaL_checkstring(lua, n)                (xmi_luaL_checklstring(lua, (n), NULL))
#define xmi_luaL_optstring(lua, n, d)               (xmi_luaL_optlstring(lua, (n), (d), NULL))
#define xmi_luaL_typename(lua, i)                   xmi_lua_typename(lua, xmi_lua_type(lua,(i)))
#define xmi_luaL_dofile(lua, fn) \
    (xmi_luaL_loadfile(lua, fn) || xmi_lua_pcall(lua, 0, XMI_LUA_MULTRET, 0))
#define xmi_luaL_dostring(lua, s) \
    (xmi_luaL_loadstring(lua, s) || xmi_lua_pcall(lua, 0, XMI_LUA_MULTRET, 0))
#define xmi_luaL_getmetatable(lua, n)               (xmi_lua_getfield(lua, XMI_LUA_REGISTRYINDEX, (n)))
#define xmi_luaL_opt(lua, f, n, d)                  (xmi_lua_isnoneornil(lua,(n)) ? (d) : f(lua,(n)))
#define xmi_luaL_loadbuffer(lua, s, sz, n)          xmi_luaL_loadbufferx(lua, s, sz, n, NULL)
#define xmi_luaL_pushfail(lua)                      xmi_lua_pushnil(lua)

/* we cannot redefine lua functions in loadxmi.c,
 * because original lua.h has been included
 */
#ifndef XM_PREFIX_H

// thread status
#   define LUA_OK                   XMI_LUA_OK
#   define LUA_YIELD                XMI_LUA_YIELD
#   define LUA_ERRRUN               XMI_LUA_ERRRUN
#   define LUA_ERRSYNTAX            XMI_LUA_ERRSYNTAX
#   define LUA_ERRMEM               XMI_LUA_ERRMEM
#   define LUA_ERRERR               XMI_LUA_ERRERR

// basic types
#   define LUA_TNONE                XMI_LUA_TNONE
#   define LUA_TNIL                 XMI_LUA_TNIL
#   define LUA_TBOOLEAN             XMI_LUA_TBOOLEAN
#   define LUA_TLIGHTUSERDATA       XMI_LUA_TLIGHTUSERDATA
#   define LUA_TNUMBER              XMI_LUA_TNUMBER
#   define LUA_TSTRING              XMI_LUA_TSTRING
#   define LUA_TTABLE               XMI_LUA_TTABLE
#   define LUA_TFUNCTION            XMI_LUA_TFUNCTION
#   define LUA_TUSERDATA            XMI_LUA_TUSERDATA
#   define LUA_TTHREAD              XMI_LUA_TTHREAD
#   define LUA_NUMTYPES             XMI_LUA_NUMTYPES

// get macros
#   define lua_getglobal            xmi_lua_getglobal
#   define lua_gettable             xmi_lua_gettable
#   define lua_getfield             xmi_lua_getfield
#   define lua_geti                 xmi_lua_geti
#   define lua_rawget               xmi_lua_rawget
#   define lua_rawgeti              xmi_lua_rawgeti
#   define lua_rawgetp              xmi_lua_rawgetp
#   define lua_createtable          xmi_lua_createtable
#   define lua_newuserdatauv        xmi_lua_newuserdatauv
#   define lua_getmetatable         xmi_lua_getmetatable
#   define lua_getiuservalue        xmi_lua_getiuservalue
#   define lua_upvalueindex         xmi_lua_upvalueindex
#   define lua_newtable             xmi_lua_newtable
#   define lua_pop                  xmi_lua_pop
#   define lua_newuserdata          xmi_lua_newuserdata
#   define lua_getuservalue         xmi_lua_getuservalue

// set macros
#   define lua_setglobal            xmi_lua_setglobal
#   define lua_settable             xmi_lua_settable
#   define lua_setfield             xmi_lua_setfield
#   define lua_seti                 xmi_lua_seti
#   define lua_rawset               xmi_lua_rawset
#   define lua_rawseti              xmi_lua_rawseti
#   define lua_rawsetp              xmi_lua_rawsetp
#   define lua_setmetatable         xmi_lua_setmetatable
#   define lua_setiuservalue        xmi_lua_setiuservalue
#   define lua_setuservalue         xmi_lua_setuservalue

// access macros
#   define lua_isnumber             xmi_lua_isnumber
#   define lua_isstring             xmi_lua_isstring
#   define lua_iscfunction          xmi_lua_iscfunction
#   define lua_isuserdata           xmi_lua_isuserdata
#   define lua_type                 xmi_lua_type
#   define lua_typename             xmi_lua_typename
#   ifndef XMI_USE_LUAJIT
#   define lua_isinteger            xmi_lua_isinteger
#   endif

#   define lua_isfunction           xmi_lua_isfunction
#   define lua_istable              xmi_lua_istable
#   define lua_islightuserdata      xmi_lua_islightuserdata
#   define lua_isnil                xmi_lua_isnil
#   define lua_isboolean            xmi_lua_isboolean
#   define lua_isthread             xmi_lua_isthread
#   define lua_isnone               xmi_lua_isnone
#   define lua_isnoneornil          xmi_lua_isnoneornil

#   define lua_tonumberx            xmi_lua_tonumberx
#   define lua_tointegerx           xmi_lua_tointegerx
#   define lua_toboolean            xmi_lua_toboolean
#   define lua_tolstring            xmi_lua_tolstring
#   define lua_rawlen               xmi_lua_rawlen
#   define lua_tocfunction          xmi_lua_tocfunction
#   define lua_touserdata           xmi_lua_touserdata
#   define lua_tothread             xmi_lua_tothread
#   define lua_topointer            xmi_lua_topointer
#   define lua_tostring             xmi_lua_tostring
#   define lua_tonumber             xmi_lua_tonumber
#   define lua_tointeger            xmi_lua_tointeger

// push macros
#   define lua_pushnil              xmi_lua_pushnil
#   define lua_pushinteger          xmi_lua_pushinteger
#   define lua_pushboolean          xmi_lua_pushboolean
#   define lua_pushnumber           xmi_lua_pushnumber
#   define lua_pushlstring          xmi_lua_pushlstring
#   define lua_pushstring           xmi_lua_pushstring
#   define lua_pushvfstring         xmi_lua_pushvfstring
#   define lua_pushfstring          xmi_lua_pushfstring
#   define lua_pushcclosure         xmi_lua_pushcclosure
#   define lua_pushlightuserdata    xmi_lua_pushlightuserdata
#   define lua_pushthread           xmi_lua_pushthread
#   define lua_pushcfunction        xmi_lua_pushcfunction
#   define lua_pushliteral          xmi_lua_pushliteral

// stack functions
#   define lua_absindex             xmi_lua_absindex
#   define lua_gettop               xmi_lua_gettop
#   define lua_settop               xmi_lua_settop
#   define lua_pushvalue            xmi_lua_pushvalue
#   define lua_rotate               xmi_lua_rotate
#   define lua_copy                 xmi_lua_copy
#   define lua_checkstack           xmi_lua_checkstack
#   define lua_xmove                xmi_lua_xmove
#   define lua_insert               xmi_lua_insert
#   define lua_remove               xmi_lua_remove
#   define lua_replace              xmi_lua_replace

// miscellaneous functions
#   define lua_error                xmi_lua_error
#   define lua_next                 xmi_lua_next
#   define lua_concat               xmi_lua_concat
#   define lua_len                  xmi_lua_len
#   define lua_stringtonumber       xmi_lua_stringtonumber
#   define lua_getallocf            xmi_lua_getallocf
#   define lua_setallocf            xmi_lua_setallocf
#   define lua_toclose              xmi_lua_toclose
#   define lua_closeslot            xmi_lua_closeslot

// 'load' and 'call' functions
#   ifndef XMI_USE_LUAJIT
#   define lua_callk                xmi_lua_callk
#   define lua_pcallk               xmi_lua_pcallk
#   endif
#   define lua_call                 xmi_lua_call
#   define lua_pcall                xmi_lua_pcall
#   define lua_load                 xmi_lua_load
#   define lua_dump                 xmi_lua_dump

// luaL macros
#   define luaL_getmetafield        xmi_luaL_getmetafield
#   define luaL_callmeta            xmi_luaL_callmeta
#   define luaL_tolstring           xmi_luaL_tolstring
#   define luaL_argerror            xmi_luaL_argerror
#   define luaL_typeerror           xmi_luaL_typeerror
#   define luaL_checklstring        xmi_luaL_checklstring
#   define luaL_optlstring          xmi_luaL_optlstring
#   define luaL_checknumber         xmi_luaL_checknumber
#   define luaL_optnumber           xmi_luaL_optnumber
#   define luaL_checkinteger        xmi_luaL_checkinteger
#   define luaL_optinteger          xmi_luaL_optinteger
#   define luaL_checkstack          xmi_luaL_checkstack
#   define luaL_checktype           xmi_luaL_checktype
#   define luaL_checkany            xmi_luaL_checkany
#   define luaL_newmetatable        xmi_luaL_newmetatable
#   define luaL_setmetatable        xmi_luaL_setmetatable
#   define luaL_testudata           xmi_luaL_testudata
#   define luaL_checkudata          xmi_luaL_checkudata
#   define luaL_where               xmi_luaL_where
#   define luaL_error               xmi_luaL_error
#   define luaL_checkoption         xmi_luaL_checkoption
#   define luaL_fileresult          xmi_luaL_fileresult
#   define luaL_execresult          xmi_luaL_execresult
#   define luaL_setfuncs            xmi_luaL_setfuncs
#   define luaL_loadfilex           xmi_luaL_loadfilex
#   define luaL_loadfile            xmi_luaL_loadfile
#   define luaL_loadstring          xmi_luaL_loadstring

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

// types
#   define luaL_Reg                 xmi_luaL_Reg
#   define lua_State                xmi_lua_State
#   define lua_Number               xmi_lua_Number
#   define lua_Integer              xmi_lua_Integer
#   define lua_Unsigned             xmi_lua_Unsigned
#   define lua_KContext             xmi_lua_KContext
#   define lua_CFunction            xmi_lua_CFunction
#   define lua_KFunction            xmi_lua_KFunction
#   define lua_Reader               xmi_lua_Reader
#   define lua_Writer               xmi_lua_Writer
#   define lua_Alloc                xmi_lua_Alloc
#   define lua_WarnFunction         xmi_lua_WarnFunction
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
typedef LUA_NUMBER xmi_lua_Number;
typedef LUA_INTEGER xmi_lua_Integer;
#ifndef XMI_USE_LUAJIT
typedef LUA_UNSIGNED xmi_lua_Unsigned;
typedef LUA_KCONTEXT xmi_lua_KContext;
#endif

typedef struct xmi_lua_State_ {
    int dummy;
}xmi_lua_State;

typedef int (*xmi_lua_CFunction)(lua_State* lua);
#ifndef XMI_USE_LUAJIT
typedef int (*xmi_lua_KFunction)(lua_State* lua, int status, lua_KContext ctx);
#endif
typedef const char* (*xmi_lua_Reader)(lua_State* lua, void* ud, size_t* sz);
typedef int (*xmi_lua_Writer)(lua_State* lua, const void* p, size_t sz, void* ud);
typedef void* (*xmi_lua_Alloc)(void* ud, void* ptr, size_t osize, size_t nsize);
typedef void (*xmi_lua_WarnFunction)(void* ud, const char* msg, int tocont);

typedef struct xmi_luaL_Reg_ {
    char const*         name;
    xmi_lua_CFunction   func;
}xmi_luaL_Reg;

typedef struct xmi_lua_ops_t_ {

    // get functions
#ifdef XMI_USE_LUAJIT
    void*           (*_lua_newuserdata)(lua_State* lua, size_t sz);
    void            (*_lua_gettable)(lua_State* lua, int idx);
    void            (*_lua_getfield)(lua_State* lua, int idx, const char* k);
    void            (*_lua_rawgeti)(lua_State* lua, int idx, int n);
    void            (*_lua_rawget)(lua_State* lua, int idx);
#else
    int             (*_lua_getglobal)(lua_State* lua, const char* name);
    int             (*_lua_geti)(lua_State* lua, int idx, lua_Integer n);
    int             (*_lua_rawgetp)(lua_State* lua, int idx, const void* p);
    int             (*_lua_getiuservalue)(lua_State* lua, int idx, int n);
    void*           (*_lua_newuserdatauv)(lua_State* lua, size_t sz, int nuvalue);
    int             (*_lua_gettable)(lua_State* lua, int idx);
    int             (*_lua_getfield)(lua_State* lua, int idx, const char* k);
    int             (*_lua_rawgeti)(lua_State* lua, int idx, lua_Integer n);
    int             (*_lua_rawget)(lua_State* lua, int idx);
#endif
    void            (*_lua_createtable)(lua_State* lua, int narr, int nrec);
    int             (*_lua_getmetatable)(lua_State* lua, int objindex);

    // set functions
#ifdef XMI_USE_LUAJIT
    void            (*_lua_rawseti)(lua_State* lua, int idx, int n);
#else
    void            (*_lua_setglobal)(lua_State* lua, const char* name);
    void            (*_lua_seti)(lua_State* lua, int idx, lua_Integer n);
    void            (*_lua_rawsetp)(lua_State* lua, int idx, const void* p);
    int             (*_lua_setiuservalue)(lua_State* lua, int idx, int n);
    void            (*_lua_rawseti)(lua_State* lua, int idx, lua_Integer n);
#endif
    void            (*_lua_settable)(lua_State* lua, int idx);
    void            (*_lua_setfield)(lua_State* lua, int idx, const char* k);
    void            (*_lua_rawset)(lua_State* lua, int idx);
    int             (*_lua_setmetatable)(lua_State* lua, int objindex);

    // access functions
    int             (*_lua_isnumber)(lua_State* lua, int idx);
    int             (*_lua_isstring)(lua_State* lua, int idx);
    int             (*_lua_iscfunction)(lua_State* lua, int idx);
    int             (*_lua_isuserdata)(lua_State* lua, int idx);
    int             (*_lua_type)(lua_State* lua, int idx);
    const char*     (*_lua_typename)(lua_State* lua, int tp);
#ifndef XMI_USE_LUAJIT
    int             (*_lua_isinteger)(lua_State* lua, int idx);
#endif

    lua_Number      (*_lua_tonumberx)(lua_State* lua, int idx, int* isnum);
    lua_Integer     (*_lua_tointegerx)(lua_State* lua, int idx, int* isnum);
    int             (*_lua_toboolean)(lua_State* lua, int idx);
    const char*     (*_lua_tolstring)(lua_State* lua, int idx, size_t* len);
    lua_CFunction   (*_lua_tocfunction)(lua_State* lua, int idx);
    void*           (*_lua_touserdata)(lua_State* lua, int idx);
    lua_State*      (*_lua_tothread)(lua_State* lua, int idx);
    const void*     (*_lua_topointer)(lua_State* lua, int idx);
#ifndef XMI_USE_LUAJIT
    lua_Unsigned    (*_lua_rawlen)(lua_State* lua, int idx);
#endif

    // push functions
    void            (*_lua_pushnil)(lua_State* lua);
    void            (*_lua_pushinteger)(lua_State* lua, lua_Integer n);
    void            (*_lua_pushboolean)(lua_State* lua, int b);
    void            (*_lua_pushnumber)(lua_State* lua, lua_Number n);
#ifdef XMI_USE_LUAJIT
    void            (*_lua_pushlstring)(lua_State* lua, const char* s, size_t len);
    void            (*_lua_pushstring)(lua_State* lua, const char* s);
#else
    const char*     (*_lua_pushlstring)(lua_State* lua, const char* s, size_t len);
    const char*     (*_lua_pushstring)(lua_State* lua, const char* s);
#endif
    const char*     (*_lua_pushvfstring)(lua_State* lua, const char* fmt, va_list argp);
    const char*     (*_lua_pushfstring)(lua_State* lua, const char* fmt, ...);
    void            (*_lua_pushcclosure)(lua_State* lua, lua_CFunction fn, int n);
    void            (*_lua_pushlightuserdata)(lua_State* lua, void* p);
    int             (*_lua_pushthread)(lua_State* lua);

    // stack functions
#ifdef XMI_USE_LUAJIT
    void            (*_lua_insert)(lua_State* lua, int idx);
    void            (*_lua_remove)(lua_State* lua, int idx);
    void            (*_lua_replace)(lua_State* lua, int idx);
#else
    int             (*_lua_absindex)(lua_State* lua, int idx);
    void            (*_lua_rotate)(lua_State* lua, int idx, int n);
#endif
    int             (*_lua_gettop)(lua_State* lua);
    void            (*_lua_settop)(lua_State* lua, int idx);
    void            (*_lua_pushvalue)(lua_State* lua, int idx);
    void            (*_lua_copy)(lua_State* lua, int fromidx, int toidx);
    int             (*_lua_checkstack)(lua_State* lua, int n);
    void            (*_lua_xmove)(lua_State* from, lua_State* to, int n);

    // miscellaneous functions
    int             (*_lua_error)(lua_State* lua);
    int             (*_lua_next)(lua_State* lua, int idx);
    void            (*_lua_concat)(lua_State* lua, int n);
    lua_Alloc       (*_lua_getallocf)(lua_State* lua, void** ud);
    void            (*_lua_setallocf)(lua_State* lua, lua_Alloc f, void* ud);
#ifndef XMI_USE_LUAJIT
    void            (*_lua_len)(lua_State* lua, int idx);
    void            (*_lua_toclose)(lua_State* lua, int idx);
    void            (*_lua_closeslot)(lua_State* lua, int idx);
    size_t          (*_lua_stringtonumber)(lua_State* lua, const char* s);
#endif

    // 'load' and 'call' functions
#ifdef XMI_USE_LUAJIT
    void            (*_lua_call)(lua_State* lua, int nargs, int nresults);
    int             (*_lua_pcall)(lua_State* lua, int nargs, int nresults, int errfunc);
    int             (*_lua_load)(lua_State* lua, lua_Reader reader, void* dt, const char* chunkname);
    int             (*_lua_dump)(lua_State* lua, lua_Writer writer, void* data);
#else
    void            (*_lua_callk)(lua_State* lua, int nargs, int nresults, lua_KContext ctx, lua_KFunction k);
    int             (*_lua_pcallk)(lua_State* lua, int nargs, int nresults, int errfunc, lua_KContext ctx, lua_KFunction k);
    int             (*_lua_load)(lua_State* lua, lua_Reader reader, void* dt, const char* chunkname, const char* mode);
    int             (*_lua_dump)(lua_State* lua, lua_Writer writer, void* data, int strip);
#endif

    // luaL functions
#ifndef XMI_USE_LUAJIT
    const char*     (*_luaL_tolstring)(lua_State* lua, int idx, size_t* len);
    int             (*_luaL_typeerror)(lua_State* lua, int arg, const char* tname);
#endif
    int             (*_luaL_getmetafield)(lua_State* lua, int obj, const char* e);
    int             (*_luaL_callmeta)(lua_State* lua, int obj, const char* e);
    int             (*_luaL_argerror)(lua_State* lua, int numarg, const char* extramsg);
    const char*     (*_luaL_checklstring)(lua_State* lua, int arg, size_t* l);
    const char*     (*_luaL_optlstring)(lua_State* lua, int arg, const char* def, size_t* l);
    lua_Number      (*_luaL_checknumber)(lua_State* lua, int arg);
    lua_Number      (*_luaL_optnumber)(lua_State* lua, int arg, lua_Number def);
    lua_Integer     (*_luaL_checkinteger)(lua_State* lua, int idx);
    lua_Integer     (*_luaL_optinteger)(lua_State* lua, int arg, lua_Integer def);
    void            (*_luaL_checkstack)(lua_State* lua, int sz, const char* msg);
    void            (*_luaL_checktype)(lua_State* lua, int arg, int t);
    void            (*_luaL_checkany)(lua_State* lua, int arg);
    int             (*_luaL_newmetatable)(lua_State* lua, const char* tname);
    void            (*_luaL_setmetatable)(lua_State* lua, const char* tname);
    void*           (*_luaL_testudata)(lua_State* lua, int ud, const char* tname);
    void*           (*_luaL_checkudata)(lua_State* lua, int ud, const char* tname);
    void            (*_luaL_where)(lua_State* lua, int lvl);
    int             (*_luaL_error)(lua_State* lua, const char* fmt, ...);
    int             (*_luaL_checkoption)(lua_State* lua, int arg, const char* def, const char* const lst[]);
    int             (*_luaL_fileresult)(lua_State* lua, int stat, const char* fname);
    int             (*_luaL_execresult)(lua_State* lua, int stat);
    void            (*_luaL_setfuncs)(lua_State* lua, const luaL_Reg* l, int nup);
    int             (*_luaL_loadfilex)(lua_State* lua, const char* filename, const char* mode);
    int             (*_luaL_loadstring)(lua_State* lua, const char* s);

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


