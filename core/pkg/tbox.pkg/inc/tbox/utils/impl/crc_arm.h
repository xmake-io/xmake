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
 * @file        crc_arm.h
 *
 */
#ifndef TB_UTILS_IMPL_CRC_ARM_H
#define TB_UTILS_IMPL_CRC_ARM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifndef TB_ARCH_ARM64
#   define tb_crc32_encode(crc, ib, in, table)  tb_crc32_encode_asm(crc, ib, in, table)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_uint32_t tb_crc32_encode_asm(tb_uint32_t crc, tb_byte_t const* ib, tb_size_t in, tb_uint32_t const* table);


#endif

