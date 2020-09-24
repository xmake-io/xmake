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
// the RegGetValueA func type
typedef BOOL (WINAPI* xm_RegGetValueA_t)(HKEY hkey, LPCSTR lpSubKey, LPCSTR lpValue, DWORD dwFlags, LPDWORD pdwType, PVOID pvData, LPDWORD pcbData);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* query registry
 *
 * local value, errors = winos.registry_query("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug;Debugger")
 */
tb_int_t xm_winos_registry_query(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the path
    tb_char_t const* path = luaL_checkstring(lua, 1);
    tb_check_return_val(path, 0);

    // query key-value
    tb_bool_t   ok = tb_false;
    HKEY        key = NULL;
    HKEY        keynew = NULL;
    tb_char_t   pathbuf[TB_PATH_MAXN];
    tb_char_t*  value = tb_null;
    do
    {
        // copy path
        tb_size_t size = tb_strlcpy(pathbuf, path, sizeof(pathbuf));
        if (size >= sizeof(pathbuf))
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "too long path: %s", path);
            break;
        }

        // parse path key and subkey
        tb_char_t* pathkey      = tb_null;
        tb_char_t* pathsubkey   = tb_null;
        tb_char_t* p            = pathbuf;
        for (; *p && *p != '\\'; p++) ;
        if (*p == '\\')
        {
            *p = '\0';
            pathkey = pathbuf;
            pathsubkey = p + 1;
        }
        if (!pathkey || !pathsubkey)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "parse pathkey and pathsubkey failed: %s", path);
            break;
        }

        // parse value name
        tb_char_t* valuename = tb_null;
        for (p = pathbuf + size - 1; p >= pathbuf && *p && *p != ';'; p--) ;
        if (p >= pathbuf && *p == ';')
        {
            valuename = p + 1;
            *p = '\0';
        }

        // trace
        tb_trace_d("key: %s, subkey: %s, name: %s", pathkey, pathsubkey, valuename? valuename : "(default)");

        // get registry key
        if (!tb_strcmp(pathkey, "HKEY_CLASSES_ROOT"))         key = HKEY_CLASSES_ROOT;
        else if (!tb_strcmp(pathkey, "HKEY_CURRENT_CONFIG"))  key = HKEY_CURRENT_CONFIG;
        else if (!tb_strcmp(pathkey, "HKEY_CURRENT_USER"))    key = HKEY_CURRENT_USER;
        else if (!tb_strcmp(pathkey, "HKEY_LOCAL_MACHINE"))   key = HKEY_LOCAL_MACHINE;
        else if (!tb_strcmp(pathkey, "HKEY_USERS"))           key = HKEY_USERS;
        else
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "invalid registry path: %s", path);
            break;
        }

        // attempt to load RegGetValueA
        static xm_RegGetValueA_t s_RegGetValueA = tb_null;
        if (!s_RegGetValueA)
        {
            // load the advapi32 module
            tb_dynamic_ref_t module = (tb_dynamic_ref_t)GetModuleHandleA("advapi32.dll");
            if (!module) module = tb_dynamic_init("advapi32.dll");
            if (module) s_RegGetValueA = (xm_RegGetValueA_t)tb_dynamic_func(module, "RegGetValueA");
        }

        // get registry value
        DWORD type = 0;
        if (s_RegGetValueA)
        {
            // get registry value size
            DWORD valuesize = 0;
            if (s_RegGetValueA(key, pathsubkey, valuename, RRF_RT_ANY, 0, tb_null, &valuesize) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry value size failed: %s", path);
                break;
            }

            // make value buffer
            value = (tb_char_t*)tb_malloc0(valuesize + 1);
            tb_assert_and_check_break(value);

            // get value result
            type = 0;
            if (s_RegGetValueA(key, pathsubkey, valuename, RRF_RT_ANY, &type, (PVOID)value, &valuesize) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry value failed: %s", path);
                break;
            }
        }
        else
        {
            // open registry key
            if (RegOpenKeyExA(key, pathsubkey, 0, KEY_QUERY_VALUE, &keynew) != ERROR_SUCCESS && keynew)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "open registry key failed: %s", path);
                break;
            }

            // get registry value size
            DWORD valuesize = 0;
            if (RegQueryValueExA(keynew, valuename, tb_null, tb_null, tb_null, &valuesize) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry value size failed: %s", path);
                break;
            }

            // make value buffer
            value = (tb_char_t*)tb_malloc0(valuesize + 1);
            tb_assert_and_check_break(value);

            // get value result
            type = 0;
            if (RegQueryValueExA(keynew, valuename, tb_null, &type, (LPBYTE)value, &valuesize) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry value failed: %s", path);
                break;
            }
        }

        // save result
        switch (type)
        {
        case REG_SZ:
        case REG_EXPAND_SZ:
            lua_pushstring(lua, value);
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
    if (keynew != NULL)
        RegCloseKey(keynew);
    keynew = NULL;

    // exit value
    if (value) tb_free(value);
    value = tb_null;

    // ok?
    return ok? 1 : 2;
}
