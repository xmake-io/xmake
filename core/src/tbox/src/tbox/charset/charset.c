/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        charset.c
 * @ingroup     charset
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "charset.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */

// ascii
tb_long_t tb_charset_ascii_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_ascii_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

// utf8
tb_long_t tb_charset_utf8_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_utf8_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

// utf16
tb_long_t tb_charset_utf16_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_utf16_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

// utf32
tb_long_t tb_charset_utf32_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_utf32_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

// ucs2
tb_long_t tb_charset_ucs2_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_ucs2_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

// ucs4
tb_long_t tb_charset_ucs4_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_ucs4_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

// gb2312
tb_long_t tb_charset_gb2312_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_gb2312_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

// iso8859
tb_long_t tb_charset_iso8859_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_iso8859_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the charsets, @note: type & name is sorted
static tb_charset_t g_charsets[] =
{
    {TB_CHARSET_TYPE_ASCII,     "ascii",    tb_charset_ascii_get,   tb_charset_ascii_set    }
,   {TB_CHARSET_TYPE_GB2312,    "gb2312",   tb_charset_gb2312_get,  tb_charset_gb2312_set   }
,   {TB_CHARSET_TYPE_GBK,       "gbk",      tb_charset_gb2312_get,  tb_charset_gb2312_set   }
,   {TB_CHARSET_TYPE_ISO8859,   "iso8859",  tb_charset_iso8859_get, tb_charset_iso8859_set  }
,   {TB_CHARSET_TYPE_UCS2,      "ucs3",     tb_charset_ucs2_get,    tb_charset_ucs2_set     }
,   {TB_CHARSET_TYPE_UCS4,      "ucs4",     tb_charset_ucs4_get,    tb_charset_ucs4_set     }
,   {TB_CHARSET_TYPE_UTF16,     "utf16",    tb_charset_utf16_get,   tb_charset_utf16_set    }
,   {TB_CHARSET_TYPE_UTF32,     "utf32",    tb_charset_utf32_get,   tb_charset_utf32_set    }
,   {TB_CHARSET_TYPE_UTF8,      "utf8",     tb_charset_utf8_get,    tb_charset_utf8_set     }
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * finder
 */
static tb_long_t tb_charset_comp_by_name(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t name)
{
    // check
    tb_assert(item);

    // comp
    return tb_stricmp(((tb_charset_ref_t)item)->name, (tb_char_t const*)name);
}
static tb_long_t tb_charset_comp_by_type(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t type)
{
    // check
    tb_assert(item && type);

    // comp
    return (tb_long_t)((tb_charset_ref_t)item)->type - (tb_long_t)type;
}
static tb_charset_ref_t tb_charset_find_by_name(tb_char_t const* name)
{
    // make iterator
    tb_array_iterator_t array_iterator;
    tb_iterator_ref_t   iterator = tb_array_iterator_init_mem(&array_iterator, g_charsets, tb_arrayn(g_charsets), sizeof(tb_charset_t));
    tb_assert_and_check_return_val(iterator, tb_null);

    // find it by the binary search
    tb_size_t itor = tb_binary_find_all_if(iterator, tb_charset_comp_by_name, name);

    // ok?
    if (itor != tb_iterator_tail(iterator))
        return (tb_charset_ref_t)tb_iterator_item(iterator, itor);
    else return tb_null;
}
static tb_charset_ref_t tb_charset_find_by_type(tb_size_t type)
{
    // make iterator
    tb_array_iterator_t array_iterator;
    tb_iterator_ref_t   iterator = tb_array_iterator_init_mem(&array_iterator, g_charsets, tb_arrayn(g_charsets), sizeof(tb_charset_t));
    tb_assert_and_check_return_val(iterator, tb_null);

    // find it by the binary search
    tb_size_t itor = tb_binary_find_all_if(iterator, tb_charset_comp_by_type, (tb_cpointer_t)TB_CHARSET_TYPE(type));

    // ok?
    if (itor != tb_iterator_tail(iterator))
        return (tb_charset_ref_t)tb_iterator_item(iterator, itor);
    else return tb_null;
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_char_t const* tb_charset_name(tb_size_t type)
{
    // find
    tb_charset_ref_t charset = tb_charset_find_by_type(type);
    tb_assert_and_check_return_val(charset, tb_null);

    // type
    return charset->name;
}
tb_size_t tb_charset_type(tb_char_t const* name)
{
    // find
    tb_charset_ref_t charset = tb_charset_find_by_name(name);
    tb_assert_and_check_return_val(charset, TB_CHARSET_TYPE_NONE);

    // type
    return charset->type;
}
tb_charset_ref_t tb_charset_find(tb_size_t type)
{
    return tb_charset_find_by_type(type);
}
tb_long_t tb_charset_conv_bst(tb_size_t ftype, tb_size_t ttype, tb_static_stream_ref_t fst, tb_static_stream_ref_t tst)
{
    // check
    tb_assert_and_check_return_val(TB_CHARSET_TYPE_OK(ftype) && TB_CHARSET_TYPE_OK(ttype) && fst && tst, -1);
    tb_assert_and_check_return_val(tb_static_stream_valid(fst) && tb_static_stream_valid(tst), -1);

    // init the charset
    tb_charset_ref_t fr = tb_charset_find_by_type(ftype);
    tb_charset_ref_t to = tb_charset_find_by_type(ttype);
    tb_assert_and_check_return_val(fr && to && fr->get && fr->set, -1);

    // no data? 
    tb_check_return_val(tb_static_stream_left(fst), 0);

    // big endian?
    tb_bool_t fbe = !(ftype & TB_CHARSET_TYPE_LE)? tb_true : tb_false;
    tb_bool_t tbe = !(ttype & TB_CHARSET_TYPE_LE)? tb_true : tb_false;

    // walk
    tb_uint32_t         ch;
    tb_byte_t const*    tp = tb_static_stream_pos(tst);
    while (tb_static_stream_left(fst) && tb_static_stream_left(tst))
    {
        // get ucs4 character
        tb_long_t ok = 0;
        if ((ok = fr->get(fst, fbe, &ch)) > 0)
        {
            // set ucs4 character
            if (to->set(tst, tbe, ch) < 0) break;
        }
        else if (ok < 0) break;
    }

    // ok?
    return tb_static_stream_pos(tst) - tp;
}
tb_long_t tb_charset_conv_cstr(tb_size_t ftype, tb_size_t ttype, tb_char_t const* cstr, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(TB_CHARSET_TYPE_OK(ftype) && TB_CHARSET_TYPE_OK(ttype) && cstr && data && size, -1);

    // conv
    return tb_charset_conv_data(ftype, ttype, (tb_byte_t const*)cstr, tb_strlen(cstr), data, size);
}
tb_long_t tb_charset_conv_data(tb_size_t ftype, tb_size_t ttype, tb_byte_t const* idata, tb_size_t isize, tb_byte_t* odata, tb_size_t osize)
{
    // check
    tb_assert_and_check_return_val(TB_CHARSET_TYPE_OK(ftype) && TB_CHARSET_TYPE_OK(ttype) && idata && isize && odata && osize, -1);

    // init static stream
    tb_static_stream_t ist;
    tb_static_stream_t ost;
    tb_static_stream_init(&ist, (tb_byte_t*)idata, isize);
    tb_static_stream_init(&ost, odata, osize);

    // conv
    return tb_charset_conv_bst(ftype, ttype, &ist, &ost);
}

