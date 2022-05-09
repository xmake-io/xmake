/*!A cross-platform build utility based on Lua
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except idata compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to idata writing, software
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
    tb_byte_t           buffer[TB_STREAM_BLOCK_MAXN];
    tb_int_t            buffer_size;
    tb_int_t            buffer_position;
    tb_byte_t*          output;
    tb_int_t            output_maxn;
    tb_int_t            accelerate;
    LZ4_stream_t        encoder;
    LZ4_streamDecode_t  decoder;
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

static __tb_inline__ tb_void_t xm_lz4_stream_buffer_save_dict(xm_lz4_stream_t* stream, tb_char_t const* dict, tb_int_t dict_size)
{
    tb_int_t limit_len = LZ4_STREAM_DICTSIZE;
    if (limit_len > stream->buffer_size)
        limit_len = stream->buffer_size;

    if (dict_size > limit_len)
    {
        dict += dict_size - limit_len;
        dict_size = limit_len;
    }

    tb_memmov(stream->buffer, dict, dict_size);
    LZ4_setStreamDecode(&stream->decoder, (tb_char_t*)stream->buffer, dict_size);
    stream->buffer_position = dict_size;
}

static __tb_inline__ tb_void_t xm_lz4_stream_init(xm_lz4_stream_t* stream)
{
    stream->accelerate = 1;
    stream->buffer_position = 0;
    stream->buffer_size = sizeof(stream->buffer);
    stream->output = tb_null;
    stream->output_maxn = 0;
    LZ4_resetStream(&stream->encoder);
    LZ4_setStreamDecode(&stream->decoder, tb_null, 0);
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
    // check
    tb_assert_and_check_return_val(stream && idata && isize && podata, -1);

    // ensure the output buffer
    tb_int_t bound = LZ4_compressBound(isize);
    if (bound > 0 && bound > stream->output_maxn)
    {
        if (!stream->output) stream->output = tb_malloc_bytes(bound);
        else stream->output = (tb_byte_t*)tb_ralloc(stream->output, bound);
        stream->output_maxn = bound;
    }
    tb_assert_and_check_return_val(stream->output && stream->output_maxn > 0, -1);

    // do compress
    tb_int_t real = 0;
    tb_int_t policy = xm_lz4_stream_buffer_policy(stream->buffer_size, stream->buffer_position, isize);
    if (policy == LZ4_STREAM_BUFFER_POLICY_APPEND || policy == LZ4_STREAM_BUFFER_POLICY_RESET)
    {
        tb_byte_t* buffer = tb_null;
        if (policy == LZ4_STREAM_BUFFER_POLICY_APPEND)
        {
            buffer = stream->buffer + stream->buffer_position;
            stream->buffer_position += isize;
        }
        else
        {
            buffer = stream->buffer;
            stream->buffer_position = isize;
        }
        tb_memcpy(buffer, idata, isize);
        real = LZ4_compress_fast_continue(&stream->encoder, (tb_char_t*)buffer, (tb_char_t*)stream->output, isize, bound, stream->accelerate);
        tb_assert_and_check_return_val(real > 0, -1);
    }
    else
    {
        real = LZ4_compress_fast_continue(&stream->encoder, (tb_char_t*)idata, (tb_char_t*)stream->output, isize, bound, stream->accelerate);
        tb_assert_and_check_return_val(real > 0, -1);
        stream->buffer_position = LZ4_saveDict(&stream->encoder, (tb_char_t*)stream->buffer, stream->buffer_size);
    }

    *podata = stream->output;
    return real;
}

static __tb_inline__ tb_int_t xm_lz4_stream_decompress(xm_lz4_stream_t* stream, tb_byte_t const* idata, tb_int_t isize, tb_byte_t** podata)
{
    // check
    tb_assert_and_check_return_val(stream && idata && isize && podata, -1);

    // ensure the output buffer
    tb_int_t bound = isize << 2;
    if (bound > 0 && bound > stream->output_maxn)
    {
        if (!stream->output) stream->output = tb_malloc_bytes(bound);
        else stream->output = (tb_byte_t*)tb_ralloc(stream->output, bound);
        stream->output_maxn = bound;
    }
    tb_assert_and_check_return_val(stream->output && stream->output_maxn > 0, -1);

    // do decompress
    tb_int_t real = -1;
    tb_int_t policy = xm_lz4_stream_buffer_policy(stream->buffer_size, stream->buffer_position, isize);
    if (policy == LZ4_STREAM_BUFFER_POLICY_APPEND || policy == LZ4_STREAM_BUFFER_POLICY_RESET)
    {
        tb_byte_t* buffer;
        tb_size_t  new_position;
        if (policy == LZ4_STREAM_BUFFER_POLICY_APPEND)
        {
            buffer = stream->buffer + stream->buffer_position;
            new_position = stream->buffer_position + bound;
        }
        else
        {
            buffer = stream->buffer;
            new_position = bound;
        }
        real = LZ4_decompress_safe_continue(&stream->decoder, (tb_char_t*)idata, (tb_char_t*)buffer, isize, bound);
        tb_assert_and_check_return_val(real >= 0, -1);
        stream->buffer_position = new_position;

        *podata = buffer;
    }
    else
    {
        real = LZ4_decompress_safe_continue(&stream->decoder, (tb_char_t*)idata, (tb_char_t*)stream->output, isize, bound);
        tb_assert_and_check_return_val(real >= 0, -1);

        xm_lz4_stream_buffer_save_dict(stream, (tb_char_t*)stream->output, real);

        *podata = stream->output;
    }
    return real;
}

#endif


