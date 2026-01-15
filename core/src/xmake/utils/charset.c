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
 * @file        charset.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "charset"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "charset.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the charsets, @note: type & name is sorted
static xm_charset_entry_t g_charsets[] = {
    { TB_CHARSET_TYPE_ANSI, "ansi" },
    { TB_CHARSET_TYPE_ASCII, "ascii" },
    { TB_CHARSET_TYPE_GB2312, "gb2312" },
    { TB_CHARSET_TYPE_GBK, "gbk" },
    { TB_CHARSET_TYPE_ISO8859, "iso8859" },
    { TB_CHARSET_TYPE_UCS2 | TB_CHARSET_TYPE_NE, "ucs2" },
    { TB_CHARSET_TYPE_UCS4 | TB_CHARSET_TYPE_NE, "ucs4" },
    { TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_NE, "utf16" },
    { TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_BE, "utf16be" },
    { TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_NE, "utf16bom" },
    { TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_LE, "utf16le" },
    { TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_LE, "utf16lebom" },
    { TB_CHARSET_TYPE_UTF32 | TB_CHARSET_TYPE_NE, "utf32" },
    { TB_CHARSET_TYPE_UTF32 | TB_CHARSET_TYPE_BE, "utf32be" },
    { TB_CHARSET_TYPE_UTF32 | TB_CHARSET_TYPE_LE, "utf32le" },
    { TB_CHARSET_TYPE_UTF8, "utf8" },
    { TB_CHARSET_TYPE_UTF8, "utf8bom" },
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * finder
 */
static tb_long_t xm_charset_comp_by_name(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t name) {
    return tb_stricmp(((xm_charset_entry_ref_t)item)->name, (tb_char_t const *)name);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
xm_charset_entry_ref_t xm_charset_find_by_name(tb_char_t const *name) {
    // make iterator
    tb_array_iterator_t array_iterator;
    tb_iterator_ref_t   iterator =
        tb_array_iterator_init_mem(&array_iterator, g_charsets, tb_arrayn(g_charsets), sizeof(xm_charset_entry_t));
    tb_assert_and_check_return_val(iterator, tb_null);

    // find it by the binary search
    tb_size_t itor = tb_binary_find_all_if(iterator, xm_charset_comp_by_name, name);
    if (itor != tb_iterator_tail(iterator)) {
        return (xm_charset_entry_ref_t)tb_iterator_item(iterator, itor);
    } else {
        return tb_null;
    }
}
