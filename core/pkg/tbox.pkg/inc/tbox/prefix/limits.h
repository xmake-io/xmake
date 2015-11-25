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
 * @file        limits.h
 *
 */
#ifndef TB_PREFIX_LIMITS_H
#define TB_PREFIX_LIMITS_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#define TB_MAXS8                ((tb_sint8_t)(0x7f))
#define TB_MINS8                ((tb_sint8_t)(0x81))
#define TB_MAXU8                ((tb_uint8_t)(0xff))
#define TB_MINU8                ((tb_uint8_t)(0))

#define TB_MAXS16               ((tb_sint16_t)(0x7fff))
#define TB_MINS16               ((tb_sint16_t)(0x8001))
#define TB_MAXU16               ((tb_uint16_t)(0xffff))
#define TB_MINU16               ((tb_uint16_t)(0))

#define TB_MAXS32               ((tb_sint32_t)(0x7fffffff))
#define TB_MINS32               ((tb_sint32_t)(0x80000001))
#define TB_MAXU32               ((tb_uint32_t)(0xffffffff))
#define TB_MINU32               ((tb_uint32_t)(0))

#define TB_MAXS64               ((tb_sint64_t)(0x7fffffffffffffffLL))
#define TB_MINS64               ((tb_sint64_t)(0x8000000000000001LL))
#define TB_MAXU64               ((tb_uint64_t)(0xffffffffffffffffULL))
#define TB_MINU64               ((tb_uint64_t)(0))

#define TB_NAN32                (0x80000000)


#endif


