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
 * @file        cache.h
 *
 */
#ifndef TB_PREFIX_ASM_CACHE_H
#define TB_PREFIX_ASM_CACHE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the cpu L1 cache shift, default: (1 << 5) == 32 bytes
#ifndef TB_L1_CACHE_SHIFT
#   define TB_L1_CACHE_SHIFT                (5)
#endif

// the cpu L1 cache bytes, default: 32 bytes
#ifndef TB_L1_CACHE_BYTES
#   define TB_L1_CACHE_BYTES                (1 << TB_L1_CACHE_SHIFT)
#endif

// the smp cache bytes
#ifndef TB_SMP_CACHE_BYTES
#   define TB_SMP_CACHE_BYTES               TB_L1_CACHE_BYTES
#endif

// the cacheline aligned keyword
#ifndef __tb_cacheline_aligned__
#   if defined(TB_COMPILER_IS_GCC)
#       define __tb_cacheline_aligned__     __attribute__((__aligned__(TB_SMP_CACHE_BYTES)))
#   elif defined(TB_COMPILER_IS_MSVC)
#       if TB_SMP_CACHE_BYTES == 4
#           define __tb_cacheline_aligned__     __declspec(align(4))
#       elif TB_SMP_CACHE_BYTES == 8
#           define __tb_cacheline_aligned__     __declspec(align(8))
#       elif TB_SMP_CACHE_BYTES == 16
#           define __tb_cacheline_aligned__     __declspec(align(16))
#       elif TB_SMP_CACHE_BYTES == 32
#           define __tb_cacheline_aligned__     __declspec(align(32))
#       elif TB_SMP_CACHE_BYTES == 64
#           define __tb_cacheline_aligned__     __declspec(align(64))
#       elif TB_SMP_CACHE_BYTES == 128
#           define __tb_cacheline_aligned__     __declspec(align(128))
#       elif TB_SMP_CACHE_BYTES == 256
#           define __tb_cacheline_aligned__     __declspec(align(256))
#       else
#           error unknown cacheline bytes
#       endif
#   else
#       define __tb_cacheline_aligned__
#   endif
#endif
  
#endif


