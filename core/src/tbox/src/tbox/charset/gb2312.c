/*!The Treasure Box Library
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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        gb2312.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../stream/stream.h"
#include "gb2312.g"

/* //////////////////////////////////////////////////////////////////////////////////////
 * helper
 */
static tb_uint32_t tb_charset_gb2312_from_ucs4(tb_uint32_t ch)
{
    // is ascii?
    if (ch <= 0x7f) return ch;

    // find the gb2312 character
    tb_long_t left = 0;
    tb_long_t right = (g_charset_ucs4_to_gb2312_table_size / sizeof(g_charset_ucs4_to_gb2312_table_data[0])) - 1;
    while (left <= right)
    {
        // the middle character
        tb_long_t       mid = (left + right) >> 1;
        tb_uint16_t     mid_ucs4 = g_charset_ucs4_to_gb2312_table_data[mid][0];

        // find it?
        if (mid_ucs4 == ch)
            return g_charset_ucs4_to_gb2312_table_data[mid][1];

        if (ch > mid_ucs4) left = mid + 1;
        else right = mid - 1;
    }

    return 0;
}
static tb_uint32_t tb_charset_gb2312_to_ucs4(tb_uint32_t ch)
{
    // is ascii?
    if (ch <= 0x7f) return ch;

    // is gb2312?
    if (ch >= 0xa1a1 && ch <= 0xf7fe)
        return g_charset_gb2312_to_ucs4_table_data[ch - 0xa1a1];
    else return 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_long_t tb_charset_gb2312_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_gb2312_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch)
{   
    // init
    tb_byte_t const*    p = tb_static_stream_pos(sstream);
    tb_size_t           n = tb_static_stream_left(sstream);

    if (*p <= 0x7f) 
    {
        // not enough? break it
        tb_check_return_val(n, -1);

        // get character
        *ch = tb_static_stream_read_u8(sstream);
    }
    else
    {
        // not enough? break it
        tb_check_return_val(n > 1, -1);

        // get character
        *ch = tb_charset_gb2312_to_ucs4(be? tb_static_stream_read_u16_be(sstream) : tb_static_stream_read_u16_le(sstream));
    }

    // ok
    return 1;
}

tb_long_t tb_charset_gb2312_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);
tb_long_t tb_charset_gb2312_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch)
{
    // init
    tb_size_t n = tb_static_stream_left(sstream);

    // character
    ch = tb_charset_gb2312_from_ucs4(ch);
    if (ch <= 0x7f) 
    {
        // not enough? break it
        tb_check_return_val(n, -1);

        // set character
        tb_static_stream_writ_u8(sstream, ch & 0xff);
    }
    else
    {
        // not enough? break it
        tb_check_return_val(n > 1, 0);

        // set character
        if (be) tb_static_stream_writ_u16_be(sstream, ch & 0xffff);
        else tb_static_stream_writ_u16_le(sstream, ch & 0xffff);
    }

    // ok
    return 1;
}
