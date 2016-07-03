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
#ifndef TB_PLATFORM_ARCH_ARM_FRAME_H
#define TB_PLATFORM_ARCH_ARM_FRAME_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the current stack frame address
#if !defined(TB_CURRENT_STACK_FRAME) \
    && defined(TB_COMPILER_IS_GCC) \
    &&  TB_COMPILER_VERSION_BE(4, 1)
#   define TB_CURRENT_STACK_FRAME               (__builtin_frame_address(0) - 12)
#endif

// the advance stack frame address
#ifndef TB_ADVANCE_STACK_FRAME
#   define TB_ADVANCE_STACK_FRAME(next)         ((tb_frame_layout_t*)(next) - 1)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the frame layout type
typedef struct __tb_frame_layout_t
{
    // the next
    struct __tb_frame_layout_t*     next;

    // the sp
    tb_pointer_t                    sp;

    // the frame return address
    tb_pointer_t                    return_address;

}tb_frame_layout_t;


#endif
