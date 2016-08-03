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
 * Copyright (C) 2016, Olexander Yermakov and ruki All rights reserved.
 *
 * @author      alexyer, ruki
 * @file        fnv32.h
 * @ingroup     hash
 *
 */
#ifndef TB_HASH_FNV32_H
#define TB_HASH_FNV32_H

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

/*! make fnv32 hash
 *
 * @param data      the data
 * @param size      the size
 * @param seed      uses this seed if be non-zero
 *
 * @return          the fnv32 value
 */
tb_uint32_t         tb_fnv32_make(tb_byte_t const* data, tb_size_t size, tb_uint32_t seed);

/*! make fnv32 hash from c-string
 *
 * @param cstr      the c-string
 * @param seed      uses this seed if be non-zero
 *
 * @return          the fnv32 value
 */
tb_uint32_t         tb_fnv32_make_from_cstr(tb_char_t const* cstr, tb_uint32_t seed);

/*! make fnv32(1a) hash
 *
 * @param data      the data
 * @param size      the size
 * @param seed      uses this seed if be non-zero
 *
 * @return          the fnv32 value
 */
tb_uint32_t         tb_fnv32_1a_make(tb_byte_t const* data, tb_size_t size, tb_uint32_t seed);

/*! make fnv32(1a) hash from c-string
 *
 * @param cstr      the c-string
 * @param seed      uses this seed if be non-zero
 *
 * @return          the fnv32 value
 */
tb_uint32_t         tb_fnv32_1a_make_from_cstr(tb_char_t const* cstr, tb_uint32_t seed);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
