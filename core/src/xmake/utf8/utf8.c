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
 * @file        utf8.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "utf8.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_char_t const* xm_utf8_decode(tb_char_t const* s, xm_utf8_int_t* val, tb_bool_t strict) {
    static const xm_utf8_int_t limits[] = {~(xm_utf8_int_t)0, 0x80, 0x800, 0x10000u, 0x200000u, 0x4000000u};
    tb_uint32_t c = (tb_byte_t)s[0];
    xm_utf8_int_t res = 0; 
    if (c < 0x80) {
        res = c;
    } else {
        if (xm_utf8_iscont(c)) {
            return tb_null;
        }
        tb_int_t count = 0; 
        for (; c & 0x40; c <<= 1) { 
            tb_uint32_t cc = (tb_byte_t)s[++count]; 
            if (!xm_utf8_iscont(cc)) {
                return tb_null; 
            }
            res = (res << 6) | (cc & 0x3F); 
        }
        res |= ((xm_utf8_int_t)(c & 0x7F) << (count * 5)); 
        if (count > 5 || res > XM_UTF8_MAXUTF || res < limits[count]) {
            return tb_null; 
        }
        s += count; 
    }
    if (strict) {
        if (res > XM_UTF8_MAXUNICODE || (0xD800u <= res && res <= 0xDFFFu)) {
            return tb_null;
        }
    }
    if (val) {
        *val = res;
    }
    return s + 1; 
}

tb_size_t xm_utf8_encode(tb_char_t* s, xm_utf8_int_t val) {
    tb_assert_and_check_return_val(s, 0);

    if (val < 0x80) {
        s[0] = (tb_char_t)val;
        return 1;
    }
    if (val < 0x800) {
        s[0] = (tb_char_t)(0xc0 | ((val >> 6) & 0x1f));
        s[1] = (tb_char_t)(0x80 | (val & 0x3f));
        return 2;
    }
    if (val < 0x10000) {
        s[0] = (tb_char_t)(0xe0 | ((val >> 12) & 0x0f));
        s[1] = (tb_char_t)(0x80 | ((val >> 6) & 0x3f));
        s[2] = (tb_char_t)(0x80 | (val & 0x3f));
        return 3;
    }
    if (val <= 0x10FFFF) {
        s[0] = (tb_char_t)(0xf0 | ((val >> 18) & 0x07));
        s[1] = (tb_char_t)(0x80 | ((val >> 12) & 0x3f));
        s[2] = (tb_char_t)(0x80 | ((val >> 6) & 0x3f));
        s[3] = (tb_char_t)(0x80 | (val & 0x3f));
        return 4;
    }
    if (val <= 0x3FFFFFF) {
        s[0] = (tb_char_t)(0xf8 | ((val >> 24) & 0x03));
        s[1] = (tb_char_t)(0x80 | ((val >> 18) & 0x3f));
        s[2] = (tb_char_t)(0x80 | ((val >> 12) & 0x3f));
        s[3] = (tb_char_t)(0x80 | ((val >> 6) & 0x3f));
        s[4] = (tb_char_t)(0x80 | (val & 0x3f));
        return 5;
    }
    if (val <= 0x7FFFFFFF) {
        s[0] = (tb_char_t)(0xfc | ((val >> 30) & 0x01));
        s[1] = (tb_char_t)(0x80 | ((val >> 24) & 0x3f));
        s[2] = (tb_char_t)(0x80 | ((val >> 18) & 0x3f));
        s[3] = (tb_char_t)(0x80 | ((val >> 12) & 0x3f));
        s[4] = (tb_char_t)(0x80 | ((val >> 6) & 0x3f));
        s[5] = (tb_char_t)(0x80 | (val & 0x3f));
        return 6;
    }
    return 0;
}

tb_long_t xm_utf8_charpos(tb_char_t const* s, tb_size_t len, tb_long_t byte_pos) {
    if (byte_pos <= 0) return 0;
    if (byte_pos > len + 1) byte_pos = len + 1;

    // adjust byte_pos to the start of the character
    // 
    // performance: 
    // 0(1) complexity, because utf8 sequence is max 4 bytes
    while (byte_pos > 1 && xm_utf8_iscont(s[byte_pos - 1])) {
        byte_pos--;
    }
    
    // get character position
    tb_long_t count = xm_utf8_len_impl(s, len, 1, byte_pos - 1, tb_true, tb_null);
    return count >= 0? count + 1 : -1;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation interfaces
 */
static struct { xm_utf8_int_t first; xm_utf8_int_t last; } const g_non_spacing[] = 
{
    {0x0300, 0x036F},   {0x0483, 0x0486},   {0x0488, 0x0489},
    {0x0591, 0x05BD},   {0x05BF, 0x05BF},   {0x05C1, 0x05C2},
    {0x05C4, 0x05C5},   {0x05C7, 0x05C7},   {0x0600, 0x0603},
    {0x0610, 0x0615},   {0x064B, 0x065E},   {0x0670, 0x0670},
    {0x06D6, 0x06E4},   {0x06E7, 0x06E8},   {0x06EA, 0x06ED},
    {0x070F, 0x070F},   {0x0711, 0x0711},   {0x0730, 0x074A},
    {0x07A6, 0x07B0},   {0x07EB, 0x07F3},   {0x0901, 0x0902},
    {0x093C, 0x093C},   {0x0941, 0x0948},   {0x094D, 0x094D},
    {0x0951, 0x0954},   {0x0962, 0x0963},   {0x0981, 0x0981},
    {0x09BC, 0x09BC},   {0x09C1, 0x09C4},   {0x09CD, 0x09CD},
    {0x09E2, 0x09E3},   {0x0A01, 0x0A02},   {0x0A3C, 0x0A3C},
    {0x0A41, 0x0A42},   {0x0A47, 0x0A48},   {0x0A4B, 0x0A4D},
    {0x0A70, 0x0A71},   {0x0A81, 0x0A82},   {0x0ABC, 0x0ABC},
    {0x0AC1, 0x0AC5},   {0x0AC7, 0x0AC8},   {0x0ACD, 0x0ACD},
    {0x0AE2, 0x0AE3},   {0x0B01, 0x0B01},   {0x0B3C, 0x0B3C},
    {0x0B3F, 0x0B3F},   {0x0B41, 0x0B43},   {0x0B4D, 0x0B4D},
    {0x0B56, 0x0B56},   {0x0B82, 0x0B82},   {0x0BC0, 0x0BC0},
    {0x0BCD, 0x0BCD},   {0x0C3E, 0x0C40},   {0x0C46, 0x0C48},
    {0x0C4A, 0x0C4D},   {0x0C55, 0x0C56},   {0x0CBC, 0x0CBC},
    {0x0CBF, 0x0CBF},   {0x0CC6, 0x0CC6},   {0x0CCC, 0x0CCD},
    {0x0CE2, 0x0CE3},   {0x0D41, 0x0D43},   {0x0D4D, 0x0D4D},
    {0x0DCA, 0x0DCA},   {0x0DD2, 0x0DD4},   {0x0DD6, 0x0DD6},
    {0x0E31, 0x0E31},   {0x0E34, 0x0E3A},   {0x0E47, 0x0E4E},
    {0x0EB1, 0x0EB1},   {0x0EB4, 0x0EB9},   {0x0EBB, 0x0EBC},
    {0x0EC8, 0x0ECD},   {0x0F18, 0x0F19},   {0x0F35, 0x0F35},
    {0x0F37, 0x0F37},   {0x0F39, 0x0F39},   {0x0F71, 0x0F7E},
    {0x0F80, 0x0F84},   {0x0F86, 0x0F87},   {0x0F90, 0x0F97},
    {0x0F99, 0x0FBC},   {0x0FC6, 0x0FC6},   {0x102D, 0x1030},
    {0x1032, 0x1032},   {0x1036, 0x1037},   {0x1039, 0x1039},
    {0x1058, 0x1059},   {0x1160, 0x11FF},   {0x135F, 0x135F},
    {0x1712, 0x1714},   {0x1732, 0x1734},   {0x1752, 0x1753},
    {0x1772, 0x1773},   {0x17B4, 0x17B5},   {0x17B7, 0x17BD},
    {0x17C6, 0x17C6},   {0x17C9, 0x17D3},   {0x17DD, 0x17DD},
    {0x180B, 0x180D},   {0x18A9, 0x18A9},   {0x1920, 0x1922},
    {0x1927, 0x1928},   {0x1932, 0x1932},   {0x1939, 0x193B},
    {0x1A17, 0x1A18},   {0x1B00, 0x1B03},   {0x1B34, 0x1B34},
    {0x1B36, 0x1B3A},   {0x1B3C, 0x1B3C},   {0x1B42, 0x1B42},
    {0x1B6B, 0x1B73},   {0x1DC0, 0x1DCA},   {0x1DFE, 0x1DFF},
    {0x200B, 0x200F},   {0x202A, 0x202E},   {0x2060, 0x2063},
    {0x206A, 0x206F},   {0x20D0, 0x20EF},   {0x302A, 0x302F},
    {0x3099, 0x309A},   {0xA806, 0xA806},   {0xA80B, 0xA80B},
    {0xA825, 0xA826},   {0xFB1E, 0xFB1E},   {0xFE00, 0xFE0F},
    {0xFE20, 0xFE23},   {0xFEFF, 0xFEFF},   {0xFFF9, 0xFFFB},
    {0x10A01, 0x10A03}, {0x10A05, 0x10A06}, {0x10A0C, 0x10A0F},
    {0x10A38, 0x10A3A}, {0x10A3F, 0x10A3F}, {0x1D167, 0x1D169},
    {0x1D173, 0x1D182}, {0x1D185, 0x1D18B}, {0x1D1AA, 0x1D1AD},
    {0x1D242, 0x1D244}, {0xE0001, 0xE0001}, {0xE0020, 0xE007F},
    {0xE0100, 0xE01EF}
};

tb_long_t xm_utf8_charwidth(xm_utf8_int_t val) {

    // test for 8-bit control characters
    if (val == 0) return 0;
    if (val < 32 || (val >= 0x7f && val < 0xa0)) {
        if (val == 0x09) return 4; // TAB
        if (val == 0x08) return -1; // BS
        return 0; // other control chars
    }

    // binary search in table of non-spacing characters
    tb_long_t min = 0;
    tb_long_t max = tb_arrayn(g_non_spacing) - 1;
    if (val >= g_non_spacing[0].first && val <= g_non_spacing[max].last) {
        while (max >= min) {
            tb_long_t mid = (min + max) / 2;
            if (val > g_non_spacing[mid].last) {
                min = mid + 1;
            } else if (val < g_non_spacing[mid].first) {
                max = mid - 1;
            } else {
                return 0;
            }
        }
    }

    if  (val >= 0x1100 && (val <= 0x115f ||  // Hangul Jamo init. consonants
        val == 0x2329 || val == 0x232a ||
        (val >= 0x2e80 && val <= 0xa4cf &&
        val != 0x303f) ||                    // CJK ... Yi
        (val >= 0xac00 && val <= 0xd7a3) ||  // Hangul Syllables
        (val >= 0xf900 && val <= 0xfaff) ||  // CJK Compatibility Ideographs
        (val >= 0xfe10 && val <= 0xfe19) ||  // Vertical forms
        (val >= 0xfe30 && val <= 0xfe6f) ||  // CJK Compatibility Forms
        (val >= 0xff00 && val <= 0xff60) ||  // Fullwidth Forms
        (val >= 0xffe0 && val <= 0xffe6) ||
        (val >= 0x20000 && val <= 0x2fffd) ||
        (val >= 0x30000 && val <= 0x3fffd))) {
        return 2;
    }

    return 1;
}

tb_long_t xm_utf8_strwidth(tb_char_t const* s, tb_size_t len) {
    tb_assert_and_check_return_val(s, -1);
    
    tb_long_t width = 0;
    tb_char_t const* p = s;
    tb_char_t const* e = s + len;
    while (p < e) {
        xm_utf8_int_t val;
        tb_char_t const* next = xm_utf8_decode(p, &val, tb_true);
        if (next) {
            tb_long_t w = xm_utf8_charwidth(val);
            if (w < 0) return -1;
            width += w;
            p = next;
        } else {
            p++; // invalid byte, skip
        }
    }
    return width;
}

tb_long_t xm_utf8_len_impl(tb_char_t const* s, tb_size_t len, tb_long_t posi, tb_long_t posj, tb_bool_t strict, tb_size_t* errpos) {
    tb_assert_and_check_return_val(s, -1);

    tb_long_t n = 0;
    while (posi <= posj) {
        tb_char_t const* s1 = xm_utf8_decode(s + posi - 1, tb_null, strict);
        if (s1 == tb_null) {
            if (errpos) {
                *errpos = posi;
            }
            return -1;
        }
        posi = s1 - s + 1;
        n++;
    }
    return n;
}

tb_long_t xm_utf8_offset_impl(tb_char_t const* s, tb_size_t len, tb_long_t n, tb_long_t posi) {
    tb_assert_and_check_return_val(s, -1);

    // check
    if (1 > posi || --posi > (tb_long_t)len) {
        return -1; // error: position out of bounds
    }

    if (n == 0) {
        // find beginning of current byte sequence
        while (posi > 0 && xm_utf8_iscontp(s + posi)) {
            posi--;
        }
    } else {
        if (xm_utf8_iscontp(s + posi)) {
            return -2; // error: initial position is a continuation byte
        }
        
        if (n < 0) {
            while (n < 0 && posi > 0) {
                do {
                    posi--;
                } while (posi > 0 && xm_utf8_iscontp(s + posi));
                n++;
            }
        } else {
            n--;
            while (n > 0 && posi < (tb_long_t)len) {
                do {
                    posi++;
                } while (xm_utf8_iscontp(s + posi));
                n--;
            }
        }
    }

    if (n == 0) {
        return posi + 1;
    }
    return 0; // nil
}

tb_bool_t xm_utf8_codepoint_impl(tb_char_t const* s, tb_size_t len, tb_long_t posi, tb_long_t posj, tb_bool_t strict, xm_utf8_codepoint_func_t func, tb_cpointer_t udata) {
    tb_assert_and_check_return_val(s, tb_false);

    if (posi > posj) {
        return tb_true; 
    }
    
    tb_char_t const* se = s + posj;
    for (s += posi - 1; s < se;) {
        xm_utf8_int_t code;
        s = xm_utf8_decode(s, &code, strict);
        if (s == tb_null) {
            return tb_false;
        }
        if (func && !func(code, udata)) {
            return tb_false;
        }
    }
    return tb_true;
}

tb_long_t xm_utf8_find_impl(tb_char_t const* s, tb_size_t len, tb_char_t const* sub, tb_size_t sublen, tb_long_t init, tb_long_t* pchar_end) {
    tb_assert_and_check_return_val(s && sub, 0);

    if (sublen == 0) {
        if (init > (tb_long_t)len + 1) init = len + 1;
        
        tb_long_t start_byte = 1;
        if (init > 0) {
            start_byte = xm_utf8_offset_impl(s, len, init, 1);
        } else if (init < 0) {
            start_byte = xm_utf8_offset_impl(s, len, init, len + 1);
        }
        if (start_byte <= 0) start_byte = 1; 
        
        tb_long_t char_pos = 1;
        if (start_byte > 1) {
            tb_long_t c = xm_utf8_len_impl(s, len, 1, start_byte - 1, tb_true, tb_null);
            if (c >= 0) char_pos = c + 1;
        }
        
        if (pchar_end) *pchar_end = char_pos - 1;
        return char_pos;
    }

    tb_long_t start_byte = 1;
    if (init > 0) {
        start_byte = xm_utf8_offset_impl(s, len, init, 1);
    } else if (init < 0) {
        start_byte = xm_utf8_offset_impl(s, len, init, len + 1);
    }
    if (start_byte <= 0) return 0; 

    tb_char_t const* p = tb_strstr(s + start_byte - 1, sub);
    if (!p) return 0;

    tb_long_t found_byte_start = p - s + 1;

    tb_long_t char_start = 1;
    if (found_byte_start > 1) {
        tb_long_t c = xm_utf8_len_impl(s, len, 1, found_byte_start - 1, tb_true, tb_null);
        if (c < 0) return 0; 
        char_start = c + 1;
    }

    if (pchar_end) {
        tb_long_t match_len = xm_utf8_len_impl(s, len, found_byte_start, found_byte_start + sublen - 1, tb_true, tb_null);
        if (match_len < 0) return 0;
        *pchar_end = char_start + match_len - 1;
    }

    return char_start;
}

tb_long_t xm_utf8_lastof_impl(tb_char_t const* s, tb_size_t len, tb_char_t const* sub, tb_size_t sublen) {
    tb_assert_and_check_return_val(s && sub, 0);

    if (sublen == 0) return 0;

    tb_char_t const* p = s;
    tb_char_t const* last = tb_null;
    
    while (1) {
        p = tb_strstr(p, sub);
        if (!p) break;
        last = p;
        p += 1; 
    }

    if (last) {
        return (tb_long_t)(last - s + 1);
    }
    return 0;
}

tb_long_t xm_utf8_byte_impl(tb_char_t const* s, tb_size_t len, tb_long_t i, tb_long_t j, xm_utf8_codepoint_func_t func, tb_cpointer_t udata) {
    tb_size_t sublen = 0;
    tb_char_t const* sub = xm_utf8_sub_impl(s, len, i, j, &sublen);
    if (sub && sublen > 0) {
        
        // decode and push codepoints
        tb_long_t n = 0;
        tb_char_t const* p = sub;
        tb_char_t const* e = sub + sublen;
        while (p < e) {
            xm_utf8_int_t val;
            tb_char_t const* next = xm_utf8_decode(p, &val, tb_true);
            if (next) {
                if (func && !func(val, udata)) break;
                n++;
                p = next;
            } else {
                p++; 
            }
        }
        return n;
    }
    return 0;
}

tb_char_t const* xm_utf8_sub_impl(tb_char_t const* s, tb_size_t len, tb_long_t i, tb_long_t j, tb_size_t* psublen) {
    tb_assert_and_check_return_val(s && psublen, tb_null);
    *psublen = 0;

    // map i (char index) to byte offset
    tb_long_t start_byte = 0;
    if (i > 0) {
        start_byte = xm_utf8_offset_impl(s, len, i, 1);
    } else if (i < 0) {
        start_byte = xm_utf8_offset_impl(s, len, i, len + 1);
    } else {
        start_byte = 1;
    }

    if (start_byte == -1) {
        if (i > 0) {
            return ""; 
        } else {
            start_byte = 1;
        }
    } else if (start_byte == 0) {
        if (i < 0) {
            start_byte = 1;
        } else {
            return ""; 
        }
    }

    // map j (char index) to byte offset (end)
    tb_long_t end_byte = 0;
    if (j >= 0) {
        end_byte = xm_utf8_offset_impl(s, len, j + 1, 1);
    } else {
        end_byte = xm_utf8_offset_impl(s, len, j + 1, len + 1);
    }

    if (end_byte == -1) {
        if (j >= 0) end_byte = len + 1;
        else end_byte = 1;
    } else if (end_byte == 0) {
         if (j >= 0) end_byte = len + 1;
         else end_byte = 1;
    }

    if (end_byte <= start_byte) {
        return "";
    }

    *psublen = end_byte - start_byte;
    return s + start_byte - 1;
}

tb_char_t* xm_utf8_reverse_impl(tb_char_t const* s, tb_size_t len, tb_char_t* buf) {
    tb_assert_and_check_return_val(s && len && buf, tb_null);

    tb_char_t const* p = s;
    tb_char_t const* e = s + len;
    tb_char_t* d = buf + len;

    while (p < e) {
        xm_utf8_int_t code;
        tb_char_t const* next = xm_utf8_decode(p, &code, tb_false);
        
        // invalid utf8? treat as 1 byte
        tb_size_t n = 1;
        if (next) {
            n = next - p;
        }
        
        // safety check
        if (p + n > e) n = e - p;

        d -= n;
        tb_memcpy(d, p, n);
        p += n;
    }
    buf[len] = '\0';
    return buf;
}

