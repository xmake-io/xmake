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
#include <ctype.h>

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
 * private implementation
 */

/* Check if string contains only ASCII characters (all bytes < 0x80)
 */
static tb_bool_t xm_string_is_ascii(tb_char_t const* str, tb_size_t size) {
    tb_size_t i;
    for (i = 0; i < size; i++) {
        if ((tb_byte_t)str[i] >= 0x80) {
            return tb_false;
        }
    }
    return tb_true;
}

/* Fast ASCII-only case conversion using tb_char_t
 * Returns tb_true on success, tb_false on failure
 */
static tb_bool_t xm_string_case_ascii(lua_State* lua, tb_char_t const* str, tb_size_t size, tb_bool_t lower) {
    tb_char_t* buf = (tb_char_t*)tb_malloc_bytes(size);
    if (!buf) {
        return tb_false;
    }

    tb_size_t i;
    for (i = 0; i < size; i++) {
        tb_byte_t c = (tb_byte_t)str[i];
        if (lower) {
            buf[i] = (tb_char_t)tolower(c);
        } else {
            buf[i] = (tb_char_t)toupper(c);
        }
    }

    lua_pushlstring(lua, buf, size);
    tb_free(buf);
    return tb_true;
}

/* Unicode case conversion using wide characters
 * Returns tb_true on success, tb_false on failure
 */
static tb_bool_t xm_string_case_unicode(lua_State* lua, tb_char_t const* str, tb_size_t size, tb_bool_t lower) {
    tb_bool_t   ok = tb_false;
    tb_size_t   wn = size + 1;
    tb_wchar_t* wb = tb_nalloc_type(wn, tb_wchar_t);

    if (!wb) {
        return tb_false;
    }

    // Convert input UTF-8 to Wide Char
    wn = tb_mbstowcs(wb, str, wn);
    if (wn == (tb_size_t)-1) {
        tb_free(wb);
        return tb_false;
    }

    // Perform Case Conversion
    tb_size_t i;
#ifdef TB_CONFIG_OS_WINDOWS
    // Windows Implementation
    for (i = 0; i < wn; i++) {
        tb_wchar_t wc = wb[i];
        if (lower) {
            if (!IsCharLowerW(wc)) {
                CharLowerBuffW(&wb[i], 1);
            }
        } else {
            if (!IsCharUpperW(wc)) {
                CharUpperBuffW(&wb[i], 1);
            }
        }
    }
#else
    // POSIX Thread-Safe Implementation
    locale_t new_loc = newlocale(LC_CTYPE_MASK, "en_US.UTF-8", (locale_t)0);
    if (!new_loc) {
        new_loc = newlocale(LC_CTYPE_MASK, "UTF-8", (locale_t)0);
    }

    if (new_loc) {
        locale_t old_loc = uselocale(new_loc);
        for (i = 0; i < wn; i++) {
            tb_wchar_t wc = wb[i];
            if (lower) {
                if (!iswlower(wc)) wb[i] = towlower(wc);
            } else {
                if (!iswupper(wc)) wb[i] = towupper(wc);
            }
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
        if (n != (tb_size_t)-1) {
            lua_pushlstring(lua, ub, n);
            ok = tb_true;
        }
        tb_free(ub);
    }

    tb_free(wb);
    return ok;
}

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

    tb_bool_t ok;

    // Fast path: ASCII-only strings don't need wide character conversion
    if (xm_string_is_ascii(str, size)) {
        ok = xm_string_case_ascii(lua, str, size, lower);
    } else {
        // Slow path: Unicode strings need wide character conversion
        ok = xm_string_case_unicode(lua, str, size, lower);
    }

    // Fallback: return original string if conversion failed
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
