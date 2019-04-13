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
#   define tb_setjmp(buf)               setjmp(buf)
#   define tb_longjmp(buf, val)         longjmp(buf, val)
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
