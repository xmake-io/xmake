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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        prefix.h
 *
 */
#ifndef XM_LZ4_PREFIX_H
#define XM_LZ4_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "lz4frame.h"
#include "lz4.h"
#include "lz4hc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define LZ4_STREAM_DICTSIZE (65536)

#define LZ4_STREAM_BUFFER_POLICY_APPEND    (0)
#define LZ4_STREAM_BUFFER_POLICY_RESET     (1)
#define LZ4_STREAM_BUFFER_POLICY_EXTERNAL  (2)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the lz4 stream type
typedef struct __xm_lz4_stream_t
{
    tb_byte_t    buffer[TB_STREAM_BLOCK_MAXN];
    tb_int_t     buffer_size;
    tb_int_t     buffer_position;
    tb_byte_t*   output;
    tb_int_t     output_maxn;
    LZ4_stream_t handle;
}xm_lz4_stream_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
static __tb_inline__ tb_int_t xm_lz4_stream_buffer_policy(tb_int_t buffer_size, tb_int_t buffer_position, tb_int_t data_size)
{
    if (data_size > buffer_size || data_size > LZ4_STREAM_DICTSIZE)
        return LZ4_STREAM_BUFFER_POLICY_EXTERNAL;
    if (buffer_position + data_size <= buffer_size)
        return LZ4_STREAM_BUFFER_POLICY_APPEND;
    if (data_size + LZ4_STREAM_DICTSIZE > buffer_position)
        return LZ4_STREAM_BUFFER_POLICY_EXTERNAL;
    return LZ4_STREAM_BUFFER_POLICY_RESET;
}

static __tb_inline__ tb_void_t xm_lz4_stream_init(xm_lz4_stream_t* stream)
{
    stream->buffer_position = 0;
    stream->buffer_size = sizeof(stream->buffer);
    stream->output = tb_null;
    stream->output_maxn = 0;
    LZ4_resetStream(&stream->handle);
}

static __tb_inline__ tb_void_t xm_lz4_stream_exit(xm_lz4_stream_t* stream)
{
    if (stream->output)
    {
        tb_free(stream->output);
        stream->output = tb_null;
    }
}

static __tb_inline__ tb_int_t xm_lz4_stream_compress(xm_lz4_stream_t* stream, tb_byte_t const* idata, tb_int_t isize, tb_byte_t** podata)
{
    // TODO
    return -1;
}

#endif


