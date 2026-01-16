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

    // find charsets
    xm_charset_entry_ref_t fcharset = xm_charset_find_by_name("utf8");
#if defined(TB_CONFIG_OS_WINDOWS)
    xm_charset_entry_ref_t tcharset = xm_charset_find_by_name("utf16");
#else
    xm_charset_entry_ref_t tcharset = xm_charset_find_by_name("utf32");
#endif
    tb_check_return_val(fcharset && tcharset, 0);

    // convert string
    tb_long_t  dst_size = 0;
    tb_size_t  dst_maxn = (tb_size_t)(size + 1) * 4;
    tb_byte_t* dst_data = tb_malloc_bytes(dst_maxn);
    if (dst_data && dst_maxn &&
        (dst_size = tb_charset_conv_data(fcharset->type, tcharset->type, (tb_byte_t const*)str, (tb_size_t)size, dst_data, dst_maxn)) >= 0 &&
        dst_size < dst_maxn) {

        // to lower/upper
#if defined(TB_CONFIG_OS_WINDOWS)
        tb_uint16_t* p = (tb_uint16_t*)dst_data;
        tb_size_t    n = (tb_size_t)dst_size / 2;
#else
        tb_uint32_t* p = (tb_uint32_t*)dst_data;
        tb_size_t    n = (tb_size_t)dst_size / 4;
#endif
        while (n--) {
            *p = (tb_wchar_t)(lower? towlower((wint_t)*p) : towupper((wint_t)*p));
            p++;
        }

        // convert string back
        tb_long_t  res_size = 0;
        tb_size_t  res_maxn = dst_maxn * 2;
        tb_byte_t* res_data = tb_malloc_bytes(res_maxn);
        if (res_data && res_maxn &&
            (res_size = tb_charset_conv_data(tcharset->type, fcharset->type, dst_data, (tb_size_t)dst_size, res_data, res_maxn)) >= 0 &&
            res_size < res_maxn) {
            lua_pushlstring(lua, (tb_char_t const*)res_data, res_size);
        } else {
            lua_pushnil(lua);
        }
        if (res_data) tb_free(res_data);
    } else {
        lua_pushnil(lua);
    }
    
    // free data
    if (dst_data) tb_free(dst_data);

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
