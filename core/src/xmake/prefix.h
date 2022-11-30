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
 * @file        prefix.h
 *
 */
#ifndef XM_PREFIX_H
#define XM_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix/prefix.h"
#include "luaconf.h"
#if defined(TB_CONFIG_OS_WINDOWS) && defined(__cplusplus)
#   undef LUA_API
#   undef LUALIB_API
#   define LUA_API extern "C"
#   define LUALIB_API	LUA_API
#endif
#ifdef USE_LUAJIT
#   include "luajit.h"
#   include "lualib.h"
#   include "lauxlib.h"
#else
#   include "lua.h"
#   include "lualib.h"
#   include "lauxlib.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private interfaces
 */

static __tb_inline__ tb_void_t xm_lua_pushpointer(lua_State* lua, tb_pointer_t ptr)
{
    lua_pushlightuserdata(lua, ptr);
}
static __tb_inline__ tb_bool_t xm_lua_ispointer(lua_State* lua, tb_int_t idx)
{
    return lua_isuserdata(lua, idx);
}
static __tb_inline__ tb_pointer_t xm_lua_topointer2(lua_State* lua, tb_int_t idx, tb_char_t const** pstr)
{
    if (pstr) *pstr = tb_null;
    return lua_touserdata(lua, idx);
}
static __tb_inline__ tb_pointer_t xm_lua_topointer(lua_State* lua, tb_int_t idx)
{
    return lua_touserdata(lua, idx);
}

static __tb_inline__ tb_void_t xm_lua_register(lua_State *lua, tb_char_t const* libname, luaL_Reg const* l)
{
#if LUA_VERSION_NUM >= 504
    lua_getglobal(lua, libname);
    if (lua_isnil(lua, -1))
    {
        lua_pop(lua, 1);
        lua_newtable(lua);
    }
    luaL_setfuncs(lua, l, 0);
    lua_setglobal(lua, libname);
#else
    luaL_register(lua, libname, l);
#endif
}

#endif


