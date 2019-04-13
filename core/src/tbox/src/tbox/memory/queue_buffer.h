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
 * @file        queue_buffer.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_QUEUE_BUFFER_H
#define TB_MEMORY_QUEUE_BUFFER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the queue buffer type
typedef struct __tb_queue_buffer_t
{
    // the buffer data
    tb_byte_t*      data;

    // the buffer head
    tb_byte_t*      head;

    // the buffer size
    tb_size_t       size;

    // the buffer maxn
    tb_size_t       maxn;

}tb_queue_buffer_t, *tb_queue_buffer_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init buffer
 *
 * @param buffer    the buffer
 * @param maxn      the buffer maxn
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_queue_buffer_init(tb_queue_buffer_ref_t buffer, tb_size_t maxn);

/*! exit buffer
 *
 * @param buffer    the buffer
 */
tb_void_t           tb_queue_buffer_exit(tb_queue_buffer_ref_t buffer);

/*! the buffer data
 *
 * @param buffer    the buffer
 *
 * @return          the buffer data
 */
tb_byte_t*          tb_queue_buffer_data(tb_queue_buffer_ref_t buffer);

/*! the buffer head
 *
 * @param buffer    the buffer
 *
 * @return          the buffer head
 */
tb_byte_t*          tb_queue_buffer_head(tb_queue_buffer_ref_t buffer);

/*! the buffer tail
 *
 * @param buffer    the buffer
 *
 * @return          the buffer tail
 */
tb_byte_t*          tb_queue_buffer_tail(tb_queue_buffer_ref_t buffer);

/*! the buffer maxn
 *
 * @param buffer    the buffer
 *
 * @return          the buffer maxn
 */
tb_size_t           tb_queue_buffer_maxn(tb_queue_buffer_ref_t buffer);

/*! the buffer size
 *
 * @param buffer    the buffer
 *
 * @return          the buffer size
 */
tb_size_t           tb_queue_buffer_size(tb_queue_buffer_ref_t buffer);

/*! the buffer left
 *
 * @param buffer    the buffer
 *
 * @return          the buffer left
 */
tb_size_t           tb_queue_buffer_left(tb_queue_buffer_ref_t buffer);

/*! the buffer full?
 *
 * @param buffer    the buffer
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_queue_buffer_full(tb_queue_buffer_ref_t buffer);

/*! the buffer null?
 *
 * @param buffer    the buffer
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_queue_buffer_null(tb_queue_buffer_ref_t buffer);

/*! clear buffer
 *
 * @param buffer    the buffer
 */
tb_void_t           tb_queue_buffer_clear(tb_queue_buffer_ref_t buffer);

/*! resize buffer size
 *
 * @param buffer    the buffer
 * @param maxn      the buffer maxn
 *
 * @return          the buffer data
 */
tb_byte_t*          tb_queue_buffer_resize(tb_queue_buffer_ref_t buffer, tb_size_t maxn);

/*! skip buffer
 *
 * @param buffer    the buffer
 * @param size      the skiped size
 *
 * @return          the real size
 */
tb_long_t           tb_queue_buffer_skip(tb_queue_buffer_ref_t buffer, tb_size_t size);

/*! read buffer
 *
 * @param buffer    the buffer
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size
 */
tb_long_t           tb_queue_buffer_read(tb_queue_buffer_ref_t buffer, tb_byte_t* data, tb_size_t size);

/*! writ buffer
 *
 * @param buffer    the buffer
 * @param data      the data
 * @param size      the size
 *
 * @return          the real size
 */
tb_long_t           tb_queue_buffer_writ(tb_queue_buffer_ref_t buffer, tb_byte_t const* data, tb_size_t size);

/*! init pull buffer for reading
 *
 * @param buffer    the buffer
 * @param size      the size
 *
 * @return          the data
 */
tb_byte_t*          tb_queue_buffer_pull_init(tb_queue_buffer_ref_t buffer, tb_size_t* size);

/*! exit pull buffer for reading
 *
 * @param buffer    the buffer
 * @param size      the size
 */
tb_void_t           tb_queue_buffer_pull_exit(tb_queue_buffer_ref_t buffer, tb_size_t size);

/*! init push buffer for writing
 *
 * @param buffer    the buffer
 * @param size      the size
 *
 * @return          the data
 */
tb_byte_t*          tb_queue_buffer_push_init(tb_queue_buffer_ref_t buffer, tb_size_t* size);

/*! exit push buffer for writing
 *
 * @param buffer    the buffer
 * @param size      the size
 */
tb_void_t           tb_queue_buffer_push_exit(tb_queue_buffer_ref_t buffer, tb_size_t size);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif

