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
#include "luajit.h"
#include "lualib.h"
#include "lauxlib.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private interfaces
 */

// this issue has been fixed, @see https://github.com/LuaJIT/LuaJIT/commit/e9af1abec542e6f9851ff2368e7f196b6382a44c
#if 0//TB_CPU_BIT64
/* we use this interface instead of lua_pushlightuserdata() to fix bad light userdata pointer bug
 *
 * @see https://github.com/xmake-io/xmake/issues/914
 * https://github.com/LuaJIT/LuaJIT/pull/230
 *
 * @note we cannot lua_newuserdata() because we need pass this pointer to the external lua code
 * in poller_wait()/event_callback, but lua_pushuserdata does not exists
 */
static __tb_inline__ tb_void_t xm_lua_pushpointer(lua_State* lua, tb_pointer_t ptr)
{
    tb_uint64_t ptrval = (tb_uint64_t)ptr;
    if ((ptrval >> 47) == 0)
        lua_pushlightuserdata(lua, ptr);
    else
    {
        tb_char_t str[64];
        tb_long_t len = tb_snprintf(str, sizeof(str), "%p", ptr);
        lua_pushlstring(lua, str, len);
    }
}
static __tb_inline__ tb_bool_t xm_lua_ispointer(lua_State* lua, tb_int_t idx)
{
    return lua_isuserdata(lua, idx) || lua_isstring(lua, idx);
}
static __tb_inline__ tb_pointer_t xm_lua_topointer2(lua_State* lua, tb_int_t idx, tb_char_t const** pstr)
{
    tb_pointer_t ptr = tb_null;
    if (lua_isuserdata(lua, idx))
    {
        ptr = lua_touserdata(lua, idx);
        if (pstr) *pstr = tb_null;
    }
    else
    {
        size_t len = 0;
        tb_char_t const* str = luaL_checklstring(lua, idx, &len);
        if (str && len > 2 && str[0] == '0' && str[1] == 'x')
            ptr = (tb_pointer_t)tb_s16tou64(str);
        if (pstr) *pstr = str;
    }
    return ptr;
}
static __tb_inline__ tb_pointer_t xm_lua_topointer(lua_State* lua, tb_int_t idx)
{
   return xm_lua_topointer2(lua, idx, tb_null);
}
#else
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
#endif

#endif


