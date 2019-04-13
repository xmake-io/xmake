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
