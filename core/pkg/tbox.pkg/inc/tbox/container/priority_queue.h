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

