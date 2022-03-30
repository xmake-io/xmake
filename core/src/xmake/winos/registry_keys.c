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
 * types
 */

// the enum info type
typedef struct __xm_winos_registry_enum_info_t
{
    lua_State*          lua;
    HKEY                key;
    tb_int_t            ok;
    tb_char_t const*    error;
    tb_int_t            count;
    tb_wchar_t          key_name[1024];
    tb_char_t           key_path_a[TB_PATH_MAXN];

}xm_winos_registry_enum_info_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_winos_registry_enum_keys(xm_winos_registry_enum_info_t* info, tb_wchar_t const* rootdir, tb_long_t recursion)
{
    // enum keys
    HKEY        keynew = tb_null;
    lua_State*  lua = info->lua;
    tb_wchar_t* key_path = tb_null;
    tb_size_t   key_path_maxn = TB_PATH_MAXN;
    do
    {
        // open registry key
        if (RegOpenKeyExW(info->key, rootdir, 0, KEY_READ, &keynew) != ERROR_SUCCESS && keynew)
        {
            info->ok = -1;
            info->error = "open registry key failed";
            break;
        }

        // query keys
        DWORD key_name_num = 0;
        DWORD key_name_maxn = 0;
        if (RegQueryInfoKeyW(keynew, tb_null, tb_null, tb_null, &key_name_num, &key_name_maxn, tb_null, tb_null, tb_null, tb_null, tb_null, tb_null) != ERROR_SUCCESS)
        {
            // cannot query this key, we ignore it
            break;
        }
        key_name_maxn++; // add `\0`

        // ensure enough key path buffer
        if (key_name_maxn > tb_arrayn(info->key_name))
        {
            info->ok = -1;
            info->error = "no enough key path buffer";
            break;
        }

        // init key path
        key_path = (tb_wchar_t*)tb_malloc(key_path_maxn * sizeof(tb_wchar_t));
        if (!key_path)
        {
            info->ok = -1;
            info->error = "no enough key path buffer";
            break;
        }

        // get all keys
        DWORD i = 0;
        for (i = 0; i < key_name_num && info->ok > 0; i++)
        {
            // get key name
            info->key_name[0] = L'\0';
            DWORD key_name_size = tb_arrayn(info->key_name);
            if (RegEnumKeyExW(keynew, i, info->key_name, &key_name_size, tb_null, tb_null, tb_null, tb_null) != ERROR_SUCCESS)
            {
                info->ok = -1;
                info->error = "get registry key failed";
                break;
            }

            // get key path
            tb_swprintf(key_path, key_path_maxn, L"%s\\%s", rootdir, info->key_name);

            // get key path (mbs)
            tb_size_t key_path_a_size = tb_wtoa(info->key_path_a, key_path, sizeof(info->key_path_a));
            if (key_path_a_size == -1)
            {
                info->ok = -1;
                info->error = "convert registry key path failed";
                break;
            }

            // do callback(key_name)
            lua_pushvalue(lua, 4);
            lua_pushlstring(lua, info->key_path_a, key_path_a_size);
            lua_call(lua, 1, 1);
            info->count++;

            // is continue?
            tb_bool_t is_continue = lua_toboolean(lua, -1);
            lua_pop(lua, 1);
            if (!is_continue)
            {
                info->ok = 0;
                break;
            }

            // enum all subkeys
            if (recursion > 0 || recursion < 0)
                xm_winos_registry_enum_keys(info, key_path, recursion > 0? recursion - 1 : recursion);
        }

    } while (0);

    // exit registry key
    if (keynew)
        RegCloseKey(keynew);
    keynew = tb_null;

    // free key path
    if (key_path) tb_free(key_path);
    key_path = tb_null;
}

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
    tb_long_t recursion      = (tb_long_t)lua_tointeger(lua, 3);
    tb_bool_t is_function    = lua_isfunction(lua, 4);
    tb_check_return_val(rootkey && rootdir && is_function, 0);

    // enum keys
    tb_bool_t   ok = tb_false;
    tb_int_t    count = 0;
    HKEY        key = tb_null;
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

        // do enum
        tb_wchar_t rootdir_w[TB_PATH_MAXN];
        if (tb_atow(rootdir_w, rootdir, TB_PATH_MAXN) == -1)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "rootdir is too long: %s", rootdir);
            break;
        }
        xm_winos_registry_enum_info_t info;
        info.lua   = lua;
        info.key   = key;
        info.count = 0;
        info.ok    = tb_true;
        info.error = tb_null;
        xm_winos_registry_enum_keys(&info, rootdir_w, recursion);
        count = info.count;
        ok    = info.ok >= 0;
        if (!ok)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "%s: %s\\%s", info.error? info.error : "enum registry keys failed", rootkey, rootdir);
        }

    } while (0);

    // ok?
    if (ok)
    {
        lua_pushinteger(lua, count);
        return 1;
    }
    else return 2;
}

