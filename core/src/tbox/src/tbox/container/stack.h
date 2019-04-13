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
 * @file        stack.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_STACK_H
#define TB_CONTAINER_STACK_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "vector.h"
#include "element.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the stack ref type 
 *
 * <pre>
 * stack: |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||------|
 *       head                                                           last    tail
 *
 * stack: |||||||||||||||||||||||||||||||||||||||||------|
 *       head                                   last    tail
 *
 * performance: 
 *
 * push:    fast
 * pop:     fast
 *
 * iterator:
 * next:    fast
 * prev:    fast
 * </pre>
 *
 * @note the itor of the same item is fixed
 *
 */
typedef tb_vector_ref_t tb_stack_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init stack
 *
 * @param grow      the item grow
 * @param element   the element
 *
 * @return          the stack
 */
tb_stack_ref_t      tb_stack_init(tb_size_t grow, tb_element_t element);

/*! exit stack
 *
 * @param stack     the stack
 */
tb_void_t           tb_stack_exit(tb_stack_ref_t stack);

/*! the stack head item
 *
 * @param stack     the stack
 *
 * @return          the head item
 */
tb_pointer_t        tb_stack_head(tb_stack_ref_t stack);

/*! the stack last item
 *
 * @param stack     the stack
 *
 * @return          the last item
 */
tb_pointer_t        tb_stack_last(tb_stack_ref_t stack);

/*! clear the stack
 *
 * @param stack     the stack
 */
tb_void_t           tb_stack_clear(tb_stack_ref_t stack);

/*! copy the stack
 *
 * @param stack     the stack
 * @param copy      the copied stack
 */
tb_void_t           tb_stack_copy(tb_stack_ref_t stack, tb_stack_ref_t copy);

/*! put the stack item
 *
 * @param stack     the stack
 * @param data      the item data
 */
tb_void_t           tb_stack_put(tb_stack_ref_t stack, tb_cpointer_t data);

/*! pop the stack item
 *
 * @param stack     the stack
 */
tb_void_t           tb_stack_pop(tb_stack_ref_t stack);

/*! the stack top item
 *
 * @param stack     the stack
 *
 * @return          the stack top item
 */
tb_pointer_t        tb_stack_top(tb_stack_ref_t stack);

/*! the stack size
 *
 * @param stack     the stack
 *
 * @return          the stack size
 */
tb_size_t           tb_stack_size(tb_stack_ref_t stack);

/*! the stack maxn
 *
 * @param stack     the stack
 *
 * @return          the stack maxn
 */
tb_size_t           tb_stack_maxn(tb_stack_ref_t stack);

#ifdef __tb_debug__
/*! dump stack
 *
 * @param stack     the stack
 */
tb_void_t           tb_stack_dump(tb_stack_ref_t stack);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

