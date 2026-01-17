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
#include "../utils/charset.h"
#include <wctype.h>
#include <utf8proc.h>

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

    // convert string
    tb_size_t  dst_maxn = (tb_size_t)(size + 1) * 4;
    tb_byte_t* dst_data = tb_malloc_bytes(dst_maxn);
    if (dst_data) {
        tb_byte_t*       p = dst_data;
        tb_byte_t const* s = (tb_byte_t const*)str;
        tb_byte_t const* e = s + size;
        while (s < e) {
            utf8proc_int32_t codepoint;
            utf8proc_ssize_t len = utf8proc_iterate((utf8proc_uint8_t const*)s, e - s, &codepoint);
            if (len > 0) {
                if (lower) codepoint = utf8proc_tolower(codepoint);
                else       codepoint = utf8proc_toupper(codepoint);
                utf8proc_ssize_t wlen = utf8proc_encode_char(codepoint, (utf8proc_uint8_t*)p);
                if (wlen > 0) p += wlen;
                s += len;
            } else {
                *p++ = *s++;
            }
        }
        lua_pushlstring(lua, (tb_char_t const*)dst_data, p - dst_data);
        tb_free(dst_data);
    } else {
        lua_pushnil(lua);
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
