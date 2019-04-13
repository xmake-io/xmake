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
