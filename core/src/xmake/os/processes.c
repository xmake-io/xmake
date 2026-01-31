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
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        processes.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "processes"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_WINDOWS
#include <windows.h>
#include <tlhelp32.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_int_t xm_winos_processes(lua_State* lua) {
#ifdef TB_CONFIG_OS_WINDOWS
    // init result table
    lua_newtable(lua);

    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnapshot != INVALID_HANDLE_VALUE) {
        PROCESSENTRY32W pe32;
        pe32.dwSize = sizeof(PROCESSENTRY32W);

        if (Process32FirstW(hSnapshot, &pe32)) {
            tb_int_t i = 1;
            do {
                // new process entry table
                lua_newtable(lua);

                // name
                tb_char_t name[MAX_PATH * 4];
                tb_size_t size = tb_charset_conv_data(TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_LE, TB_CHARSET_TYPE_UTF8, (tb_byte_t const*)pe32.szExeFile, tb_wcslen(pe32.szExeFile) * sizeof(tb_wchar_t), (tb_byte_t*)name, sizeof(name));
                if (size != -1) {
                    lua_pushlstring(lua, name, size);
                } else {
                    lua_pushstring(lua, "");
                }
                lua_setfield(lua, -2, "name");

                // pid
                lua_pushinteger(lua, (tb_int_t)pe32.th32ProcessID);
                lua_setfield(lua, -2, "pid");

                // ppid
                lua_pushinteger(lua, (tb_int_t)pe32.th32ParentProcessID);
                lua_setfield(lua, -2, "ppid");

                // result[i++] = entry
                lua_rawseti(lua, -2, i++);

            } while (Process32NextW(hSnapshot, &pe32));
        }
        CloseHandle(hSnapshot);
    }
    return 1;
#else
    return 0;
#endif
}
