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
#ifdef XMI_USE_LUAJIT
        s_luaops._lua_newuserdata       = &lua_newuserdata;
#else
        s_luaops._lua_getglobal         = &lua_getglobal;
        s_luaops._lua_geti              = &lua_geti;
        s_luaops._lua_rawgetp           = &lua_rawgetp;
        s_luaops._lua_getiuservalue     = &lua_getiuservalue;
        s_luaops._lua_newuserdatauv     = &lua_newuserdatauv;
#endif
        s_luaops._lua_gettable          = &lua_gettable;
        s_luaops._lua_getfield          = &lua_getfield;
        s_luaops._lua_rawget            = &lua_rawget;
        s_luaops._lua_rawgeti           = &lua_rawgeti;
        s_luaops._lua_createtable       = &lua_createtable;
        s_luaops._lua_getmetatable      = &lua_getmetatable;

        // set functions
#ifndef XMI_USE_LUAJIT
        s_luaops._lua_setglobal         = &lua_setglobal;
        s_luaops._lua_seti              = &lua_seti;
        s_luaops._lua_rawsetp           = &lua_rawsetp;
        s_luaops._lua_setiuservalue     = &lua_setiuservalue;
#endif
        s_luaops._lua_settable          = &lua_settable;
        s_luaops._lua_setfield          = &lua_setfield;
        s_luaops._lua_rawset            = &lua_rawset;
        s_luaops._lua_rawseti           = &lua_rawseti;
        s_luaops._lua_setmetatable      = &lua_setmetatable;

        // access functions
        s_luaops._lua_isnumber          = &lua_isnumber;
        s_luaops._lua_isstring          = &lua_isstring;
        s_luaops._lua_iscfunction       = &lua_iscfunction;
        s_luaops._lua_isuserdata        = &lua_isuserdata;
        s_luaops._lua_type              = &lua_type;
        s_luaops._lua_typename          = &lua_typename;
#ifndef XMI_USE_LUAJIT
        s_luaops._lua_isinteger         = &lua_isinteger;
#endif

        s_luaops._lua_tonumberx         = &lua_tonumberx;
        s_luaops._lua_tointegerx        = &lua_tointegerx;
        s_luaops._lua_toboolean         = &lua_toboolean;
        s_luaops._lua_tolstring         = &lua_tolstring;
        s_luaops._lua_tocfunction       = &lua_tocfunction;
        s_luaops._lua_touserdata        = &lua_touserdata;
        s_luaops._lua_tothread          = &lua_tothread;
        s_luaops._lua_topointer         = &lua_topointer;
#ifndef XMI_USE_LUAJIT
        s_luaops._lua_rawlen            = &lua_rawlen;
#endif

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
#ifdef XMI_USE_LUAJIT
        s_luaops._lua_insert            = &lua_insert;
        s_luaops._lua_remove            = &lua_remove;
        s_luaops._lua_replace           = &lua_replace;
#else
        s_luaops._lua_absindex          = &lua_absindex;
        s_luaops._lua_rotate            = &lua_rotate;
#endif
        s_luaops._lua_gettop            = &lua_gettop;
        s_luaops._lua_settop            = &lua_settop;
        s_luaops._lua_pushvalue         = &lua_pushvalue;
        s_luaops._lua_copy              = &lua_copy;
        s_luaops._lua_checkstack        = &lua_checkstack;
        s_luaops._lua_xmove             = &lua_xmove;

        // miscellaneous functions
        s_luaops._lua_error             = &lua_error;
        s_luaops._lua_next              = &lua_next;
        s_luaops._lua_concat            = &lua_concat;
        s_luaops._lua_getallocf         = &lua_getallocf;
        s_luaops._lua_setallocf         = &lua_setallocf;
#ifndef XMI_USE_LUAJIT
        s_luaops._lua_len               = &lua_len;
        s_luaops._lua_toclose           = &lua_toclose;
        s_luaops._lua_closeslot         = &lua_closeslot;
        s_luaops._lua_stringtonumber    = &lua_stringtonumber;
#endif

        // 'load' and 'call' functions
#ifdef XMI_USE_LUAJIT
        s_luaops._lua_call              = &lua_call;
        s_luaops._lua_pcall             = &lua_pcall;
#else
        s_luaops._lua_callk             = &lua_callk;
        s_luaops._lua_pcallk            = &lua_pcallk;
#endif
        s_luaops._lua_load              = &lua_load;
        s_luaops._lua_dump              = &lua_dump;

        // luaL functions
#ifndef XMI_USE_LUAJIT
        s_luaops._luaL_tolstring        = &luaL_tolstring;
        s_luaops._luaL_typeerror        = &luaL_typeerror;
#endif
        s_luaops._luaL_getmetafield     = &luaL_getmetafield;
        s_luaops._luaL_callmeta         = &luaL_callmeta;
        s_luaops._luaL_argerror         = &luaL_argerror;
        s_luaops._luaL_checklstring     = &luaL_checklstring;
        s_luaops._luaL_optlstring       = &luaL_optlstring;
        s_luaops._luaL_checknumber      = &luaL_checknumber;
        s_luaops._luaL_optnumber        = &luaL_optnumber;
        s_luaops._luaL_checkinteger     = &luaL_checkinteger;
        s_luaops._luaL_optinteger       = &luaL_optinteger;
        s_luaops._luaL_checkstack       = &luaL_checkstack;
        s_luaops._luaL_checktype        = &luaL_checktype;
        s_luaops._luaL_checkany         = &luaL_checkany;
        s_luaops._luaL_newmetatable     = &luaL_newmetatable;
        s_luaops._luaL_testudata        = &luaL_testudata;
        s_luaops._luaL_checkudata       = &luaL_checkudata;
        s_luaops._luaL_where            = &luaL_where;
        s_luaops._luaL_error            = &luaL_error;
        s_luaops._luaL_checkoption      = &luaL_checkoption;
        s_luaops._luaL_fileresult       = &luaL_fileresult;
        s_luaops._luaL_execresult       = &luaL_execresult;
        s_luaops._luaL_setfuncs         = &luaL_setfuncs;
        s_luaops._luaL_loadfilex        = &luaL_loadfilex;
        s_luaops._luaL_loadstring       = &luaL_loadstring;

        s_luaops_inited                 = tb_true;
    }
    xmisetup_func(&s_luaops);

    // load module
    lua_pushcfunction(lua, luaopen_func);
    return 1;
}
