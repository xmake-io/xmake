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
 * @file        ctype.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_CTYPE_H
#define TB_LIBC_CTYPE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// is
#define tb_isspace(x)               (((x) == 0x20) || ((x) > 0x8 && (x) < 0xe))
#define tb_isgraph(x)               ((x) > 0x1f && (x) < 0x7f)
#define tb_isalpha(x)               (((x) > 0x40 && (x) < 0x5b) || ((x) > 0x60 && (x) < 0x7b))
#define tb_isupper(x)               ((x) > 0x40 && (x) < 0x5b)
#define tb_islower(x)               ((x) > 0x60 && (x) < 0x7b)
#define tb_isascii(x)               ((x) >= 0x0 && (x) < 0x80)
#define tb_isdigit(x)               ((x) > 0x2f && (x) < 0x3a)
#define tb_isdigit2(x)              ((x) == '0' || (x) == '1')
#define tb_isdigit8(x)              (((x) > 0x2f && (x) < 0x38))
#define tb_isdigit10(x)             (tb_isdigit(x))
#define tb_isdigit16(x)             (((x) > 0x2f && (x) < 0x3a) || ((x) > 0x40 && (x) < 0x47) || ((x) > 0x60 && (x) < 0x67))

// to lower & upper
#define tb_tolower(x)               (tb_isupper(x)? (x) + 0x20 : (x))
#define tb_toupper(x)               (tb_islower(x)? (x) - 0x20 : (x))



#endif
