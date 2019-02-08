/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
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
#ifndef TB_OBJECT_WRITER_PREFIX_H
#define TB_OBJECT_WRITER_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */
static __tb_inline__ tb_bool_t tb_oc_writer_tab(tb_stream_ref_t stream, tb_bool_t deflate, tb_size_t tab)
{
    // writ tab
    if (!deflate) 
    {
        while (tab--) if (tb_stream_printf(stream, "    ") < 0) return tb_false;
    }

    // ok
    return tb_true;
}
static __tb_inline__ tb_bool_t tb_oc_writer_newline(tb_stream_ref_t stream, tb_bool_t deflate)
{
    // writ newline
    if (!deflate && tb_stream_printf(stream, __tb_newline__) < 0) return tb_false;

    // ok
    return tb_true;
}
static __tb_inline__ tb_bool_t tb_oc_writer_bin_type_size(tb_stream_ref_t stream, tb_size_t type, tb_uint64_t size)
{
    // check
    tb_assert_and_check_return_val(stream && type <= 0xff, tb_false);

    // byte for size < 64bits
    tb_size_t sizeb = tb_object_need_bytes(size);
    tb_assert_and_check_return_val(sizeb <= 8, tb_false);

    // flag for size
    tb_size_t sizef = 0;
    switch (sizeb)
    {
    case 1: sizef = 0xc; break;
    case 2: sizef = 0xd; break;
    case 4: sizef = 0xe; break;
    case 8: sizef = 0xf; break;
    default: break;
    }
    tb_assert_and_check_return_val(sizef, tb_false);

    // writ flag 
    tb_uint8_t flag = ((type < 0xf? (tb_uint8_t)type : 0xf) << 4) | (size < 0xc? (tb_uint8_t)size : (tb_uint8_t)sizef);
    if (!tb_stream_bwrit_u8(stream, flag)) return tb_false;

    // trace
//  tb_trace("writ: type: %lu, size: %llu", type, size);

    // writ type
    if (type >= 0xf) if (!tb_stream_bwrit_u8(stream, (tb_uint8_t)type)) return tb_false;

    // writ size
    if (size >= 0xc)
    {
        switch (sizeb)
        {
        case 1:
            if (!tb_stream_bwrit_u8(stream, (tb_uint8_t)size)) return tb_false;
            break;
        case 2:
            if (!tb_stream_bwrit_u16_be(stream, (tb_uint16_t)size)) return tb_false;
            break;
        case 4:
            if (!tb_stream_bwrit_u32_be(stream, (tb_uint32_t)size)) return tb_false;
            break;
        case 8:
            if (!tb_stream_bwrit_u64_be(stream, (tb_uint64_t)size)) return tb_false;
            break;
        default:
            tb_assert_and_check_return_val(0, tb_false);
            break;
        }
    }

    // ok
    return tb_true;
}

#endif
