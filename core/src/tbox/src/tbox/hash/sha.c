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
 * @file        sha.c
 * @ingroup     hash
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "sha.h"
#include "../utils/bits.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// rol
#define TB_SHA_ROL(v, b)               (((v) << (b)) | ((v) >> (32 - (b))))

// (TB_SHA_R0 + TB_SHA_R1), TB_SHA_R2, TB_SHA_R3, TB_SHA_R4 are the different operations used in SHA1
#define TB_SHA_BLK0(i)                 (block[i] = tb_bits_be_to_ne_u32(((tb_uint32_t const*)buffer)[i]))
#define TB_SHA_BLK(i)                  (block[i] = TB_SHA_ROL(block[i - 3] ^ block[i - 8] ^ block[i - 14] ^ block[i - 16], 1))

#define TB_SHA_R0(v, w, x, y, z, i)     z += ((w & (x ^ y)) ^ y) + TB_SHA_BLK0(i) + 0x5a827999 + TB_SHA_ROL(v, 5);        w = TB_SHA_ROL(w, 30);
#define TB_SHA_R1(v, w, x, y, z, i)     z += ((w &(x ^ y)) ^ y) + TB_SHA_BLK(i) + 0x5a827999 + TB_SHA_ROL(v, 5);          w = TB_SHA_ROL(w, 30);
#define TB_SHA_R2(v, w, x, y, z, i)     z += (w ^ x ^ y) + TB_SHA_BLK(i) + 0x6ed9eba1 + TB_SHA_ROL(v, 5);                 w = TB_SHA_ROL(w, 30);
#define TB_SHA_R3(v, w, x, y, z, i)     z += (((w | x) & y) | (w & x)) + TB_SHA_BLK(i) + 0x8f1bbcdc + TB_SHA_ROL(v, 5);   w = TB_SHA_ROL(w, 30);
#define TB_SHA_R4(v, w, x, y, z, i)     z += (w ^ x ^ y) + TB_SHA_BLK(i) + 0xca62c1d6 + TB_SHA_ROL(v, 5);                 w = TB_SHA_ROL(w, 30);

#define TB_SHA_CH(x,y,z)                (((x) & ((y) ^ (z))) ^ (z))
#define TB_SHA_MAJ(x,y,z)               ((((x) | (y)) & (z)) | ((x) & (y)))

#define TB_SHA_SIGMA0_256(x)            (TB_SHA_ROL((x), 30) ^ TB_SHA_ROL((x), 19) ^ TB_SHA_ROL((x), 10))
#define TB_SHA_SIGMA1_256(x)            (TB_SHA_ROL((x), 26) ^ TB_SHA_ROL((x), 21) ^ TB_SHA_ROL((x),  7))
#define TB_SHA_SIGMA0_256_(x)           (TB_SHA_ROL((x), 25) ^ TB_SHA_ROL((x), 14) ^ ((x) >> 3))
#define TB_SHA_SIGMA1_256_(x)           (TB_SHA_ROL((x), 15) ^ TB_SHA_ROL((x), 13) ^ ((x) >> 10))
#define TB_SHA_BLK_(i)                  (block[i] = block[i - 16] + TB_SHA_SIGMA0_256_(block[i - 15]) + TB_SHA_SIGMA1_256_(block[i - 2]) + block[i - 7])

// round256
#define TB_SHA_ROUND256(a,b,c,d,e,f,g,h) \
    T1 += (h) + TB_SHA_SIGMA1_256(e) + TB_SHA_CH((e), (f), (g)) + g_sha_k256[i]; \
    (d) += T1; \
    (h) = T1 + TB_SHA_SIGMA0_256(a) + TB_SHA_MAJ((a), (b), (c)); \
    i++

// round256(0, 15)
#define TB_SHA_ROUND256_0_TO_15(a,b,c,d,e,f,g,h) \
    T1 = TB_SHA_BLK0(i); \
    TB_SHA_ROUND256(a,b,c,d,e,f,g,h)

// round256(16, 63)
#define TB_SHA_ROUND256_16_TO_63(a,b,c,d,e,f,g,h) \
    T1 = TB_SHA_BLK_(i); \
    TB_SHA_ROUND256(a,b,c,d,e,f,g,h)

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
static tb_uint32_t const g_sha_k256[64] = 
{
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t tb_sha_transform_sha1(tb_uint32_t state[5], tb_byte_t const buffer[64])
{
    // init 
    tb_uint32_t block[80];
    tb_uint32_t a = state[0];
    tb_uint32_t b = state[1];
    tb_uint32_t c = state[2];
    tb_uint32_t d = state[3];
    tb_uint32_t e = state[4];

#ifdef __tb_small__

    // done
    tb_size_t i = 0;
    for (i = 0; i < 80; i++)
    {
        tb_int_t t;
        if (i < 16) t = tb_bits_be_to_ne_u32(((tb_uint32_t*)buffer)[i]);
        else t = TB_SHA_ROL(block[i - 3] ^ block[i - 8] ^ block[i - 14] ^ block[i - 16], 1);
        block[i] = t;
        t += e + TB_SHA_ROL(a, 5);

        if (i < 40) 
        {
            if (i < 20) t += ((b & (c ^ d)) ^ d) + 0x5a827999;
            else t += ( b ^ c ^ d) + 0x6ED9EBA1;
        } 
        else 
        {
            if (i < 60) t += (((b | c) & d) | (b & c)) + 0x8f1bbcdc;
            else t += ( b ^ c ^ d) + 0xca62c1d6;
        }

        e = d;
        d = c;
        c = TB_SHA_ROL(b, 30);
        b = a;
        a = t;
    }
#else
    // done
    tb_size_t i = 0;
    for (i = 0; i < 15; i += 5)
    {
        TB_SHA_R0(a, b, c, d, e, 0 + i);
        TB_SHA_R0(e, a, b, c, d, 1 + i);
        TB_SHA_R0(d, e, a, b, c, 2 + i);
        TB_SHA_R0(c, d, e, a, b, 3 + i);
        TB_SHA_R0(b, c, d, e, a, 4 + i);
    }

    TB_SHA_R0(a, b, c, d, e, 15);
    TB_SHA_R1(e, a, b, c, d, 16);
    TB_SHA_R1(d, e, a, b, c, 17);
    TB_SHA_R1(c, d, e, a, b, 18);
    TB_SHA_R1(b, c, d, e, a, 19);

    for (i = 20; i < 40; i += 5)
    {
        TB_SHA_R2(a, b, c, d, e, 0 + i);
        TB_SHA_R2(e, a, b, c, d, 1 + i);
        TB_SHA_R2(d, e, a, b, c, 2 + i);
        TB_SHA_R2(c, d, e, a, b, 3 + i);
        TB_SHA_R2(b, c, d, e, a, 4 + i);
    }
    for (; i < 60; i += 5)
    {
        TB_SHA_R3(a, b, c, d, e, 0 + i);
        TB_SHA_R3(e, a, b, c, d, 1 + i);
        TB_SHA_R3(d, e, a, b, c, 2 + i);
        TB_SHA_R3(c, d, e, a, b, 3 + i);
        TB_SHA_R3(b, c, d, e, a, 4 + i);
    }
    for (; i < 80; i += 5)
    {
        TB_SHA_R4(a, b, c, d, e, 0 + i);
        TB_SHA_R4(e, a, b, c, d, 1 + i);
        TB_SHA_R4(d, e, a, b, c, 2 + i);
        TB_SHA_R4(c, d, e, a, b, 3 + i);
        TB_SHA_R4(b, c, d, e, a, 4 + i);
    }
#endif

    // update state
    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
}

static tb_void_t tb_sha_transform_sha2(tb_uint32_t* state, tb_byte_t const buffer[64])
{
    // init
    tb_uint32_t T1;
    tb_uint32_t block[64];
    tb_uint32_t a = state[0];
    tb_uint32_t b = state[1];
    tb_uint32_t c = state[2];
    tb_uint32_t d = state[3];
    tb_uint32_t e = state[4];
    tb_uint32_t f = state[5];
    tb_uint32_t g = state[6];
    tb_uint32_t h = state[7];

#ifdef __tb_small__

    // done
    tb_uint32_t T2;
    tb_size_t   i = 0;
    for (i = 0; i < 64; i++) 
    {
        if (i < 16) T1 = TB_SHA_BLK0(i);
        else T1 = TB_SHA_BLK_(i);

        T1 += h + TB_SHA_SIGMA1_256(e) + TB_SHA_CH(e, f, g) + g_sha_k256[i];
        T2 = TB_SHA_SIGMA0_256(a) + TB_SHA_MAJ(a, b, c);

        h = g;
        g = f;
        f = e;
        e = d + T1;
        d = c;
        c = b;
        b = a;
        a = T1 + T2;
    }
#else

    // done
    tb_size_t   i = 0;
    for (i = 0; i < 16; ) 
    {
        TB_SHA_ROUND256_0_TO_15(a, b, c, d, e, f, g, h);
        TB_SHA_ROUND256_0_TO_15(h, a, b, c, d, e, f, g);
        TB_SHA_ROUND256_0_TO_15(g, h, a, b, c, d, e, f);
        TB_SHA_ROUND256_0_TO_15(f, g, h, a, b, c, d, e);
        TB_SHA_ROUND256_0_TO_15(e, f, g, h, a, b, c, d);
        TB_SHA_ROUND256_0_TO_15(d, e, f, g, h, a, b, c);
        TB_SHA_ROUND256_0_TO_15(c, d, e, f, g, h, a, b);
        TB_SHA_ROUND256_0_TO_15(b, c, d, e, f, g, h, a);
    }

    for ( ; i < 64; ) 
    {
        TB_SHA_ROUND256_16_TO_63(a, b, c, d, e, f, g, h);
        TB_SHA_ROUND256_16_TO_63(h, a, b, c, d, e, f, g);
        TB_SHA_ROUND256_16_TO_63(g, h, a, b, c, d, e, f);
        TB_SHA_ROUND256_16_TO_63(f, g, h, a, b, c, d, e);
        TB_SHA_ROUND256_16_TO_63(e, f, g, h, a, b, c, d);
        TB_SHA_ROUND256_16_TO_63(d, e, f, g, h, a, b, c);
        TB_SHA_ROUND256_16_TO_63(c, d, e, f, g, h, a, b);
        TB_SHA_ROUND256_16_TO_63(b, c, d, e, f, g, h, a);
    }
#endif

    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
    state[5] += f;
    state[6] += g;
    state[7] += h;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_sha_init(tb_sha_t* sha, tb_size_t mode)
{
    // check
    tb_assert_and_check_return(sha);

    // init sha
    tb_memset(sha, 0, sizeof(tb_sha_t));

    // done
    sha->digest_len = (mode >> 5) & 0xff;
    switch (mode) 
    {
    case TB_SHA_MODE_SHA1_160:
        sha->state[0] = 0x67452301;
        sha->state[1] = 0xefcdab89;
        sha->state[2] = 0x98badcfe;
        sha->state[3] = 0x10325476;
        sha->state[4] = 0xc3d2e1f0;
        sha->transform = tb_sha_transform_sha1;
        break;
    case TB_SHA_MODE_SHA2_224:
        sha->state[0] = 0xc1059ed8;
        sha->state[1] = 0x367cd507;
        sha->state[2] = 0x3070dd17;
        sha->state[3] = 0xf70e5939;
        sha->state[4] = 0xffc00b31;
        sha->state[5] = 0x68581511;
        sha->state[6] = 0x64f98fa7;
        sha->state[7] = 0xbefa4fa4;
        sha->transform = tb_sha_transform_sha2;
        break;
    case TB_SHA_MODE_SHA2_256: 
        sha->state[0] = 0x6a09e667;
        sha->state[1] = 0xbb67ae85;
        sha->state[2] = 0x3c6ef372;
        sha->state[3] = 0xa54ff53a;
        sha->state[4] = 0x510e527f;
        sha->state[5] = 0x9b05688c;
        sha->state[6] = 0x1f83d9ab;
        sha->state[7] = 0x5be0cd19;
        sha->transform = tb_sha_transform_sha2;
        break;
    default:
        tb_assert(0);
        break;
    }
    sha->count = 0;
}
tb_void_t tb_sha_exit(tb_sha_t* sha, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(sha && data);

    // the count
    tb_hize_t count = tb_bits_be_to_ne_u64(sha->count << 3);

    // spak 
    tb_sha_spak(sha, (tb_byte_t const*)"\200", 1);
    while ((sha->count & 63) != 56) tb_sha_spak(sha, (tb_byte_t const*)"", 1);
    tb_sha_spak(sha, (tb_byte_t*)&count, 8);

    // done
    tb_uint32_t i = 0;
    tb_uint32_t n = sha->digest_len;
    tb_assert((n << 2) <= size);
    for (i = 0; i < n; i++) tb_bits_set_u32_be(data + (i << 2), sha->state[i]);
}
tb_void_t tb_sha_spak(tb_sha_t* sha, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(sha && data);

    // update count
    tb_uint32_t j = (tb_uint32_t)sha->count & 63;
    sha->count += size;

    // done
    tb_uint32_t i;
#ifdef __tb_small__
    for (i = 0; i < size; i++) 
    {
        sha->buffer[j++] = data[i];
        if (64 == j) 
        {
            sha->transform(sha->state, sha->buffer);
            j = 0;
        }
    }
#else
    if ((j + size) > 63)
    {
        tb_memcpy(&sha->buffer[j], data, (i = 64 - j));
        sha->transform(sha->state, sha->buffer);
        for (; i + 63 < size; i += 64)
            sha->transform(sha->state, &data[i]);
        j = 0;
    } 
    else i = 0;
    tb_memcpy(&sha->buffer[j], &data[i], size - i);
#endif
}
tb_size_t tb_sha_make(tb_size_t mode, tb_byte_t const* ib, tb_size_t in, tb_byte_t* ob, tb_size_t on)
{
    // check
    tb_assert_and_check_return_val(ib && in && ob && on >= 16, 0);

    // init 
    tb_sha_t sha;
    tb_sha_init(&sha, mode);

    // spank
    tb_sha_spak(&sha, ib, in);

    // exit
    tb_sha_exit(&sha, ob, on);

    // ok?
    return (sha.digest_len << 2);
}

