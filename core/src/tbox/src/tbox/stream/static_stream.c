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
 * @file        static_stream.c
 * @ingroup     stream
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "static_stream.h"
#include "stream.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../memory/memory.h"
#include "../string/string.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
tb_bool_t tb_static_stream_init(tb_static_stream_ref_t stream, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(stream && data, tb_false);

    // init
    stream->p   = data;
    stream->b   = 0;
    stream->n   = size;
    stream->e   = data + size;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_goto(tb_static_stream_ref_t stream, tb_byte_t* data)
{
    // check
    tb_assert_and_check_return_val(stream && data <= stream->e, tb_false);

    // goto
    stream->b = 0;
    if (data <= stream->e) stream->p = data;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_sync(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_false);

    // sync
    if (stream->b) 
    {
        // check
        tb_assert_and_check_return_val(stream->p + 1 <= stream->e, tb_false);

        // p++
        stream->p++;
        stream->b = 0;
    }

    // ok
    return tb_true;
}
tb_byte_t const* tb_static_stream_beg(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // the head
    return stream->e? (stream->e - stream->n) : tb_null;
}
tb_byte_t const* tb_static_stream_pos(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p <= stream->e, tb_null);

    // sync
    tb_static_stream_sync(stream);

    // the position 
    return stream->p;
}
tb_byte_t const* tb_static_stream_end(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // the end
    return stream->e;
}
tb_size_t tb_static_stream_size(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // the size
    return stream->n;
}
tb_size_t tb_static_stream_offset(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // sync
    tb_static_stream_sync(stream);

    // the offset
    return (((stream->p + stream->n) > stream->e)? (stream->p + stream->n - stream->e) : 0);
}
tb_size_t tb_static_stream_left(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p <= stream->e, 0);

    // sync
    tb_static_stream_sync(stream);

    // the left
    return (stream->e - stream->p);
}
tb_size_t tb_static_stream_left_bits(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // the left bits
    return ((stream->p < stream->e)? (((stream->e - stream->p) << 3) - stream->b) : 0);
}
tb_bool_t tb_static_stream_valid(tb_static_stream_ref_t stream)
{
    // null?
    if (!stream) return tb_false;

    // out of range?
    if (stream->p && stream->p > stream->e) return tb_false;
    if (stream->p == stream->e && stream->b) return tb_false;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_skip(tb_static_stream_ref_t stream, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(stream, tb_false);

    // sync it first
    if (!tb_static_stream_sync(stream)) return tb_false;

    // check
    tb_assert_and_check_return_val(stream->p + size <= stream->e, tb_false);

    // skip
    stream->p += size;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_skip_bits(tb_static_stream_ref_t stream, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p <= stream->e, tb_false);

    // the new position
    tb_byte_t*  p = stream->p + ((stream->b + nbits) >> 3);
    tb_size_t   b = (stream->b + nbits) & 0x07;
    tb_assert_and_check_return_val(p <= stream->e && (p < stream->e || !b), tb_false);

    // skip it
    stream->p = p;
    stream->b = b;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_skip_cstr(tb_static_stream_ref_t stream)
{
    // read it
    tb_static_stream_read_cstr(stream);

    // ok?
    return tb_static_stream_valid(stream);
}
tb_uint32_t tb_static_stream_peek_ubits32(tb_static_stream_ref_t stream, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // no nbits?
    tb_check_return_val(nbits, 0);

    // save 
    tb_byte_t*  p = stream->p;
    tb_size_t   b = stream->b;

    // peek value
    tb_uint32_t val = tb_static_stream_read_ubits32(stream, nbits);

    // restore 
    stream->p = p;
    stream->b = b;

    // ok?
    return val;
}
tb_sint32_t tb_static_stream_peek_sbits32(tb_static_stream_ref_t stream, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // no nbits?
    tb_check_return_val(nbits, 0);

    // save 
    tb_byte_t*  p = stream->p;
    tb_size_t   b = stream->b;

    // peek value
    tb_sint32_t val = tb_static_stream_read_sbits32(stream, nbits);

    // restore 
    stream->p = p;
    stream->b = b;

    // ok?
    return val;
}
tb_uint32_t tb_static_stream_read_ubits32(tb_static_stream_ref_t stream, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && nbits, 0);

    // read value
    tb_uint32_t val = tb_bits_get_ubits32(stream->p, stream->b, nbits);

    // skip bits
    if (!tb_static_stream_skip_bits(stream, nbits)) return 0;

    // ok?
    return val;
}
tb_sint32_t tb_static_stream_read_sbits32(tb_static_stream_ref_t stream, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && nbits, 0);

    // read value
    tb_sint32_t val = tb_bits_get_sbits32(stream->p, stream->b, nbits);

    // skip bits
    if (!tb_static_stream_skip_bits(stream, nbits)) return 0;

    // ok?
    return val;
}
tb_uint64_t tb_static_stream_read_ubits64(tb_static_stream_ref_t stream, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && nbits, 0);

    // read value
    tb_uint64_t val = tb_bits_get_ubits64(stream->p, stream->b, nbits);

    // skip bits
    if (!tb_static_stream_skip_bits(stream, nbits)) return 0;

    // ok?
    return val;
}
tb_sint64_t tb_static_stream_read_sbits64(tb_static_stream_ref_t stream, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && nbits, 0);

    // read value
    tb_sint64_t val = tb_bits_get_sbits64(stream->p, stream->b, nbits);

    // skip bits
    if (!tb_static_stream_skip_bits(stream, nbits)) return 0;

    // ok?
    return val;
}
tb_char_t const* tb_static_stream_read_cstr(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p <= stream->e, tb_null);

    // sync it first
    if (!tb_static_stream_sync(stream)) return tb_null;

    // the string data
    tb_char_t const* data = (tb_char_t const*)stream->p;

    // the string size
    tb_size_t size = tb_strnlen(data, stream->e - stream->p);

    // skip bytes
    if (!tb_static_stream_skip(stream, size + 1)) return tb_null;

    // ok
    return data;
}
tb_size_t tb_static_stream_read_data(tb_static_stream_ref_t stream, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p <= stream->e && data, 0);
    
    // no size?
    tb_check_return_val(size, 0);

    // sync it first
    if (!tb_static_stream_sync(stream)) return 0;
    
    // the need size
    tb_size_t need = size;
    if (stream->e - stream->p < need) need = stream->e - stream->p;
    if (need) 
    {
        // copy it
        tb_memcpy(data, stream->p, need);

        // skip it
        if (!tb_static_stream_skip(stream, need)) return 0;
    }

    // ok?
    return need;
}
tb_uint8_t tb_static_stream_read_u1(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e, 0);

    // the value
    tb_uint8_t val = ((*stream->p) >> (7 - stream->b)) & 1;

    // update position
    stream->b++;
    if (stream->b >= 8) 
    {
        // check
        tb_assert_and_check_return_val(stream->p <= stream->e, 0);

        // update
        stream->p++;
        stream->b = 0;
    }

    // ok?
    return val;
}
tb_uint8_t tb_static_stream_read_u8(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && !stream->b, 0);

    // read it
    return *(stream->p++);
}
tb_sint8_t tb_static_stream_read_s8(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && !stream->b, 0);

    // read it
    return *(stream->p++);
}
tb_uint16_t tb_static_stream_read_u16_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 1 < stream->e && !stream->b, 0);

    // read it
    tb_uint16_t val = tb_bits_get_u16_be(stream->p); stream->p += 2;

    // ok?
    return val;
}
tb_sint16_t tb_static_stream_read_s16_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 1 < stream->e && !stream->b, 0);

    // read it
    tb_sint16_t val = tb_bits_get_s16_be(stream->p); stream->p += 2;

    // ok?
    return val;
}
tb_uint16_t tb_static_stream_read_u16_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 1 < stream->e && !stream->b, 0);

    // read it
    tb_uint16_t val = tb_bits_get_u16_le(stream->p); stream->p += 2;

    // ok?
    return val;
}
tb_sint16_t tb_static_stream_read_s16_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 1 < stream->e && !stream->b, 0);

    // read it
    tb_sint16_t val = tb_bits_get_s16_le(stream->p); stream->p += 2;

    // ok?
    return val;
}
tb_uint32_t tb_static_stream_read_u24_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 2 < stream->e && !stream->b, 0);

    // read it
    tb_uint32_t val = tb_bits_get_u24_be(stream->p); stream->p += 3;

    // ok?
    return val;
}
tb_sint32_t tb_static_stream_read_s24_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 2 < stream->e && !stream->b, 0);

    // read it
    tb_sint32_t val = tb_bits_get_s24_be(stream->p); stream->p += 3;

    // ok?
    return val;
}
tb_uint32_t tb_static_stream_read_u24_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 2 < stream->e && !stream->b, 0);

    // read it
    tb_uint32_t val = tb_bits_get_u24_le(stream->p); stream->p += 3;

    // ok?
    return val;
}
tb_sint32_t tb_static_stream_read_s24_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 2 < stream->e && !stream->b, 0);

    // read it
    tb_sint32_t val = tb_bits_get_s24_le(stream->p); stream->p += 3;

    // ok?
    return val;
}
tb_uint32_t tb_static_stream_read_u32_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, 0);

    // read it
    tb_uint32_t val = tb_bits_get_u32_be(stream->p); stream->p += 4;

    // ok?
    return val;
}
tb_sint32_t tb_static_stream_read_s32_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, 0);

    // read it
    tb_sint32_t val = tb_bits_get_s32_be(stream->p); stream->p += 4;

    // ok?
    return val;
}
tb_uint32_t tb_static_stream_read_u32_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, 0);

    // read it
    tb_uint32_t val = tb_bits_get_u32_le(stream->p); stream->p += 4;

    // ok?
    return val;
}
tb_sint32_t tb_static_stream_read_s32_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, 0);

    // read it
    tb_sint32_t val = tb_bits_get_s32_le(stream->p); stream->p += 4;

    // ok?
    return val;
}
tb_uint64_t tb_static_stream_read_u64_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, 0);

    // read it
    tb_uint64_t val = tb_bits_get_u64_be(stream->p); stream->p += 8;

    // ok?
    return val;
}
tb_sint64_t tb_static_stream_read_s64_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, 0);

    // read it
    tb_sint64_t val = tb_bits_get_s64_be(stream->p); stream->p += 8;

    // ok?
    return val;
}
tb_uint64_t tb_static_stream_read_u64_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, 0);

    // read it
    tb_uint64_t val = tb_bits_get_u64_le(stream->p); stream->p += 8;

    // ok?
    return val;
}
tb_sint64_t tb_static_stream_read_s64_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, 0);

    // read it
    tb_sint64_t val = tb_bits_get_s64_le(stream->p); stream->p += 8;

    // ok?
    return val;
}
tb_bool_t tb_static_stream_writ_ubits32(tb_static_stream_ref_t stream, tb_uint32_t val, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && nbits, 0);

    // writ bits
    tb_bits_set_ubits32(stream->p, stream->b, val, nbits);

    // skip bits
    return tb_static_stream_skip_bits(stream, nbits);
}
tb_bool_t tb_static_stream_writ_sbits32(tb_static_stream_ref_t stream, tb_sint32_t val, tb_size_t nbits)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && nbits, 0);

    // writ bits
    tb_bits_set_sbits32(stream->p, stream->b, val, nbits);

    // skip bits
    return tb_static_stream_skip_bits(stream, nbits);
}
tb_size_t tb_static_stream_writ_data(tb_static_stream_ref_t stream, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p <= stream->e && data, 0);

    // no size?
    tb_check_return_val(size, 0);

    // sync it first
    if (!tb_static_stream_sync(stream)) return 0;

    // the need size
    tb_size_t need = size;
    if (stream->e - stream->p < need) need = stream->e - stream->p;
    if (need)
    {
        // copy it
        tb_memcpy(stream->p, data, need);

        // skip it
        if (!tb_static_stream_skip(stream, need)) return 0;
    }

    // ok?
    return need;
}
tb_char_t* tb_static_stream_writ_cstr(tb_static_stream_ref_t stream, tb_char_t const* cstr)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p <= stream->e && cstr, tb_null);

    // sync it first
    if (!tb_static_stream_sync(stream)) return tb_null;

    // writ string
    tb_char_t*          b = (tb_char_t*)stream->p;
    tb_char_t*          p = (tb_char_t*)stream->p;
    tb_char_t const*    e = (tb_char_t const*)stream->e - 1;
    while (*cstr && p < e) *p++ = *cstr++;
    *p++ = '\0';

    // check
    tb_assert_and_check_return_val(!*cstr, tb_null);

    // update position
    stream->p = (tb_byte_t*)p;

    // ok
    return b;
}
tb_bool_t tb_static_stream_writ_u1(tb_static_stream_ref_t stream, tb_uint8_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e, tb_false);

    // writ bits
    *(stream->p) &= ~(0x1 << (7 - stream->b));
    *(stream->p) |= ((val & 0x1) << (7 - stream->b));

    // update position
    stream->b++;
    if (stream->b >= 8) 
    {
        // check
        tb_assert_and_check_return_val(stream->p <= stream->e, 0);

        // update
        stream->p++;
        stream->b = 0;
    }

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u8(tb_static_stream_ref_t stream, tb_uint8_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && !stream->b, tb_false);

    // writ it
    *(stream->p++) = val;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s8(tb_static_stream_ref_t stream, tb_sint8_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p < stream->e && !stream->b, tb_false);

    // writ it
    *(stream->p++) = val;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u16_be(tb_static_stream_ref_t stream, tb_uint16_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 1 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_u16_be(stream->p, val); stream->p += 2;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s16_be(tb_static_stream_ref_t stream, tb_sint16_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 1 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_s16_be(stream->p, val);
    stream->p += 2;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u16_le(tb_static_stream_ref_t stream, tb_uint16_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 1 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_u16_le(stream->p, val); stream->p += 2;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s16_le(tb_static_stream_ref_t stream, tb_sint16_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 1 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_s16_le(stream->p, val); stream->p += 2;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u24_be(tb_static_stream_ref_t stream, tb_uint32_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 2 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_u24_be(stream->p, val); stream->p += 3;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s24_be(tb_static_stream_ref_t stream, tb_sint32_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 2 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_s24_be(stream->p, val); stream->p += 3;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u24_le(tb_static_stream_ref_t stream, tb_uint32_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 2 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_u24_le(stream->p, val); stream->p += 3;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s24_le(tb_static_stream_ref_t stream, tb_sint32_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 2 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_s24_le(stream->p, val); stream->p += 3;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u32_be(tb_static_stream_ref_t stream, tb_uint32_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_u32_be(stream->p, val); stream->p += 4;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s32_be(tb_static_stream_ref_t stream, tb_sint32_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_s32_be(stream->p, val); stream->p += 4;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u32_le(tb_static_stream_ref_t stream, tb_uint32_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_u32_le(stream->p, val); stream->p += 4;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s32_le(tb_static_stream_ref_t stream, tb_sint32_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_s32_le(stream->p, val); stream->p += 4;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u64_be(tb_static_stream_ref_t stream, tb_uint64_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_u64_be(stream->p, val); stream->p += 8;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s64_be(tb_static_stream_ref_t stream, tb_sint64_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_s64_be(stream->p, val); stream->p += 8;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_u64_le(tb_static_stream_ref_t stream, tb_uint64_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_u64_le(stream->p, val); stream->p += 8;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_s64_le(tb_static_stream_ref_t stream, tb_sint64_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_s64_le(stream->p, val); stream->p += 8;

    // ok
    return tb_true;
}

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
tb_float_t tb_static_stream_read_float_le(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, 0);

    // read it
    tb_float_t val = tb_bits_get_float_le(stream->p); stream->p += 4;

    // ok?
    return val;
}
tb_float_t tb_static_stream_read_float_be(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, 0);

    // read it
    tb_float_t val = tb_bits_get_float_be(stream->p); stream->p += 4;

    // ok?
    return val;
}
tb_double_t tb_static_stream_read_double_ble(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, 0);

    // read it
    tb_double_t val = tb_bits_get_double_ble(stream->p); stream->p += 8;

    // ok?
    return val;
}
tb_double_t tb_static_stream_read_double_bbe(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, 0);

    // read it
    tb_double_t val = tb_bits_get_double_bbe(stream->p); stream->p += 8;

    // ok?
    return val;
}
tb_double_t tb_static_stream_read_double_lle(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, 0);

    // read it
    tb_double_t val = tb_bits_get_double_lle(stream->p); stream->p += 8;

    // ok?
    return val;
}
tb_double_t tb_static_stream_read_double_lbe(tb_static_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, 0);

    // read it
    tb_double_t val = tb_bits_get_double_lbe(stream->p); stream->p += 8;

    // ok?
    return val;
}
tb_bool_t tb_static_stream_writ_float_le(tb_static_stream_ref_t stream, tb_float_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_float_le(stream->p, val); stream->p += 4;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_float_be(tb_static_stream_ref_t stream, tb_float_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 3 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_float_be(stream->p, val); stream->p += 4;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_double_ble(tb_static_stream_ref_t stream, tb_double_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_double_ble(stream->p, val); stream->p += 8;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_double_bbe(tb_static_stream_ref_t stream, tb_double_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_double_bbe(stream->p, val); stream->p += 8;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_double_lle(tb_static_stream_ref_t stream, tb_double_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_double_lle(stream->p, val); stream->p += 8;

    // ok
    return tb_true;
}
tb_bool_t tb_static_stream_writ_double_lbe(tb_static_stream_ref_t stream, tb_double_t val)
{
    // check
    tb_assert_and_check_return_val(stream && stream->p && stream->p + 7 < stream->e && !stream->b, tb_false);

    // writ it
    tb_bits_set_double_lbe(stream->p, val); stream->p += 8;

    // ok
    return tb_true;
}

#endif
