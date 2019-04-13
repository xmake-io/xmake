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
 * @file        queue_buffer.c
 * @ingroup     memory
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "memory.h"
#include "../libc/libc.h"
#include "../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_queue_buffer_init(tb_queue_buffer_ref_t buffer, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(buffer, tb_false);

    // init 
    buffer->data = tb_null;
    buffer->head = tb_null;
    buffer->size = 0;
    buffer->maxn = maxn;

    // ok
    return tb_true;
}
tb_void_t tb_queue_buffer_exit(tb_queue_buffer_ref_t buffer)
{
    if (buffer)
    {
        if (buffer->data) tb_free(buffer->data);
        tb_memset(buffer, 0, sizeof(tb_queue_buffer_t));
    }
}
tb_byte_t* tb_queue_buffer_data(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return_val(buffer, tb_null);

    // the data
    return buffer->data;
}
tb_byte_t* tb_queue_buffer_head(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return_val(buffer, tb_null);

    // the head
    return buffer->head;
}
tb_byte_t* tb_queue_buffer_tail(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return_val(buffer, tb_null);

    // the tail
    return buffer->head? buffer->head + buffer->size : tb_null;
}
tb_size_t tb_queue_buffer_size(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return_val(buffer, 0);

    // the size
    return buffer->size;
}
tb_size_t tb_queue_buffer_maxn(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return_val(buffer, 0);

    // the maxn
    return buffer->maxn;
}
tb_size_t tb_queue_buffer_left(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return_val(buffer && buffer->size <= buffer->maxn, 0);

    // the left
    return buffer->maxn - buffer->size;
}
tb_bool_t tb_queue_buffer_full(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return_val(buffer, tb_false);

    // is full?
    return buffer->size == buffer->maxn? tb_true : tb_false;
}
tb_bool_t tb_queue_buffer_null(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return_val(buffer, tb_false);

    // is null?
    return buffer->size? tb_false : tb_true;
}
tb_void_t tb_queue_buffer_clear(tb_queue_buffer_ref_t buffer)
{
    // check
    tb_assert_and_check_return(buffer);

    // clear it
    buffer->size = 0;
    buffer->head = buffer->data;
}
tb_byte_t* tb_queue_buffer_resize(tb_queue_buffer_ref_t buffer, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(buffer && maxn && maxn >= buffer->size, tb_null);

    // has data?
    if (buffer->data)
    {
        // move data to head
        if (buffer->head != buffer->data)
        {
            if (buffer->size) tb_memmov(buffer->data, buffer->head, buffer->size);
            buffer->head = buffer->data;
        }

        // realloc
        if (maxn > buffer->maxn)
        {
            // init head
            buffer->head = tb_null;

            // make data
            buffer->data = (tb_byte_t*)tb_ralloc(buffer->data, maxn);
            tb_assert_and_check_return_val(buffer->data, tb_null);

            // save head
            buffer->head = buffer->data;
        }
    }

    // update maxn
    buffer->maxn = maxn;

    // ok
    return buffer->data;
}
tb_long_t tb_queue_buffer_skip(tb_queue_buffer_ref_t buffer, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(buffer, -1);

    // no data?
    tb_check_return_val(buffer->data && buffer->size && size, 0);
    tb_assert_and_check_return_val(buffer->head, -1);

    // read data
    tb_long_t read = buffer->size > size? size : buffer->size;
    buffer->head += read;
    buffer->size -= read;

    // null? reset head
    if (!buffer->size) buffer->head = buffer->data;

    // ok
    return read;
}
tb_long_t tb_queue_buffer_read(tb_queue_buffer_ref_t buffer, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(buffer && data, -1);

    // no data?
    tb_check_return_val(buffer->data && buffer->size && size, 0);
    tb_assert_and_check_return_val(buffer->head, -1);

    // read data
    tb_long_t read = buffer->size > size? size : buffer->size;
    tb_memcpy(data, buffer->head, read);
    buffer->head += read;
    buffer->size -= read;

    // null? reset head
    if (!buffer->size) buffer->head = buffer->data;

    // ok
    return read;
}
tb_long_t tb_queue_buffer_writ(tb_queue_buffer_ref_t buffer, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(buffer && data && buffer->maxn, -1);

    // no data?
    if (!buffer->data)
    {
        // make data
        buffer->data = tb_malloc_bytes(buffer->maxn);
        tb_assert_and_check_return_val(buffer->data, -1);

        // init it
        buffer->head = buffer->data;
        buffer->size = 0;
    }
    tb_assert_and_check_return_val(buffer->data && buffer->head, -1);

    // full?
    tb_size_t left = buffer->maxn - buffer->size;
    tb_check_return_val(left, 0);

    // attempt to write data in tail directly if the tail space is enough
    tb_byte_t* tail = buffer->head + buffer->size;
    if (buffer->data + buffer->maxn >= tail + size)
    {
        tb_memcpy(tail, data, size);
        buffer->size += size;
        return (tb_long_t)size;
    }

    // move data to head
    if (buffer->head != buffer->data)
    {
        if (buffer->size) tb_memmov(buffer->data, buffer->head, buffer->size);
        buffer->head = buffer->data;
    }

    // write data
    tb_size_t writ = left > size? size : left;
    tb_memcpy(buffer->data + buffer->size, data, writ);
    buffer->size += writ;

    // ok
    return writ;
}
tb_byte_t* tb_queue_buffer_pull_init(tb_queue_buffer_ref_t buffer, tb_size_t* size)
{
    // check
    tb_assert_and_check_return_val(buffer, tb_null);

    // no data?
    tb_check_return_val(buffer->data && buffer->size, tb_null);
    tb_assert_and_check_return_val(buffer->head, tb_null);

    // save size
    if (size) *size = buffer->size;

    // ok
    return buffer->head;
}
tb_void_t tb_queue_buffer_pull_exit(tb_queue_buffer_ref_t buffer, tb_size_t size)
{
    // check
    tb_assert_and_check_return(buffer && buffer->head && size <= buffer->size);

    // update
    buffer->size -= size;
    buffer->head += size;

    // null? reset head
    if (!buffer->size) buffer->head = buffer->data;
}
tb_byte_t* tb_queue_buffer_push_init(tb_queue_buffer_ref_t buffer, tb_size_t* size)
{
    // check
    tb_assert_and_check_return_val(buffer && buffer->maxn, tb_null);

    // no data?
    if (!buffer->data)
    {
        // make data
        buffer->data = tb_malloc_bytes(buffer->maxn);
        tb_assert_and_check_return_val(buffer->data, tb_null);

        // init 
        buffer->head = buffer->data;
        buffer->size = 0;
    }
    tb_assert_and_check_return_val(buffer->data && buffer->head, tb_null);

    // full?
    tb_size_t left = buffer->maxn - buffer->size;
    tb_check_return_val(left, tb_null);

    // move data to head first, make sure there is enough write space 
    if (buffer->head != buffer->data)
    {
        if (buffer->size) tb_memmov(buffer->data, buffer->head, buffer->size);
        buffer->head = buffer->data;
    }

    // save size
    if (size) *size = left;

    // ok
    return buffer->head + buffer->size;
}
tb_void_t tb_queue_buffer_push_exit(tb_queue_buffer_ref_t buffer, tb_size_t size)
{
    // check
    tb_assert_and_check_return(buffer && buffer->head && buffer->size + size <= buffer->maxn);

    // update the size
    buffer->size += size;
}

