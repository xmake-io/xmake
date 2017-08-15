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
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        utf16.c
 * @ingroup     charset
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../stream/stream.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_long_t tb_charset_utf16_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_utf16_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch)
{
    // init
    tb_byte_t const*    p = tb_static_stream_pos(sstream);
    tb_byte_t const*    q = p;
    tb_size_t           n = tb_static_stream_left(sstream);

    // not enough? break it
    tb_check_return_val(n > 1, -1);

    // the first character
    tb_uint32_t c = be? tb_bits_get_u16_be(p) : tb_bits_get_u16_le(p);
    p += 2;

    // large?
    if (c >= 0xd800 && c <= 0xdbff) 
    {
        // not enough? break it
        tb_check_return_val(n > 3, -1);

        // the next character
        tb_uint32_t c2 = be? tb_bits_get_u16_be(p) : tb_bits_get_u16_le(p);
        if (c2 >= 0xdc00 && c2 <= 0xdfff)
        {
            c = ((c - 0xd800) << 10) + (c2 - 0xdc00) + 0x0010000;
            p += 2;
        };
    };

    // next
    if (p > q) tb_static_stream_skip(sstream, p - q);

    // set character
    *ch = c;

    // ok?
    return p > q? 1 : 0;
}

tb_long_t tb_charset_utf16_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);
tb_long_t tb_charset_utf16_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch)
{
    // init
    tb_size_t n = tb_static_stream_left(sstream);

    if (ch <= 0x0000ffff) 
    {
        // not enough? break it
        tb_check_return_val(n > 1, -1);

        // set character
        if (be) tb_static_stream_writ_u16_be(sstream, ch);
        else tb_static_stream_writ_u16_le(sstream, ch);
    }
    else if (ch > 0x0010ffff)
    {
        // not enough? break it
        tb_check_return_val(n > 1, -1);

        // set character
        if (be) tb_static_stream_writ_u16_be(sstream, 0x0000fffd);
        else tb_static_stream_writ_u16_le(sstream, 0x0000fffd);
    }
    else
    {
        // not enough? break it
        tb_check_return_val(n > 3, -1);

        // set character
        ch -= 0x0010000;
        if (be)
        {
            tb_static_stream_writ_u16_be(sstream, (ch >> 10) + 0xd800);
            tb_static_stream_writ_u16_be(sstream, (ch & 0x3ff) + 0xdc00);
        }
        else 
        {
            tb_static_stream_writ_u16_le(sstream, (ch >> 10) + 0xd800);
            tb_static_stream_writ_u16_le(sstream, (ch & 0x3ff) + 0xdc00);
        }
    };

    // ok
    return 1;
}

