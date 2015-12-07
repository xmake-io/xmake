/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        prefix.h
 *
 */
#ifndef TB_NETWORK_DNS_PREFIX_H
#define TB_NETWORK_DNS_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../ipaddr.h"
#include "../../utils/utils.h"
#include "../../stream/static_stream.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the protocol header
#define TB_DNS_HEADER_SIZE          (12)
#define TB_DNS_HEADER_MAGIC         (0xbeef)

// the protocol port
#define TB_DNS_HOST_PORT            (53)

// the name maximum size 
#define TB_DNS_NAME_MAXN            (256)

// the rpkt maximum size 
#define TB_DNS_RPKT_MAXN            (TB_DNS_HEADER_SIZE + TB_DNS_NAME_MAXN + 256)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the dns header type
typedef struct __tb_dns_header_t
{
    tb_uint16_t         id;             // identification number

    tb_uint16_t         qr     :1;      // query/response flag
    tb_uint16_t         opcode :4;      // purpose of message
    tb_uint16_t         aa     :1;      // authoritive answer
    tb_uint16_t         tc     :1;      // truncated message
    tb_uint16_t         rd     :1;      // recursion desired

    tb_uint16_t         ra     :1;      // recursion available
    tb_uint16_t         z      :1;      // its z! reserved
    tb_uint16_t         ad     :1;      // authenticated data
    tb_uint16_t         cd     :1;      // checking disabled
    tb_uint16_t         rcode  :4;      // response code

    tb_uint16_t         question;       // number of question entries
    tb_uint16_t         answer;         // number of answer entries
    tb_uint16_t         authority;      // number of authority entries
    tb_uint16_t         resource;       // number of resource entries

}tb_dns_header_t;

// the dns question type
typedef struct __tb_dns_question_t
{
    tb_uint16_t         type;
    tb_uint16_t         class_;

}tb_dns_question_t;

// the dns resource type
typedef struct __tb_dns_resource_t
{
    tb_uint16_t         type;
    tb_uint16_t         class_;
    tb_uint32_t         ttl;
    tb_uint16_t         size;

}tb_dns_resource_t;

// the dns answer type
typedef struct __tb_dns_answer_t
{
    tb_char_t           name[TB_DNS_NAME_MAXN];
    tb_dns_resource_t   res;
    tb_byte_t const*    rdata;

}tb_dns_answer_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */

// size + data, e.g. .www.google.com => 3www6google3com
static __tb_inline__ tb_char_t const* tb_dns_encode_name(tb_char_t* name)
{
    tb_assert_and_check_return_val(name && name[0] == '.', tb_null);
    
    // encode
    tb_byte_t   n = 0;
    tb_char_t*  b = name;
    tb_char_t*  p = name + 1;
    while (*p)
    {
        if (*p == '.')
        {
            //*b = '0' + n;
            *b = (tb_char_t)n;
            n = 0;
            b = p;
        }
        else n++;
        p++;
    }
    //*b = '0' + n;
    *b = n;

    // ok
    return name;
}
static __tb_inline__ tb_char_t const* tb_dns_decode_name_impl(tb_char_t const* sb, tb_char_t const* se, tb_char_t const* ps, tb_char_t** pd)
{
    tb_char_t const*    p = ps;
    tb_char_t*          q = *pd;
    while (p < se)
    {
        tb_byte_t c = *p++;
        if (!c) break;
        // is pointer? 11xxxxxx xxxxxxxx
        else if (c >= 0xc0)
        {
            tb_uint16_t pos = c;
            pos &= ~0xc0;
            pos <<= 8;
            pos |= *p++;
            tb_dns_decode_name_impl(sb, se, sb + pos, &q);
            break; 
        }
        // is ascii? 00xxxxxx
        else
        {
            while (c--) *q++ = *p++;
            *q++ = '.';
        }
    }
    *pd = q;
    return p;
}
static __tb_inline__ tb_char_t const* tb_dns_decode_name(tb_static_stream_ref_t sstream, tb_char_t* name)
{
    tb_char_t* q = name;
    tb_char_t* p = (tb_char_t*)tb_dns_decode_name_impl((tb_char_t const*)tb_static_stream_beg(sstream), (tb_char_t const*)tb_static_stream_end(sstream), (tb_char_t const*)tb_static_stream_pos(sstream), &q);
    if (p)
    {
        tb_assert(q - name < TB_DNS_NAME_MAXN);
        if (q > name && *(q - 1) == '.') *--q = '\0';
        tb_static_stream_goto(sstream, (tb_byte_t*)p);
        return name;
    }
    else return tb_null;
}

#endif
