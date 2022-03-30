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
 * @author      TitanSnow, ruki
 * @file        registry_query.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "registry_query"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
// the RegGetValueW func type
typedef BOOL (WINAPI* xm_RegGetValueW_t)(HKEY hkey, LPCWSTR lpSubKey, LPCWSTR lpValue, DWORD dwFlags, LPDWORD pdwType, PVOID pvData, LPDWORD pcbData);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* query registry
 *
 * local value, errors = winos.registry_query("HKEY_LOCAL_MACHINE", "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug", "Debugger")
 */
tb_int_t xm_winos_registry_query(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the arguments
    tb_char_t const* rootkey   = luaL_checkstring(lua, 1);
    tb_char_t const* rootdir   = luaL_checkstring(lua, 2);
    tb_char_t const* valuename = luaL_checkstring(lua, 3);
    tb_check_return_val(rootkey && rootdir && valuename, 0);

    // query key-value
    tb_bool_t   ok = tb_false;
    HKEY        key = tb_null;
    HKEY        keynew = tb_null;
    tb_char_t*  value = tb_null;
    tb_wchar_t* value_w = tb_null;
    tb_size_t   value_n = (tb_size_t)-1;
    do
    {
        // get registry rootkey
        if (!tb_strcmp(rootkey, "HKEY_CLASSES_ROOT"))         key = HKEY_CLASSES_ROOT;
        else if (!tb_strcmp(rootkey, "HKCR"))                 key = HKEY_CLASSES_ROOT;
        else if (!tb_strcmp(rootkey, "HKEY_CURRENT_CONFIG"))  key = HKEY_CURRENT_CONFIG;
        else if (!tb_strcmp(rootkey, "HKCC"))                 key = HKEY_CURRENT_CONFIG;
        else if (!tb_strcmp(rootkey, "HKEY_CURRENT_USER"))    key = HKEY_CURRENT_USER;
        else if (!tb_strcmp(rootkey, "HKCU"))                 key = HKEY_CURRENT_USER;
        else if (!tb_strcmp(rootkey, "HKEY_LOCAL_MACHINE"))   key = HKEY_LOCAL_MACHINE;
        else if (!tb_strcmp(rootkey, "HKLM"))                 key = HKEY_LOCAL_MACHINE;
        else if (!tb_strcmp(rootkey, "HKEY_USERS"))           key = HKEY_USERS;
        else
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "invalid registry rootkey: %s", rootkey);
            break;
        }

        // convert rootdir to wide characters
        tb_wchar_t rootdir_w[TB_PATH_MAXN];
        if (tb_atow(rootdir_w, rootdir, TB_PATH_MAXN) == (tb_size_t)-1)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "invalid registry rootkey:: %s", rootdir);
            break;
        }

        // convert valuename to wide characters
        tb_wchar_t valuename_w[TB_PATH_MAXN];
        if (tb_atow(valuename_w, valuename, TB_PATH_MAXN) == (tb_size_t)-1)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "invalid registry valuename: %s", valuename);
            break;
        }

        // attempt to load RegGetValueW
        static xm_RegGetValueW_t s_RegGetValueW = tb_null;
        if (!s_RegGetValueW)
        {
            // load the advapi32 module
            tb_dynamic_ref_t module = (tb_dynamic_ref_t)GetModuleHandleA("advapi32.dll");
            if (!module) module = tb_dynamic_init("advapi32.dll");
            if (module) s_RegGetValueW = (xm_RegGetValueW_t)tb_dynamic_func(module, "RegGetValueW");
        }

        // get registry value
        DWORD type = 0;
        if (s_RegGetValueW)
        {
            // get registry value size
            DWORD valuesize_w = 0;
            if (s_RegGetValueW(key, rootdir_w, valuename_w, RRF_RT_ANY, 0, tb_null, &valuesize_w) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry value size failed: %s\\%s;%s", rootkey, rootdir, valuename);
                break;
            }

            // make value buffer
            DWORD valuesize = valuesize_w * 2;
            value = (tb_char_t*)tb_malloc0(valuesize);
            tb_assert_and_check_break(value);
            value_w = (tb_wchar_t*)tb_malloc0(valuesize_w);
            tb_assert_and_check_break(value_w);

            // get value result, we attempt to do not expand value if get failed
            type = 0;
            if (s_RegGetValueW(key, rootdir_w, valuename_w, RRF_RT_ANY, &type, (PVOID)value_w, &valuesize_w) != ERROR_SUCCESS &&
                s_RegGetValueW(key, rootdir_w, valuename_w, RRF_RT_ANY | RRF_NOEXPAND, &type, (PVOID)value_w, &valuesize_w) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry value failed: %s\\%s;%s", rootkey, rootdir, valuename);
                break;
            }
            
            value_n = tb_wtoa(value, value_w, valuesize);
            if (value_n == (tb_size_t)-1)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "wtoa registry value failed: %s\\%s;%s", rootkey, rootdir, valuename);
                break;
            }
        }
        else
        {
            // open registry key
            if (RegOpenKeyExW(key, rootdir_w, 0, KEY_QUERY_VALUE, &keynew) != ERROR_SUCCESS && keynew)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "open registry key failed: %s\\%s", rootkey, rootdir);
                break;
            }

            // get registry value size
            DWORD valuesize_w = 0;
            if (RegQueryValueExW(keynew, valuename_w, tb_null, tb_null, tb_null, &valuesize_w) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry value size failed: %s\\%s;%s", rootkey, rootdir, valuename);
                break;
            }

            // make value buffer
            DWORD valuesize = valuesize_w * 2;
            value = (tb_char_t*)tb_malloc0(valuesize);
            tb_assert_and_check_break(value);
            value_w = (tb_wchar_t*)tb_malloc0(valuesize_w);
            tb_assert_and_check_break(value_w);

            // get value result
            type = 0;
            if (RegQueryValueExW(keynew, valuename_w, tb_null, &type, (LPBYTE)value_w, &valuesize_w) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry value failed: %s\\%s;%s", rootkey, rootdir, valuename);
                break;
            }

            value_n = tb_wtoa(value, value_w, valuesize);
            if (value_n == (tb_size_t)-1)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "wtoa registry value failed: %s\\%s;%s", rootkey, rootdir, valuename);
                break;
            }
        }

        // save result
        switch (type)
        {
        case REG_SZ:
        case REG_EXPAND_SZ:
            lua_pushlstring(lua, value, value_n);
            ok = tb_true;
            break;
        case REG_DWORD:
            lua_pushfstring(lua, "%d", *((tb_int_t*)value));
            ok = tb_true;
            break;
        case REG_QWORD:
            lua_pushfstring(lua, "%lld", *((tb_int64_t*)value));
            ok = tb_true;
            break;
        default:
            lua_pushnil(lua);
            lua_pushfstring(lua, "unsupported registry value type: %d", type);
            break;
        }

    } while (0);

    // exit registry key
    if (keynew)
        RegCloseKey(keynew);
    keynew = tb_null;

    // exit value
    if (value) tb_free(value);
    value = tb_null;
    if (value_w) tb_free(value_w);
    value_w = tb_null;

    // ok?
    return ok? 1 : 2;
}
