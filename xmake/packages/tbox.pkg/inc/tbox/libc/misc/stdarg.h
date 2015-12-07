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
