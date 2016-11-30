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
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
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
