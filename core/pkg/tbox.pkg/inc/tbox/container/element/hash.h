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

#endif
