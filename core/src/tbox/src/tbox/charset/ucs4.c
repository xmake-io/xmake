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
 * @file        ucs4.c
 * @ingroup     charset
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../stream/stream.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_long_t tb_charset_ucs4_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);
tb_long_t tb_charset_ucs4_get(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch)
{
    *ch = be? tb_static_stream_read_u32_be(sstream) : tb_static_stream_read_u32_le(sstream);
    return 1;
}

tb_long_t tb_charset_ucs4_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);
tb_long_t tb_charset_ucs4_set(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch)
{
    if (be) tb_static_stream_writ_u32_be(sstream, ch);
    else tb_static_stream_writ_u32_le(sstream, ch);
    return 1;
}

