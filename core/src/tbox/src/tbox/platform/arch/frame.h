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
 * @file        frame.h
 *
 */
#ifndef TB_PLATFORM_ARCH_FRAME_H
#define TB_PLATFORM_ARCH_FRAME_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_ARCH_x86)
#   include "x86/frame.h"
#elif defined(TB_ARCH_x64)
#   include "x64/frame.h"
#elif defined(TB_ARCH_ARM)
#   include "arm/frame.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the first frame address
#if !defined(TB_FIRST_FRAME_POINTER) \
    && defined(TB_COMPILER_IS_GCC) \
    &&  TB_COMPILER_VERSION_BE(4, 1)
#   define TB_FIRST_FRAME_POINTER               __builtin_frame_address(0)
#endif

// the current stack frame address
#ifndef TB_CURRENT_STACK_FRAME
#   define TB_CURRENT_STACK_FRAME               ({ tb_char_t __csf; &__csf; })
#endif

/* the advance stack frame address
 *
 * by default assume the `next' pointer in struct layout points to the next struct layout.
 */
#ifndef TB_ADVANCE_STACK_FRAME
#   define TB_ADVANCE_STACK_FRAME(next)         ((tb_frame_layout_t*)(next))
#endif

/* the address is inner than the stack address
 *
 * by default we assume that the stack grows downward.
 */
#ifndef TB_STACK_INNER_THAN
#   define TB_STACK_INNER_THAN                  <
#endif

#endif
