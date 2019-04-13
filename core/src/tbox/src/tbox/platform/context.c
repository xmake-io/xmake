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
 * @file        context.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "context.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if !defined(TB_ARCH_x86) && \
    !defined(TB_ARCH_x64) && \
    !defined(TB_ARCH_ARM) && \
    !defined(TB_ARCH_MIPS) 
tb_context_ref_t tb_context_make(tb_byte_t* stackdata, tb_size_t stacksize, tb_context_func_t func)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_context_from_t tb_context_jump(tb_context_ref_t context, tb_cpointer_t priv)
{
    // noimpl
    tb_trace_noimpl();

    // return emtry context
    tb_context_from_t from = {0};
    return from;
}
#endif

