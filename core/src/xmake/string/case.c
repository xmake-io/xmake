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
#include "tbox/libc/stdlib/setlocale.h"
/* Include Tbox platform header for spinlocks if not already in prefix.h */
#include "tbox/platform/spinlock.h" 

#ifdef TB_CONFIG_OS_WINDOWS
#   include <windows.h>
#else
#   include <locale.h>
#   if TB_CONFIG_OS_MACOS || TB_CONFIG_OS_IOS || TB_CONFIG_OS_BSD
#       include <xlocale.h>
#   endif
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
            locale_t new_loc = (locale_t)0;
            locale_t old_loc = (locale_t)0;

            // Create a temporary UTF-8 locale object
            // LC_CTYPE_MASK: We only care about character classification/case
            new_loc = newlocale(LC_CTYPE_MASK, "UTF-8", (locale_t)0);
            if (!new_loc) {
                // Fallback if system calls it en_US.UTF-8
                new_loc = newlocale(LC_CTYPE_MASK, "en_US.UTF-8", (locale_t)0);
            }

            // Switch thread locale (No global lock needed!)
            if (new_loc) {
                old_loc = uselocale(new_loc);
            }

            // Convert
            tb_size_t i = 0;
            for (i = 0; i < wn; i++) {
                wb[i] = lower? towlower(wb[i]) : towupper(wb[i]);
            }

            // Restore thread locale and free object
            if (new_loc) {
                uselocale(old_loc);
                freelocale(new_loc);
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
