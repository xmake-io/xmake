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
 * @file        bits.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_BITS_H
#define TB_UTILS_BITS_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../libm/libm.h"
#if defined(TB_COMPILER_IS_GCC) \
    && TB_COMPILER_VERSION_BE(4, 1)
#   include "impl/bits_gcc.h"
#endif
#if defined(TB_ARCH_x86) || defined(TB_ARCH_x64)
#   include "impl/bits_x86.h"
#elif defined(TB_ARCH_ARM)
#   include "impl/bits_arm.h"
#elif defined(TB_ARCH_SH4)
#   include "impl/bits_sh4.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// 1-bits
#define tb_bits_get_u1(p)                   (((*(p)) >> 7) & 1)
#define tb_bits_set_u1(p, x)                do { *(p) &= 0x7f; *(p) |= (((x) & 0x1) << 7); } while (0)

// 8-bits
#define tb_bits_get_u8(p)                   (*(p))
#define tb_bits_get_s8(p)                   (*(p))

#define tb_bits_set_u8(p, x)                do { *(p) = (tb_uint8_t)(x); } while (0)
#define tb_bits_set_s8(p, x)                do { *(p) = (tb_sint8_t)(x); } while (0)

// 16-bits
#define tb_bits_get_u16_le_impl(p)          ((tb_uint16_t)((tb_uint16_t)*((p) + 1) << 8 | (tb_uint16_t)*(p)))
#define tb_bits_get_s16_le_impl(p)          tb_bits_get_u16_le_impl(p)
#define tb_bits_get_u16_be_impl(p)          ((tb_uint16_t)(*((p)) << 8 | (tb_uint16_t)*((p) + 1)))
#define tb_bits_get_s16_be_impl(p)          tb_bits_get_u16_be_impl(p)
#define tb_bits_get_u16_ne_impl(p)          (*((tb_uint16_t*)(p)))
#define tb_bits_get_s16_ne_impl(p)          tb_bits_get_u16_ne_impl(p)

#define tb_bits_set_u16_le_impl(p, x)       tb_bits_set_u16_le_inline(p, x)
#define tb_bits_set_s16_le_impl(p, x)       tb_bits_set_u16_le_inline(p, x)
#define tb_bits_set_u16_be_impl(p, x)       tb_bits_set_u16_be_inline(p, x)
#define tb_bits_set_s16_be_impl(p, x)       tb_bits_set_u16_be_inline(p, x)
#define tb_bits_set_u16_ne_impl(p, x)       do { *((tb_uint16_t*)(p)) = (tb_uint16_t)(x); } while (0)
#define tb_bits_set_s16_ne_impl(p, x)       tb_bits_set_u16_ne_impl(p, x)

// 24-bits
#define tb_bits_get_u24_le_impl(p)          ((tb_uint32_t)(*((p) + 2) << 16 | *((p) + 1) << 8 | *(p)))
#define tb_bits_get_s24_le_impl(p)          ((tb_bits_get_u24_le_impl(p) + 0xff800000) ^ 0xff800000)
#define tb_bits_get_u24_be_impl(p)          ((tb_uint32_t)(*(p) << 16 | *((p) + 1) << 8 | *((p) + 2)))
#define tb_bits_get_s24_be_impl(p)          ((tb_bits_get_u24_be_impl(p) + 0xff800000) ^ 0xff800000)
#define tb_bits_get_u24_ne_impl(p)          ((tb_uint32_t)(*((tb_uint32_t*)(p)) & 0x00ffffff))
#define tb_bits_get_s24_ne_impl(p)          ((tb_bits_get_u24_ne_impl(p) + 0xff800000) ^ 0xff800000)

#define tb_bits_set_u24_le_impl(p, x)       tb_bits_set_u24_le_inline(p, x)
#define tb_bits_set_s24_le_impl(p, x)       tb_bits_set_u24_le_inline(p, x)
#define tb_bits_set_u24_be_impl(p, x)       tb_bits_set_u24_be_inline(p, x)
#define tb_bits_set_s24_be_impl(p, x)       tb_bits_set_u24_be_inline(p, x)
#define tb_bits_set_u24_ne_impl(p, x)       do { *((tb_uint32_t*)(p)) = (tb_uint32_t)(x) & 0x00ffffff; } while (0)
#define tb_bits_set_s24_ne_impl(p, x)       tb_bits_set_u24_ne_impl(p, x)

// 32-bits
#define tb_bits_get_u32_le_impl(p)          ((tb_uint32_t)(*((p) + 3) << 24 | *((p) + 2) << 16 | *((p) + 1) << 8 | *(p)))
#define tb_bits_get_s32_le_impl(p)          tb_bits_get_u32_le_impl(p)
#define tb_bits_get_u32_be_impl(p)          ((tb_uint32_t)(*(p) << 24 | *((p) + 1) << 16 | *((p) + 2) << 8 | *((p) + 3)))
#define tb_bits_get_s32_be_impl(p)          tb_bits_get_u32_be_impl(p)
#define tb_bits_get_u32_ne_impl(p)          (*((tb_uint32_t*)(p)))
#define tb_bits_get_s32_ne_impl(p)          tb_bits_get_u32_ne_impl(p)

#define tb_bits_set_u32_le_impl(p, x)       tb_bits_set_u32_le_inline(p, x)
#define tb_bits_set_s32_le_impl(p, x)       tb_bits_set_u32_le_inline(p, x)
#define tb_bits_set_u32_be_impl(p, x)       tb_bits_set_u32_be_inline(p, x)
#define tb_bits_set_s32_be_impl(p, x)       tb_bits_set_u32_be_inline(p, x)
#define tb_bits_set_u32_ne_impl(p, x)       do { *((tb_uint32_t*)(p)) = (tb_uint32_t)(x); } while (0)
#define tb_bits_set_s32_ne_impl(p, x)       tb_bits_set_u32_ne_impl(p, x)

// 64-bits
#define tb_bits_get_u64_le_impl(p)          ((tb_uint64_t)*((p) + 7) << 56 | (tb_uint64_t)*((p) + 6) << 48 | (tb_uint64_t)*((p) + 5) << 40 | (tb_uint64_t)*((p) + 4) << 32 | (tb_uint64_t)*((p) + 3) << 24 | (tb_uint64_t)*((p) + 2) << 16 | (tb_uint64_t)*((p) + 1) << 8 | (tb_uint64_t)*(p))
#define tb_bits_get_s64_le_impl(p)          tb_bits_get_u64_le_impl(p)
#define tb_bits_get_u64_be_impl(p)          ((tb_uint64_t)*(p) << 56 | (tb_uint64_t)*((p) + 1) << 48 | (tb_uint64_t)*((p) + 2) << 40 | (tb_uint64_t)*((p) + 3) << 32 | (tb_uint64_t)*((p) + 4) << 24 | (tb_uint64_t)*((p) + 5) << 16 | (tb_uint64_t)*((p) + 6) << 8 | (tb_uint64_t)*((p) + 7))
#define tb_bits_get_s64_be_impl(p)          tb_bits_get_u64_be_impl(p)
#define tb_bits_get_u64_ne_impl(p)          (*((tb_uint64_t*)(p)))
#define tb_bits_get_s64_ne_impl(p)          tb_bits_get_u64_ne_impl(p)

#define tb_bits_set_u64_le_impl(p, x)       tb_bits_set_u64_le_inline(p, x)
#define tb_bits_set_s64_le_impl(p, x)       tb_bits_set_u64_le_inline(p, x)
#define tb_bits_set_u64_be_impl(p, x)       tb_bits_set_u64_be_inline(p, x)
#define tb_bits_set_s64_be_impl(p, x)       tb_bits_set_u64_be_inline(p, x)
#define tb_bits_set_u64_ne_impl(p, x)       do { *((tb_uint64_t*)(p)) = (tb_uint64_t)(x); } while (0)
#define tb_bits_set_s64_ne_impl(p, x)       tb_bits_set_u64_ne_impl(p, x)

// float
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT

#   define tb_bits_get_float_le(p)              tb_bits_get_float_le_inline(p)
#   define tb_bits_get_float_be(p)              tb_bits_get_float_be_inline(p)

#   define tb_bits_set_float_le(p, x)           tb_bits_set_float_le_inline(p, x)
#   define tb_bits_set_float_be(p, x)           tb_bits_set_float_be_inline(p, x)

#   define tb_bits_get_double_ble(p)            tb_bits_get_double_ble_inline(p)
#   define tb_bits_get_double_bbe(p)            tb_bits_get_double_bbe_inline(p)

#   define tb_bits_get_double_lle(p)            tb_bits_get_double_lle_inline(p)
#   define tb_bits_get_double_lbe(p)            tb_bits_get_double_lbe_inline(p)

#   define tb_bits_set_double_ble(p, x)         tb_bits_set_double_ble_inline(p, x)
#   define tb_bits_set_double_bbe(p, x)         tb_bits_set_double_bbe_inline(p, x)

#   define tb_bits_set_double_lle(p, x)         tb_bits_set_double_lle_inline(p, x)
#   define tb_bits_set_double_lbe(p, x)         tb_bits_set_double_lbe_inline(p, x)

#   ifdef TB_FLOAT_BIGENDIAN
#       define tb_bits_get_double_nbe(p)        tb_bits_get_double_bbe(p)
#       define tb_bits_get_double_nle(p)        tb_bits_get_double_ble(p)

#       define tb_bits_set_double_nbe(p, x)     tb_bits_set_double_bbe(p, x)
#       define tb_bits_set_double_nle(p, x)     tb_bits_set_double_ble(p, x)
#   else
#       define tb_bits_get_double_nbe(p)        tb_bits_get_double_lbe(p)
#       define tb_bits_get_double_nle(p)        tb_bits_get_double_lle(p)

#       define tb_bits_set_double_nbe(p, x)     tb_bits_set_double_lbe(p, x)
#       define tb_bits_set_double_nle(p, x)     tb_bits_set_double_lle(p, x)
#   endif
#   ifdef TB_WORDS_BIGENDIAN
#       define tb_bits_get_float_ne(p)          tb_bits_get_float_be(p)
#       define tb_bits_set_float_ne(p, x)       tb_bits_set_float_be(p, x)

#       define tb_bits_get_double_nne(p)        tb_bits_get_double_nbe(p)
#       define tb_bits_get_double_bne(p)        tb_bits_get_double_bbe(p)
#       define tb_bits_get_double_lne(p)        tb_bits_get_double_lbe(p)

#       define tb_bits_set_double_nne(p, x)     tb_bits_set_double_nbe(p, x)
#       define tb_bits_set_double_bne(p, x)     tb_bits_set_double_bbe(p, x)
#       define tb_bits_set_double_lne(p, x)     tb_bits_set_double_lbe(p, x)
#   else
#       define tb_bits_get_float_ne(p)          tb_bits_get_float_le(p)
#       define tb_bits_set_float_ne(p, x)       tb_bits_set_float_le(p, x)

#       define tb_bits_get_double_nne(p)        tb_bits_get_double_nle(p)
#       define tb_bits_get_double_bne(p)        tb_bits_get_double_ble(p)
#       define tb_bits_get_double_lne(p)        tb_bits_get_double_lle(p)

#       define tb_bits_set_double_nne(p, x)     tb_bits_set_double_nle(p, x)
#       define tb_bits_set_double_bne(p, x)     tb_bits_set_double_ble(p, x)
#       define tb_bits_set_double_lne(p, x)     tb_bits_set_double_lle(p, x)
#   endif
#endif

#ifdef TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE

#   ifdef TB_WORDS_BIGENDIAN
// 16-bits
#   define tb_bits_get_u16_le(p)        tb_bits_get_u16_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_s16_le(p)        tb_bits_get_s16_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_u16_be(p)        tb_bits_get_u16_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_s16_be(p)        tb_bits_get_s16_ne_impl((tb_byte_t*)(p))

#   define tb_bits_set_u16_le(p, x)     tb_bits_set_u16_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s16_le(p, x)     tb_bits_set_s16_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u16_be(p, x)     tb_bits_set_u16_ne_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s16_be(p, x)     tb_bits_set_s16_ne_impl((tb_byte_t*)(p), x)

// 24-bits
#   define tb_bits_get_u24_le(p)        tb_bits_get_u24_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_s24_le(p)        tb_bits_get_s24_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_u24_be(p)        tb_bits_get_u24_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_s24_be(p)        tb_bits_get_s24_ne_impl((tb_byte_t*)(p))

#   define tb_bits_set_u24_le(p, x)     tb_bits_set_u24_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s24_le(p, x)     tb_bits_set_s24_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u24_be(p, x)     tb_bits_set_u24_ne_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s24_be(p, x)     tb_bits_set_s24_ne_impl((tb_byte_t*)(p), x)

// 32-bits
#   define tb_bits_get_u32_le(p)        tb_bits_get_u32_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_s32_le(p)        tb_bits_get_s32_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_u32_be(p)        tb_bits_get_u32_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_s32_be(p)        tb_bits_get_s32_ne_impl((tb_byte_t*)(p))

#   define tb_bits_set_u32_le(p, x)     tb_bits_set_u32_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s32_le(p, x)     tb_bits_set_u32_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u32_be(p, x)     tb_bits_set_u32_ne_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s32_be(p, x)     tb_bits_set_s32_ne_impl((tb_byte_t*)(p), x)

// 64-bits
#   define tb_bits_get_u64_le(p)        tb_bits_get_u64_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_s64_le(p)        tb_bits_get_s64_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_u64_be(p)        tb_bits_get_u64_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_s64_be(p)        tb_bits_get_s64_ne_impl((tb_byte_t*)(p))

#   define tb_bits_set_u64_le(p, x)     tb_bits_set_u64_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s64_le(p, x)     tb_bits_set_u64_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u64_be(p, x)     tb_bits_set_u64_ne_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s64_be(p, x)     tb_bits_set_s64_ne_impl((tb_byte_t*)(p), x)

#   else

// 16-bits
#   define tb_bits_get_u16_le(p)        tb_bits_get_u16_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_s16_le(p)        tb_bits_get_s16_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_u16_be(p)        tb_bits_get_u16_be_impl((tb_byte_t*)(p))
#   define tb_bits_get_s16_be(p)        tb_bits_get_s16_be_impl((tb_byte_t*)(p))

#   define tb_bits_set_u16_le(p, x)     tb_bits_set_u16_ne_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s16_le(p, x)     tb_bits_set_s16_ne_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u16_be(p, x)     tb_bits_set_u16_be_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s16_be(p, x)     tb_bits_set_s16_be_impl((tb_byte_t*)(p), x)

// 24-bits
#   define tb_bits_get_u24_le(p)        tb_bits_get_u24_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_s24_le(p)        tb_bits_get_s24_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_u24_be(p)        tb_bits_get_u24_be_impl((tb_byte_t*)(p))
#   define tb_bits_get_s24_be(p)        tb_bits_get_s24_be_impl((tb_byte_t*)(p))

#   define tb_bits_set_u24_le(p, x)     tb_bits_set_u24_ne_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s24_le(p, x)     tb_bits_set_s24_ne_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u24_be(p, x)     tb_bits_set_u24_be_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s24_be(p, x)     tb_bits_set_s24_be_impl((tb_byte_t*)(p), x)

// 32-bits
#   define tb_bits_get_u32_le(p)        tb_bits_get_u32_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_s32_le(p)        tb_bits_get_s32_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_u32_be(p)        tb_bits_get_u32_be_impl((tb_byte_t*)(p))
#   define tb_bits_get_s32_be(p)        tb_bits_get_s32_be_impl((tb_byte_t*)(p))

#   define tb_bits_set_u32_le(p, x)     tb_bits_set_u32_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s32_le(p, x)     tb_bits_set_u32_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u32_be(p, x)     tb_bits_set_u32_be_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s32_be(p, x)     tb_bits_set_s32_be_impl((tb_byte_t*)(p), x)

// 64-bits
#   define tb_bits_get_u64_le(p)        tb_bits_get_u64_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_s64_le(p)        tb_bits_get_s64_ne_impl((tb_byte_t*)(p))
#   define tb_bits_get_u64_be(p)        tb_bits_get_u64_be_impl((tb_byte_t*)(p))
#   define tb_bits_get_s64_be(p)        tb_bits_get_s64_be_impl((tb_byte_t*)(p))

#   define tb_bits_set_u64_le(p, x)     tb_bits_set_u64_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s64_le(p, x)     tb_bits_set_u64_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u64_be(p, x)     tb_bits_set_u64_be_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s64_be(p, x)     tb_bits_set_s64_be_impl((tb_byte_t*)(p), x)

#   endif /* TB_WORDS_BIGENDIAN */

#else
// 16-bits
#   define tb_bits_get_u16_le(p)        tb_bits_get_u16_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_s16_le(p)        tb_bits_get_s16_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_u16_be(p)        tb_bits_get_u16_be_impl((tb_byte_t*)(p))
#   define tb_bits_get_s16_be(p)        tb_bits_get_s16_be_impl((tb_byte_t*)(p))

#   define tb_bits_set_u16_le(p, x)     tb_bits_set_u16_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s16_le(p, x)     tb_bits_set_s16_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u16_be(p, x)     tb_bits_set_u16_be_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s16_be(p, x)     tb_bits_set_s16_be_impl((tb_byte_t*)(p), x)

// 24-bits
#   define tb_bits_get_u24_le(p)        tb_bits_get_u24_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_s24_le(p)        tb_bits_get_s24_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_u24_be(p)        tb_bits_get_u24_be_impl((tb_byte_t*)(p))
#   define tb_bits_get_s24_be(p)        tb_bits_get_s24_be_impl((tb_byte_t*)(p))

#   define tb_bits_set_u24_le(p, x)     tb_bits_set_u24_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s24_le(p, x)     tb_bits_set_s24_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u24_be(p, x)     tb_bits_set_u24_be_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s24_be(p, x)     tb_bits_set_s24_be_impl((tb_byte_t*)(p), x)

// 32-bits
#   define tb_bits_get_u32_le(p)        tb_bits_get_u32_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_s32_le(p)        tb_bits_get_s32_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_u32_be(p)        tb_bits_get_u32_be_impl((tb_byte_t*)(p))
#   define tb_bits_get_s32_be(p)        tb_bits_get_s32_be_impl((tb_byte_t*)(p))

#   define tb_bits_set_u32_le(p, x)     tb_bits_set_u32_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s32_le(p, x)     tb_bits_set_u32_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u32_be(p, x)     tb_bits_set_u32_be_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s32_be(p, x)     tb_bits_set_s32_be_impl((tb_byte_t*)(p), x)

// 64-bits
#   define tb_bits_get_u64_le(p)        tb_bits_get_u64_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_s64_le(p)        tb_bits_get_s64_le_impl((tb_byte_t*)(p))
#   define tb_bits_get_u64_be(p)        tb_bits_get_u64_be_impl((tb_byte_t*)(p))
#   define tb_bits_get_s64_be(p)        tb_bits_get_s64_be_impl((tb_byte_t*)(p))

#   define tb_bits_set_u64_le(p, x)     tb_bits_set_u64_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s64_le(p, x)     tb_bits_set_u64_le_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_u64_be(p, x)     tb_bits_set_u64_be_impl((tb_byte_t*)(p), x)
#   define tb_bits_set_s64_be(p, x)     tb_bits_set_s64_be_impl((tb_byte_t*)(p), x)

#endif /* TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE */

#ifdef TB_WORDS_BIGENDIAN
#   define tb_bits_get_u16_ne(p)        tb_bits_get_u16_be(p)
#   define tb_bits_get_s16_ne(p)        tb_bits_get_s16_be(p)
#   define tb_bits_get_u24_ne(p)        tb_bits_get_u24_be(p)
#   define tb_bits_get_s24_ne(p)        tb_bits_get_s24_be(p)
#   define tb_bits_get_u32_ne(p)        tb_bits_get_u32_be(p)
#   define tb_bits_get_s32_ne(p)        tb_bits_get_s32_be(p)
#   define tb_bits_get_u64_ne(p)        tb_bits_get_u64_be(p)
#   define tb_bits_get_s64_ne(p)        tb_bits_get_s64_be(p)

#   define tb_bits_set_u16_ne(p, x)     tb_bits_set_u16_be(p, x)
#   define tb_bits_set_s16_ne(p, x)     tb_bits_set_s16_be(p, x)
#   define tb_bits_set_u24_ne(p, x)     tb_bits_set_u24_be(p, x)
#   define tb_bits_set_s24_ne(p, x)     tb_bits_set_s24_be(p, x)
#   define tb_bits_set_u32_ne(p, x)     tb_bits_set_u32_be(p, x)
#   define tb_bits_set_s32_ne(p, x)     tb_bits_set_s32_be(p, x)
#   define tb_bits_set_u64_ne(p, x)     tb_bits_set_u64_be(p, x)
#   define tb_bits_set_s64_ne(p, x)     tb_bits_set_s64_be(p, x)

#else
#   define tb_bits_get_u16_ne(p)        tb_bits_get_u16_le(p)
#   define tb_bits_get_s16_ne(p)        tb_bits_get_s16_le(p)
#   define tb_bits_get_u24_ne(p)        tb_bits_get_u24_le(p)
#   define tb_bits_get_s24_ne(p)        tb_bits_get_s24_le(p)
#   define tb_bits_get_u32_ne(p)        tb_bits_get_u32_le(p)
#   define tb_bits_get_s32_ne(p)        tb_bits_get_s32_le(p)
#   define tb_bits_get_u64_ne(p)        tb_bits_get_u64_le(p)
#   define tb_bits_get_s64_ne(p)        tb_bits_get_s64_le(p)

#   define tb_bits_set_u16_ne(p, x)     tb_bits_set_u16_le(p, x)
#   define tb_bits_set_s16_ne(p, x)     tb_bits_set_s16_le(p, x)
#   define tb_bits_set_u24_ne(p, x)     tb_bits_set_u24_le(p, x)
#   define tb_bits_set_s24_ne(p, x)     tb_bits_set_s24_le(p, x)
#   define tb_bits_set_u32_ne(p, x)     tb_bits_set_u32_le(p, x)
#   define tb_bits_set_s32_ne(p, x)     tb_bits_set_s32_le(p, x)
#   define tb_bits_set_u64_ne(p, x)     tb_bits_set_u64_le(p, x)
#   define tb_bits_set_s64_ne(p, x)     tb_bits_set_s64_le(p, x)

#endif /* TB_WORDS_BIGENDIAN */

// swap
#ifndef tb_bits_swap_u16
#   define tb_bits_swap_u16(x)          tb_bits_swap_u16_inline((tb_uint16_t)(x))
#endif

#ifndef tb_bits_swap_u24
#   define tb_bits_swap_u24(x)          tb_bits_swap_u24_inline((tb_uint32_t)(x))
#endif

#ifndef tb_bits_swap_u32
#   define tb_bits_swap_u32(x)          tb_bits_swap_u32_inline((tb_uint32_t)(x))
#endif

#ifndef tb_bits_swap_u64
#   define tb_bits_swap_u64(x)          tb_bits_swap_u64_inline((tb_uint64_t)(x))
#endif

#ifdef TB_WORDS_BIGENDIAN
#   define tb_bits_be_to_ne_u16(x)      ((tb_uint16_t)(x))
#   define tb_bits_le_to_ne_u16(x)      tb_bits_swap_u16(x)
#   define tb_bits_be_to_ne_u24(x)      ((tb_uint32_t)(x) & 0x00ffffff)
#   define tb_bits_le_to_ne_u24(x)      tb_bits_swap_u24(x)
#   define tb_bits_be_to_ne_u32(x)      ((tb_uint32_t)(x))
#   define tb_bits_le_to_ne_u32(x)      tb_bits_swap_u32(x)
#   define tb_bits_be_to_ne_u64(x)      ((tb_uint64_t)(x))
#   define tb_bits_le_to_ne_u64(x)      tb_bits_swap_u64(x)
#else
#   define tb_bits_be_to_ne_u16(x)      tb_bits_swap_u16(x)
#   define tb_bits_le_to_ne_u16(x)      ((tb_uint16_t)(x))
#   define tb_bits_be_to_ne_u24(x)      tb_bits_swap_u24(x)
#   define tb_bits_le_to_ne_u24(x)      ((tb_uint32_t)(x) & 0x00ffffff)
#   define tb_bits_be_to_ne_u32(x)      tb_bits_swap_u32(x)
#   define tb_bits_le_to_ne_u32(x)      ((tb_uint32_t)(x))
#   define tb_bits_be_to_ne_u64(x)      tb_bits_swap_u64(x)
#   define tb_bits_le_to_ne_u64(x)      ((tb_uint64_t)(x))
#endif

#define tb_bits_ne_to_be_u16(x)         tb_bits_be_to_ne_u16(x)
#define tb_bits_ne_to_le_u16(x)         tb_bits_le_to_ne_u16(x)
#define tb_bits_ne_to_be_u24(x)         tb_bits_be_to_ne_u24(x)
#define tb_bits_ne_to_le_u24(x)         tb_bits_le_to_ne_u24(x)
#define tb_bits_ne_to_be_u32(x)         tb_bits_be_to_ne_u32(x)
#define tb_bits_ne_to_le_u32(x)         tb_bits_le_to_ne_u32(x)
#define tb_bits_ne_to_be_u64(x)         tb_bits_be_to_ne_u64(x)
#define tb_bits_ne_to_le_u64(x)         tb_bits_le_to_ne_u64(x)

// cl0, count leading bit 0
#ifndef tb_bits_cl0_u32_be 
#   define tb_bits_cl0_u32_be(x)        tb_bits_cl0_u32_be_inline(x)
#endif
#ifndef tb_bits_cl0_u32_le
#   define tb_bits_cl0_u32_le(x)        tb_bits_cl0_u32_le_inline(x)
#endif
#ifndef tb_bits_cl0_u64_be
#   define tb_bits_cl0_u64_be(x)        tb_bits_cl0_u64_be_inline(x)
#endif
#ifndef tb_bits_cl0_u64_le
#   define tb_bits_cl0_u64_le(x)        tb_bits_cl0_u64_le_inline(x)
#endif

// cl1, count leading bit 1
#ifndef tb_bits_cl1_u32_be 
#   define tb_bits_cl1_u32_be(x)        tb_bits_cl0_u32_be(~(tb_uint32_t)(x))
#endif
#ifndef tb_bits_cl1_u32_le
#   define tb_bits_cl1_u32_le(x)        tb_bits_cl0_u32_le(~(tb_uint32_t)(x))
#endif
#ifndef tb_bits_cl1_u64_be
#   define tb_bits_cl1_u64_be(x)        tb_bits_cl0_u64_be(~(tb_uint64_t)(x))
#endif
#ifndef tb_bits_cl1_u64_le
#   define tb_bits_cl1_u64_le(x)        tb_bits_cl0_u64_le(~(tb_uint64_t)(x))
#endif

// cb1, count bit 1
#ifndef tb_bits_cb1_u32
#   define tb_bits_cb1_u32(x)           tb_bits_cb1_u32_inline(x)
#endif
#ifndef tb_bits_cb1_u64
#   define tb_bits_cb1_u64(x)           tb_bits_cb1_u64_inline(x)
#endif

// cb0, count bit 0
#ifndef tb_bits_cb0_u32
#   define tb_bits_cb0_u32(x)           ((x)? (tb_size_t)tb_bits_cb1_u32(~(tb_uint32_t)(x)) : 32)
#endif
#ifndef tb_bits_cb0_u64
#   define tb_bits_cb0_u64(x)           ((x)? (tb_size_t)tb_bits_cb1_u64(~(tb_uint64_t)(x)) : 64)
#endif

/* fb0, find the first bit 0
 * 
 * find bit zero by little endian, fb0(...11101101) == 1
 * find bit zero by big endian, fb0(...11101101) == 27
 */
#ifndef tb_bits_fb0_u32_be 
#   define tb_bits_fb0_u32_be(x)        ((x)? tb_bits_cl0_u32_be(~(tb_uint32_t)(x)) : 0)
#endif
#ifndef tb_bits_fb0_u32_le
#   define tb_bits_fb0_u32_le(x)        ((x)? tb_bits_cl0_u32_le(~(tb_uint32_t)(x)) : 0)
#endif
#ifndef tb_bits_fb0_u64_be 
#   define tb_bits_fb0_u64_be(x)        ((x)? tb_bits_cl0_u64_be(~(tb_uint64_t)(x)) : 0)
#endif
#ifndef tb_bits_fb0_u64_le
#   define tb_bits_fb0_u64_le(x)        ((x)? tb_bits_cl0_u64_le(~(tb_uint64_t)(x)) : 0)
#endif

// fb1, find the first bit 1
#ifndef tb_bits_fb1_u32_be 
#   define tb_bits_fb1_u32_be(x)        ((x)? tb_bits_cl0_u32_be(x) : 32)
#endif
#ifndef tb_bits_fb1_u32_le
#   define tb_bits_fb1_u32_le(x)        ((x)? tb_bits_cl0_u32_le(x) : 32)
#endif
#ifndef tb_bits_fb1_u64_be 
#   define tb_bits_fb1_u64_be(x)        ((x)? tb_bits_cl0_u64_be(x) : 64)
#endif
#ifndef tb_bits_fb1_u64_le
#   define tb_bits_fb1_u64_le(x)        ((x)? tb_bits_cl0_u64_le(x) : 64)
#endif

// only for tb_size_t
#if TB_CPU_BIT64

#   define tb_bits_swap(x)              tb_bits_swap_u64(x)

#   define tb_bits_cl0_be(x)            tb_bits_cl0_u64_be(x)
#   define tb_bits_cl0_le(x)            tb_bits_cl0_u64_le(x)
#   define tb_bits_cl1_be(x)            tb_bits_cl1_u64_be(x)
#   define tb_bits_cl1_le(x)            tb_bits_cl1_u64_le(x)

#   define tb_bits_fb0_be(x)            tb_bits_fb0_u64_be(x)
#   define tb_bits_fb0_le(x)            tb_bits_fb0_u64_le(x)
#   define tb_bits_fb1_be(x)            tb_bits_fb1_u64_be(x)
#   define tb_bits_fb1_le(x)            tb_bits_fb1_u64_le(x)

#   define tb_bits_cb0(x)               tb_bits_cb0_u64(x)
#   define tb_bits_cb1(x)               tb_bits_cb1_u64(x)

#elif TB_CPU_BIT32

#   define tb_bits_swap(x)              tb_bits_swap_u32(x)

#   define tb_bits_cl0_be(x)            tb_bits_cl0_u32_be(x)
#   define tb_bits_cl0_le(x)            tb_bits_cl0_u32_le(x)
#   define tb_bits_cl1_be(x)            tb_bits_cl1_u32_be(x)
#   define tb_bits_cl1_le(x)            tb_bits_cl1_u32_le(x)

#   define tb_bits_fb0_be(x)            tb_bits_fb0_u32_be(x)
#   define tb_bits_fb0_le(x)            tb_bits_fb0_u32_le(x)
#   define tb_bits_fb1_be(x)            tb_bits_fb1_u32_be(x)
#   define tb_bits_fb1_le(x)            tb_bits_fb1_u32_le(x)

#   define tb_bits_cb0(x)               tb_bits_cb0_u32(x)
#   define tb_bits_cb1(x)               tb_bits_cb1_u32(x)

#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! get ubits32 integer
 *
 * @param p     the data pointer
 * @param b     the start bits
 * @param n     the bits count
 *
 * @return      the ubits32 integer
 */
tb_uint32_t     tb_bits_get_ubits32(tb_byte_t const* p, tb_size_t b, tb_size_t n);

/*! get sbits32 integer
 *
 * @param p     the data pointer
 * @param b     the start bits
 * @param n     the bits count
 *
 * @return      the ubits32 integer
 */
tb_sint32_t     tb_bits_get_sbits32(tb_byte_t const* p, tb_size_t b, tb_size_t n);

/*! set ubits32 integer
 *
 * @param p     the data pointer
 * @param b     the start bits
 * @param x     the value
 * @param n     the bits count
 */
tb_void_t       tb_bits_set_ubits32(tb_byte_t* p, tb_size_t b, tb_uint32_t x, tb_size_t n);

/*! set ubits32 integer
 *
 * @param p     the data pointer
 * @param b     the start bits
 * @param x     the value
 * @param n     the bits count
 */
tb_void_t       tb_bits_set_sbits32(tb_byte_t* p, tb_size_t b, tb_sint32_t x, tb_size_t n);

/*! get ubits64 integer
 *
 * @param p     the data pointer
 * @param b     the start bits
 * @param n     the bits count
 *
 * @return      the ubits64 integer
 */
tb_uint64_t     tb_bits_get_ubits64(tb_byte_t const* p, tb_size_t b, tb_size_t n);

/*! get sbits64 integer
 *
 * @param p     the data pointer
 * @param b     the start bits
 * @param n     the bits count
 *
 * @return      the ubits64 integer
 */
tb_sint64_t     tb_bits_get_sbits64(tb_byte_t const* p, tb_size_t b, tb_size_t n);

/* //////////////////////////////////////////////////////////////////////////////////////
 * bits
 */

static __tb_inline__ tb_void_t tb_bits_set_u16_le_inline(tb_byte_t* p, tb_uint16_t x)
{
    p[0] = (tb_byte_t)x;
    p[1] = (tb_byte_t)(x >> 8); 
}
static __tb_inline__ tb_void_t tb_bits_set_u16_be_inline(tb_byte_t* p, tb_uint16_t x)
{
    p[0] = (tb_byte_t)(x >> 8); 
    p[1] = (tb_byte_t)x;
}
static __tb_inline__ tb_void_t tb_bits_set_u24_le_inline(tb_byte_t* p, tb_uint32_t x)
{ 
    p[0] = (tb_byte_t)x;
    p[1] = (tb_byte_t)(x >> 8); 
    p[2] = (tb_byte_t)(x >> 16);
}
static __tb_inline__ tb_void_t tb_bits_set_u24_be_inline(tb_byte_t* p, tb_uint32_t x)
{
    p[0] = (tb_byte_t)(x >> 16); 
    p[1] = (tb_byte_t)(x >> 8); 
    p[2] = (tb_byte_t)x;
}
static __tb_inline__ tb_void_t tb_bits_set_u32_le_inline(tb_byte_t* p, tb_uint32_t x)
{ 
    p[0] = (tb_byte_t)x;
    p[1] = (tb_byte_t)(x >> 8); 
    p[2] = (tb_byte_t)(x >> 16);
    p[3] = (tb_byte_t)(x >> 24);
}
static __tb_inline__ tb_void_t tb_bits_set_u32_be_inline(tb_byte_t* p, tb_uint32_t x)
{
    p[0] = (tb_byte_t)(x >> 24); 
    p[1] = (tb_byte_t)(x >> 16); 
    p[2] = (tb_byte_t)(x >> 8); 
    p[3] = (tb_byte_t)x;
}
static __tb_inline__ tb_void_t tb_bits_set_u64_le_inline(tb_byte_t* p, tb_uint64_t x)
{ 
    p[0] = (tb_byte_t)x;
    p[1] = (tb_byte_t)(x >> 8); 
    p[2] = (tb_byte_t)(x >> 16);
    p[3] = (tb_byte_t)(x >> 24);
    p[4] = (tb_byte_t)(x >> 32);
    p[5] = (tb_byte_t)(x >> 40);
    p[6] = (tb_byte_t)(x >> 48);
    p[7] = (tb_byte_t)(x >> 56);
}
static __tb_inline__ tb_void_t tb_bits_set_u64_be_inline(tb_byte_t* p, tb_uint64_t x)
{
    p[0] = (tb_byte_t)(x >> 56); 
    p[1] = (tb_byte_t)(x >> 48); 
    p[2] = (tb_byte_t)(x >> 40); 
    p[3] = (tb_byte_t)(x >> 32); 
    p[4] = (tb_byte_t)(x >> 24); 
    p[5] = (tb_byte_t)(x >> 16); 
    p[6] = (tb_byte_t)(x >> 8); 
    p[7] = (tb_byte_t)x;
}


/* //////////////////////////////////////////////////////////////////////////////////////
 * swap
 */

// swap
static __tb_inline__ tb_uint16_t const tb_bits_swap_u16_inline(tb_uint16_t x)
{
    x = (x >> 8) | (x << 8);
    return x;
}
static __tb_inline__ tb_uint32_t const tb_bits_swap_u24_inline(tb_uint32_t x)
{
    return (x >> 16) | (x & 0x0000ff00) | (x << 16);
}
static __tb_inline__ tb_uint32_t const tb_bits_swap_u32_inline(tb_uint32_t x)
{
    x = ((x << 8) & 0xff00ff00) | ((x >> 8) & 0x00ff00ff);
    x = (x >> 16) | (x << 16);
    return x;
}
static __tb_inline__ tb_hize_t const tb_bits_swap_u64_inline(tb_hize_t x)
{
    union 
    {
        tb_hize_t u64;
        tb_uint32_t u32[2];

    } w, r;

    w.u64 = x;

    r.u32[0] = tb_bits_swap_u32(w.u32[1]);
    r.u32[1] = tb_bits_swap_u32(w.u32[0]);

    return r.u64;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * cl0
 */
static __tb_inline__ tb_size_t tb_bits_cl0_u32_be_inline(tb_uint32_t x)
{
    tb_check_return_val(x, 32);

    tb_size_t n = 31;
    if (x & 0xffff0000) { n -= 16;  x >>= 16;   }
    if (x & 0xff00)     { n -= 8;   x >>= 8;    }
    if (x & 0xf0)       { n -= 4;   x >>= 4;    }
    if (x & 0xc)        { n -= 2;   x >>= 2;    }
    if (x & 0x2)        { n--;                  }

    return n;
}
static __tb_inline__ tb_size_t tb_bits_cl0_u32_le_inline(tb_uint32_t x)
{
    tb_check_return_val(x, 32);

    tb_size_t n = 31;
    if (x & 0x0000ffff) { n -= 16;  } else x >>= 16;
    if (x & 0x00ff)     { n -= 8;   } else x >>= 8;
    if (x & 0x0f)       { n -= 4;   } else x >>= 4;
    if (x & 0x3)        { n -= 2;   } else x >>= 2;
    if (x & 0x1)        { n--;      }

    return n;
}
static __tb_inline__ tb_size_t tb_bits_cl0_u64_be_inline(tb_uint64_t x)
{
    tb_check_return_val(x, 64);

    tb_size_t n = tb_bits_cl0_u32_be((tb_uint32_t)(x >> 32));
    if (n == 32) n += tb_bits_cl0_u32_be((tb_uint32_t)x);

    return n;
}
static __tb_inline__ tb_size_t tb_bits_cl0_u64_le_inline(tb_uint64_t x)
{
    tb_check_return_val(x, 64);

    tb_size_t n = tb_bits_cl0_u32_le((tb_uint32_t)x);
    if (n == 32) n += tb_bits_cl0_u32_le((tb_uint32_t)(x >> 32));

    return n;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * cb1
 */
static __tb_inline__ tb_size_t tb_bits_cb1_u32_inline(tb_uint32_t x)
{
    tb_check_return_val(x, 0);

#if 0
    /* 
     * 0x55555555 = 01010101010101010101010101010101 
     * 0x33333333 = 00110011001100110011001100110011 
     * 0x0f0f0f0f = 00001111000011110000111100001111 
     * 0x00ff00ff = 00000000111111110000000011111111 
     * 0x0000ffff = 00000000000000001111111111111111 
     */  

    x = (x & 0x55555555) + ((x >> 1) & 0x55555555);  
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);  
    x = (x & 0x0f0f0f0f) + ((x >> 4) & 0x0f0f0f0f);  
    x = (x & 0x00ff00ff) + ((x >> 8) & 0x00ff00ff);  
    x = (x & 0x0000ffff) + ((x >> 16) & 0x0000ffff); 
#elif 0
    // mit hackmem count
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4)) & 0x0f0f0f0f;
    x = x + (x >> 8);
    x = x + (x >> 16);
    x &= 0x7f;
#elif 0
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4) & 0x0f0f0f0f);
    x = (x * 0x01010101) >> 24;
#elif 0
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4) & 0x0f0f0f0f) % 255;
#else
    x = x - ((x >> 1) & 0x77777777) - ((x >> 2) & 0x33333333) - ((x >> 3) & 0x11111111);
    x = (x + (x >> 4)) & 0x0f0f0f0f;
    x = (x * 0x01010101) >> 24;
#endif

    return x;
}
static __tb_inline__ tb_size_t tb_bits_cb1_u64_inline(tb_uint64_t x)
{
    tb_check_return_val(x, 0);

#if 0
    x = x - ((x >> 1) & 0x5555555555555555L);
    x = (x & 0x3333333333333333L) + ((x >> 2) & 0x3333333333333333L);
    x = (x + (x >> 4)) & 0x0f0f0f0f0f0f0f0fL;
    x = x + (x >> 8);
    x = x + (x >> 16);
    x = x + (x >> 32);
    x &= 0x7f;
#else
    x = x - ((x >> 1) & 0x7777777777777777ULL) - ((x >> 2) & 0x3333333333333333ULL) - ((x >> 3) & 0x1111111111111111ULL);
    x = (x + (x >> 4)) & 0x0f0f0f0f0f0f0f0fULL;
    x = (x * 0x0101010101010101ULL) >> 56;
#endif

    return (tb_size_t)x;
}

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
/* //////////////////////////////////////////////////////////////////////////////////////
 * float
 */
static __tb_inline__ tb_float_t tb_bits_get_float_le_inline(tb_byte_t const* p)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
    && !defined(TB_WORDS_BIGENDIAN)
    return *((tb_float_t*)p);
#else
    tb_ieee_float_t conv;
    conv.i = tb_bits_get_u32_le(p);
    return conv.f;
#endif
}
static __tb_inline__ tb_float_t tb_bits_get_float_be_inline(tb_byte_t const* p)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
    && defined(TB_WORDS_BIGENDIAN)
    return *((tb_float_t*)p);
#else
    tb_ieee_float_t conv;
    conv.i = tb_bits_get_u32_be(p);
    return conv.f;
#endif
}
static __tb_inline__ tb_void_t tb_bits_set_float_le_inline(tb_byte_t* p, tb_float_t x)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
    && !defined(TB_WORDS_BIGENDIAN)
    *((tb_float_t*)p) = x;
#else
    tb_ieee_float_t conv;
    conv.f = x;
    tb_bits_set_u32_le(p, conv.i);
#endif
}
static __tb_inline__ tb_void_t tb_bits_set_float_be_inline(tb_byte_t* p, tb_float_t x)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
    && defined(TB_WORDS_BIGENDIAN)
    *((tb_float_t*)p) = x;
#else
    tb_ieee_float_t conv;
    conv.f = x;
    tb_bits_set_u32_be(p, conv.i);
#endif
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * double
 */
static __tb_inline__ tb_double_t tb_bits_get_double_bbe_inline(tb_byte_t const* p)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
        && defined(TB_FLOAT_BIGENDIAN) \
            && defined(TB_WORDS_BIGENDIAN)
    return *((tb_double_t*)p);
#else
    union 
    {
        tb_uint32_t i[2];
        tb_double_t d;

    } conv;

    conv.i[1] = tb_bits_get_u32_be(p);
    conv.i[0] = tb_bits_get_u32_be(p + 4);

    return conv.d;
#endif
}
static __tb_inline__ tb_double_t tb_bits_get_double_ble_inline(tb_byte_t const* p)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
        && defined(TB_FLOAT_BIGENDIAN) \
            && !defined(TB_WORDS_BIGENDIAN)
    return *((tb_double_t*)p);
#else
    union 
    {
        tb_uint32_t i[2];
        tb_double_t d;

    } conv;


    conv.i[1] = tb_bits_get_u32_le(p);
    conv.i[0] = tb_bits_get_u32_le(p + 4);

    return conv.d;
#endif
}
static __tb_inline__ tb_double_t tb_bits_get_double_lbe_inline(tb_byte_t const* p)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
        && !defined(TB_FLOAT_BIGENDIAN) \
            && defined(TB_WORDS_BIGENDIAN)
    return *((tb_double_t*)p);
#else
    union 
    {
        tb_uint32_t i[2];
        tb_double_t d;

    } conv;

    conv.i[0] = tb_bits_get_u32_be(p);
    conv.i[1] = tb_bits_get_u32_be(p + 4);

    return conv.d;
#endif
}
static __tb_inline__ tb_double_t tb_bits_get_double_lle_inline(tb_byte_t const* p)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
        && !defined(TB_FLOAT_BIGENDIAN) \
            && !defined(TB_WORDS_BIGENDIAN)
    return *((tb_double_t*)p);
#else
    union 
    {
        tb_uint32_t i[2];
        tb_double_t d;

    } conv;

    conv.i[0] = tb_bits_get_u32_le(p);
    conv.i[1] = tb_bits_get_u32_le(p + 4);
    return conv.d;
#endif
}
// big double endian & big words endian
// 7 6 5 4 3 2 1 0
static __tb_inline__ tb_void_t tb_bits_set_double_bbe_inline(tb_byte_t* p, tb_double_t x)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
        && defined(TB_FLOAT_BIGENDIAN) \
            && defined(TB_WORDS_BIGENDIAN)
    *((tb_double_t*)p) = x;
#else
    union 
    {
        tb_uint32_t     i[2];
        tb_double_t     d;

    } conv;

    conv.d = x;

    tb_bits_set_u32_be(p,       conv.i[1]);
    tb_bits_set_u32_be(p + 4,   conv.i[0]);
#endif
}
// big double endian & litte words endian
// 4 5 6 7 0 1 2 3
static __tb_inline__ tb_void_t tb_bits_set_double_ble_inline(tb_byte_t* p, tb_double_t x)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
        && defined(TB_FLOAT_BIGENDIAN) \
            && !defined(TB_WORDS_BIGENDIAN)
    *((tb_double_t*)p) = x;
#else
    union 
    {
        tb_uint32_t     i[2];
        tb_double_t     d;

    } conv;

    conv.d = x;

    tb_bits_set_u32_le(p,       conv.i[1]);
    tb_bits_set_u32_le(p + 4,   conv.i[0]);
#endif
}
// litte double endian & big words endian
// 3 2 1 0 7 6 5 4
static __tb_inline__ tb_void_t tb_bits_set_double_lbe_inline(tb_byte_t* p, tb_double_t x)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
        && !defined(TB_FLOAT_BIGENDIAN) \
            && defined(TB_WORDS_BIGENDIAN)
    *((tb_double_t*)p) = x;
#else
    union 
    {
        tb_uint32_t     i[2];
        tb_double_t     d;

    } conv;

    conv.d = x;

    tb_bits_set_u32_be(p,       conv.i[0]);
    tb_bits_set_u32_be(p + 4,   conv.i[1]);
#endif
}
// litte double endian & litte words endian
// 0 1 2 3 4 5 6 7
static __tb_inline__ tb_void_t tb_bits_set_double_lle_inline(tb_byte_t* p, tb_double_t x)
{
#if defined(TB_CONFIG_MEMORY_UNALIGNED_ACCESS_ENABLE) \
        && !defined(TB_FLOAT_BIGENDIAN) \
            && !defined(TB_WORDS_BIGENDIAN)
    *((tb_double_t*)p) = x;
#else
    union 
    {
        tb_uint32_t     i[2];
        tb_double_t     d;

    } conv;

    conv.d = x;

    tb_bits_set_u32_le(p,       conv.i[0]);
    tb_bits_set_u32_le(p + 4,   conv.i[1]);
#endif
}


#endif /* TB_CONFIG_TYPE_HAVE_FLOAT */

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

