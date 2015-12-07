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
#ifndef TB_PLATFORM_ARCH_x64_FRAME_H
#define TB_PLATFORM_ARCH_x64_FRAME_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the current stack frame address
#if !defined(TB_CURRENT_STACK_FRAME) \
    && defined(TB_ASSEMBLER_IS_GAS)
#   define TB_CURRENT_STACK_FRAME       ({ __tb_register__ tb_char_t* frame __tb_asm__("rsp"); frame; })
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the frame layout type
typedef struct __tb_frame_layout_t
{
    // the next
    struct __tb_frame_layout_t*     next;

    // the frame return address
    tb_pointer_t                    return_address;

}tb_frame_layout_t;


#endif
