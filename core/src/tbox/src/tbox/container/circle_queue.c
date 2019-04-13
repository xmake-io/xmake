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
 * @file        circle_queue.c
 * @ingroup     container
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "circle_queue.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../memory/memory.h"
#include "../stream/stream.h"
#include "../platform/platform.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef __tb_small__
#   define TB_CIRCLE_QUEUE_SIZE_DEFAULT            (256)
#else
#   define TB_CIRCLE_QUEUE_SIZE_DEFAULT            (65536)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the circle queue type
typedef struct __tb_circle_queue_t
{
    // the itor
    tb_iterator_t           itor;

    // the data
    tb_byte_t*              data;
    
    // the head
    tb_size_t               head;

    // the tail
    tb_size_t               tail;

    // the maxn
    tb_size_t               maxn;

    // the size
    tb_size_t               size;

    // the element
    tb_element_t            element;

}tb_circle_queue_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_size_t tb_circle_queue_itor_size(tb_iterator_ref_t iterator)
{   
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert_and_check_return_val(queue, 0);

    // the size
    return queue->size;
}
static tb_size_t tb_circle_queue_itor_head(tb_iterator_ref_t iterator)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert_and_check_return_val(queue, 0);

    // head
    return queue->head;
}
static tb_size_t tb_circle_queue_itor_last(tb_iterator_ref_t iterator)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert_and_check_return_val(queue, 0);

    // last
    return (queue->tail + queue->maxn - 1) % queue->maxn;
}
static tb_size_t tb_circle_queue_itor_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert_and_check_return_val(queue, 0);

    // tail
    return queue->tail;
}
static tb_size_t tb_circle_queue_itor_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert_and_check_return_val(queue, 0);

    // next
    return (itor + 1) % queue->maxn;
}
static tb_size_t tb_circle_queue_itor_prev(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert_and_check_return_val(queue, 0);

    // prev
    return (itor + queue->maxn - 1) % queue->maxn;
}
static tb_pointer_t tb_circle_queue_itor_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert_and_check_return_val(queue && itor < queue->maxn, tb_null);

    // item
    return queue->element.data(&queue->element, queue->data + itor * iterator->step);
}
static tb_void_t tb_circle_queue_itor_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert(queue);

    // copy
    queue->element.copy(&queue->element, queue->data + itor * iterator->step, item);
}
static tb_long_t tb_circle_queue_itor_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)iterator;
    tb_assert_and_check_return_val(queue && queue->element.comp, 0);

    // comp
    return queue->element.comp(&queue->element, litem, ritem);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_circle_queue_ref_t tb_circle_queue_init(tb_size_t maxn, tb_element_t element)
{
    // check
    tb_assert_and_check_return_val(element.size && element.dupl && element.data, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_circle_queue_t*  queue = tb_null;
    do
    {
        // make queue
        queue = tb_malloc0_type(tb_circle_queue_t);
        tb_assert_and_check_break(queue);

        // using the default maxn
        if (!maxn) maxn = TB_CIRCLE_QUEUE_SIZE_DEFAULT;

        // init queue, + tail
        queue->maxn      = maxn + 1;
        queue->element   = element;

        // init operation
        static tb_iterator_op_t op = 
        {
            tb_circle_queue_itor_size
        ,   tb_circle_queue_itor_head
        ,   tb_circle_queue_itor_last
        ,   tb_circle_queue_itor_tail
        ,   tb_circle_queue_itor_prev
        ,   tb_circle_queue_itor_next
        ,   tb_circle_queue_itor_item
        ,   tb_circle_queue_itor_comp
        ,   tb_circle_queue_itor_copy
        ,   tb_null
        ,   tb_null
        };

        // init iterator
        queue->itor.priv = tb_null;
        queue->itor.step = element.size;
        queue->itor.mode = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_MUTABLE;
        queue->itor.op   = &op;

        // make data
        queue->data = (tb_byte_t*)tb_nalloc0(queue->maxn, element.size);
        tb_assert_and_check_break(queue->data);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        if (queue) tb_circle_queue_exit((tb_circle_queue_ref_t)queue);
        queue = tb_null;
    }

    // ok?
    return (tb_circle_queue_ref_t)queue;
}
tb_void_t tb_circle_queue_exit(tb_circle_queue_ref_t self)
{   
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return(queue);
    
    // clear data
    tb_circle_queue_clear(self);

    // free data
    if (queue->data) tb_free(queue->data);

    // free it
    tb_free(queue);
}
tb_void_t tb_circle_queue_clear(tb_circle_queue_ref_t self)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return(queue);
    
    // clear it
    while (!tb_circle_queue_null(self)) tb_circle_queue_pop(self);
    queue->head = 0;
    queue->tail = 0;
    queue->size = 0;
}
tb_void_t tb_circle_queue_put(tb_circle_queue_ref_t self, tb_cpointer_t data)
{   
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return(queue && queue->size < queue->maxn);

    // put it
    queue->element.dupl(&queue->element, queue->data + queue->tail * queue->element.size, data);
    queue->tail = (queue->tail + 1) % queue->maxn;
    queue->size++;
}
tb_void_t tb_circle_queue_pop(tb_circle_queue_ref_t self)
{   
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return(queue && queue->size);

    // pop it
    if (queue->element.free) queue->element.free(&queue->element, queue->data + queue->head * queue->element.size);
    queue->head = (queue->head + 1) % queue->maxn;
    queue->size--;
}
tb_pointer_t tb_circle_queue_get(tb_circle_queue_ref_t self)
{
    // get the head item
    return tb_circle_queue_head(self);
}
tb_pointer_t tb_circle_queue_head(tb_circle_queue_ref_t self)
{
    // the head item
    return tb_iterator_item((tb_iterator_ref_t)self, tb_iterator_head((tb_iterator_ref_t)self));
}
tb_pointer_t tb_circle_queue_last(tb_circle_queue_ref_t self)
{
    // the last item
    return tb_iterator_item((tb_iterator_ref_t)self, tb_iterator_last((tb_iterator_ref_t)self));
}
tb_size_t tb_circle_queue_size(tb_circle_queue_ref_t self)
{   
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return_val(queue, 0);

    // the size
    return queue->size;
}
tb_size_t tb_circle_queue_maxn(tb_circle_queue_ref_t self)
{   
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return_val(queue, 0);

    // the maxn
    return queue->maxn;
}
tb_bool_t tb_circle_queue_full(tb_circle_queue_ref_t self)
{   
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return_val(queue, tb_true);

    // is full?
    return (queue->size + 1) == queue->maxn;
}
tb_bool_t tb_circle_queue_null(tb_circle_queue_ref_t self)
{   
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return_val(queue, tb_true);

    // is null?
    return !queue->size;
}
#ifdef __tb_debug__
tb_void_t tb_circle_queue_dump(tb_circle_queue_ref_t self)
{
    // check
    tb_circle_queue_t* queue = (tb_circle_queue_t*)self;
    tb_assert_and_check_return(queue);

    // trace
    tb_trace_i("self: size: %lu", tb_circle_queue_size(self));

    // done
    tb_char_t cstr[4096];
    tb_for_all (tb_pointer_t, data, self)
    {
        // trace
        if (queue->element.cstr) 
        {
            tb_trace_i("    %s", queue->element.cstr(&queue->element, data, cstr, sizeof(cstr)));
        }
        else
        {
            tb_trace_i("    %p", data);
        }
    }
}
#endif
