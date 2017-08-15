/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        filter.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "async_stream_filter"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the filter stream type
typedef struct __tb_async_stream_filter_impl_t
{
    // the filter 
    tb_filter_ref_t                     filter;

    // the filter is referenced? need not exit it
    tb_uint32_t                         bref    : 1;

    // is reading now?
    tb_uint32_t                         bread   : 1;

    // the stream
    tb_async_stream_ref_t               stream;

    // the read size
    tb_size_t                           size;

    // the offset
    tb_atomic64_t                       offset;

    // is closing for sync
    tb_bool_t                           bclosing;

    // the func
    union
    {
        tb_async_stream_open_func_t     open;
        tb_async_stream_read_func_t     read;
        tb_async_stream_writ_func_t     writ;
        tb_async_stream_sync_func_t     sync;
        tb_async_stream_task_func_t     task;
        tb_async_stream_clos_func_t     clos;

    }                                   func;

    // the priv
    tb_cpointer_t                       priv;

}tb_async_stream_filter_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_async_stream_filter_impl_t* tb_async_stream_filter_impl_cast(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_async_stream_type(stream) == TB_STREAM_TYPE_FLTR, tb_null);

    // ok?
    return (tb_async_stream_filter_impl_t*)stream;
}
static tb_void_t tb_async_stream_filter_impl_clos_clear(tb_async_stream_filter_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl);

    // clos the filter
    if (impl->filter) tb_filter_clos(impl->filter);

    // clear the mode
    impl->bread = 0;

    // clear the offset
    tb_atomic64_set0(&impl->offset);

    // clear base
    tb_async_stream_clear((tb_async_stream_ref_t)impl);
}
static tb_void_t tb_async_stream_filter_impl_clos_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast((tb_async_stream_ref_t)priv);
    tb_assert_and_check_return(impl && impl->func.clos);

    // trace
    tb_trace_d("clos: notify: ..");

    // clear it
    tb_async_stream_filter_impl_clos_clear(impl);

    /* done clos func
     *
     * note: cannot use this stream after closing, the stream may be exited in the closing func
     */
    impl->func.clos((tb_async_stream_ref_t)impl, TB_STATE_OK, impl->priv);

    // trace
    tb_trace_d("clos: notify: ok");
}
static tb_bool_t tb_async_stream_filter_impl_clos_try(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // try closing ok?
    if (!impl->stream || tb_async_stream_clos_try(impl->stream))
    {
        // clear it
        tb_async_stream_filter_impl_clos_clear(impl);

        // ok
        return tb_true;
    }

    // failed
    return tb_false;
}
static tb_bool_t tb_async_stream_filter_impl_clos(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv)
{   
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);

    // trace
    tb_trace_d("clos: ..");

    // init clos
    impl->func.clos  = func;
    impl->priv       = priv;

    // close it
    return tb_async_stream_clos(impl->stream, tb_async_stream_filter_impl_clos_func, impl);
}
static tb_bool_t tb_async_stream_filter_impl_open_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(stream, tb_false);

    // the stream
    tb_async_stream_filter_impl_t* impl = (tb_async_stream_filter_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.open, tb_false);

    // trace
    tb_trace_d("open: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // open done
    return tb_async_stream_open_func((tb_async_stream_ref_t)impl, state, impl->func.open, impl->priv);
}
static tb_bool_t tb_async_stream_filter_impl_open_try(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->stream, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // clear the mode
        impl->bread = 0;

        // clear the offset
        tb_atomic64_set0(&impl->offset);

        // open filter first
        if (impl->filter && !tb_filter_open(impl->filter)) break;

        // try opening stream
        if (!tb_async_stream_open_try(impl->stream)) break;

        // open done
        tb_async_stream_open_done(stream);

        // ok
        ok = tb_true;

    } while (0);

    // failed? clear it
    if (!ok) tb_async_stream_filter_impl_clos_clear(impl);

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_filter_impl_open(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);

    // clear the mode
    impl->bread = 0;

    // clear the offset
    tb_atomic64_set0(&impl->offset);

    // open filter first
    if (impl->filter && !tb_filter_open(impl->filter)) 
    {
        // open done
        return tb_async_stream_open_func(stream, TB_STATE_FAILED, func, priv);
    }

    // init func and priv
    impl->priv       = priv;
    impl->func.open  = func;

    // post open
    return tb_async_stream_open(impl->stream, tb_async_stream_filter_impl_open_func, stream);
}
static tb_bool_t tb_async_stream_filter_impl_sync_read_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(stream, tb_false);

    // the stream
    tb_async_stream_filter_impl_t* impl = (tb_async_stream_filter_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.read, tb_false);

    // trace
    tb_trace_d("sync_read: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // killed or failed?
    if (state != TB_STATE_OK && state != TB_STATE_CLOSED)
    {
        // done func
        impl->func.read((tb_async_stream_ref_t)impl, state, tb_null, 0, impl->size, impl->priv);

        // break it
        return tb_false;
    }

    // spak the filter
    tb_byte_t const*    data = tb_null;
    tb_long_t           spak = tb_filter_spak(impl->filter, tb_null, 0, &data, impl->size, -1);
    
    // has output data?
    tb_bool_t ok = tb_false;
    if (spak > 0 && data)
    {   
        // save offset
        tb_atomic64_fetch_and_add(&impl->offset, spak);

        // done data
        ok = impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_OK, data, spak, impl->size, impl->priv);
    }
    // closed?
    else
    {
        // done closed
        impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_CLOSED, tb_null, 0, impl->size, impl->priv);

        // break it
        // ok = tb_false;
    }

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_filter_impl_read_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(stream, tb_false);

    // the stream
    tb_async_stream_filter_impl_t* impl = (tb_async_stream_filter_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.read, tb_false);

    // trace
    tb_trace_d("read: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // done filter
    tb_bool_t ok = tb_false;
    if (impl->filter)
    {
        // done filter
        switch (state)
        {
        case TB_STATE_OK:
            {
                // spak the filter
                tb_long_t spak = tb_filter_spak(impl->filter, data, real, &data, size, 0);
                
                // has output data?
                if (spak > 0 && data)
                {
                    // save offset
                    tb_atomic64_fetch_and_add(&impl->offset, spak);

                    // done data
                    ok = impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_OK, data, spak, size, impl->priv);
                }
                // no data? continue it
                else if (!spak) ok = tb_true;
                // closed?
                else
                {
                    // done closed
                    impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_CLOSED, tb_null, 0, size, impl->priv);

                    // break it
                    // ok = tb_false;
                }

                // eof and continue?
                if (tb_filter_beof(impl->filter) && ok)
                {
                    // done sync for reading
                    ok = tb_async_stream_task(impl->stream, 0, tb_async_stream_filter_impl_sync_read_func, impl);
                    
                    // error? done error
                    if (!ok) impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_UNKNOWN_ERROR, tb_null, 0, size, impl->priv);

                    // need not read data, break it
                    ok = tb_false;
                }
            }
            break;
        case TB_STATE_CLOSED:
            {
                // done sync for reading
                ok = tb_async_stream_task(impl->stream, 0, tb_async_stream_filter_impl_sync_read_func, impl);
                
                // error? done error
                if (!ok) impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_UNKNOWN_ERROR, tb_null, 0, size, impl->priv);
            }
            break;
        default:
            {
                // done closed or failed
                impl->func.read((tb_async_stream_ref_t)impl, state, tb_null, 0, size, impl->priv);

                // break it
                // ok = tb_false;
            }
            break;
        }
    }
    // done func
    else ok = impl->func.read((tb_async_stream_ref_t)impl, state, data, real, size, impl->priv);
 
    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_filter_impl_read(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);

    // clear the offset if be writ mode now
    if (!impl->bread) tb_atomic64_set0(&impl->offset);

    // set read mode
    impl->bread = 1;

    // save func and priv
    impl->priv       = priv;
    impl->func.read  = func;
    impl->size       = size;

    // filter eof? flush the left data
    if (impl->filter && tb_filter_beof(impl->filter))
        return tb_async_stream_task(impl->stream, 0, tb_async_stream_filter_impl_sync_read_func, impl);

    // post read
    return tb_async_stream_read_after(impl->stream, delay, size, tb_async_stream_filter_impl_read_func, stream);
}
static tb_bool_t tb_async_stream_filter_impl_writ_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(stream, tb_false);

    // the stream
    tb_async_stream_filter_impl_t* impl = (tb_async_stream_filter_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.writ, tb_false);

    // trace
    tb_trace_d("writ: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // save offset
    if (real) tb_atomic64_fetch_and_add(&impl->offset, real);

    // done func
    return impl->func.writ((tb_async_stream_ref_t)impl, state, data, real, size, impl->priv);
}
static tb_bool_t tb_async_stream_filter_impl_writ(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->stream && data && size && func, tb_false);

    // clear the offset if be read mode now
    if (impl->bread) tb_atomic64_set0(&impl->offset);

    // set writ mode
    impl->bread = 0;

    // save func and priv
    impl->priv       = priv;
    impl->func.writ  = func;

    // done filter
    tb_bool_t ok = tb_true;
    if (impl->filter)
    {
        // spak the filter
        tb_long_t real = tb_filter_spak(impl->filter, data, size, &data, size, 0);
        
        // has data? 
        if (real > 0 && data)
        {
            // post writ
            ok = tb_async_stream_writ_after(impl->stream, delay, data, real, tb_async_stream_filter_impl_writ_func, stream);
        }
        // no data or end? continue to writ or sync
        else
        {
            // done func, no data and finished
            ok = func((tb_async_stream_ref_t)impl, TB_STATE_OK, tb_null, 0, 0, impl->priv);
        }
    }
    // post writ
    else ok = tb_async_stream_writ_after(impl->stream, delay, data, size, tb_async_stream_filter_impl_writ_func, stream);

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_filter_impl_sync_func(tb_async_stream_ref_t stream, tb_size_t state, tb_bool_t bclosing, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(stream, tb_false);

    // the stream
    tb_async_stream_filter_impl_t* impl = (tb_async_stream_filter_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.sync, tb_false);

    // trace
    tb_trace_d("sync: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // done func
    return impl->func.sync((tb_async_stream_ref_t)impl, state, bclosing, impl->priv);
}
static tb_bool_t tb_async_stream_filter_impl_writ_sync_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(stream && data && size, tb_false);

    // the stream
    tb_async_stream_filter_impl_t* impl = (tb_async_stream_filter_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.sync, tb_false);

    // trace
    tb_trace_d("writ_sync: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // save offset
    if (real) tb_atomic64_fetch_and_add(&impl->offset, real);

    // not finished? continue it
    tb_bool_t ok = tb_false;
    if (state == TB_STATE_OK && real < size) ok = tb_true;
    // ok? sync it
    else if (state == TB_STATE_OK && real == size)
    {
        // post sync
        ok = tb_async_stream_sync(impl->stream, impl->bclosing, tb_async_stream_filter_impl_sync_func, impl);

        // failed? done func
        if (!ok) ok = impl->func.sync((tb_async_stream_ref_t)impl, TB_STATE_UNKNOWN_ERROR, impl->bclosing, impl->priv);
    }
    // failed?
    else
    {
        // failed? done func
        ok = impl->func.sync((tb_async_stream_ref_t)impl, state != TB_STATE_OK? state : TB_STATE_UNKNOWN_ERROR, impl->bclosing, impl->priv);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_filter_impl_sync(tb_async_stream_ref_t stream, tb_bool_t bclosing, tb_async_stream_sync_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);

    // clear the offset if be read mode now
    if (impl->bread) tb_atomic64_set0(&impl->offset);
 
    // set writ mode
    impl->bread = 0;

    // save func and priv
    impl->priv       = priv;
    impl->func.sync  = func;
    impl->bclosing   = bclosing;

    // done filter
    tb_bool_t ok = tb_true;
    if (impl->filter)
    {
        // trace
        tb_trace_d("sync: spak: %s", tb_url_cstr(tb_async_stream_url(stream)));

        // spak the filter
        tb_byte_t const*    data = tb_null;
        tb_long_t           real = tb_filter_spak(impl->filter, tb_null, 0, &data, 0, bclosing? -1 : 1);
        
        // has data? post writ and sync
        if (real > 0 && data)
            ok = tb_async_stream_writ(impl->stream, data, real, tb_async_stream_filter_impl_writ_sync_func, stream);
    }
    // post sync
    else ok = tb_async_stream_sync(impl->stream, bclosing, tb_async_stream_filter_impl_sync_func, stream);

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_filter_impl_task_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(stream, tb_false);

    // the stream
    tb_async_stream_filter_impl_t* impl = (tb_async_stream_filter_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.task, tb_false);

    // done func
    return impl->func.task((tb_async_stream_ref_t)impl, state, impl->priv);
}
static tb_bool_t tb_async_stream_filter_impl_task(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);

    // save func and priv
    impl->priv       = priv;
    impl->func.task  = func;

    // post task
    return tb_async_stream_task(impl->stream, delay, tb_async_stream_filter_impl_task_func, stream);
}
static tb_void_t tb_async_stream_filter_impl_kill(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return(impl);

    // kill stream
    if (impl->stream) tb_async_stream_kill(impl->stream);
}
static tb_bool_t tb_async_stream_filter_impl_exit(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // exit it
    if (!impl->bref && impl->filter) tb_filter_exit(impl->filter);
    impl->filter = tb_null;
    impl->bref = 0;

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_filter_impl_ctrl(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_async_stream_filter_impl_t* impl = tb_async_stream_filter_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_STREAM_CTRL_GET_OFFSET:
        {
            // check
            tb_assert_and_check_break(tb_async_stream_is_opened(stream));

            // the poffset
            tb_hize_t* poffset = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_break(poffset);

            // get offset
            *poffset = (tb_hize_t)tb_atomic64_get(&impl->offset);

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FLTR_SET_STREAM:
        {
            // check
            tb_assert_and_check_break(tb_async_stream_is_closed(stream));

            // set pstream
            impl->stream = (tb_async_stream_ref_t)tb_va_arg(args, tb_async_stream_ref_t);

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FLTR_GET_STREAM:
        {
            // the pstream
            tb_async_stream_ref_t* pstream = (tb_async_stream_ref_t*)tb_va_arg(args, tb_async_stream_ref_t*);
            tb_assert_and_check_break(pstream);

            // get stream
            *pstream = impl->stream;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FLTR_SET_FILTER:
        {
            // check
            tb_assert_and_check_break(tb_async_stream_is_closed(stream));

            // exit filter first if exists
            if (!impl->bref && impl->filter) tb_filter_exit(impl->filter);

            // set filter
            tb_filter_ref_t filter = (tb_filter_ref_t)tb_va_arg(args, tb_filter_ref_t);
            impl->filter = filter;
            impl->bref = filter? 1 : 0;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FLTR_GET_FILTER:
        {
            // the pfilter
            tb_filter_ref_t* pfilter = (tb_filter_ref_t*)tb_va_arg(args, tb_filter_ref_t*);
            tb_assert_and_check_break(pfilter);

            // get filter
            *pfilter = impl->filter;

            // ok
            return tb_true;
        }
    default:
        break;
    }

    // failed
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_async_stream_ref_t tb_async_stream_init_filter(tb_aicp_ref_t aicp)
{
    return tb_async_stream_init(    aicp
                                ,   TB_STREAM_TYPE_FLTR
                                ,   sizeof(tb_async_stream_filter_impl_t)
                                ,   0
                                ,   0
                                ,   tb_async_stream_filter_impl_open_try
                                ,   tb_async_stream_filter_impl_clos_try
                                ,   tb_async_stream_filter_impl_open
                                ,   tb_async_stream_filter_impl_clos
                                ,   tb_async_stream_filter_impl_exit
                                ,   tb_async_stream_filter_impl_kill
                                ,   tb_async_stream_filter_impl_ctrl
                                ,   tb_async_stream_filter_impl_read
                                ,   tb_async_stream_filter_impl_writ
                                ,   tb_null
                                ,   tb_async_stream_filter_impl_sync
                                ,   tb_async_stream_filter_impl_task);
}
tb_async_stream_ref_t tb_async_stream_init_filter_from_null(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // the aicp
    tb_aicp_ref_t aicp = tb_async_stream_aicp(stream);
    tb_assert_and_check_return_val(aicp, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_async_stream_ref_t  impl = tb_null;
    do
    {
        // init stream
        impl = tb_async_stream_init_filter(aicp);
        tb_assert_and_check_break(impl);

        // set stream
        if (!tb_async_stream_ctrl(impl, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // check
        tb_assert_static(!(tb_offsetof(tb_async_stream_filter_impl_t, offset) & (sizeof(tb_atomic64_t) - 1)));

        // ok 
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_async_stream_exit((tb_async_stream_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return impl;
}
#ifdef TB_CONFIG_MODULE_HAVE_ZIP
tb_async_stream_ref_t tb_async_stream_init_filter_from_zip(tb_async_stream_ref_t stream, tb_size_t algo, tb_size_t action)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // the aicp
    tb_aicp_ref_t aicp = tb_async_stream_aicp(stream);
    tb_assert_and_check_return_val(aicp, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   impl = tb_null;
    do
    {
        // init stream
        impl = tb_async_stream_init_filter(aicp);
        tb_assert_and_check_break(impl);

        // set stream
        if (!tb_async_stream_ctrl(impl, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // set filter
        ((tb_async_stream_filter_impl_t*)impl)->bref = 0;
        ((tb_async_stream_filter_impl_t*)impl)->filter = tb_filter_init_from_zip(algo, action);
        tb_assert_and_check_break(((tb_async_stream_filter_impl_t*)impl)->filter);
        
        // ok 
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_async_stream_exit(impl);
        impl = tb_null;
    }

    // ok?
    return impl;
}
#endif
tb_async_stream_ref_t tb_async_stream_init_filter_from_cache(tb_async_stream_ref_t stream, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // the aicp
    tb_aicp_ref_t aicp = tb_async_stream_aicp(stream);
    tb_assert_and_check_return_val(aicp, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   impl = tb_null;
    do
    {
        // init stream
        impl = tb_async_stream_init_filter(aicp);
        tb_assert_and_check_break(impl);

        // set stream
        if (!tb_async_stream_ctrl(impl, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // set filter
        ((tb_async_stream_filter_impl_t*)impl)->bref = 0;
        ((tb_async_stream_filter_impl_t*)impl)->filter = tb_filter_init_from_cache(size);
        tb_assert_and_check_break(((tb_async_stream_filter_impl_t*)impl)->filter);
        
        // ok 
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_async_stream_exit(impl);
        impl = tb_null;
    }

    // ok?
    return impl;
}
#ifdef TB_CONFIG_MODULE_HAVE_CHARSET
tb_async_stream_ref_t tb_async_stream_init_filter_from_charset(tb_async_stream_ref_t stream, tb_size_t fr, tb_size_t to)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // the aicp
    tb_aicp_ref_t aicp = tb_async_stream_aicp(stream);
    tb_assert_and_check_return_val(aicp, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   impl = tb_null;
    do
    {
        // init stream
        impl = tb_async_stream_init_filter(aicp);
        tb_assert_and_check_break(impl);

        // set stream
        if (!tb_async_stream_ctrl(impl, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // set filter
        ((tb_async_stream_filter_impl_t*)impl)->bref = 0;
        ((tb_async_stream_filter_impl_t*)impl)->filter = tb_filter_init_from_charset(fr, to);
        tb_assert_and_check_break(((tb_async_stream_filter_impl_t*)impl)->filter);
        
        // ok 
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_async_stream_exit(impl);
        impl = tb_null;
    }

    // ok?
    return impl;
}
#endif
tb_async_stream_ref_t tb_async_stream_init_filter_from_chunked(tb_async_stream_ref_t stream, tb_bool_t dechunked)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // the aicp
    tb_aicp_ref_t aicp = tb_async_stream_aicp(stream);
    tb_assert_and_check_return_val(aicp, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   impl = tb_null;
    do
    {
        // init stream
        impl = tb_async_stream_init_filter(aicp);
        tb_assert_and_check_break(impl);

        // set stream
        if (!tb_async_stream_ctrl(impl, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // set filter
        ((tb_async_stream_filter_impl_t*)impl)->bref = 0;
        ((tb_async_stream_filter_impl_t*)impl)->filter = tb_filter_init_from_chunked(dechunked);
        tb_assert_and_check_break(((tb_async_stream_filter_impl_t*)impl)->filter);
        
        // ok 
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_async_stream_exit(impl);
        impl = tb_null;
    }

    // ok?
    return impl;
}
