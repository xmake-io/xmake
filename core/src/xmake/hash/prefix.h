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
 * @file        prefix.h
 *
 */
#ifndef XM_HASH_PREFIX_H
#define XM_HASH_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * helper implementation
 */

static __tb_inline__ tb_uint32_t xm_hash_xorshift32(tb_uint32_t x)
{
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    return x;
}

static __tb_inline__ tb_uint64_t xm_hash_xorshift64(tb_uint64_t x)
{
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    return x;
}

// http://xorshift.di.unimi.it/xorshift128plus.c
static __tb_inline__ tb_uint64_t xm_hash_xorshift128(tb_uint64_t* s)
{
    tb_uint64_t s1       = s[0];
    tb_uint64_t const s0 = s[1];
    s[0] = s0;
    s1 ^= s1 << 23;
    s[1] = s1 ^ s0 ^ (s1 >> 18) ^ (s0 >> 5);
    return s[1] + s0;
}

static __tb_inline__ tb_size_t xm_hash_make_cstr(tb_char_t hash[256], tb_byte_t const* data, tb_size_t size)
{
    static tb_char_t const* digits_table = "0123456789abcdef";
    tb_size_t i = 0;
    tb_byte_t value;
    tb_char_t* s = hash;
    for (i = 0; i < size; ++i)
    {
        value = data[i];
        s[0] = digits_table[(value >> 4) & 15];
        s[1] = digits_table[value & 15];
        s += 2;
    }
    *s = '\0';
    return s - hash;
}

#endif


