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
 * inlines
 */
static __tb_inline__ tb_void_t tb_oc_reader_bin_type_size(tb_stream_ref_t stream, tb_size_t* ptype, tb_uint64_t* psize)
{
    // check
    tb_assert_and_check_return(stream);

    // clear it first
    if (ptype) *ptype = 0;
    if (psize) *psize = 0;

    // the flag
    tb_uint8_t flag = 0;
    tb_bool_t ok = tb_stream_bread_u8(stream, &flag);
    tb_assert_and_check_return(ok);

    // read type and size
    tb_size_t   type = flag >> 4;
    tb_uint64_t size = flag & 0x0f;
    if (type == 0xf)
    {
        tb_uint8_t value = 0;
        if (tb_stream_bread_u8(stream, &value)) type = value;
    }

    // done
    tb_value_t value;
    switch (size)
    {
    case 0xc:
        if (tb_stream_bread_u8(stream, &value.u8)) size = value.u8;
        break;
    case 0xd:
        if (tb_stream_bread_u16_be(stream, &value.u16)) size = value.u16;
        break;
    case 0xe:
        if (tb_stream_bread_u32_be(stream, &value.u32)) size = value.u32;
        break;
    case 0xf:
        if (tb_stream_bread_u64_be(stream, &value.u64)) size = value.u64;
        break;
    default:
        break;
    }

    // trace
//  tb_trace_d("type: %lu, size: %llu", type, size);

    // save
    if (ptype) *ptype = type;
    if (psize) *psize = size;
}

#endif
