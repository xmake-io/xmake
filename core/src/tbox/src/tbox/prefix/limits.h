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


