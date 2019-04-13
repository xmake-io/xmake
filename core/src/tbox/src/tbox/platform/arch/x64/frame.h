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
