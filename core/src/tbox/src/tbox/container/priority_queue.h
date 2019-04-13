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
 * @file        priority_queue.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_PRIORITY_QUEUE_H
#define TB_CONTAINER_PRIORITY_QUEUE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "element.h"
#include "heap.h"
#include "iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the priority queue ref type
 *
 * using the min/max heap
 */
typedef tb_heap_ref_t       tb_priority_queue_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init queue, default: min-priority
 *
 * @param grow              the element grow, using the default grow if be zero
 * @param element           the element
 *
 * @return                  the queue
 */
tb_priority_queue_ref_t     tb_priority_queue_init(tb_size_t grow, tb_element_t element);

/*! exit queue
 *
 * @param queue             the queue
 */
tb_void_t                   tb_priority_queue_exit(tb_priority_queue_ref_t queue);

/*! clear the queue
 *
 * @param queue             the queue
 */
tb_void_t                   tb_priority_queue_clear(tb_priority_queue_ref_t queue);

/*! the queue size
 *
 * @param queue             the queue
 *
 * @return                  the queue size
 */
tb_size_t                   tb_priority_queue_size(tb_priority_queue_ref_t queue);

/*! the queue maxn
 *
 * @param queue             the queue
 *
 * @return                  the queue maxn
 */
tb_size_t                   tb_priority_queue_maxn(tb_priority_queue_ref_t queue);

/*! get the queue item
 *
 * @param queue             the queue
 *
 * @return                  the queue top item
 */
tb_pointer_t                tb_priority_queue_get(tb_priority_queue_ref_t queue);

/*! put the queue item
 *
 * @param queue             the queue
 * @param data              the item data
 */
tb_void_t                   tb_priority_queue_put(tb_priority_queue_ref_t queue, tb_cpointer_t data);

/*! pop the queue item
 *
 * @param queue             the queue
 */
tb_void_t                   tb_priority_queue_pop(tb_priority_queue_ref_t queue);

/*! remove the queue item
 *
 * @param queue             the queue
 * @param itor              the itor
 */
tb_void_t                   tb_priority_queue_remove(tb_priority_queue_ref_t queue, tb_size_t itor);

#ifdef __tb_debug__
/*! dump queue
 *
 * @param queue             the queue
 */
tb_void_t                   tb_priority_queue_dump(tb_priority_queue_ref_t queue);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

