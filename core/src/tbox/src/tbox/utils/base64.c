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
 * @file        base64.c
 * @ingroup     utils
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "base64.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define TB_BASE64_OUTPUT_MIN(in)  (((in) + 2) / 3 * 4 + 1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_base64_encode(tb_byte_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on)
{
    // table
    static tb_char_t const table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // check 
    tb_assert_and_check_return_val(ib && ob && !(in >= TB_MAXU32 / 4 || on < TB_BASE64_OUTPUT_MIN(in)), 0);

    // done
    tb_char_t*      op = ob;
    tb_uint32_t     bits = 0;
    tb_long_t       left = in;
    tb_long_t       shift = 0;
    while (left) 
    {
        bits = (bits << 8) + *ib++;
        left--;
        shift += 8;

        do 
        {
            *op++ = table[(bits << 6 >> shift) & 0x3f];
            shift -= 6;
        } 
        while (shift > 6 || (left == 0 && shift > 0));
    }

    // done tail
    while ((op - ob) & 3) *op++ = '=';
    *op = '\0';

    // ok?
    return (op - ob);
}
tb_size_t tb_base64_decode(tb_char_t const* ib, tb_size_t in, tb_byte_t* ob, tb_size_t on)
{
    // check
    tb_assert_and_check_return_val(ib && ob, 0);

    // the table
    static tb_byte_t table[] =
    {
        0x3e, 0xff, 0xff, 0xff, 0x3f, 0x34, 0x35, 0x36
    ,   0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0xff
    ,   0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x01
    ,   0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09
    ,   0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11
    ,   0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19
    ,   0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x1a, 0x1b
    ,   0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23
    ,   0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b
    ,   0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33
    };

    // done
    tb_int_t    i = 0;
    tb_int_t    v = 0;
    tb_byte_t*  op = ob;
    tb_size_t   tn = tb_arrayn(table);
    for (i = 0; i < in && ib[i] && ib[i] != '='; i++) 
    {
        tb_uint32_t idx = ib[i] - 43;
        if (idx >= tn || table[idx] == 0xff) return 0;

        v = (v << 6) + table[idx];
        if (i & 3) 
        {
            if (op - ob < on) *op++ = v >> (6 - 2 * (i & 3));
        }
    }

    // ok?
    return (op - ob);
}
