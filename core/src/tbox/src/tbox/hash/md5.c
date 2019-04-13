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
 * @file        md5.c
 * @ingroup     hash
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "md5.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// TB_MD5_F, TB_MD5_G and TB_MD5_H are basic MD5 functions: selection, majority, parity 
#define TB_MD5_F(x, y, z)   (((x) & (y)) | ((~x) & (z)))
#define TB_MD5_G(x, y, z)   (((x) & (z)) | ((y) & (~z)))
#define TB_MD5_H(x, y, z)   ((x) ^ (y) ^ (z))
#define TB_MD5_I(x, y, z)   ((y) ^ ((x) | (~z)))

// TB_MD5_ROTATE_LEFT rotates x left n bits */
#define TB_MD5_ROTATE_LEFT(x, n)    (((x) << (n)) | ((x) >> (32 - (n))))

// TB_MD5_FF, TB_MD5_GG, TB_MD5_HH, and TB_MD5_II transformations for rounds 1, 2, 3, and 4
// Rotation is separate from addition to prevent recomputation
#define TB_MD5_FF(a, b, c, d, x, s, ac) {(a) += TB_MD5_F ((b), (c), (d)) + (x) + (tb_uint32_t)(ac); (a) = TB_MD5_ROTATE_LEFT ((a), (s)); (a) += (b); }
#define TB_MD5_GG(a, b, c, d, x, s, ac) {(a) += TB_MD5_G ((b), (c), (d)) + (x) + (tb_uint32_t)(ac); (a) = TB_MD5_ROTATE_LEFT ((a), (s)); (a) += (b); }
#define TB_MD5_HH(a, b, c, d, x, s, ac) {(a) += TB_MD5_H ((b), (c), (d)) + (x) + (tb_uint32_t)(ac); (a) = TB_MD5_ROTATE_LEFT ((a), (s)); (a) += (b); }
#define TB_MD5_II(a, b, c, d, x, s, ac) {(a) += TB_MD5_I ((b), (c), (d)) + (x) + (tb_uint32_t)(ac); (a) = TB_MD5_ROTATE_LEFT ((a), (s)); (a) += (b); }

// Constants for transformation 
#define TB_MD5_S11 7  // Round 1
#define TB_MD5_S12 12
#define TB_MD5_S13 17
#define TB_MD5_S14 22
#define TB_MD5_S21 5  // Round 2
#define TB_MD5_S22 9
#define TB_MD5_S23 14
#define TB_MD5_S24 20
#define TB_MD5_S31 4  // Round 3
#define TB_MD5_S32 11
#define TB_MD5_S33 16
#define TB_MD5_S34 23
#define TB_MD5_S41 6  // Round 4
#define TB_MD5_S42 10
#define TB_MD5_S43 15
#define TB_MD5_S44 21

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

/* Padding */
static tb_byte_t g_md5_padding[64] = 
{
    0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementaion
 */

// basic md5 step. the sp based on ip
static tb_void_t tb_md5_transform(tb_uint32_t* sp, tb_uint32_t* ip)
{
    // check
    tb_assert_and_check_return(sp && ip);

    // init
    tb_uint32_t a = sp[0], b = sp[1], c = sp[2], d = sp[3];

    // round 1 
    TB_MD5_FF ( a, b, c, d, ip[ 0], TB_MD5_S11, (tb_uint32_t) 3614090360u); /* 1 */
    TB_MD5_FF ( d, a, b, c, ip[ 1], TB_MD5_S12, (tb_uint32_t) 3905402710u); /* 2 */
    TB_MD5_FF ( c, d, a, b, ip[ 2], TB_MD5_S13, (tb_uint32_t)  606105819u); /* 3 */
    TB_MD5_FF ( b, c, d, a, ip[ 3], TB_MD5_S14, (tb_uint32_t) 3250441966u); /* 4 */
    TB_MD5_FF ( a, b, c, d, ip[ 4], TB_MD5_S11, (tb_uint32_t) 4118548399u); /* 5 */
    TB_MD5_FF ( d, a, b, c, ip[ 5], TB_MD5_S12, (tb_uint32_t) 1200080426u); /* 6 */
    TB_MD5_FF ( c, d, a, b, ip[ 6], TB_MD5_S13, (tb_uint32_t) 2821735955u); /* 7 */
    TB_MD5_FF ( b, c, d, a, ip[ 7], TB_MD5_S14, (tb_uint32_t) 4249261313u); /* 8 */
    TB_MD5_FF ( a, b, c, d, ip[ 8], TB_MD5_S11, (tb_uint32_t) 1770035416u); /* 9 */
    TB_MD5_FF ( d, a, b, c, ip[ 9], TB_MD5_S12, (tb_uint32_t) 2336552879u); /* 10 */
    TB_MD5_FF ( c, d, a, b, ip[10], TB_MD5_S13, (tb_uint32_t) 4294925233u); /* 11 */
    TB_MD5_FF ( b, c, d, a, ip[11], TB_MD5_S14, (tb_uint32_t) 2304563134u); /* 12 */
    TB_MD5_FF ( a, b, c, d, ip[12], TB_MD5_S11, (tb_uint32_t) 1804603682u); /* 13 */
    TB_MD5_FF ( d, a, b, c, ip[13], TB_MD5_S12, (tb_uint32_t) 4254626195u); /* 14 */
    TB_MD5_FF ( c, d, a, b, ip[14], TB_MD5_S13, (tb_uint32_t) 2792965006u); /* 15 */
    TB_MD5_FF ( b, c, d, a, ip[15], TB_MD5_S14, (tb_uint32_t) 1236535329u); /* 16 */

    // round 2
    TB_MD5_GG ( a, b, c, d, ip[ 1], TB_MD5_S21, (tb_uint32_t) 4129170786u); /* 17 */
    TB_MD5_GG ( d, a, b, c, ip[ 6], TB_MD5_S22, (tb_uint32_t) 3225465664u); /* 18 */
    TB_MD5_GG ( c, d, a, b, ip[11], TB_MD5_S23, (tb_uint32_t)  643717713u); /* 19 */
    TB_MD5_GG ( b, c, d, a, ip[ 0], TB_MD5_S24, (tb_uint32_t) 3921069994u); /* 20 */
    TB_MD5_GG ( a, b, c, d, ip[ 5], TB_MD5_S21, (tb_uint32_t) 3593408605u); /* 21 */
    TB_MD5_GG ( d, a, b, c, ip[10], TB_MD5_S22, (tb_uint32_t)   38016083u); /* 22 */
    TB_MD5_GG ( c, d, a, b, ip[15], TB_MD5_S23, (tb_uint32_t) 3634488961u); /* 23 */
    TB_MD5_GG ( b, c, d, a, ip[ 4], TB_MD5_S24, (tb_uint32_t) 3889429448u); /* 24 */
    TB_MD5_GG ( a, b, c, d, ip[ 9], TB_MD5_S21, (tb_uint32_t)  568446438u); /* 25 */
    TB_MD5_GG ( d, a, b, c, ip[14], TB_MD5_S22, (tb_uint32_t) 3275163606u); /* 26 */
    TB_MD5_GG ( c, d, a, b, ip[ 3], TB_MD5_S23, (tb_uint32_t) 4107603335u); /* 27 */
    TB_MD5_GG ( b, c, d, a, ip[ 8], TB_MD5_S24, (tb_uint32_t) 1163531501u); /* 28 */
    TB_MD5_GG ( a, b, c, d, ip[13], TB_MD5_S21, (tb_uint32_t) 2850285829u); /* 29 */
    TB_MD5_GG ( d, a, b, c, ip[ 2], TB_MD5_S22, (tb_uint32_t) 4243563512u); /* 30 */
    TB_MD5_GG ( c, d, a, b, ip[ 7], TB_MD5_S23, (tb_uint32_t) 1735328473u); /* 31 */
    TB_MD5_GG ( b, c, d, a, ip[12], TB_MD5_S24, (tb_uint32_t) 2368359562u); /* 32 */

    // round 3
    TB_MD5_HH ( a, b, c, d, ip[ 5], TB_MD5_S31, (tb_uint32_t) 4294588738u); /* 33 */
    TB_MD5_HH ( d, a, b, c, ip[ 8], TB_MD5_S32, (tb_uint32_t) 2272392833u); /* 34 */
    TB_MD5_HH ( c, d, a, b, ip[11], TB_MD5_S33, (tb_uint32_t) 1839030562u); /* 35 */
    TB_MD5_HH ( b, c, d, a, ip[14], TB_MD5_S34, (tb_uint32_t) 4259657740u); /* 36 */
    TB_MD5_HH ( a, b, c, d, ip[ 1], TB_MD5_S31, (tb_uint32_t) 2763975236u); /* 37 */
    TB_MD5_HH ( d, a, b, c, ip[ 4], TB_MD5_S32, (tb_uint32_t) 1272893353u); /* 38 */
    TB_MD5_HH ( c, d, a, b, ip[ 7], TB_MD5_S33, (tb_uint32_t) 4139469664u); /* 39 */
    TB_MD5_HH ( b, c, d, a, ip[10], TB_MD5_S34, (tb_uint32_t) 3200236656u); /* 40 */
    TB_MD5_HH ( a, b, c, d, ip[13], TB_MD5_S31, (tb_uint32_t)  681279174u); /* 41 */
    TB_MD5_HH ( d, a, b, c, ip[ 0], TB_MD5_S32, (tb_uint32_t) 3936430074u); /* 42 */
    TB_MD5_HH ( c, d, a, b, ip[ 3], TB_MD5_S33, (tb_uint32_t) 3572445317u); /* 43 */
    TB_MD5_HH ( b, c, d, a, ip[ 6], TB_MD5_S34, (tb_uint32_t)   76029189u); /* 44 */
    TB_MD5_HH ( a, b, c, d, ip[ 9], TB_MD5_S31, (tb_uint32_t) 3654602809u); /* 45 */
    TB_MD5_HH ( d, a, b, c, ip[12], TB_MD5_S32, (tb_uint32_t) 3873151461u); /* 46 */
    TB_MD5_HH ( c, d, a, b, ip[15], TB_MD5_S33, (tb_uint32_t)  530742520u); /* 47 */
    TB_MD5_HH ( b, c, d, a, ip[ 2], TB_MD5_S34, (tb_uint32_t) 3299628645u); /* 48 */

    // round 4
    TB_MD5_II ( a, b, c, d, ip[ 0], TB_MD5_S41, (tb_uint32_t) 4096336452u); /* 49 */
    TB_MD5_II ( d, a, b, c, ip[ 7], TB_MD5_S42, (tb_uint32_t) 1126891415u); /* 50 */
    TB_MD5_II ( c, d, a, b, ip[14], TB_MD5_S43, (tb_uint32_t) 2878612391u); /* 51 */
    TB_MD5_II ( b, c, d, a, ip[ 5], TB_MD5_S44, (tb_uint32_t) 4237533241u); /* 52 */
    TB_MD5_II ( a, b, c, d, ip[12], TB_MD5_S41, (tb_uint32_t) 1700485571u); /* 53 */
    TB_MD5_II ( d, a, b, c, ip[ 3], TB_MD5_S42, (tb_uint32_t) 2399980690u); /* 54 */
    TB_MD5_II ( c, d, a, b, ip[10], TB_MD5_S43, (tb_uint32_t) 4293915773u); /* 55 */
    TB_MD5_II ( b, c, d, a, ip[ 1], TB_MD5_S44, (tb_uint32_t) 2240044497u); /* 56 */
    TB_MD5_II ( a, b, c, d, ip[ 8], TB_MD5_S41, (tb_uint32_t) 1873313359u); /* 57 */
    TB_MD5_II ( d, a, b, c, ip[15], TB_MD5_S42, (tb_uint32_t) 4264355552u); /* 58 */
    TB_MD5_II ( c, d, a, b, ip[ 6], TB_MD5_S43, (tb_uint32_t) 2734768916u); /* 59 */
    TB_MD5_II ( b, c, d, a, ip[13], TB_MD5_S44, (tb_uint32_t) 1309151649u); /* 60 */
    TB_MD5_II ( a, b, c, d, ip[ 4], TB_MD5_S41, (tb_uint32_t) 4149444226u); /* 61 */
    TB_MD5_II ( d, a, b, c, ip[11], TB_MD5_S42, (tb_uint32_t) 3174756917u); /* 62 */
    TB_MD5_II ( c, d, a, b, ip[ 2], TB_MD5_S43, (tb_uint32_t)  718787259u); /* 63 */
    TB_MD5_II ( b, c, d, a, ip[ 9], TB_MD5_S44, (tb_uint32_t) 3951481745u); /* 64 */

    sp[0] += a;
    sp[1] += b;
    sp[2] += c;
    sp[3] += d;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// set pseudo_rand to zero for rfc md5 implementation
tb_void_t tb_md5_init(tb_md5_t* md5, tb_uint32_t pseudo_rand)
{
    // check
    tb_assert_and_check_return(md5);

    // init
    md5->i[0] = md5->i[1] = (tb_uint32_t)0;

    // load magic initialization constants 
    md5->sp[0] = (tb_uint32_t)0x67452301 + (pseudo_rand * 11);
    md5->sp[1] = (tb_uint32_t)0xefcdab89 + (pseudo_rand * 71);
    md5->sp[2] = (tb_uint32_t)0x98badcfe + (pseudo_rand * 37);
    md5->sp[3] = (tb_uint32_t)0x10325476 + (pseudo_rand * 97);
}

tb_void_t tb_md5_spak(tb_md5_t* md5, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(md5 && data);

    // init
    tb_uint32_t ip[16];
    tb_size_t   i = 0, ii = 0;

    // compute number of bytes mod 64
    tb_int_t mdi = (tb_int_t)((md5->i[0] >> 3) & 0x3F);

    // update number of bits
    if ((md5->i[0] + ((tb_uint32_t)size << 3)) < md5->i[0]) md5->i[1]++;

    md5->i[0] += ((tb_uint32_t)size << 3);
    md5->i[1] += ((tb_uint32_t)size >> 29);

    while (size--)
    {
        // add new character to buffer, increment mdi
        md5->ip[mdi++] = *data++;

        // transform if necessary 
        if (mdi == 0x40)
        {
            for (i = 0, ii = 0; i < 16; i++, ii += 4)
            {
                ip[i] =     (((tb_uint32_t)md5->ip[ii + 3]) << 24)
                        |   (((tb_uint32_t)md5->ip[ii + 2]) << 16)
                        |   (((tb_uint32_t)md5->ip[ii + 1]) << 8)
                        |   ((tb_uint32_t)md5->ip[ii]);
            }

            tb_md5_transform(md5->sp, ip);
            mdi = 0;
        }
    }
}

tb_void_t tb_md5_exit(tb_md5_t* md5, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(md5 && data);

    // init
    tb_uint32_t ip[16];
    tb_int_t    mdi = 0;
    tb_size_t   i = 0;
    tb_size_t   ii = 0;
    tb_size_t   pad_n = 0;

    // save number of bits 
    ip[14] = md5->i[0];
    ip[15] = md5->i[1];

    // compute number of bytes mod 64
    mdi = (tb_int_t)((md5->i[0] >> 3) & 0x3F);

    // pad out to 56 mod 64
    pad_n = (mdi < 56) ? (56 - mdi) : (120 - mdi);
    tb_md5_spak (md5, g_md5_padding, pad_n);

    // append length ip bits and transform
    for (i = 0, ii = 0; i < 14; i++, ii += 4)
    {
        ip[i] =     (((tb_uint32_t)md5->ip[ii + 3]) << 24)
                |   (((tb_uint32_t)md5->ip[ii + 2]) << 16)
                |   (((tb_uint32_t)md5->ip[ii + 1]) <<  8)
                |   ((tb_uint32_t)md5->ip[ii]);
    }
    tb_md5_transform (md5->sp, ip);

    // store buffer ip data
    for (i = 0, ii = 0; i < 4; i++, ii += 4)
    {
        md5->data[ii]   = (tb_byte_t)( md5->sp[i]        & 0xff);
        md5->data[ii+1] = (tb_byte_t)((md5->sp[i] >>  8) & 0xff);
        md5->data[ii+2] = (tb_byte_t)((md5->sp[i] >> 16) & 0xff);
        md5->data[ii+3] = (tb_byte_t)((md5->sp[i] >> 24) & 0xff);
    }

    // output
    tb_memcpy(data, md5->data, 16);
}

tb_size_t tb_md5_make(tb_byte_t const* ib, tb_size_t in, tb_byte_t* ob, tb_size_t on)
{
    // check
    tb_assert_and_check_return_val(ib && in && ob && on >= 16, 0);

    // init 
    tb_md5_t md5;
    tb_md5_init(&md5, 0);

    // spank
    tb_md5_spak(&md5, ib, in);

    // exit
    tb_md5_exit(&md5, ob, on);

    // ok
    return 16;
}

