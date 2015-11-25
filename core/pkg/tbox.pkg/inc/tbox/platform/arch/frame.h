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
