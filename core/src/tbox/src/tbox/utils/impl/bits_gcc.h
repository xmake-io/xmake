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
 * @file        bits_gcc.h
 *
 */
#ifndef TB_UTILS_IMPL_BITS_GCC_H
#define TB_UTILS_IMPL_BITS_GCC_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
// swap 
#if TB_COMPILER_VERSION_BE(4, 3)
#   define tb_bits_swap_u32(x)      __builtin_bswap32(x)
#   define tb_bits_swap_u64(x)      __builtin_bswap64(x)
#endif

// cl0
#if TB_COMPILER_VERSION_BE(4, 1)
#   define tb_bits_cl0_u32_be(x)    ((x)? (tb_size_t)__builtin_clz((tb_uint32_t)(x)) : 32)
#   define tb_bits_cl0_u32_le(x)    ((x)? (tb_size_t)__builtin_ctz((tb_uint32_t)(x)) : 32)
#   define tb_bits_cl0_u64_be(x)    ((x)? (tb_size_t)__builtin_clzll((tb_uint64_t)(x)) : 64)
#   define tb_bits_cl0_u64_le(x)    ((x)? (tb_size_t)__builtin_ctzll((tb_uint64_t)(x)) : 64)
#endif

// cb1
#if TB_COMPILER_VERSION_BE(4, 1)
#   define tb_bits_cb1_u32(x)       ((x)? (tb_size_t)__builtin_popcount((tb_uint32_t)(x)) : 0)
#   define tb_bits_cb1_u64(x)       ((x)? (tb_size_t)__builtin_popcountll((tb_uint64_t)(x)) : 0)
#endif

// fb1
#if TB_COMPILER_VERSION_BE(4, 1)
#   define tb_bits_fb1_u32_le(x)    ((x)? (tb_size_t)__builtin_ffs((tb_uint32_t)(x)) - 1 : 32)
#   define tb_bits_fb1_u64_le(x)    ((x)? (tb_size_t)__builtin_ffsll((tb_uint64_t)(x)) - 1 : 64)
#endif

#endif 


