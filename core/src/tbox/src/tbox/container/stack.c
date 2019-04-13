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
 * @file        stack.c
 * @ingroup     container
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "stack.h"
#include "../libc/libc.h"
#include "../utils/utils.h"
#include "../memory/memory.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

tb_stack_ref_t tb_stack_init(tb_size_t grow, tb_element_t element)
{
    return (tb_stack_ref_t)tb_vector_init(grow, element);
}
tb_void_t tb_stack_exit(tb_stack_ref_t self)
{
    tb_vector_exit((tb_vector_ref_t)self);
}
tb_void_t tb_stack_clear(tb_stack_ref_t self)
{
    tb_vector_clear((tb_vector_ref_t)self);
}
tb_void_t tb_stack_copy(tb_stack_ref_t self, tb_stack_ref_t copy)
{
    tb_vector_copy((tb_vector_ref_t)self, copy);
}
tb_void_t tb_stack_put(tb_stack_ref_t self, tb_cpointer_t data)
{
    tb_vector_insert_tail((tb_vector_ref_t)self, data);
}
tb_void_t tb_stack_pop(tb_stack_ref_t self)
{
    tb_vector_remove_last((tb_vector_ref_t)self);
}
tb_pointer_t tb_stack_top(tb_stack_ref_t self)
{
    return tb_vector_last((tb_vector_ref_t)self);
}
tb_pointer_t tb_stack_head(tb_stack_ref_t self)
{
    return tb_vector_head((tb_vector_ref_t)self);
}
tb_pointer_t tb_stack_last(tb_stack_ref_t self)
{
    return tb_vector_last((tb_vector_ref_t)self);
}
tb_size_t tb_stack_size(tb_stack_ref_t self)
{
    return tb_vector_size((tb_vector_ref_t)self);
}
tb_size_t tb_stack_maxn(tb_stack_ref_t self)
{
    return tb_vector_maxn((tb_vector_ref_t)self);
}
#ifdef __tb_debug__
tb_void_t tb_stack_dump(tb_stack_ref_t self)
{
    tb_vector_dump((tb_vector_ref_t)self);
}
#endif
