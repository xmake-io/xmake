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
        s_luaops._lua_createtable       = &lua_createtable;
        s_luaops._lua_gettop            = &lua_gettop;
        s_luaops._lua_type              = &lua_type;

        // to functions
        s_luaops._lua_tointegerx        = &lua_tointegerx;
        s_luaops._lua_toboolean         = &lua_toboolean;
        s_luaops._lua_touserdata        = &lua_touserdata;

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
