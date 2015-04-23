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
 * @file        maf.h
 * @ingroup     libm
 *
 */
#ifndef TB_LIBM_MAF_H
#define TB_LIBM_MAF_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if defined(TB_COMPILER_IS_GCC) \
        && TB_COMPILER_VERSION_BE(3, 3)
#   define TB_MAF       (__builtin_huge_val())
#elif defined(TB_COMPILER_IS_GCC) && TB_COMPILER_VERSION_BE(2, 96)
#   define TB_MAF       (__extension__ 0x1.0p2047)
#elif defined(TB_COMPILER_IS_GCC)
#   define TB_MAF       (__extension__ ((union { unsigned __l __attribute__((__mode__(__DI__))); tb_double_t __d; }) { __l: 0x7ff0000000000000ULL }).__d)
#else
    typedef union { tb_byte_t __c[8]; tb_double_t __d; } __tb_maf_t;
#   ifdef TB_WORDS_BIGENDIAN
#       define __tb_maf_bytes   { 0x7f, 0xf0, 0, 0, 0, 0, 0, 0 }
#   else
#       define __tb_maf_bytes   { 0, 0, 0, 0, 0, 0, 0xf0, 0x7f }
#   endif
    static __tb_maf_t __tb_maf = { __tb_maf_bytes };
#   define TB_MAF       (__tb_maf.__d)
#endif


#endif
