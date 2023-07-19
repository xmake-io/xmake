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
 * types
 */

// we need to define LZ4_byte if < 1.9.3
#if defined(LZ4_VERSION_NUMBER) && LZ4_VERSION_NUMBER < (1 * 100 * 100 + 9 * 100 + 3)
#   if defined(__cplusplus) || (defined (__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L) /* C99 */)
#       include <stdint.h>
        typedef int8_t  LZ4_i8;
        typedef uint8_t  LZ4_byte;
        typedef uint16_t LZ4_u16;
        typedef uint32_t LZ4_u32;
#   else
        typedef signed char  LZ4_i8;
        typedef unsigned char  LZ4_byte;
        typedef unsigned short LZ4_u16;
        typedef unsigned int   LZ4_u32;
#   endif
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the lz4 compress stream type
typedef struct __xm_lz4_cstream_t
{
    LZ4F_cctx*          cctx;
    LZ4_byte*           buffer;
    tb_size_t           buffer_size;
    tb_size_t           buffer_maxn;
    tb_size_t           write_maxn;
    tb_size_t           header_size;
    LZ4_byte            header[LZ4F_HEADER_SIZE_MAX];
}xm_lz4_cstream_t;

// the lz4 decompress stream type
typedef struct __xm_lz4_dstream_t
{
    LZ4F_dctx*          dctx;
    LZ4_byte*           buffer;
    tb_size_t           buffer_size;
    tb_size_t           buffer_maxn;
    tb_size_t           header_size;
    LZ4_byte            header[LZ4F_HEADER_SIZE_MAX];
}xm_lz4_dstream_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

static __tb_inline__ tb_void_t xm_lz4_cstream_exit(xm_lz4_cstream_t* stream)
{
    if (stream)
    {
        if (stream->cctx)
        {
            LZ4F_freeCompressionContext(stream->cctx);
            stream->cctx = tb_null;
        }
        if (stream->buffer)
        {
            tb_free(stream->buffer);
            stream->buffer = tb_null;
        }
        tb_free(stream);
    }
}

static __tb_inline__ xm_lz4_cstream_t* xm_lz4_cstream_init()
{
    tb_size_t ret;
    tb_bool_t ok = tb_false;
    xm_lz4_cstream_t* stream = tb_null;
    LZ4F_preferences_t const* prefsPtr = tb_null;
    do
    {
        stream = tb_malloc0_type(xm_lz4_cstream_t);
        tb_assert_and_check_break(stream);

        stream->write_maxn = 64 * 1024;
        stream->buffer_maxn = LZ4F_compressBound(stream->write_maxn, prefsPtr);
        stream->buffer = (LZ4_byte*)tb_malloc(stream->buffer_maxn);
        tb_assert_and_check_break(stream->buffer);

        ret = LZ4F_createCompressionContext(&stream->cctx, LZ4F_getVersion());
        if (LZ4F_isError(ret))
            break;

        ret = LZ4F_compressBegin(stream->cctx, stream->header, LZ4F_HEADER_SIZE_MAX, prefsPtr);
        if (LZ4F_isError(ret))
            break;

        stream->header_size = ret;

        ok = tb_true;

    } while (0);

    if (!ok && stream)
    {
        xm_lz4_cstream_exit(stream);
        stream = tb_null;
    }
    return stream;
}

static __tb_inline__ tb_long_t xm_lz4_cstream_write(xm_lz4_cstream_t* stream, tb_byte_t const* idata, tb_size_t isize, tb_bool_t end)
{
    // check
    tb_assert_and_check_return_val(stream && stream->cctx && idata && isize, -1);
    tb_assert_and_check_return_val(isize <= stream->write_maxn, -1);
    tb_assert_and_check_return_val(stream->buffer_size + isize < stream->buffer_maxn, -1);

    tb_size_t real = LZ4F_compressUpdate(stream->cctx, stream->buffer + stream->buffer_size,
        stream->buffer_maxn - stream->buffer_size, idata, isize, tb_null);
    if (LZ4F_isError(real))
        return -1;
    stream->buffer_size += real;

    if (end)
    {
        tb_size_t ret = LZ4F_compressEnd(stream->cctx, stream->buffer + stream->buffer_size,
            stream->buffer_maxn - stream->buffer_size, tb_null);
        if (LZ4F_isError(ret))
            return -1;

        real += ret;
        stream->buffer_size += ret;
    }

    return isize;
}

static __tb_inline__ tb_long_t xm_lz4_cstream_read(xm_lz4_cstream_t* stream, tb_byte_t* odata, tb_size_t osize)
{
    // check
    tb_assert_and_check_return_val(stream && stream->cctx && odata && osize, -1);
    tb_assert_and_check_return_val(osize >= stream->header_size, -1);

    tb_size_t read = 0;
    if (stream->header_size)
    {
        tb_memcpy(odata, stream->header, stream->header_size);
        read += stream->header_size;
        osize -= stream->header_size;
        stream->header_size = 0;
    }

    tb_size_t need = tb_min(stream->buffer_size, osize);
    tb_memcpy(odata + read, stream->buffer, need);
    if (need < stream->buffer_size)
        tb_memmov(stream->buffer, stream->buffer + need, stream->buffer_size - need);
    stream->buffer_size -= need;
    read += need;
    return read;
}

static __tb_inline__ tb_void_t xm_lz4_dstream_exit(xm_lz4_dstream_t* stream)
{
    if (stream)
    {
        if (stream->dctx)
        {
            LZ4F_freeDecompressionContext(stream->dctx);
            stream->dctx = tb_null;
        }
        if (stream->buffer)
        {
            tb_free(stream->buffer);
            stream->buffer = tb_null;
        }
        tb_free(stream);
    }
}

static __tb_inline__ xm_lz4_dstream_t* xm_lz4_dstream_init()
{
    LZ4F_errorCode_t ret;
    tb_bool_t ok = tb_false;
    xm_lz4_dstream_t* stream = tb_null;
    do
    {
        stream = tb_malloc0_type(xm_lz4_dstream_t);
        tb_assert_and_check_break(stream);

        ret = LZ4F_createDecompressionContext(&stream->dctx, LZ4F_getVersion());
        if (LZ4F_isError(ret))
            break;

        ok = tb_true;

    } while (0);

    if (!ok && stream)
    {
        xm_lz4_dstream_exit(stream);
        stream = tb_null;
    }
    return stream;
}

static __tb_inline__ tb_long_t xm_lz4_dstream_write(xm_lz4_dstream_t* stream, tb_byte_t const* idata, tb_size_t isize, tb_bool_t end)
{
    // check
    tb_assert_and_check_return_val(stream && stream->dctx && idata && isize, -1);

    // read header first
    const tb_size_t header_size = sizeof(stream->header);
    if (stream->header_size < header_size)
    {
        tb_size_t size = tb_min(header_size - stream->header_size, isize);
        tb_memcpy(stream->header + stream->header_size, idata, size);
        stream->header_size += size;
        idata += size;
        isize -= size;

        // get frame info if header is ok
        if (stream->header_size == header_size)
        {
            LZ4F_frameInfo_t info;
            size_t consumed_size = header_size;
            LZ4F_errorCode_t ret = LZ4F_getFrameInfo(stream->dctx, &info, stream->header, &consumed_size);
            if (LZ4F_isError(ret))
                return -1;

            switch (info.blockSizeID)
            {
            case LZ4F_default:
            case LZ4F_max64KB:
                stream->buffer_maxn = 64 * 1024;
                break;
            case LZ4F_max256KB:
                stream->buffer_maxn = 256 * 1024;
                break;
            case LZ4F_max1MB:
                stream->buffer_maxn = 1 * 1024 * 1024;
                break;
            case LZ4F_max4MB:
                stream->buffer_maxn = 4 * 1024 * 1024;
                break;
            default:
                return -1;
            }

            stream->buffer = (LZ4_byte*)tb_malloc(stream->buffer_maxn);
            tb_assert_and_check_return_val(stream->buffer, -1);

            stream->buffer_size = header_size - consumed_size;
            tb_memcpy(stream->buffer, stream->header + consumed_size, stream->buffer_size);
        }
    }
    tb_check_return_val(stream->header_size == header_size && isize, 0);
    tb_assert_and_check_return_val(stream->buffer && stream->buffer_size + isize <= stream->buffer_maxn, -1);

    // append the input data
    tb_memcpy(stream->buffer + stream->buffer_size, idata, isize);
    stream->buffer_size += isize;
    return isize;
}

static __tb_inline__ tb_long_t xm_lz4_dstream_read(xm_lz4_dstream_t* stream, tb_byte_t* odata, tb_size_t osize)
{
    // check
    tb_assert_and_check_return_val(stream && stream->dctx && stream->buffer && odata && osize, -1);
    tb_check_return_val(stream->buffer_size, 0);

    // do decompress
    size_t srcsize = stream->buffer_size;
    size_t dstsize = osize;
    tb_size_t ret = LZ4F_decompress(stream->dctx, odata, &dstsize, stream->buffer, &srcsize, tb_null);
    if (LZ4F_isError(ret))
        return -1;

    // move the left input data
    if (srcsize < stream->buffer_size)
        tb_memmov(stream->buffer, stream->buffer + srcsize, stream->buffer_size - srcsize);
    stream->buffer_size -= srcsize;
    return dstsize;
}

#endif


