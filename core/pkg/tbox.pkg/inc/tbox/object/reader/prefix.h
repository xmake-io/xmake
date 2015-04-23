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
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_READER_PREFIX_H
#define TB_OBJECT_READER_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// bytes
#define tb_object_reader_need_bytes(x)              \
                                                    (((tb_uint64_t)(x)) < (1ull << 8) ? 1 : \
                                                    (((tb_uint64_t)(x)) < (1ull << 16) ? 2 : \
                                                    (((tb_uint64_t)(x)) < (1ull << 24) ? 3 : \
                                                    (((tb_uint64_t)(x)) < (1ull << 32) ? 4 : 8))))

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */
static __tb_inline__ tb_void_t tb_object_reader_bin_type_size(tb_stream_ref_t stream, tb_size_t* ptype, tb_uint64_t* psize)
{
    // check
    tb_assert_and_check_return(stream);

    // the flag
    tb_uint8_t flag = tb_stream_bread_u8(stream);

    // the type & size
    tb_size_t   type = flag >> 4;
    tb_uint64_t size = flag & 0x0f;
    if (type == 0xf) type = tb_stream_bread_u8(stream);
    switch (size)
    {
    case 0xc:
        size = tb_stream_bread_u8(stream);
        break;
    case 0xd:
        size = tb_stream_bread_u16_be(stream);
        break;
    case 0xe:
        size = tb_stream_bread_u32_be(stream);
        break;
    case 0xf:
        size = tb_stream_bread_u64_be(stream);
        break;
    default:
        break;
    }

    // trace
//  tb_trace("type: %lu, size: %llu", type, size);

    // save
    if (ptype) *ptype = type;
    if (psize) *psize = size;
}

#endif
