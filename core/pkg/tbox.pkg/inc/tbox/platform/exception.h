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

#endif


