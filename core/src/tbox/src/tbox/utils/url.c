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
 * @file        url.c
 * @ingroup     utils
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "url.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_url_encode(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on)
{
    // init
    tb_char_t const*    ip = ib;
    tb_char_t*          op = ob;
    tb_char_t const*    ie = ib + in;
    tb_char_t const*    oe = ob + on;
    static tb_char_t    ht[] = "0123456789ABCDEF";

    // done
    while (ip < ie && op < oe) 
    {
        // character
        tb_byte_t c = *ip++;

        // space?
        if (c == ' ') *op++ = '+';
        // %xx?
        else if (   (c < '0' && c != '-' && c != '.') 
                ||  (c < 'A' && c > '9') 
                ||  (c > 'Z' && c < 'a' && c != '_') 
                ||  (c > 'z'))
        {
            op[0] = '%';
            op[1] = ht[c >> 4];
            op[2] = ht[c & 15];
            op += 3;
        } 
        else *op++ = c;
    }

    // end
    *op = '\0';

    // ok
    return op - ob;
}
tb_size_t tb_url_decode(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on)
{
    // init
    tb_char_t const*    ip = ib;
    tb_char_t*          op = ob;
    tb_char_t const*    ie = ib + in;
    tb_char_t const*    oe = ob + on;

    // done
    tb_char_t ch[3] = {0};
    while (ip < ie && op < oe) 
    {
        // space?
        if (*ip == '+') *op = ' ';
        // %xx?
        else if (*ip == '%' && ip + 2 < ie && tb_isdigit16(ip[1]) && tb_isdigit16(ip[2]))
        {
            ch[0] = ip[1];
            ch[1] = ip[2];
            *op = (tb_char_t)tb_s16tou32(ch);
            ip += 2;
        }
        else *op = *ip;

        // next
        ip++;
        op++;
    }

    // end
    *op = '\0';

    // ok
    return op - ob;
}
tb_size_t tb_url_encode2(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on)
{
    // init
    tb_char_t const*    ip = ib;
    tb_char_t*          op = ob;
    tb_char_t const*    ie = ib + in;
    tb_char_t const*    oe = ob + on;
    static tb_char_t    ht[] = "0123456789ABCDEF";

    // done
    while (ip < ie && op < oe) 
    {
        // character
        tb_byte_t c = *ip++;

        // %xx?
        if (    (c < '0' && c != '-' && c != '.' && c != '&' && c != '!' && c != '#' && c != '$' && c != '\'' && c != '(' && c != ')' && c != '+' && c != ',' && c != '*' && c != '/') 
            ||  (c < 'A' && c > '9' && c != '@' && c != '?' && c != '=' && c != ';' && c != ':')
            ||  (c > 'Z' && c < 'a' && c != '_') 
            ||  (c > 'z' && c != '~'))
        {
            op[0] = '%';
            op[1] = ht[c >> 4];
            op[2] = ht[c & 15];
            op += 3;
        } 
        else *op++ = c;
    }

    // end
    *op = '\0';

    // ok
    return op - ob;
}
tb_size_t tb_url_decode2(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on)
{
    // init
    tb_char_t const*    ip = ib;
    tb_char_t*          op = ob;
    tb_char_t const*    ie = ib + in;
    tb_char_t const*    oe = ob + on;

    // done
    tb_char_t ch[3] = {0};
    while (ip < ie && op < oe) 
    {
        // %xx?
        if (*ip == '%' && ip + 2 < ie && tb_isdigit16(ip[1]) && tb_isdigit16(ip[2]))
        {
            ch[0] = ip[1];
            ch[1] = ip[2];
            *op = (tb_char_t)tb_s16tou32(ch);
            ip += 2;
        }
        else *op = *ip;

        // next
        ip++;
        op++;
    }

    // end
    *op = '\0';

    // ok
    return op - ob;
}
tb_size_t tb_url_encode_args(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on)
{
    // init
    tb_char_t const*    ip = ib;
    tb_char_t*          op = ob;
    tb_char_t const*    ie = ib + in;
    tb_char_t const*    oe = ob + on;
    static tb_char_t    ht[] = "0123456789ABCDEF";

    // done
    while (ip < ie && op < oe) 
    {
        // character
        tb_byte_t c = *ip++;

        // %xx?
        if (    (c < '0' && c != '-' && c != '.' && c != '!' && c != '(' && c != ')' && c != '*' && c != '\'') 
            ||  (c < 'A' && c > '9')
            ||  (c > 'Z' && c < 'a' && c != '_') 
            ||  (c > 'z' && c != '~'))
        {
            op[0] = '%';
            op[1] = ht[c >> 4];
            op[2] = ht[c & 15];
            op += 3;
        } 
        else *op++ = c;
    }

    // end
    *op = '\0';

    // ok
    return op - ob;
}
tb_size_t tb_url_decode_args(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on)
{
    return tb_url_decode2(ib, in, ob, on);
}
