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
 * @file        case.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "case"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <wctype.h>
#ifdef TB_CONFIG_OS_WINDOWS
#   include <windows.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * helper
 */
static tb_int_t xm_string_case(lua_State* lua, tb_bool_t lower) {

    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the string
    size_t           size = 0;
    tb_char_t const* str  = luaL_checklstring(lua, 1, &size);
    tb_check_return_val(str, 0);

    // empty?
    if (!size) {
        lua_pushstring(lua, "");
        return 1;
    }

    // convert to wchar
    tb_size_t   wn = size + 1;
    tb_wchar_t* wb = tb_nalloc_type(wn, tb_wchar_t);
    if (wb) {
        wn = tb_mbstowcs(wb, str, wn);
        if (wn != -1) {
            
            // to case
#ifdef TB_CONFIG_OS_WINDOWS
            if (lower) CharLowerBuffW((LPWSTR)wb, (DWORD)wn);
            else CharUpperBuffW((LPWSTR)wb, (DWORD)wn);
#else
            tb_size_t i = 0;
            for (i = 0; i < wn; i++) {
                wb[i] = lower? towlower(wb[i]) : towupper(wb[i]);
            }
#endif

            // convert to utf8
            tb_size_t   un = (wn + 1) * 4;
            tb_char_t*  ub = (tb_char_t*)tb_malloc_bytes(un);
            if (ub) {
                tb_size_t n = tb_wcstombs(ub, wb, un);
                if (n != -1) {
                    lua_pushlstring(lua, ub, n);
                } else {
                    lua_pushlstring(lua, str, size);
                }
                tb_free(ub);
            } else {
                lua_pushlstring(lua, str, size);
            }
        } else {
            lua_pushlstring(lua, str, size);
        }
        tb_free(wb);
    } else {
        lua_pushlstring(lua, str, size);
    }
    
    // ok
    return 1;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_string_lower(lua_State* lua) {
    return xm_string_case(lua, tb_true);
}

tb_int_t xm_string_upper(lua_State* lua) {
    return xm_string_case(lua, tb_false);
}
