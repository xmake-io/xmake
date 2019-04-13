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
 * @file        queue.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_CIRCLE_QUEUE_H
#define TB_CONTAINER_CIRCLE_QUEUE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "element.h"
#include "iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the circle queue ref type
 *
 * <pre>
 * queue: |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||------|
 *       head                                                           last    tail
 *
 * queue: ||||||||||||||-----|--------------------------||||||||||||||||||||||||||
 *                   last  tail                       head                
 *
 * performance: 
 *
 * put: O(1)
 * pop: O(1)
 *
 * iterator:
 *
 * next: fast
 * prev: fast
 *
 * </pre>
 *
 * @note the index of the same item is mutable
 *
 */
typedef tb_iterator_ref_t   tb_circle_queue_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init queue
 *
 * @param maxn          the item maxn, using the default maxn if be zero
 * @param element       the element
 *
 * @return              the queue
 */
tb_circle_queue_ref_t   tb_circle_queue_init(tb_size_t maxn, tb_element_t element);

/*! exit queue
 *
 * @param queue         the queue
 */
tb_void_t               tb_circle_queue_exit(tb_circle_queue_ref_t queue);

/*! the queue head item
 *
 * @param queue         the queue
 *
 * @return              the head item
 */
tb_pointer_t            tb_circle_queue_head(tb_circle_queue_ref_t queue);

/*! the queue last item
 *
 * @param queue         the queue
 *
 * @return              the last item
 */
tb_pointer_t            tb_circle_queue_last(tb_circle_queue_ref_t queue);

/*! clear the queue
 *
 * @param queue         the queue
 */
tb_void_t               tb_circle_queue_clear(tb_circle_queue_ref_t queue);

/*! put the queue item
 *
 * @param queue         the queue
 * @param data          the item data
 */
tb_void_t               tb_circle_queue_put(tb_circle_queue_ref_t queue, tb_cpointer_t data);

/*! pop the queue item
 *
 * @param queue         the queue
 */
tb_void_t               tb_circle_queue_pop(tb_circle_queue_ref_t queue);

/*! get the queue item
 *
 * @param queue         the queue
 *
 * @return              the queue item
 */
tb_pointer_t            tb_circle_queue_get(tb_circle_queue_ref_t queue);

/*! the queue size
 *
 * @param queue         the queue
 *
 * @return              the queue size
 */
tb_size_t               tb_circle_queue_size(tb_circle_queue_ref_t queue);

/*! the queue maxn
 *
 * @param queue         the queue
 *
 * @return              the queue maxn
 */
tb_size_t               tb_circle_queue_maxn(tb_circle_queue_ref_t queue);

/*! the queue full?
 *
 * @param queue         the queue
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_circle_queue_full(tb_circle_queue_ref_t queue);

/*! the queue null?
 *
 * @param queue         the queue
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_circle_queue_null(tb_circle_queue_ref_t queue);

#ifdef __tb_debug__
/*! dump queue
 *
 * @param queue         the queue
 */
tb_void_t               tb_circle_queue_dump(tb_circle_queue_ref_t circle_queue);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

