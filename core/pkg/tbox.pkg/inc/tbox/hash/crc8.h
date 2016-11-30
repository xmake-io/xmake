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
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        crc8.h
 * @ingroup     hash
 *
 */
#ifndef TB_HASH_CRC8_H
#define TB_HASH_CRC8_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// encode value
#define tb_crc8_make_value(mode, crc, value)       tb_crc8_make(mode, crc, (tb_byte_t const*)&(value), sizeof(value))

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! make crc8 (ATM)
 *
 * @param data      the input data
 * @param size      the input size
 * @param seed      uses this seed if be non-zero
 *
 * @return          the crc value
 */
tb_uint8_t         tb_crc8_make(tb_byte_t const* data, tb_size_t size, tb_uint8_t seed);

/*! make crc8 (ATM) for cstr
 *
 * @param cstr      the input cstr
 * @param seed      uses this seed if be non-zero
 *
 * @return          the crc value
 */
tb_uint8_t         tb_crc8_make_from_cstr(tb_char_t const* cstr, tb_uint8_t seed);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

