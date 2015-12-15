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
 * @file        abort.h
 *
 */
#ifndef TB_PREFIX_ABORT_H
#define TB_PREFIX_ABORT_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "trace.h"
#include "assembler.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// abort it, @note ud2 cannot be aborted immediately for multi-thread
#if defined(TB_ARCH_x86) || defined(TB_ARCH_x64)
#   if defined(TB_ASSEMBLER_IS_MASM)
//#       define tb_abort_done()                          do { __tb_asm__ { ud2 } } while (0)
#       define tb_abort_done()                          do { __tb_asm__ { int 3 } } while (0)
#   elif defined(TB_ASSEMBLER_IS_GAS)
//#       define tb_abort_done()                          do { __tb_asm__ __tb_volatile__ ("ud2"); } while (0)
#     define tb_abort_done()                            do { __tb_asm__ __tb_volatile__ ("int3"); } while (0)
#   endif
#endif

#ifndef tb_abort_done
#   define tb_abort_done()                              do { *((__tb_volatile__ tb_int_t*)0) = 0; } while (0)
#endif

// abort
#define tb_abort()                                      do { tb_trace_e("abort"); tb_abort_done(); } while(0)

#endif


