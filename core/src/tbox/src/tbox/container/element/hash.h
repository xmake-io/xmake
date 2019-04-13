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
 * @file        hash.h
 *
 */
#ifndef TB_CONTAINER_ELEMENT_HASH_H
#define TB_CONTAINER_ELEMENT_HASH_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* compute the uint8 hash 
 *
 * @param value     the value
 * @param mask      the mask
 * @param index     the hash func index
 *
 * @return          the hash value
 */
tb_size_t           tb_element_hash_uint8(tb_uint8_t value, tb_size_t mask, tb_size_t index);

/* compute the uint16 hash 
 *
 * @param value     the value
 * @param mask      the mask
 * @param index     the hash func index
 *
 * @return          the hash value
 */
tb_size_t           tb_element_hash_uint16(tb_uint16_t value, tb_size_t mask, tb_size_t index);

/* compute the uint32 hash 
 *
 * @param value     the value
 * @param mask      the mask
 * @param index     the hash func index
 *
 * @return          the hash value
 */
tb_size_t           tb_element_hash_uint32(tb_uint32_t value, tb_size_t mask, tb_size_t index);

/* compute the uint64 hash 
 *
 * @param value     the value
 * @param mask      the mask
 * @param index     the hash func index
 *
 * @return          the hash value
 */
tb_size_t           tb_element_hash_uint64(tb_uint64_t value, tb_size_t mask, tb_size_t index);

/* compute the data hash 
 *
 * @param data      the data
 * @param size      the size
 * @param mask      the mask
 * @param index     the hash func index
 *
 * @return          the hash value
 */
tb_size_t           tb_element_hash_data(tb_byte_t const* data, tb_size_t size, tb_size_t mask, tb_size_t index);

/* compute the cstring hash 
 *
 * @param cstr      the cstring
 * @param mask      the mask
 * @param index     the hash func index
 *
 * @return          the hash value
 */
tb_size_t           tb_element_hash_cstr(tb_char_t const* cstr, tb_size_t mask, tb_size_t index);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
