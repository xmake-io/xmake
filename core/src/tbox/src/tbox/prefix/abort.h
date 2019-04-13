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

/* abort it, @note ud2 cannot be aborted immediately for multi-thread
 * and it will be not catched for linux exception (ignore int3 signal)
 */
#if (defined(TB_ARCH_x86) || defined(TB_ARCH_x64)) && \
        (!defined(TB_CONFIG_EXCEPTION_ENABLE) || defined(TB_CONFIG_OS_WINDOWS))
#   if defined(TB_ASSEMBLER_IS_MASM) && !defined(TB_ARCH_x64)
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


