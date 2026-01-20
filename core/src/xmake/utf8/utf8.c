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
    if (c < 0x80) 
        res = c;
    else {
        tb_int_t count = 0; 
        for (; c & 0x40; c <<= 1) { 
            tb_uint32_t cc = (tb_byte_t)s[++count]; 
            if (!xm_utf8_iscont(cc)) 
                return tb_null; 
            res = (res << 6) | (cc & 0x3F); 
        }
        res |= ((xm_utf8_int_t)(c & 0x7F) << (count * 5)); 
        if (count > 5 || res > XM_UTF8_MAXUTF || res < limits[count])
            return tb_null; 
        s += count; 
    }
    if (strict) {
        if (res > XM_UTF8_MAXUNICODE || (0xD800u <= res && res <= 0xDFFFu))
            return tb_null;
    }
    if (val) *val = res;
    return s + 1; 
}

tb_size_t xm_utf8_encode(tb_char_t* s, xm_utf8_int_t val) {
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

tb_long_t xm_utf8_len_impl(tb_char_t const* s, tb_size_t len, tb_long_t posi, tb_long_t posj, tb_bool_t strict, tb_size_t* errpos) {
    tb_long_t n = 0;
    while (posi <= posj) {
        tb_char_t const* s1 = xm_utf8_decode(s + posi - 1, tb_null, strict);
        if (s1 == tb_null) {
            if (errpos) *errpos = posi;
            return -1;
        }
        posi = s1 - s + 1;
        n++;
    }
    return n;
}

tb_long_t xm_utf8_offset_impl(tb_char_t const* s, tb_size_t len, tb_long_t n, tb_long_t posi) {
    // check
    if (1 > posi || --posi > (tb_long_t)len) 
        return -1; // error: position out of bounds

    if (n == 0) {
        // find beginning of current byte sequence
        while (posi > 0 && xm_utf8_iscontp(s + posi)) posi--;
    } else {
        if (xm_utf8_iscontp(s + posi))
            return -2; // error: initial position is a continuation byte
        
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

    if (n == 0) return posi + 1;
    return 0; // nil
}

tb_bool_t xm_utf8_codepoint_impl(tb_char_t const* s, tb_size_t len, tb_long_t posi, tb_long_t posj, tb_bool_t strict, xm_utf8_codepoint_func_t func, tb_cpointer_t udata) {
    if (posi > posj) return tb_true; 
    
    tb_char_t const* se = s + posj;
    for (s += posi - 1; s < se;) {
        xm_utf8_int_t code;
        s = xm_utf8_decode(s, &code, strict);
        if (s == tb_null) return tb_false;
        if (func && !func(code, udata)) return tb_false;
    }
    return tb_true;
}
