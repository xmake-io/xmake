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
 * @file        crc32.h
 * @ingroup     hash
 *
 */
#ifndef TB_HASH_CRC32_H
#define TB_HASH_CRC32_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// encode value
#define tb_crc32_make_value(mode, crc, value)       tb_crc32_make(mode, crc, (tb_byte_t const*)&(value), sizeof(value))

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! make crc32 (IEEE)
 *
 * @param data      the input data
 * @param size      the input size
 * @param seed      uses this seed if be non-zero
 *
 * @return          the crc value
 */
tb_uint32_t         tb_crc32_make(tb_byte_t const* data, tb_size_t size, tb_uint32_t seed);

/*! make crc32 (IEEE) for cstr
 *
 * @param cstr      the input cstr
 * @param seed      uses this seed if be non-zero
 *
 * @return          the crc value
 */
tb_uint32_t         tb_crc32_make_from_cstr(tb_char_t const* cstr, tb_uint32_t seed);

/*! make crc32 (IEEE LE)
 *
 * @param data      the input data
 * @param size      the input size
 * @param seed      uses this seed if be non-zero
 *
 * @return          the crc value
 */
tb_uint32_t         tb_crc32_le_make(tb_byte_t const* data, tb_size_t size, tb_uint32_t seed);

/*! make crc32 (IEEE LE) for cstr
 *
 * @param cstr      the input cstr
 * @param seed      uses this seed if be non-zero
 *
 * @return          the crc value
 */
tb_uint32_t         tb_crc32_le_make_from_cstr(tb_char_t const* cstr, tb_uint32_t seed);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

