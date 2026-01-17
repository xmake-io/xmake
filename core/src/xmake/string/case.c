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
#include <wctype.h>
#include <locale.h>
#include "tbox/platform/spinlock.h"

#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__DragonFly__)
#   include <xlocale.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/* Platforms that lack thread-safe uselocale() and must use setlocale() */
#if defined(TB_CONFIG_OS_WINDOWS) || defined(__NetBSD__)
#   include "tbox/libc/stdlib/setlocale.h"
#   define XM_USE_SETLOCALE
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

#ifdef XM_USE_SETLOCALE
/*
 * setlocale() is not thread-safe, so we protect it with a spinlock.
 */
static tb_spinlock_t g_locale_lock = TB_SPINLOCK_INIT;
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
            buf[i] = (tb_char_t)(isupper(c) ? tolower(c) : c);
        } else {
            buf[i] = (tb_char_t)(islower(c) ? toupper(c) : c);
        }
    }

    lua_pushlstring(lua, buf, size);
    tb_free(buf);
    return tb_true;
}

/* Perform wide character case conversion in-place
 */
static tb_void_t xm_wchar_convert_case(tb_wchar_t* wb, tb_size_t wn, tb_bool_t lower) {
    tb_size_t i;
    for (i = 0; i < wn; i++) {
        tb_wchar_t wc = wb[i];
        if (lower) {
            if (!iswlower(wc)) wb[i] = towlower(wc);
        } else {
            if (!iswupper(wc)) wb[i] = towupper(wc);
        }
    }
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
#ifdef XM_USE_SETLOCALE
    // Windows and NetBSD: Use setlocale (protected by spinlock)
    tb_spinlock_enter(&g_locale_lock);

    // Save current locale
    char*       saved_locale   = tb_null;
    char const* current_locale = setlocale(LC_CTYPE, tb_null);

    if (current_locale) {
        tb_size_t len = tb_strlen(current_locale);
        saved_locale = (char*)tb_malloc_bytes(len + 1);
        if (saved_locale) {
            tb_memcpy(saved_locale, current_locale, len + 1);
        }
    }

    // Force UTF-8 locale
    tb_setlocale();

    // Convert case
    xm_wchar_convert_case(wb, wn, lower);

    // Restore original locale
    if (saved_locale) {
        setlocale(LC_CTYPE, saved_locale);
        tb_free(saved_locale);
    }

    tb_spinlock_leave(&g_locale_lock);

#else
    // POSIX Thread-Safe Implementation (Linux/macOS/FreeBSD/DragonFly)
    locale_t new_loc = newlocale(LC_CTYPE_MASK, "en_US.UTF-8", (locale_t)0);
    if (!new_loc) {
        new_loc = newlocale(LC_CTYPE_MASK, "C.UTF-8", (locale_t)0);
    }
    if (!new_loc) {
        new_loc = newlocale(LC_CTYPE_MASK, "UTF-8", (locale_t)0);
    }

    if (new_loc) {
        locale_t old_loc = uselocale(new_loc);
        xm_wchar_convert_case(wb, wn, lower);
        uselocale(old_loc);
        freelocale(new_loc);
    } else {
        // Fallback: try without locale change
        xm_wchar_convert_case(wb, wn, lower);
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
