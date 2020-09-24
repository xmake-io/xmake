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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        convert.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "convert"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the charset entry type
typedef struct __xm_charset_entry_t
{
    // the charset type
    tb_size_t           type;

    // the charset name
    tb_char_t const*    name;

}xm_charset_entry_t, *xm_charset_entry_ref_t;

// the charsets, @note: type & name is sorted
static xm_charset_entry_t g_charsets[] =
{
    {TB_CHARSET_TYPE_ANSI,                          "ansi"    }
,   {TB_CHARSET_TYPE_ASCII,                         "ascii"   }
,   {TB_CHARSET_TYPE_GB2312,                        "gb2312"  }
,   {TB_CHARSET_TYPE_GBK,                           "gbk"     }
,   {TB_CHARSET_TYPE_ISO8859,                       "iso8859" }
,   {TB_CHARSET_TYPE_UCS2  | TB_CHARSET_TYPE_NE,    "ucs2"    }
,   {TB_CHARSET_TYPE_UCS4  | TB_CHARSET_TYPE_NE,    "ucs4"    }
,   {TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_NE,    "utf16"   }
,   {TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_BE,    "utf16be" }
,   {TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_LE,    "utf16le" }
,   {TB_CHARSET_TYPE_UTF32 | TB_CHARSET_TYPE_NE,    "utf32"   }
,   {TB_CHARSET_TYPE_UTF32 | TB_CHARSET_TYPE_BE,    "utf32be" }
,   {TB_CHARSET_TYPE_UTF32 | TB_CHARSET_TYPE_LE,    "utf32le" }
,   {TB_CHARSET_TYPE_UTF8,                          "utf8"    }
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * finder
 */
static tb_long_t xm_string_charset_comp_by_name(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t name)
{
    return tb_stricmp(((xm_charset_entry_ref_t)item)->name, (tb_char_t const*)name);
}
static xm_charset_entry_ref_t xm_string_charset_find_by_name(tb_char_t const* name)
{
    // make iterator
    tb_array_iterator_t array_iterator;
    tb_iterator_ref_t   iterator = tb_array_iterator_init_mem(&array_iterator, g_charsets, tb_arrayn(g_charsets), sizeof(xm_charset_entry_t));
    tb_assert_and_check_return_val(iterator, tb_null);

    // find it by the binary search
    tb_size_t itor = tb_binary_find_all_if(iterator, xm_string_charset_comp_by_name, name);
    if (itor != tb_iterator_tail(iterator))
        return (xm_charset_entry_ref_t)tb_iterator_item(iterator, itor);
    else return tb_null;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* convert string
 *
 * @param str       the string
 * @param ftype     the from-charset type, e.g. ascii, gb2312, gbk, ios8859, ucs2, ucs4, utf8, utf16, utf32
 * @param ttype     the to-charset type
 *
 * @code
 *      local result = string.convert(str, "gbk", "utf8")
 *      local result = string.convert(str, "utf8", "gb2312")
 * @endcode
 */
tb_int_t xm_string_convert(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the string and charset types
    size_t           src_size   = 0;
    tb_char_t const* src_cstr   = luaL_checklstring(lua, 1, &src_size);
    tb_char_t const* ftype_cstr = luaL_checkstring(lua, 2);
    tb_char_t const* ttype_cstr = luaL_checkstring(lua, 3);
    tb_check_return_val(src_cstr && ftype_cstr && ttype_cstr, 0);

    // find charsets
    xm_charset_entry_ref_t fcharset = xm_string_charset_find_by_name(ftype_cstr);
    xm_charset_entry_ref_t tcharset = xm_string_charset_find_by_name(ttype_cstr);
    luaL_argcheck(lua, fcharset, 2, "charset not found");
    luaL_argcheck(lua, tcharset, 3, "charset not found");
    tb_check_return_val(fcharset && tcharset, 0);

    // empty string?
    if (!src_size) lua_pushstring(lua, "");
    else
    {
        // convert string
        tb_long_t   dst_size = 0;
        tb_size_t   dst_maxn = (tb_size_t)src_size << 2;
        tb_byte_t*  dst_data = tb_malloc_bytes(dst_maxn);
        if (dst_data && dst_maxn && (dst_size = tb_charset_conv_data(fcharset->type, tcharset->type, (tb_byte_t const*)src_cstr, (tb_size_t)src_size, dst_data, dst_maxn)) >= 0 && dst_size < dst_maxn)
        {
            lua_pushlstring(lua, (tb_char_t const *)dst_data, dst_size);
        }
        else lua_pushnil(lua);
        tb_free(dst_data);
    }

    // ok
    return 1;
}
