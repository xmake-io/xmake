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

