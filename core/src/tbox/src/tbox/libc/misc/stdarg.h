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
 * @file        stdarg.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_MISC_STDARG_H
#define TB_LIBC_MISC_STDARG_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../../prefix.h"
#ifndef TB_COMPILER_IS_GCC
#   include <stdarg.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef TB_COMPILER_IS_GCC
#   define tb_va_start(v, l)        __builtin_va_start(v, l)
#   define tb_va_end(v)             __builtin_va_end(v)
#   define tb_va_arg(v, l)          __builtin_va_arg(v, l)
#   define tb_va_copy(v, c)         __builtin_va_copy(v, c)
#else
#   define tb_va_start(v, l)        va_start(v, l)
#   define tb_va_end(v)             va_end(v)
#   define tb_va_arg(v, l)          va_arg(v, l)
#   ifndef va_copy
#       define tb_va_copy(v, c)     ((v) = (c))
#   else
#       define tb_va_copy(v, c)     va_copy(v, c)
#   endif
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

#ifdef TB_COMPILER_IS_GCC
typedef __builtin_va_list   tb_va_list_t;
#else
typedef va_list             tb_va_list_t;
#endif

#endif
