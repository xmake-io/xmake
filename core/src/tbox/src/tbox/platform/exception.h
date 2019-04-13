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
 * @file        exception.h
 *
 */
#ifndef TB_PLATFORM_EXCEPTION_H
#define TB_PLATFORM_EXCEPTION_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_EXCEPTION_ENABLE
#   include "../libc/misc/signal.h"
#   if defined(TB_CONFIG_OS_WINDOWS)
#       include "windows/exception.h"
#   elif defined(tb_signal) 
#       include "libc/exception.h"
#   endif
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// try
#ifndef __tb_try
#   define __tb_try                                     do
#endif

// except
#ifndef __tb_except
#   define __tb_except(x)                               while (0); if (0)
#endif

// leave
#ifndef __tb_leave
#   define __tb_leave                                   break
#endif

// end
#ifndef __tb_end
#   define __tb_end                 
#endif

// check
#define tb_check_leave(x)                               { if (!(x)) __tb_leave ; }

// assert
#ifdef __tb_debug__
#   define tb_assert_leave(x)                           { if (!(x)) {tb_trace_a("expr: %s", #x); __tb_leave ; } }
#   define tb_assert_and_check_leave(x)                 tb_assert_leave(x)
#else
#   define tb_assert_leave(x)                       
#   define tb_assert_and_check_leave(x)                 tb_check_leave(x)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif


