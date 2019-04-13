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
 * @file        queue.c
 * @ingroup     container
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "queue.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_queue_ref_t tb_queue_init(tb_size_t grow, tb_element_t element)
{  
    return (tb_queue_ref_t)tb_single_list_init(grow, element);
}
tb_void_t tb_queue_exit(tb_queue_ref_t queue)
{   
    tb_single_list_exit((tb_single_list_ref_t)queue);
}
tb_void_t tb_queue_clear(tb_queue_ref_t queue)
{
    tb_single_list_clear((tb_single_list_ref_t)queue);
}
tb_void_t tb_queue_put(tb_queue_ref_t queue, tb_cpointer_t data)
{   
    tb_single_list_insert_tail((tb_single_list_ref_t)queue, data);
}
tb_void_t tb_queue_pop(tb_queue_ref_t queue)
{   
    tb_single_list_remove_head((tb_single_list_ref_t)queue);
}
tb_pointer_t tb_queue_get(tb_queue_ref_t queue)
{
    return tb_queue_head(queue);
}
tb_pointer_t tb_queue_head(tb_queue_ref_t queue)
{
    return tb_single_list_head((tb_single_list_ref_t)queue);
}
tb_pointer_t tb_queue_last(tb_queue_ref_t queue)
{
    return tb_single_list_last((tb_single_list_ref_t)queue);
}
tb_size_t tb_queue_size(tb_queue_ref_t queue)
{   
    return tb_single_list_size((tb_single_list_ref_t)queue);
}
tb_size_t tb_queue_maxn(tb_queue_ref_t queue)
{   
    return tb_single_list_maxn((tb_single_list_ref_t)queue);
}
tb_bool_t tb_queue_full(tb_queue_ref_t queue)
{   
    return (tb_single_list_size((tb_single_list_ref_t)queue) < tb_single_list_maxn((tb_single_list_ref_t)queue))? tb_false : tb_true;
}
tb_bool_t tb_queue_null(tb_queue_ref_t queue)
{   
    return tb_single_list_size((tb_single_list_ref_t)queue)? tb_false : tb_true;
}
#ifdef __tb_debug__
tb_void_t tb_queue_dump(tb_queue_ref_t queue)
{
    tb_single_list_dump((tb_single_list_ref_t)queue);
}
#endif
