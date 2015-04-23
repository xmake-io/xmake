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
 * @file        static_stream.h
 * @ingroup     stream
 *
 */
#ifndef TB_STREAM_STATIC_STREAM_H
#define TB_STREAM_STATIC_STREAM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef TB_WORDS_BIGENDIAN
#   define tb_static_stream_read_u16_ne(stream)                 tb_static_stream_read_u16_be(stream)
#   define tb_static_stream_read_s16_ne(stream)                 tb_static_stream_read_s16_be(stream)
#   define tb_static_stream_read_u24_ne(stream)                 tb_static_stream_read_u24_be(stream)
#   define tb_static_stream_read_s24_ne(stream)                 tb_static_stream_read_s24_be(stream)
#   define tb_static_stream_read_u32_ne(stream)                 tb_static_stream_read_u32_be(stream)
#   define tb_static_stream_read_s32_ne(stream)                 tb_static_stream_read_s32_be(stream)
#   define tb_static_stream_read_u64_ne(stream)                 tb_static_stream_read_u64_be(stream)
#   define tb_static_stream_read_s64_ne(stream)                 tb_static_stream_read_s64_be(stream)

#   define tb_static_stream_writ_u16_ne(stream, val)            tb_static_stream_writ_u16_be(stream, val)
#   define tb_static_stream_writ_s16_ne(stream, val)            tb_static_stream_writ_s16_be(stream, val)
#   define tb_static_stream_writ_u24_ne(stream, val)            tb_static_stream_writ_u24_be(stream, val)
#   define tb_static_stream_writ_s24_ne(stream, val)            tb_static_stream_writ_s24_be(stream, val)
#   define tb_static_stream_writ_u32_ne(stream, val)            tb_static_stream_writ_u32_be(stream, val)
#   define tb_static_stream_writ_s32_ne(stream, val)            tb_static_stream_writ_s32_be(stream, val)
#   define tb_static_stream_writ_u64_ne(stream, val)            tb_static_stream_writ_u64_be(stream, val)
#   define tb_static_stream_writ_s64_ne(stream, val)            tb_static_stream_writ_s64_be(stream, val)

#else
#   define tb_static_stream_read_u16_ne(stream)                 tb_static_stream_read_u16_le(stream)
#   define tb_static_stream_read_s16_ne(stream)                 tb_static_stream_read_s16_le(stream)
#   define tb_static_stream_read_u24_ne(stream)                 tb_static_stream_read_u24_le(stream)
#   define tb_static_stream_read_s24_ne(stream)                 tb_static_stream_read_s24_le(stream)
#   define tb_static_stream_read_u32_ne(stream)                 tb_static_stream_read_u32_le(stream)
#   define tb_static_stream_read_s32_ne(stream)                 tb_static_stream_read_s32_le(stream)
#   define tb_static_stream_read_u64_ne(stream)                 tb_static_stream_read_u64_le(stream)
#   define tb_static_stream_read_s64_ne(stream)                 tb_static_stream_read_s64_le(stream)

#   define tb_static_stream_writ_u16_ne(stream, val)            tb_static_stream_writ_u16_le(stream, val)
#   define tb_static_stream_writ_s16_ne(stream, val)            tb_static_stream_writ_s16_le(stream, val)
#   define tb_static_stream_writ_u24_ne(stream, val)            tb_static_stream_writ_u24_le(stream, val)
#   define tb_static_stream_writ_s24_ne(stream, val)            tb_static_stream_writ_s24_le(stream, val)
#   define tb_static_stream_writ_u32_ne(stream, val)            tb_static_stream_writ_u32_le(stream, val)
#   define tb_static_stream_writ_s32_ne(stream, val)            tb_static_stream_writ_s32_le(stream, val)
#   define tb_static_stream_writ_u64_ne(stream, val)            tb_static_stream_writ_u64_le(stream, val)
#   define tb_static_stream_writ_s64_ne(stream, val)            tb_static_stream_writ_s64_le(stream, val)

#endif

#ifdef TB_CONFIG_TYPE_FLOAT
#   ifdef TB_FLOAT_BIGENDIAN
#       define tb_static_stream_read_double_nbe(stream)         tb_static_stream_read_double_bbe(stream)
#       define tb_static_stream_read_double_nle(stream)         tb_static_stream_read_double_ble(stream)

#       define tb_static_stream_writ_double_nbe(stream, val)    tb_static_stream_writ_double_bbe(stream, val)
#       define tb_static_stream_writ_double_nle(stream, val)    tb_static_stream_writ_double_ble(stream, val)
#   else
#       define tb_static_stream_read_double_nbe(stream)         tb_static_stream_read_double_lbe(stream)
#       define tb_static_stream_read_double_nle(stream)         tb_static_stream_read_double_lle(stream)

#       define tb_static_stream_writ_double_nbe(stream, val)    tb_static_stream_writ_double_lbe(stream, val)
#       define tb_static_stream_writ_double_nle(stream, val)    tb_static_stream_writ_double_lle(stream, val)
#   endif
#   ifdef TB_WORDS_BIGENDIAN
#       define tb_static_stream_read_float_ne(stream)           tb_static_stream_read_float_be(stream)
#       define tb_static_stream_writ_float_ne(stream, val)      tb_static_stream_writ_float_be(stream, val)

#       define tb_static_stream_read_double_nne(stream)         tb_static_stream_read_double_nbe(stream)
#       define tb_static_stream_read_double_bne(stream)         tb_static_stream_read_double_bbe(stream)
#       define tb_static_stream_read_double_lne(stream)         tb_static_stream_read_double_lbe(stream)

#       define tb_static_stream_writ_double_nne(stream, val)    tb_static_stream_writ_double_nbe(stream, val)
#       define tb_static_stream_writ_double_bne(stream, val)    tb_static_stream_writ_double_bbe(stream, val)
#       define tb_static_stream_writ_double_lne(stream, val)    tb_static_stream_writ_double_lbe(stream, val)
#   else
#       define tb_static_stream_read_float_ne(stream)           tb_static_stream_read_float_le(stream)
#       define tb_static_stream_writ_float_ne(stream, val)      tb_static_stream_writ_float_le(stream, val)

#       define tb_static_stream_read_double_nne(stream)         tb_static_stream_read_double_nle(stream)
#       define tb_static_stream_read_double_bne(stream)         tb_static_stream_read_double_ble(stream)
#       define tb_static_stream_read_double_lne(stream)         tb_static_stream_read_double_lle(stream)

#       define tb_static_stream_writ_double_nne(stream, val)    tb_static_stream_writ_double_nle(stream, val)
#       define tb_static_stream_writ_double_bne(stream, val)    tb_static_stream_writ_double_ble(stream, val)
#       define tb_static_stream_writ_double_lne(stream, val)    tb_static_stream_writ_double_lle(stream, val)
#   endif
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the static stream type
typedef struct __tb_static_stream_t
{
    /// the pointer to the current position
    tb_byte_t*          p;

    /// the bit offset < 8
    tb_size_t           b;

    /// the pointer to the end
    tb_byte_t*          e;

    /// the data size
    tb_size_t           n;

}tb_static_stream_t;

/// the static stream ref type
typedef tb_static_stream_t*    tb_static_stream_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the static stream
 *
 * @param stream    the stream
 * @param data      the data address
 * @param size      the data size
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_init(tb_static_stream_ref_t stream, tb_byte_t* data, tb_size_t size);

/*! goto the new data address for updating the stream position
 *
 * @param stream    the stream
 * @param data      the data address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_goto(tb_static_stream_ref_t stream, tb_byte_t* data);

/*! sync the stream position if update some bits offset
 *
 * @param stream    the stream
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_sync(tb_static_stream_ref_t stream);

/*! the stream start data address
 *
 * @param stream    the stream
 *
 * @return          the start data address
 */
tb_byte_t const*    tb_static_stream_beg(tb_static_stream_ref_t stream);

/*! the stream current data address
 *
 * @param stream    the stream
 *
 * @return          the current data address
 */
tb_byte_t const*    tb_static_stream_pos(tb_static_stream_ref_t stream);

/*! the stream end data address
 *
 * @param stream    the stream
 *
 * @return          the end data address
 */
tb_byte_t const*    tb_static_stream_end(tb_static_stream_ref_t stream);

/*! the stream offset
 *
 * @param stream    the stream
 *
 * @return          the offset
 */
tb_size_t           tb_static_stream_offset(tb_static_stream_ref_t stream);

/*! the stream data size
 *
 * @param stream    the stream
 *
 * @return          the data size
 */
tb_size_t           tb_static_stream_size(tb_static_stream_ref_t stream);

/*! the stream left size
 *
 * @param stream    the stream
 *
 * @return          the left size
 */
tb_size_t           tb_static_stream_left(tb_static_stream_ref_t stream);

/*! the stream left bits
 *
 * @param stream    the stream
 *
 * @return          the left bits
 */
tb_size_t           tb_static_stream_left_bits(tb_static_stream_ref_t stream);

/*! the stream is valid?
 *
 * @param stream    the stream
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_valid(tb_static_stream_ref_t stream);

/*! skip the given size 
 *
 * @param stream    the stream
 * @param size      the skiped size
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_skip(tb_static_stream_ref_t stream, tb_size_t size);

/*! skip the given bits 
 *
 * @param stream    the stream
 * @param nbits     the skiped bits count
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_skip_bits(tb_static_stream_ref_t stream, tb_size_t nbits);

/*! skip the given c-string 
 *
 * @param stream    the stream
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_skip_cstr(tb_static_stream_ref_t stream);

/*! peek ubits value for uint32
 *
 * @param stream    the stream
 * @param nbits     the bits count
 *
 * @return          the ubits value
 */
tb_uint32_t         tb_static_stream_peek_ubits32(tb_static_stream_ref_t stream, tb_size_t nbits);

/*! peek sbits value for sint32
 *
 * @param stream    the stream
 * @param nbits     the bits count
 *
 * @return          the sbits value
 */
tb_sint32_t         tb_static_stream_peek_sbits32(tb_static_stream_ref_t stream, tb_size_t nbits);

/*! read c-string
 *
 * @param stream    the stream
 *
 * @return          the c-string
 */
tb_char_t const*    tb_static_stream_read_cstr(tb_static_stream_ref_t stream);

/*! read data
 *
 * @param stream    the stream
 * @param data      the data
 * @param size      the size
 *
 * @return          the data real size
 */
tb_size_t           tb_static_stream_read_data(tb_static_stream_ref_t stream, tb_byte_t* data, tb_size_t size);

/*! read ubits value for uint32
 *
 * @param stream    the stream
 * @param nbits     the bits count
 *
 * @return          the ubits value
 */
tb_uint32_t         tb_static_stream_read_ubits32(tb_static_stream_ref_t stream, tb_size_t nbits);

/*! read sbits value for sint32
 *
 * @param stream    the stream
 * @param nbits     the bits count
 *
 * @return          the sbits value
 */
tb_sint32_t         tb_static_stream_read_sbits32(tb_static_stream_ref_t stream, tb_size_t nbits);

/*! read ubits1 value
 *
 * @param stream    the stream
 *
 * @return          the ubits1 value
 */
tb_uint8_t          tb_static_stream_read_u1(tb_static_stream_ref_t stream);

/*! read uint8 integer
 *
 * @param stream    the stream
 *
 * @return          the uint8 integer
 */
tb_uint8_t          tb_static_stream_read_u8(tb_static_stream_ref_t stream);

/*! read sint8 integer
 *
 * @param stream    the stream
 *
 * @return          the sint8 integer
 */
tb_sint8_t          tb_static_stream_read_s8(tb_static_stream_ref_t stream);

/*! read uint16-be integer
 *
 * @param stream    the stream
 *
 * @return          the uint16-be integer
 */
tb_uint16_t         tb_static_stream_read_u16_be(tb_static_stream_ref_t stream);

/*! read sint16-be integer
 *
 * @param stream    the stream
 *
 * @return          the sint16-be integer
 */
tb_sint16_t         tb_static_stream_read_s16_be(tb_static_stream_ref_t stream);

/*! read uint16-le integer
 *
 * @param stream    the stream
 *
 * @return          the uint16-le integer
 */
tb_uint16_t         tb_static_stream_read_u16_le(tb_static_stream_ref_t stream);

/*! read sint16-le integer
 *
 * @param stream    the stream
 *
 * @return          the sint16-le integer
 */
tb_sint16_t         tb_static_stream_read_s16_le(tb_static_stream_ref_t stream);

/*! read uint24-be integer
 *
 * @param stream    the stream
 *
 * @return          the uint24-be integer
 */
tb_uint32_t         tb_static_stream_read_u24_be(tb_static_stream_ref_t stream);

/*! read sint24-be integer
 *
 * @param stream    the stream
 *
 * @return          the sint24-be integer
 */
tb_sint32_t         tb_static_stream_read_s24_be(tb_static_stream_ref_t stream);

/*! read uint24-le integer
 *
 * @param stream    the stream
 *
 * @return          the uint24-le integer
 */
tb_uint32_t         tb_static_stream_read_u24_le(tb_static_stream_ref_t stream);

/*! read sint24-le integer
 *
 * @param stream    the stream
 *
 * @return          the sint24-le integer
 */
tb_sint32_t         tb_static_stream_read_s24_le(tb_static_stream_ref_t stream);

/*! read uint32-be integer
 *
 * @param stream    the stream
 *
 * @return          the uint32-be integer
 */
tb_uint32_t         tb_static_stream_read_u32_be(tb_static_stream_ref_t stream);

/*! read sint32-be integer
 *
 * @param stream    the stream
 *
 * @return          the sint32-be integer
 */
tb_sint32_t         tb_static_stream_read_s32_be(tb_static_stream_ref_t stream);

/*! read uint32-le integer
 *
 * @param stream    the stream
 *
 * @return          the uint32-le integer
 */
tb_uint32_t         tb_static_stream_read_u32_le(tb_static_stream_ref_t stream);

/*! read sint32-le integer
 *
 * @param stream    the stream
 *
 * @return          the sint32-le integer
 */
tb_sint32_t         tb_static_stream_read_s32_le(tb_static_stream_ref_t stream);

/*! read uint64-be integer
 *
 * @param stream    the stream
 *
 * @return          the uint64-be integer
 */
tb_uint64_t         tb_static_stream_read_u64_be(tb_static_stream_ref_t stream);

/*! read sint64-be integer
 *
 * @param stream    the stream
 *
 * @return          the sint64-be integer
 */
tb_sint64_t         tb_static_stream_read_s64_be(tb_static_stream_ref_t stream);

/*! read uint64-le integer
 *
 * @param stream    the stream
 *
 * @return          the uint64-le integer
 */
tb_uint64_t         tb_static_stream_read_u64_le(tb_static_stream_ref_t stream);

/*! read sint64-le integer
 *
 * @param stream    the stream
 *
 * @return          the sint64-le integer
 */
tb_sint64_t         tb_static_stream_read_s64_le(tb_static_stream_ref_t stream);

/*! writ c-string
 *
 * @param stream    the stream
 * @param cstr      the c-string
 *
 * @return          the writed c-string address
 */
tb_char_t*          tb_static_stream_writ_cstr(tb_static_stream_ref_t stream, tb_char_t const* cstr);

/*! writ data
 *
 * @param stream    the stream
 * @param data      the data
 * @param size      the size
 *
 * @return          the writed data size
 */
tb_size_t           tb_static_stream_writ_data(tb_static_stream_ref_t stream, tb_byte_t const* data, tb_size_t size);

/*! writ ubits for uint32
 *
 * @param stream    the stream
 * @param val       the value
 * @param nbits     the bits count
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_ubits32(tb_static_stream_ref_t stream, tb_uint32_t val, tb_size_t nbits);

/*! writ sbits for sint32
 *
 * @param stream    the stream
 * @param val       the value
 * @param nbits     the bits count
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_sbits32(tb_static_stream_ref_t stream, tb_sint32_t val, tb_size_t nbits);

/*! writ ubits1 value
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u1(tb_static_stream_ref_t stream, tb_uint8_t val);

/*! writ uint8 integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u8(tb_static_stream_ref_t stream, tb_uint8_t val);

/*! writ sint8 integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s8(tb_static_stream_ref_t stream, tb_sint8_t val);

/*! writ uint16-be integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u16_be(tb_static_stream_ref_t stream, tb_uint16_t val);

/*! writ sint16-be integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s16_be(tb_static_stream_ref_t stream, tb_sint16_t val);

/*! writ uint16-le integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u16_le(tb_static_stream_ref_t stream, tb_uint16_t val);

/*! writ sint16-le integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s16_le(tb_static_stream_ref_t stream, tb_sint16_t val);

/*! writ uint24-be integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u24_be(tb_static_stream_ref_t stream, tb_uint32_t val);

/*! writ sint24-be integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s24_be(tb_static_stream_ref_t stream, tb_sint32_t val);

/*! writ uint24-le integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u24_le(tb_static_stream_ref_t stream, tb_uint32_t val);

/*! writ sint24-le integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s24_le(tb_static_stream_ref_t stream, tb_sint32_t val);

/*! writ uint32-be integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u32_be(tb_static_stream_ref_t stream, tb_uint32_t val);

/*! writ sint32-be integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s32_be(tb_static_stream_ref_t stream, tb_sint32_t val);

/*! writ uint32-le integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u32_le(tb_static_stream_ref_t stream, tb_uint32_t val);

/*! writ sint32-le integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s32_le(tb_static_stream_ref_t stream, tb_sint32_t val);

/*! writ uint64-be integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u64_be(tb_static_stream_ref_t stream, tb_uint64_t val);

/*! writ sint64-be integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s64_be(tb_static_stream_ref_t stream, tb_sint64_t val);

/*! writ uint64-le integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_u64_le(tb_static_stream_ref_t stream, tb_uint64_t val);

/*! writ sint64-le integer
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_s64_le(tb_static_stream_ref_t stream, tb_sint64_t val);

#ifdef TB_CONFIG_TYPE_FLOAT

/*! read float-le number
 *
 * @param stream    the stream
 *
 * @return          the float-le number
 */
tb_float_t          tb_static_stream_read_float_le(tb_static_stream_ref_t stream);

/*! read float-be number
 *
 * @param stream    the stream
 *
 * @return          the float-be number
 */
tb_float_t          tb_static_stream_read_float_be(tb_static_stream_ref_t stream);

/*! read double-ble number
 *
 * @param stream    the stream
 *
 * @return          the double-ble number
 */
tb_double_t         tb_static_stream_read_double_ble(tb_static_stream_ref_t stream);

/*! read double-bbe number
 *
 * @param stream    the stream
 *
 * @return          the double-bbe number
 */
tb_double_t         tb_static_stream_read_double_bbe(tb_static_stream_ref_t stream);

/*! read double-lle number
 *
 * @param stream    the stream
 *
 * @return          the double-lle number
 */
tb_double_t         tb_static_stream_read_double_lle(tb_static_stream_ref_t stream);

/*! read double-lbe number
 *
 * @param stream    the stream
 *
 * @return          the double-lbe number
 */
tb_double_t         tb_static_stream_read_double_lbe(tb_static_stream_ref_t stream);

/*! writ float-le number
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_float_le(tb_static_stream_ref_t stream, tb_float_t val);

/*! writ float-be number
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_float_be(tb_static_stream_ref_t stream, tb_float_t val);

/*! writ double-ble number
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_double_ble(tb_static_stream_ref_t stream, tb_double_t val);

/*! writ double-bbe number
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_double_bbe(tb_static_stream_ref_t stream, tb_double_t val);

/*! writ double-lle number
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_double_lle(tb_static_stream_ref_t stream, tb_double_t val);

/*! writ double-lbe number
 *
 * @param stream    the stream
 * @param val       the value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_stream_writ_double_lbe(tb_static_stream_ref_t stream, tb_double_t val);

#endif


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

