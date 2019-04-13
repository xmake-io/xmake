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
 * @file        cache.h
 *
 */
#ifndef TB_PREFIX_CACHE_H
#define TB_PREFIX_CACHE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"

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


