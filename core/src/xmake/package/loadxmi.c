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
 * @file        loadxmi.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "loadxmi"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef USE_LUAJIT
#   define XMI_USE_LUAJIT
#endif
#include "xmi.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
typedef int (*xm_setup_func_t)(xmi_lua_ops_t* ops);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_package_loadxmi(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_check_return_val(path, 0);

    tb_char_t const* name = luaL_checkstring(lua, 2);
    tb_check_return_val(name, 0);

    // load module library
    tb_dynamic_ref_t lib = tb_dynamic_init(path);
    if (!lib)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "load %s failed", path);
        return 2;
    }

    // get xmiopen_xxx function
    lua_CFunction luaopen_func = (lua_CFunction)tb_dynamic_func(lib, name);
    if (!luaopen_func)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "cannot get symbol %s failed", name);
        return 2;
    }

    // get xmisetup function
    xm_setup_func_t xmisetup_func = (xm_setup_func_t)tb_dynamic_func(lib, "xmisetup");
    if (!xmisetup_func)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "cannot get symbol xmisetup failed");
        return 2;
    }

    // setup lua interfaces
    static xmi_lua_ops_t s_luaops = {0};
    static tb_bool_t     s_luaops_inited = tb_false;
    if (!s_luaops_inited)
    {

        // get functions
        s_luaops._lua_getglobal         = &lua_getglobal;
        s_luaops._lua_gettable          = &lua_gettable;
        s_luaops._lua_getfield          = &lua_getfield;
        s_luaops._lua_geti              = &lua_geti;
        s_luaops._lua_rawget            = &lua_rawget;
        s_luaops._lua_rawgeti           = &lua_rawgeti;
        s_luaops._lua_rawgetp           = &lua_rawgetp;
        s_luaops._lua_createtable       = &lua_createtable;
        s_luaops._lua_newuserdatauv     = &lua_newuserdatauv;
        s_luaops._lua_getmetatable      = &lua_getmetatable;
        s_luaops._lua_getiuservalue     = &lua_getiuservalue;

        // set functions
        s_luaops._lua_setglobal         = &lua_setglobal;
        s_luaops._lua_settable          = &lua_settable;
        s_luaops._lua_setfield          = &lua_setfield;
        s_luaops._lua_seti              = &lua_seti;
        s_luaops._lua_rawset            = &lua_rawset;
        s_luaops._lua_rawseti           = &lua_rawseti;
        s_luaops._lua_rawsetp           = &lua_rawsetp;
        s_luaops._lua_setmetatable      = &lua_setmetatable;
        s_luaops._lua_setiuservalue     = &lua_setiuservalue;

        // access functions
        s_luaops._lua_isnumber          = &lua_isnumber;
        s_luaops._lua_isstring          = &lua_isstring;
        s_luaops._lua_iscfunction       = &lua_iscfunction;
        s_luaops._lua_isinteger         = &lua_isinteger;
        s_luaops._lua_isuserdata        = &lua_isuserdata;
        s_luaops._lua_type              = &lua_type;
        s_luaops._lua_typename          = &lua_typename;

        s_luaops._lua_tonumberx         = &lua_tonumberx;
        s_luaops._lua_tointegerx        = &lua_tointegerx;
        s_luaops._lua_toboolean         = &lua_toboolean;
        s_luaops._lua_tolstring         = &lua_tolstring;
        s_luaops._lua_rawlen            = &lua_rawlen;
        s_luaops._lua_tocfunction       = &lua_tocfunction;
        s_luaops._lua_touserdata        = &lua_touserdata;
        s_luaops._lua_tothread          = &lua_tothread;
        s_luaops._lua_topointer         = &lua_topointer;

        // push functions
        s_luaops._lua_pushnil           = &lua_pushnil;
        s_luaops._lua_pushinteger       = &lua_pushinteger;
        s_luaops._lua_pushboolean       = &lua_pushboolean;
        s_luaops._lua_pushnumber        = &lua_pushnumber;
        s_luaops._lua_pushlstring       = &lua_pushlstring;
        s_luaops._lua_pushstring        = &lua_pushstring;
        s_luaops._lua_pushvfstring      = &lua_pushvfstring;
        s_luaops._lua_pushfstring       = &lua_pushfstring;
        s_luaops._lua_pushcclosure      = &lua_pushcclosure;
        s_luaops._lua_pushlightuserdata = &lua_pushlightuserdata;
        s_luaops._lua_pushthread        = &lua_pushthread;

        // stack functions
        s_luaops._lua_absindex          = &lua_absindex;
        s_luaops._lua_gettop            = &lua_gettop;
        s_luaops._lua_settop            = &lua_settop;
        s_luaops._lua_pushvalue         = &lua_pushvalue;
        s_luaops._lua_rotate            = &lua_rotate;
        s_luaops._lua_copy              = &lua_copy;
        s_luaops._lua_checkstack        = &lua_checkstack;
        s_luaops._lua_xmove             = &lua_xmove;

        // luaL functions
        s_luaops._luaL_setfuncs         = &luaL_setfuncs;
        s_luaops._luaL_error            = &luaL_error;
        s_luaops._luaL_argerror         = &luaL_argerror;
        s_luaops._luaL_checkinteger     = &luaL_checkinteger;
        s_luaops._luaL_checkoption      = &luaL_checkoption;
        s_luaops_inited                 = tb_true;
    }
    xmisetup_func(&s_luaops);

    // load module
    lua_pushcfunction(lua, luaopen_func);
    return 1;
}