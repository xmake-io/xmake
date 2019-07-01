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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      OpportunityLiu
 * @file        ansi.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "ansi"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "ansi.h"
#include <Windows.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

static tb_int_t xm_expand_cp(tb_int_t cp);

tb_int_t xm_winos_console_cp(lua_State* lua)
{
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
    tb_int_t    n  = lua_gettop(lua);
    lua_Integer cp = luaL_checkinteger(lua, 1);
    luaL_argcheck(lua, cp >= 0 && cp < 65536, 1, "invalid code page");
    CPINFOEX cp_info;
    luaL_argcheck(lua, GetCPInfoEx((tb_uint_t)cp, 0, &cp_info), 1, "invalid code page");

    lua_newtable(lua);

    lua_pushliteral(lua, "name");
    tb_char_t* namebuf = tb_malloc_cstr(sizeof(cp_info.CodePageName) * 2);
    xm_wcstoutf8(namebuf, cp_info.CodePageName, sizeof(cp_info.CodePageName) * 2);
    lua_pushstring(lua, namebuf);
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
    tb_uint_t cp = GetACP();
    lua_pushinteger(lua, (lua_Integer)cp);
    return 1;
}

tb_int_t xm_winos_oem_cp(lua_State* lua)
{
    tb_uint_t cp = GetOEMCP();
    lua_pushinteger(lua, (lua_Integer)cp);
    return 1;
}

tb_int_t xm_winos_mbstoutf8(lua_State* lua)
{
    tb_int_t n = lua_gettop(lua);
    if (n == 0)
    {
        return 0;
    }
    tb_int_t    cp    = 0;
    tb_int_t    r_len = 0;
    lua_Integer lcp   = luaL_optinteger(lua, 1, CP_ACP);
    luaL_argcheck(lua, cp >= 0 && cp < 65536, 1, "invalid code page");
    cp = (tb_int_t)lcp;
    for (tb_int_t i = 2; i <= n; i++)
    {
        tb_char_t const* mbs      = lua_tostring(lua, i);
        tb_size_t        utf8size = tb_strlen(mbs) * 4;
        tb_char_t*       utf8     = tb_malloc_cstr(utf8size);
        utf8size                  = xm_mbstoutf8(utf8, mbs, utf8size, cp);
        lua_pushlstring(lua, utf8, utf8size);
        tb_free(utf8);
        r_len++;
    }
    return r_len;
}

tb_size_t xm_wcstoutf8(tb_char_t* s1, tb_wchar_t const* s2, tb_size_t n)
{
    if (*s2 == 0)
    {
        if (n > 0) *s1 = 0;
        return 0;
    }
    tb_size_t size = (tb_size_t)WideCharToMultiByte(CP_UTF8, 0, s2, -1, s1, (tb_int_t)n, NULL, NULL);
    if (size > 0 && s1[size - 1] == 0) size--;
    return size;
}

tb_size_t xm_utf8towcs(tb_wchar_t* s1, tb_char_t const* s2, tb_size_t n)
{
    if (*s2 == 0)
    {
        if (n > 0) *s1 = 0;
        return 0;
    }
    tb_size_t size = (tb_size_t)MultiByteToWideChar(CP_UTF8, 0, s2, -1, s1, (tb_int_t)n);
    if (size > 0 && s1[size - 1] == 0) size--;
    return size;
}

tb_size_t xm_mbstoutf8(tb_char_t* s1, tb_char_t const* s2, tb_size_t n, tb_int_t mbs_cp)
{
    if (*s2 == 0)
    {
        if (n > 0) *s1 = 0;
        return 0;
    }
    tb_int_t    u16buflen = MultiByteToWideChar(mbs_cp, 0, s2, -1, NULL, 0);
    tb_wchar_t* u16buf    = tb_nalloc_type(u16buflen, tb_wchar_t);
    u16buflen             = MultiByteToWideChar(mbs_cp, 0, s2, -1, u16buf, u16buflen);
    tb_size_t size        = (tb_size_t)WideCharToMultiByte(CP_UTF8, 0, u16buf, u16buflen, s1, (tb_int_t)n, NULL, NULL);
    tb_free(u16buf);
    if (size > 0 && s1[size - 1] == 0) size--;
    return size;
}

tb_size_t xm_utf8tombs(tb_char_t* s1, tb_char_t const* s2, tb_size_t n, tb_int_t mbs_cp)
{
    if (*s2 == 0)
    {
        if (n > 0) *s1 = 0;
        return 0;
    }
    tb_int_t    u16buflen = MultiByteToWideChar(CP_UTF8, 0, s2, -1, NULL, 0);
    tb_wchar_t* u16buf    = tb_nalloc_type(u16buflen, tb_wchar_t);
    u16buflen             = MultiByteToWideChar(CP_UTF8, 0, s2, -1, u16buf, u16buflen);
    tb_size_t size        = (tb_size_t)WideCharToMultiByte(mbs_cp, 0, u16buf, u16buflen, s1, (tb_int_t)n, NULL, NULL);
    tb_free(u16buf);
    if (size > 0 && s1[size - 1] == 0) size--;
    return size;
}

static tb_int_t xm_expand_cp(tb_int_t cp)
{
    if (cp == CP_OEMCP) return GetOEMCP();
    if (cp == CP_ACP) return GetACP();
    return cp;
}
