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
 * @author      OpportunityLiu
 * @file        ansi.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "ansi"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "ansi.h"
#include <Windows.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

static tb_int_t xm_expand_cp(tb_int_t cp)
{
    // check
    tb_assert_and_check_return_val(cp >= 0 && cp <= 65535, 0);

    if (cp == CP_OEMCP) return GetOEMCP();
    if (cp == CP_ACP) return GetACP();
    return cp;
}

tb_int_t xm_winos_console_cp(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_int_t n = lua_gettop(lua);
    if (n >= 1)
    {
        lua_Integer cp = luaL_checkinteger(lua, 1);
        luaL_argcheck(lua, cp >= 0 && cp < 65536, 1, "invalid code page");
        cp = xm_expand_cp((tb_uint_t)cp);
        luaL_argcheck(lua, SetConsoleCP((tb_uint_t)cp), 1, "failed to set code page");
        lua_pushinteger(lua, cp);
        return 1;
    }
    else
    {
        tb_uint_t cp = GetConsoleCP();
        lua_pushinteger(lua, (lua_Integer)cp);
        return 1;
    }
}

tb_int_t xm_winos_console_output_cp(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_int_t n = lua_gettop(lua);
    if (n >= 1)
    {
        lua_Integer cp = luaL_checkinteger(lua, 1);
        luaL_argcheck(lua, cp >= 0 && cp < 65536, 1, "invalid code page");
        cp = xm_expand_cp((tb_uint_t)cp);
        luaL_argcheck(lua, SetConsoleOutputCP((tb_uint_t)cp), 1, "failed to set code page");
        lua_pushinteger(lua, cp);
        return 1;
    }
    else
    {
        tb_uint_t cp = GetConsoleOutputCP();
        lua_pushinteger(lua, (lua_Integer)cp);
        return 1;
    }
}

tb_int_t xm_winos_cp_info(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_int_t    n  = lua_gettop(lua);
    lua_Integer cp = luaL_checkinteger(lua, 1);
    luaL_argcheck(lua, cp >= 0 && cp < 65536, 1, "invalid code page");
    CPINFOEX cp_info;
    luaL_argcheck(lua, GetCPInfoEx((tb_uint_t)cp, 0, &cp_info), 1, "invalid code page");

    lua_newtable(lua);

    lua_pushliteral(lua, "name");
    tb_char_t* namebuf = tb_malloc_cstr(sizeof(cp_info.CodePageName) * 2);
    tb_assert_and_check_return_val(namebuf, 0);
    tb_size_t namelen = tb_wtoa(namebuf, cp_info.CodePageName, sizeof(cp_info.CodePageName) * 2);
    tb_assert_and_check_return_val(namelen < sizeof(cp_info.CodePageName) * 2, 0);
    lua_pushlstring(lua, namebuf, namelen);
    tb_free(namebuf);
    lua_settable(lua, -3);

    lua_pushliteral(lua, "max_char_size");
    lua_pushinteger(lua, (lua_Integer)cp_info.MaxCharSize);
    lua_settable(lua, -3);

    lua_pushliteral(lua, "id");
    lua_pushinteger(lua, (lua_Integer)cp_info.CodePage);
    lua_settable(lua, -3);

    lua_pushliteral(lua, "default_char");
    lua_pushstring(lua, (tb_char_t const*)cp_info.DefaultChar);
    lua_settable(lua, -3);

    lua_pushliteral(lua, "lead_byte");
    lua_createtable(lua, MAX_LEADBYTES / 2, 0);
    for (tb_size_t i = 0; i < MAX_LEADBYTES && cp_info.LeadByte[i] != 0 && cp_info.LeadByte[i + 1] != 0; i += 2)
    {
        lua_pushinteger(lua, (i / 2) + 1);
        lua_createtable(lua, 0, 2);

        lua_pushliteral(lua, "from");
        lua_pushinteger(lua, cp_info.LeadByte[i]);
        lua_settable(lua, -3);

        lua_pushliteral(lua, "to");
        lua_pushinteger(lua, cp_info.LeadByte[i + 1]);
        lua_settable(lua, -3);

        lua_settable(lua, -3);
    }
    lua_settable(lua, -3);

    return 1;
}

tb_int_t xm_winos_ansi_cp(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_uint_t cp = GetACP();
    lua_pushinteger(lua, (lua_Integer)cp);
    return 1;
}

tb_int_t xm_winos_oem_cp(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_uint_t cp = GetOEMCP();
    lua_pushinteger(lua, (lua_Integer)cp);
    return 1;
}

