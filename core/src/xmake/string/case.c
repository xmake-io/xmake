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

#ifdef TB_CONFIG_OS_WINDOWS
#   include <windows.h>
#else
#   include <wctype.h>
#   include <locale.h>
#   if defined(__APPLE__) || defined(__FreeBSD__) || defined(__DragonFly__)
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

    tb_bool_t   ok = tb_false;
    tb_size_t   wn = size + 1;
    tb_wchar_t* wb = tb_nalloc_type(wn, tb_wchar_t);

    if (wb) {
        // Convert input UTF-8 to Wide Char
        wn = tb_mbstowcs(wb, str, wn);
        if (wn != -1) {
            
            // Perform Case Conversion
#ifdef TB_CONFIG_OS_WINDOWS
            // Windows API is naturally thread-safe for this operation
            if (lower) CharLowerBuffW((LPWSTR)wb, (DWORD)wn);
            else CharUpperBuffW((LPWSTR)wb, (DWORD)wn);
#else 
            // POSIX Thread-Safe Implementation
            // We strictly only convert if we can get a valid UTF-8 thread locale.
            // If newlocale fails, we skip conversion to avoid using an undefined global locale.
            locale_t new_loc = newlocale(LC_CTYPE_MASK, "UTF-8", (locale_t)0);
            if (!new_loc) {
                new_loc = newlocale(LC_CTYPE_MASK, "en_US.UTF-8", (locale_t)0);
            }

            if (new_loc) {
                locale_t old_loc = uselocale(new_loc);
                
                tb_size_t i = 0;
                for (i = 0; i < wn; i++) {
                    wb[i] = lower ? towlower(wb[i]) : towupper(wb[i]);
                }

                uselocale(old_loc);
                freelocale(new_loc);
            }
#endif

            // Convert Wide Char back to UTF-8
            tb_size_t   un = (wn + 1) * 4;
            tb_char_t*  ub = (tb_char_t*)tb_malloc_bytes(un);
            if (ub) {
                tb_size_t n = tb_wcstombs(ub, wb, un);
                if (n != -1) {
                    lua_pushlstring(lua, ub, n);
                    ok = tb_true;
                }
                tb_free(ub);
            }
        }
        tb_free(wb);
    }

    // Fallback: If memory allocation failed or conversion failed, return original string
    if (!ok) {
        lua_pushlstring(lua, str, size);
    }
    
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
