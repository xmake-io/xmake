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
 * @file        registry_keys.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "registry_keys"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* get registry keys
 *
 * local count, errors = winos.registry_keys("HKEY_LOCAL_MACHINE",
 *                                             "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug",
 *                                             function (key_path)
 *                                                 return true -- continue or break
 *                                             end)
 */
tb_int_t xm_winos_registry_keys(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the arguments
    tb_char_t const* rootkey = luaL_checkstring(lua, 1);
    tb_char_t const* rootdir = luaL_checkstring(lua, 2);
    tb_bool_t is_function    = lua_isfunction(lua, 3);
    tb_check_return_val(rootkey && rootdir && is_function, 0);

    // query key-value
    tb_bool_t   ok = tb_false;
    tb_int_t    count = 0;
    HKEY        key = tb_null;
    HKEY        keynew = tb_null;
    tb_char_t*  value = tb_null;
    do
    {
        // get registry rootkey
        if (!tb_strcmp(rootkey, "HKEY_CLASSES_ROOT"))         key = HKEY_CLASSES_ROOT;
        else if (!tb_strcmp(rootkey, "HKEY_CURRENT_CONFIG"))  key = HKEY_CURRENT_CONFIG;
        else if (!tb_strcmp(rootkey, "HKEY_CURRENT_USER"))    key = HKEY_CURRENT_USER;
        else if (!tb_strcmp(rootkey, "HKEY_LOCAL_MACHINE"))   key = HKEY_LOCAL_MACHINE;
        else if (!tb_strcmp(rootkey, "HKEY_USERS"))           key = HKEY_USERS;
        else
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "invalid registry rootkey: %s", rootkey);
            break;
        }

        // open registry key
        if (RegOpenKeyExA(key, rootdir, 0, KEY_READ, &keynew) != ERROR_SUCCESS && keynew)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "open registry key failed: %s\\%s", rootkey, rootdir);
            break;
        }

        // query keys
        DWORD key_path_num = 0;
        DWORD key_path_maxn = 0;
        if (RegQueryInfoKeyW(keynew, tb_null, tb_null, tb_null, &key_path_num, &key_path_maxn, tb_null, tb_null, tb_null, tb_null, tb_null, tb_null) != ERROR_SUCCESS)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "query registry info failed: %s\\%s", rootkey, rootdir);
            break;
        }
        key_path_maxn++; // add `\0`

        // ensure enough key path buffer
        tb_wchar_t key_path[TB_PATH_MAXN];
        if (key_path_maxn > tb_arrayn(key_path))
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "no enough key path buffer: %s\\%s", rootkey, rootdir);
            break;
        }

        // get all keys
        DWORD i = 0;
        tb_char_t key_path_a[TB_PATH_MAXN];
        for (i = 0; i < key_path_num; i++)
        {
            // get key path
            key_path[0] = L'\0';
            DWORD key_path_size = tb_arrayn(key_path);
            if (RegEnumKeyExW(keynew, i, key_path, &key_path_size, tb_null, tb_null, tb_null, tb_null) != ERROR_SUCCESS)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "get registry key path(%d) failed: %s\\%s", i, rootkey, rootdir);
                break;
            }

            // get key path (mbs)
            tb_size_t key_path_a_size = tb_wtoa(key_path_a, key_path, sizeof(key_path_a));
            if (key_path_a_size == -1)
            {
                lua_pushnil(lua);
                lua_pushfstring(lua, "convert registry key path(%d) failed: %s\\%s", i, rootkey, rootdir);
                break;
            }

            // do callback(key_path)
            lua_pushvalue(lua, 3);
            lua_pushlstring(lua, key_path_a, key_path_a_size);
            lua_call(lua, 1, 1);
            count++;

            // is continue?
            tb_bool_t is_continue = lua_toboolean(lua, -1);
            lua_pop(lua, 1);
            if (!is_continue)
            {
                ok = tb_true;
                break;
            }
        }

        // ok
        if (i == key_path_num)
            ok = tb_true;

    } while (0);

    // exit registry key
    if (keynew)
        RegCloseKey(keynew);
    keynew = tb_null;

    // ok?
    if (ok)
    {
        lua_pushinteger(lua, count);
        return 1;
    }
    else return 2;
}

