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
 * @file        channel.h
 * @ingroup     coroutine
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "channel"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "channel.h"
#include "coroutine.h"
#include "scheduler.h"
#include "impl/impl.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/* the channel queue type
 *
 * we do not use tb_circle_queue_t because it is too heavy
 */
typedef struct __tb_co_channel_queue_t
{
    // the data
    tb_cpointer_t*                  data;
    
    // the head
    tb_size_t                       head;

    // the tail
    tb_size_t                       tail;

    // the maxn
    tb_size_t                       maxn;

    // the size
    tb_size_t                       size;

}tb_co_channel_queue_t;

// the coroutine channel type
typedef struct __tb_co_channel_t
{
    // the queue
    tb_co_channel_queue_t           queue;

    // the free function
    tb_co_channel_free_func_t       free;

    // the user private data
    tb_cpointer_t                   priv;

    // the waiting send coroutines 
    tb_single_list_entry_head_t     waiting_send;

    // the waiting recv coroutines 
    tb_single_list_entry_head_t     waiting_recv;

}tb_co_channel_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t tb_co_channel_send_resume(tb_co_channel_t* channel, tb_pointer_t* pdata)
{
    // check
    tb_assert(channel);

    // resume the first waiting send coroutine and recv data
    tb_bool_t ok = tb_false;
    if (tb_single_list_entry_size(&channel->waiting_send))
    {
        // get the next entry from head
        tb_single_list_entry_ref_t entry = tb_single_list_entry_head(&channel->waiting_send);
        tb_assert(entry);

        // remove it from the waiting send coroutines
        tb_single_list_entry_remove_head(&channel->waiting_send);

        // get the waiting send coroutine
        tb_coroutine_ref_t waiting = (tb_coroutine_ref_t)tb_single_list_entry(&channel->waiting_send, entry);

        // resume this coroutine and recv data
        tb_pointer_t data = tb_coroutine_resume(waiting, tb_null);

        // save data
        if (pdata) *pdata = data;

        // ok
        ok = tb_true;
    }

    // ok?
    return ok;
}
static tb_void_t tb_co_channel_recv_resume(tb_co_channel_t* channel)
{
    // check
    tb_assert(channel);

    // resume the first waiting recv coroutine 
    if (tb_single_list_entry_size(&channel->waiting_recv))
    {
        // get the next entry from head
        tb_single_list_entry_ref_t entry = tb_single_list_entry_head(&channel->waiting_recv);
        tb_assert(entry);

        // remove it from the waiting recv coroutines
        tb_single_list_entry_remove_head(&channel->waiting_recv);

        // get the waiting recv coroutine
        tb_coroutine_ref_t waiting = (tb_coroutine_ref_t)tb_single_list_entry(&channel->waiting_recv, entry);

        // resume this coroutine 
        tb_coroutine_resume(waiting, tb_null);
    }
}
static tb_void_t tb_co_channel_send_suspend(tb_co_channel_t* channel, tb_cpointer_t data)
{
    // check
    tb_assert(channel);

    // get the running coroutine 
    tb_coroutine_t* running = (tb_coroutine_t*)tb_coroutine_self();
    tb_assert(running);

    // save this coroutine to the waiting send coroutines
    tb_single_list_entry_insert_tail(&channel->waiting_send, &running->rs.single_entry);

    // send data and wait it
    tb_coroutine_suspend(data);
}
static tb_void_t tb_co_channel_recv_suspend(tb_co_channel_t* channel)
{
    // check
    tb_assert(channel);

    // get the running coroutine 
    tb_coroutine_t* running = (tb_coroutine_t*)tb_coroutine_self();
    tb_assert(running);

    // save this coroutine to the waiting recv coroutines
    tb_single_list_entry_insert_tail(&channel->waiting_recv, &running->rs.single_entry);

    // wait data
    tb_coroutine_suspend(tb_null);
}
static tb_void_t tb_co_channel_send_buffer(tb_co_channel_t* channel, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(channel && channel->queue.data);

    // done
    do
    {
        // put data into queue if be not full
        if (channel->queue.size + 1 < channel->queue.maxn)
        {
            // trace
            tb_trace_d("send[%p]: put data(%p)", tb_coroutine_self(), data);

            // put data
            channel->queue.data[channel->queue.tail] = data;
            channel->queue.tail = (channel->queue.tail + 1) % channel->queue.maxn;
            channel->queue.size++;

            // notify to recv data
            tb_co_channel_recv_resume(channel);

            // send ok
            break;
        }
        // wait it if be full
        else
        {
            // trace
            tb_trace_d("send[%p]: wait ..", tb_coroutine_self());

            // wait send
            tb_co_channel_send_suspend(channel, tb_null);
 
            // trace
            tb_trace_d("send[%p]: wait ok", tb_coroutine_self());
        }

    } while (1);
 
    // trace
    tb_trace_d("send[%p]: ok", tb_coroutine_self());
}
static tb_pointer_t tb_co_channel_recv_buffer(tb_co_channel_t* channel)
{
    // check
    tb_assert_and_check_return_val(channel && channel->queue.data, tb_null);

    // done
    tb_pointer_t data = tb_null;
    do
    {
        // recv data from channel if be not null
        if (channel->queue.size)
        {
            // get data
            data = (tb_pointer_t)channel->queue.data[channel->queue.head];

            // pop data
            channel->queue.head = (channel->queue.head + 1) % channel->queue.maxn;
            channel->queue.size--;

            // trace
            tb_trace_d("recv[%p]: get data(%p)", tb_coroutine_self(), data);

            // notify to send data
            tb_co_channel_send_resume(channel, tb_null);

            // recv ok
            break;
        }
        // wait it if be null
        else
        {
            // trace
            tb_trace_d("recv[%p]: wait ..", tb_coroutine_self());

            // wait recv
            tb_co_channel_recv_suspend(channel);

            // trace
            tb_trace_d("recv[%p]: wait ok", tb_coroutine_self());
        }

    } while (1);
 
    // trace
    tb_trace_d("recv[%p]: ok", tb_coroutine_self());

    // get data
    return data;
}
static tb_bool_t tb_co_channel_send_buffer_try(tb_co_channel_t* channel, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return_val(channel && channel->queue.data, tb_false);

    // put data into queue if be not full
    if (channel->queue.size + 1 < channel->queue.maxn)
    {
        // trace
        tb_trace_d("send[%p]: put data(%p)", tb_coroutine_self(), data);

        // put data
        channel->queue.data[channel->queue.tail] = data;
        channel->queue.tail = (channel->queue.tail + 1) % channel->queue.maxn;
        channel->queue.size++;

        // notify to recv data
        tb_co_channel_recv_resume(channel);

        // send ok
        return tb_true;
    }

    // failed
    return tb_false;
}
static tb_bool_t tb_co_channel_recv_buffer_try(tb_co_channel_t* channel, tb_pointer_t* pdata)
{
    // check
    tb_assert_and_check_return_val(channel && channel->queue.data && pdata, tb_false);

    // recv data from channel if be not null
    if (channel->queue.size)
    {
        // get data
        *pdata = (tb_pointer_t)channel->queue.data[channel->queue.head];

        // pop data
        channel->queue.head = (channel->queue.head + 1) % channel->queue.maxn;
        channel->queue.size--;

        // trace
        tb_trace_d("recv[%p]: get data(%p)", tb_coroutine_self(), *pdata);

        // notify to send data
        tb_co_channel_send_resume(channel, tb_null);

        // recv ok
        return tb_true;
    }

    // failed
    return tb_false;
}
static tb_void_t tb_co_channel_send_buffer0(tb_co_channel_t* channel, tb_cpointer_t data)
{
    // check
    tb_assert(channel);

    // resume one waiting recv coroutine 
    tb_co_channel_recv_resume(channel);

    // send data and wait it
    tb_co_channel_send_suspend(channel, data);
}
static tb_pointer_t tb_co_channel_recv_buffer0(tb_co_channel_t* channel)
{
    // check
    tb_assert(channel);

    // done
    tb_pointer_t data = tb_null;
    do
    {
        // resume the first waiting send coroutine and recv data
        if (tb_co_channel_send_resume(channel, &data))
        {
            // recv ok
            break;
        }
        // no data?
        else
        {
            // wait data
            tb_co_channel_recv_suspend(channel);
        }

    } while (1);

    // ok?
    return data;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_co_channel_ref_t tb_co_channel_init(tb_size_t size, tb_co_channel_free_func_t free, tb_cpointer_t priv)
{
    // done
    tb_bool_t           ok = tb_false;
    tb_co_channel_t*    channel = tb_null;
    do
    {
        // make channel
        channel = tb_malloc0_type(tb_co_channel_t);
        tb_assert_and_check_break(channel);

        // init waiting send coroutines
        tb_single_list_entry_init(&channel->waiting_send, tb_coroutine_t, rs.single_entry, tb_null);

        // init waiting recv coroutines
        tb_single_list_entry_init(&channel->waiting_recv, tb_coroutine_t, rs.single_entry, tb_null);

        // init free function and data
        channel->free = free;
        channel->priv = priv;

        // with buffer?
        if (size)
        {
            // init maxn, + tail
            channel->queue.maxn = size + 1;

            // make data
            channel->queue.data = tb_nalloc_type(channel->queue.maxn, tb_cpointer_t);
            tb_assert_and_check_break(channel->queue.data);
        }

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (channel) tb_co_channel_exit((tb_co_channel_ref_t)channel);
        channel = tb_null;
    }

    // ok?
    return (tb_co_channel_ref_t)channel;
}
tb_void_t tb_co_channel_exit(tb_co_channel_ref_t self)
{
    // check
    tb_co_channel_t* channel = (tb_co_channel_t*)self;
    tb_assert_and_check_return(channel);

    // exit queue
    if (channel->queue.data)
    {
        // free data
        if (channel->free)
        {
            tb_size_t head = channel->queue.head;
            tb_size_t maxn = channel->queue.maxn;
            tb_size_t size = channel->queue.size;
            while (size--)
            {
                channel->free((tb_pointer_t)channel->queue.data[head], channel->priv);
                head = (head + 1) % maxn;
            }
        }

        // free it
        tb_free(channel->queue.data);
    }
    channel->queue.data = tb_null;
    channel->queue.size = 0;

    // check waiting coroutines
    tb_assert(!tb_single_list_entry_size(&channel->waiting_send));
    tb_assert(!tb_single_list_entry_size(&channel->waiting_recv));

    // exit waiting coroutines
    tb_single_list_entry_exit(&channel->waiting_send);
    tb_single_list_entry_exit(&channel->waiting_recv);

    // exit the channel
    tb_free(channel);
}
tb_void_t tb_co_channel_send(tb_co_channel_ref_t self, tb_cpointer_t data)
{
    // check
    tb_co_channel_t* channel = (tb_co_channel_t*)self;
    tb_assert_and_check_return(channel);

    // send it
    if (channel->queue.data) tb_co_channel_send_buffer(channel, data);
    else tb_co_channel_send_buffer0(channel, data);
}
tb_pointer_t tb_co_channel_recv(tb_co_channel_ref_t self)
{
    // check
    tb_co_channel_t* channel = (tb_co_channel_t*)self;
    tb_assert_and_check_return_val(channel, tb_null);

    // recv it
    return channel->queue.data? tb_co_channel_recv_buffer(channel) : tb_co_channel_recv_buffer0(channel);
}
tb_bool_t tb_co_channel_send_try(tb_co_channel_ref_t self, tb_cpointer_t data)
{
    // check
    tb_co_channel_t* channel = (tb_co_channel_t*)self;
    tb_assert_and_check_return_val(channel, tb_false);

    // try sending it
    return channel->queue.data? tb_co_channel_send_buffer_try(channel, data) : tb_false;
}
tb_bool_t tb_co_channel_recv_try(tb_co_channel_ref_t self, tb_pointer_t* pdata)
{
    // check
    tb_co_channel_t* channel = (tb_co_channel_t*)self;
    tb_assert_and_check_return_val(channel && pdata, tb_false);

    // try recving it
    return channel->queue.data? tb_co_channel_recv_buffer_try(channel, pdata) : tb_false;
}

