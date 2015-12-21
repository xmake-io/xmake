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
 * @file        crc.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_CRC_H
#define TB_UTILS_CRC_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// encode value
#define tb_crc_encode_value(mode, crc, value)       tb_crc_encode(mode, crc, (tb_byte_t const*)&(value), sizeof(value))

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the crc mode type
typedef enum __tb_crc_mode_t
{
#ifdef __tb_small__
    TB_CRC_MODE_16_CCITT    = 0
,   TB_CRC_MODE_32_IEEE_LE  = 1
,   TB_CRC_MODE_MAX         = 2
#else
    TB_CRC_MODE_8_ATM       = 0
,   TB_CRC_MODE_16_ANSI     = 1
,   TB_CRC_MODE_16_CCITT    = 2
,   TB_CRC_MODE_32_IEEE     = 3
,   TB_CRC_MODE_32_IEEE_LE  = 4
,   TB_CRC_MODE_MAX         = 5
#endif

}tb_crc_mode_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! encode crc
 *
 * @param mode      the crc mode
 * @param crc       the initial crc value
 * @param data      the input data
 * @param size      the input size
 *
 * @return          the crc value
 */
tb_uint32_t         tb_crc_encode(tb_crc_mode_t mode, tb_uint32_t crc, tb_byte_t const* data, tb_size_t size);

/*! encode crc for cstr
 *
 * @param mode      the crc mode
 * @param crc       the initial crc value
 * @param cstr      the input cstr
 *
 * @return          the crc value
 */
tb_uint32_t         tb_crc_encode_cstr(tb_crc_mode_t mode, tb_uint32_t crc, tb_char_t const* cstr);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

