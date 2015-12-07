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
 * @file        packed_e.h
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "compiler.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/* packed
 *
 * // #define TB_PACKED_ALIGN 4
 * #include "tbox/prefix/packed.h"
 * typedef struct __tb_xxxxx_t
 * {
 *      tb_byte_t   a;
 *      tb_uint32_t b;
 *
 * } __tb_packed__ tb_xxxxx_t;
 *
 * #include "tbox/prefix/packed.h"
 *
 * sizeof(tb_xxxxx_t) == 5
 *
 */
#ifdef TB_COMPILER_IS_MSVC
#   ifndef TB_PACKED_ENTER
#       ifdef TB_PACKED_ALIGN
#           pragma pack(push, TB_PACKED_ALIGN)
#       else
#           pragma pack(push, 1)
#       endif
#       define TB_PACKED_ENTER
#   else
#       pragma pack(pop)
#       undef TB_PACKED_ENTER
#       undef TB_PACKED_ALIGN
#   endif
#endif
