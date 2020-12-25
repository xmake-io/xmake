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
 * @file        registry_values.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "registry_values"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* get registry values
 *
 * local value, errors = winos.registry_values("HKEY_LOCAL_MACHINE", "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug", "Debug*")
 */
tb_int_t xm_winos_registry_values(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the arguments
    tb_char_t const* rootkey = luaL_checkstring(lua, 1);
    tb_char_t const* rootdir = luaL_checkstring(lua, 2);
    tb_char_t const* pattern = luaL_checkstring(lua, 3);
    tb_check_return_val(rootkey && rootdir && pattern, 0);

    // query key-value
    tb_bool_t   ok = tb_false;
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

        // get registry value
        DWORD type = 0;

        // open registry key
        if (RegOpenKeyExA(key, rootdir, 0, KEY_QUERY_VALUE, &keynew) != ERROR_SUCCESS && keynew)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "open registry key failed: %s\\%s", rootkey, rootdir);
            break;
        }

        // get registry value size
        DWORD valuesize = 0;
        if (RegQueryValueExA(keynew, pattern, tb_null, tb_null, tb_null, &valuesize) != ERROR_SUCCESS)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "get registry value size failed: %s\\%s;%s", rootkey, rootdir, pattern);
            break;
        }

        // make value buffer
        value = (tb_char_t*)tb_malloc0(valuesize + 1);
        tb_assert_and_check_break(value);

        // get value result
        type = 0;
        if (RegQueryValueExA(keynew, pattern, tb_null, &type, (LPBYTE)value, &valuesize) != ERROR_SUCCESS)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "get registry value failed: %s\\%s;%s", rootkey, rootdir, pattern);
            break;
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
    if (keynew)
        RegCloseKey(keynew);
    keynew = tb_null;

    // exit value
    if (value) tb_free(value);
    value = tb_null;

    // ok?
    return ok? 1 : 2;
}
