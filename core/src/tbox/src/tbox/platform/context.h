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
 * @file        context.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_CONTEXT_H
#define TB_PLATFORM_CONTEXT_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the context ref type
typedef __tb_typeref__(context);

// the context-from type
typedef struct __tb_context_from_t
{
    // the from-context
    tb_context_ref_t    context;

    // the passed user private data
    tb_cpointer_t       priv;

}tb_context_from_t;

/*! the context entry function type
 *
 * @param from          the from-context
 */
typedef tb_void_t       (*tb_context_func_t)(tb_context_from_t from);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! make context from the given the stack space and the callback function
 *
 * @param stackdata     the stack data
 * @param stacksize     the stack size
 * @param func          the entry function
 *
 * @return              the context pointer
 */
tb_context_ref_t        tb_context_make(tb_byte_t* stackdata, tb_size_t stacksize, tb_context_func_t func);

/*! jump to the given context 
 *
 * @param context       the to-context
 * @param priv          the passed user private data
 *
 * @return              the from-context
 */
tb_context_from_t       tb_context_jump(tb_context_ref_t context, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
