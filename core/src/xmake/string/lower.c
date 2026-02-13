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
 * @author      luadebug, ruki
 * @file        lower.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#   include <wctype.h>

static __tb_inline__ tb_bool_t tb_unicode_tolower_try(tb_uint32_t ch, tb_uint32_t* out)
{
    // builtin, locale-independent case mapping for some common unicode ranges:
    // - Basic Latin (ASCII)
    // - Latin-1 Supplement (partial)
    // - Latin Extended-A (partial)
    // - Greek (partial)
    // - Cyrillic (partial)
    if (sizeof(tb_wchar_t) == 2 && ch >= 0xd800 && ch <= 0xdfff) return tb_false;

    // Basic Latin (ASCII)
    if (ch <= 0x7f)
    {
        tb_trace_i("basic: %x", ch);
        *out = tb_tolower(ch);
        return tb_true;
    }

    // Latin-1 Supplement: U+00C0..U+00D6, U+00D8..U+00DE
    if ((ch >= 0x00c0 && ch <= 0x00d6) || (ch >= 0x00d8 && ch <= 0x00de)) { *out = ch + 0x20; return tb_true; }
    // Latin-1 Supplement: U+00E0..U+00F6, U+00F8..U+00FE
    if ((ch >= 0x00e0 && ch <= 0x00f6) || (ch >= 0x00f8 && ch <= 0x00fe)) { *out = ch; return tb_true; }

    // Latin-1 Supplement: U+0178 <-> U+00FF
    if (ch == 0x0178) { *out = 0x00ff; return tb_true; }
    if (ch == 0x00ff) { *out = ch; return tb_true; }

    // Latin Extended Additional: U+1E9E <-> U+00DF
    if (ch == 0x1e9e) { *out = 0x00df; return tb_true; }
    if (ch == 0x00df) { *out = ch; return tb_true; }

    // Latin Extended-A: many letters have alternating upper/lower code points
    if (ch >= 0x0100 && ch <= 0x012f) { *out = (ch & 0x1) ? ch : (ch + 1); return tb_true; }
    if (ch >= 0x0132 && ch <= 0x0137) { *out = (ch & 0x1) ? ch : (ch + 1); return tb_true; }
    if (ch >= 0x0139 && ch <= 0x0148) { *out = (ch & 0x1) ? (ch + 1) : ch; return tb_true; }
    if (ch >= 0x014a && ch <= 0x0177) { *out = (ch & 0x1) ? ch : (ch + 1); return tb_true; }
    if (ch >= 0x0179 && ch <= 0x017e) { *out = (ch & 0x1) ? (ch + 1) : ch; return tb_true; }
    // Latin Extended-A: long s (already lowercase)
    if (ch == 0x017f) { *out = ch; return tb_true; }

    // Greek and Coptic (partial): U+0391..U+03A1, U+03A3..U+03AB
    if ((ch >= 0x0391 && ch <= 0x03a1) || (ch >= 0x03a3 && ch <= 0x03ab)) { *out = ch + 0x20; return tb_true; }
    // Greek and Coptic (partial): U+03B1..U+03C1, U+03C3..U+03CB, and U+03C2
    if ((ch >= 0x03b1 && ch <= 0x03c1) || (ch >= 0x03c3 && ch <= 0x03cb) || ch == 0x03c2) { *out = ch; return tb_true; }

    // Cyrillic (partial): U+0401/U+0451 and U+0410..U+042F
    if (ch == 0x0401) { *out = 0x0451; return tb_true; }
    if (ch == 0x0451) { *out = ch; return tb_true; }
    if (ch >= 0x0402 && ch <= 0x040f) { *out = ch + 0x50; return tb_true; }
    if (ch >= 0x0452 && ch <= 0x045f) { *out = ch; return tb_true; }
    if (ch >= 0x0410 && ch <= 0x042f) { *out = ch + 0x20; return tb_true; }

    if (ch >= 0x0430 && ch <= 0x044f) {
        *out = ch;
        return tb_true;
    }

    return tb_false;
}

tb_wchar_t tb_towlower_test(tb_wchar_t c)
{
    tb_trace_i("towlower: %x, wchar: %d", (tb_uint32_t)c, sizeof(tb_wchar_t));
    tb_uint32_t ch = tb_bits_wchar_to_u32_le(c);
    tb_uint32_t out;
    if (__tb_likely__(tb_unicode_tolower_try(ch, &out))) {
        tb_trace_i("towlower: out: %x", out);
        return tb_bits_u32_le_to_wchar(out);
    }

    tb_trace_i("towlower xxx: %x", (tb_uint32_t)c);
    return (tb_wchar_t)towlower((tb_uint32_t)c);
}

static tb_wchar_t* tb_wcslwr_test(tb_wchar_t* s)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // set local locale
    tb_setlocale();

    tb_wchar_t* p = s;
    while (*p)
    {
        *p = tb_towlower_test(*p);
        p++;
    }

    // set default locale
    tb_resetlocale();

    return s;
}

static tb_size_t tb_mbstowcs_charset(tb_wchar_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);

    // init
    tb_size_t e = (sizeof(tb_wchar_t) == 4) ? TB_CHARSET_TYPE_UTF32 : TB_CHARSET_TYPE_UTF16;
    tb_long_t r = tb_charset_conv_cstr(TB_CHARSET_TYPE_UTF8, e | TB_CHARSET_TYPE_LE, s2,
                             (tb_byte_t*)s1, n * sizeof(tb_wchar_t));
    if (r > 0) r /= sizeof(tb_wchar_t);

    // strip
    if (r >= 0) s1[r] = L'\0';

    tb_trace_i("tb_mbstowcs_charset: %ld", r);
    // ok?
    return r >= 0 ? r : -1;
}

static tb_long_t tb_charset_utf8_tolower_test(tb_char_t* s, tb_size_t n)
{
    tb_assert_and_check_return_val(s, -1);

    tb_trace_i("s: %s: %d", s, n);

    // try ascii tolower first
    tb_char_t* p = s;
    tb_char_t* e = s + n;
    while (p < e && *p)
    {
        if ((*p) & 0x80) {
            break;
        }
        tb_trace_i("old: %c -> %x", *p);
        *p = tb_tolower(*p);
        tb_trace_i("new: %c -> %x", *p);
        p++;
    }
    tb_trace_i("test: %d %d", p == e, !*p);

    if (p == e || !*p) return p - s;

    // convert the suffix to wchar_t
    tb_long_t   r = -1;
    tb_size_t   wn = e - p + 1;
    tb_wchar_t  wb[256];
    tb_wchar_t* w = (wn <= 256)? wb : (tb_wchar_t*)tb_malloc(wn * sizeof(tb_wchar_t));
    if (w)
    {
    tb_trace_i("tb_mbstowcs 111");
        if (tb_mbstowcs_charset(w, p, wn) != -1)
        {
    tb_trace_i("tb_wcslwr_test 111");
            tb_wcslwr_test(w);
            r = tb_wcstombs(p, w, wn);
            if (r != -1) r += (p - s);
        }

    tb_trace_i("tb_free 111");
        if (w != wb) tb_free(w);
    }
    return r;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* string.lower
 *
 * @param str       the string
 *
 * @code
 *      local result = string.lower(str)
 * @endcode
 */
tb_int_t xm_string_lower(lua_State *lua) {
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get string
    size_t           size = 0;
    tb_char_t const* cstr = luaL_checklstring(lua, 1, &size);
    tb_check_return_val(cstr, 0);

    // empty?
    if (!size) {
        lua_pushstring(lua, "");
        return 1;
    }

    // copy string to buffer
    tb_char_t* buffer = (tb_char_t*)tb_malloc_bytes(size + 1);
    if (buffer) {
        tb_memcpy(buffer, cstr, size);
        buffer[size] = '\0';

        // to lower
        tb_long_t real_size = tb_charset_utf8_tolower_test(buffer, size);

        // push result
        if (real_size >= 0) {
            lua_pushlstring(lua, buffer, real_size);
        } else {
            lua_pushlstring(lua, cstr, size);
        }
        tb_free(buffer);
    } else {
        lua_pushnil(lua);
    }
    return 1;
}
