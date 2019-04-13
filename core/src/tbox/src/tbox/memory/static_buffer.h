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
 * @file        static_buffer.h
 * @ingroup     memory
 *
 */
#ifndef TB_MEMORY_STATIC_BUFFER_H
#define TB_MEMORY_STATIC_BUFFER_H

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

// the static buffer type
typedef struct __tb_static_buffer_t
{
    // the buffer data
    tb_byte_t*      data;

    // the buffer size
    tb_size_t       size;

    // the buffer maxn
    tb_size_t       maxn;

}tb_static_buffer_t, *tb_static_buffer_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the static buffer
 *
 * @param buffer    the static buffer
 * @param data      the data
 * @param maxn      the data maxn
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_static_buffer_init(tb_static_buffer_ref_t buffer, tb_byte_t* data, tb_size_t maxn);

/*! exit the static buffer
 *
 * @param buffer    the static buffer
 */
tb_void_t           tb_static_buffer_exit(tb_static_buffer_ref_t buffer);

/*! the buffer data
 *
 * @param buffer    the static buffer
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_data(tb_static_buffer_ref_t buffer);

/*! the buffer data size
 *
 * @param buffer    the static buffer
 *
 * @return          the buffer data size
 */
tb_size_t           tb_static_buffer_size(tb_static_buffer_ref_t buffer);

/*! the buffer data maxn
 *
 * @param buffer    the static buffer
 *
 * @return          the buffer data maxn
 */
tb_size_t           tb_static_buffer_maxn(tb_static_buffer_ref_t buffer);

/*! clear the buffer
 *
 * @param buffer    the static buffer
 */
tb_void_t           tb_static_buffer_clear(tb_static_buffer_ref_t buffer);

/*! resize the buffer size
 *
 * @param buffer    the static buffer
 * @param size      the new buffer size
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_resize(tb_static_buffer_ref_t buffer, tb_size_t size);

/*! memset: b => 0 ... e
 *
 * @param buffer    the static buffer
 * @param b         the filled byte
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memset(tb_static_buffer_ref_t buffer, tb_byte_t b);

/*! memset: b => p ... e
 *
 * @param buffer    the static buffer
 * @param p         the start position
 * @param b         the filled byte
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memsetp(tb_static_buffer_ref_t buffer, tb_size_t p, tb_byte_t b);

/*! memset: b => 0 ... n
 *
 * @param buffer    the static buffer
 * @param b         the filled byte
 * @param n         the filled count
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memnset(tb_static_buffer_ref_t buffer, tb_byte_t b, tb_size_t n);

/*! memset: b => p ... n
 *
 * @param buffer    the static buffer
 * @param p         the start position
 * @param b         the filled byte
 * @param n         the filled count
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memnsetp(tb_static_buffer_ref_t buffer, tb_size_t p, tb_byte_t b, tb_size_t n);

/*! memcpy: b => 0 ... 
 *
 * @param buffer    the static buffer
 * @param b         the copied buffer
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memcpy(tb_static_buffer_ref_t buffer, tb_static_buffer_ref_t b);

/*! memcpy: b => p ... 
 *
 * @param buffer    the static buffer
 * @param p         the start position
 * @param b         the copied buffer
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memcpyp(tb_static_buffer_ref_t buffer, tb_size_t p, tb_static_buffer_ref_t b);

/*! memcpy: b ... n => 0 ... 
 *
 * @param buffer    the static buffer
 * @param b         the copied buffer
 * @param n         the copied count
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memncpy(tb_static_buffer_ref_t buffer, tb_byte_t const* b, tb_size_t n);

/*! memcpy: b ... n => p ... 
 *
 * @param buffer    the static buffer
 * @param p         the start position
 * @param b         the copied buffer
 * @param n         the copied count
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memncpyp(tb_static_buffer_ref_t buffer, tb_size_t p, tb_byte_t const* b, tb_size_t n);

/*! memmov: b ... e => 0 ... 
 *
 * @param buffer    the static buffer
 * @param b         the moved start position
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memmov(tb_static_buffer_ref_t buffer, tb_size_t b);

/*! memmov: b ... e => p ... 
 *
 * @param buffer    the static buffer
 * @param p         the moved destination position
 * @param b         the moved start position
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memmovp(tb_static_buffer_ref_t buffer, tb_size_t p, tb_size_t b);

/*! memmov: b ... n => 0 ... 
 *
 * @param buffer    the static buffer
 * @param b         the moved start position
 * @param n         the moved count
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memnmov(tb_static_buffer_ref_t buffer, tb_size_t b, tb_size_t n);

/*! memmov: b ... n => p ... 
 *
 * @param buffer    the static buffer
 * @param p         the moved destination position
 * @param b         the moved start position
 * @param n         the moved count
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memnmovp(tb_static_buffer_ref_t buffer, tb_size_t p, tb_size_t b, tb_size_t n);

/*! memcat: b +=> e ... 
 *
 * @param buffer    the static buffer
 * @param b         the concated buffer
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memcat(tb_static_buffer_ref_t buffer, tb_static_buffer_ref_t b);

/*! memcat: b ... n +=> e ... 
 *
 * @param buffer    the static buffer
 * @param b         the concated buffer
 * @param n         the concated count
 *
 * @return          the buffer data address
 */
tb_byte_t*          tb_static_buffer_memncat(tb_static_buffer_ref_t buffer, tb_byte_t const* b, tb_size_t n);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

