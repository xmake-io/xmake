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
 * @file        priority_queue.c
 * @ingroup     container
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "priority_queue.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_priority_queue_ref_t tb_priority_queue_init(tb_size_t grow, tb_element_t element)
{
    return (tb_priority_queue_ref_t)tb_heap_init(grow, element);
}
tb_void_t tb_priority_queue_exit(tb_priority_queue_ref_t self)
{
    tb_heap_exit((tb_heap_ref_t)self);
}
tb_void_t tb_priority_queue_clear(tb_priority_queue_ref_t self)
{
    tb_heap_clear((tb_heap_ref_t)self);
}
tb_size_t tb_priority_queue_size(tb_priority_queue_ref_t self)
{
    return tb_heap_size((tb_heap_ref_t)self);
}
tb_size_t tb_priority_queue_maxn(tb_priority_queue_ref_t self)
{
    return tb_heap_maxn((tb_heap_ref_t)self);
}
tb_pointer_t tb_priority_queue_get(tb_priority_queue_ref_t self)
{
    return tb_heap_top((tb_heap_ref_t)self);
}
tb_void_t tb_priority_queue_put(tb_priority_queue_ref_t self, tb_cpointer_t data)
{
    tb_heap_put((tb_heap_ref_t)self, data);
}
tb_void_t tb_priority_queue_pop(tb_priority_queue_ref_t self)
{
    tb_heap_pop((tb_heap_ref_t)self);
}
tb_void_t tb_priority_queue_remove(tb_priority_queue_ref_t self, tb_size_t itor)
{
    tb_heap_remove((tb_heap_ref_t)self, itor);
}
#ifdef __tb_debug__
tb_void_t tb_priority_queue_dump(tb_priority_queue_ref_t self)
{
    tb_heap_dump((tb_heap_ref_t)self);
}
#endif
