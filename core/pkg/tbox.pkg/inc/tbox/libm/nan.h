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
 * @file        nan.h
 * @ingroup     libm
 *
 */
#ifndef TB_LIBM_NAN_H
#define TB_LIBM_NAN_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */


#if defined(TB_COMPILER_IS_GCC) \
        && TB_COMPILER_VERSION_BE(3, 3)
#   define TB_NAN   (__builtin_nanf (""))
#elif defined(TB_COMPILER_IS_GCC)
#   define TB_NAN   (__extension__ ((union { unsigned __l __attribute__ ((__mode__ (__SI__))); tb_float_t __d; }) { __l: 0x7fc00000UL }).__d)
#else
#   ifdef TB_WORDS_BIGENDIAN
#       define __tb_nan_bytes       { 0x7f, 0xc0, 0, 0 }
#   else
#       define __tb_nan_bytes       { 0, 0, 0xc0, 0x7f }
#   endif
    static union { tb_byte_t __c[4]; tb_float_t __d; } __tb_nan_union = { __tb_nan_bytes };
#   define TB_NAN   (__tb_nan_union.__d)
#endif

#endif
