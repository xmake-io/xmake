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
 * @file        setjmp.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_MISC_SETJMP_H
#define TB_LIBC_MISC_SETJMP_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_CONFIG_LIBC_HAVE_SETJMP) || defined(TB_CONFIG_LIBC_HAVE_SIGSETJMP)
#   include <setjmp.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// setjmp
#ifdef TB_CONFIG_LIBC_HAVE_SETJMP
#   if defined(TB_COMPILER_IS_GCC)
#       define tb_setjmp(buf)           __builtin_setjmp(buf)
#       define tb_longjmp(buf, val)     __builtin_longjmp(buf, val)
#   else
#       define tb_setjmp(buf)           setjmp(buf)
#       define tb_longjmp(buf, val)     longjmp(buf, val)
#   endif
#else
#   undef tb_setjmp
#   undef tb_longjmp
#endif

// sigsetjmp
#ifdef TB_CONFIG_LIBC_HAVE_SIGSETJMP
#   define tb_sigsetjmp(buf, sig)       sigsetjmp(buf, sig)
#   define tb_siglongjmp(buf, val)      siglongjmp(buf, val)
#else
#   undef tb_sigsetjmp
#   undef tb_siglongjmp
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the jmpbuf type
#ifdef TB_CONFIG_LIBC_HAVE_SETJMP
typedef jmp_buf     tb_jmpbuf_t;
#endif

// the sigjmpbuf type
#ifdef TB_CONFIG_LIBC_HAVE_SIGSETJMP
typedef sigjmp_buf  tb_sigjmpbuf_t;
#endif


#endif
