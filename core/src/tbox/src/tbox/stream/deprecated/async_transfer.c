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
 * @file        async_transfer.c
 * @ingroup     stream
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "async_transfer"
#define TB_TRACE_MODULE_DEBUG               (1)
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../stream.h"
#include "async_transfer.h"
#include "../../network/network.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the async impl open type
typedef struct __tb_async_transfer_open_t_t
{
    // the func
    tb_async_transfer_open_func_t       func;

    // the priv
    tb_cpointer_t                       priv;

}tb_async_transfer_open_t_t;

// the async impl ctrl type
typedef struct __tb_async_transfer_ctrl_t_t
{
    // the func
    tb_async_transfer_ctrl_func_t       func;

    // the priv
    tb_cpointer_t                       priv;

}tb_async_transfer_ctrl_t_t;

// the async impl clos type
typedef struct __tb_async_transfer_clos_t_t
{
    // the func
    tb_async_transfer_clos_func_t       func;

    // the priv
    tb_cpointer_t                       priv;

}tb_async_transfer_clos_t_t;

// the async impl done type
typedef struct __tb_async_transfer_done_t_t
{
    // the func
    tb_async_transfer_done_func_t       func;

    // the priv
    tb_cpointer_t                       priv;

    // the base_time time
    tb_hong_t                           base_time;

    // the base_time time for 1s
    tb_hong_t                           base_time1s;

    // the saved_size size
    tb_hize_t                           saved_size;

    // the saved_size size for 1s
    tb_size_t                           saved_size1s;
 
    // the closed size
    tb_hong_t                           closed_size;

    // the closed state
    tb_size_t                           closed_state;

    // the closed offset 
    tb_hize_t                           closed_offset;

    // the current rate
    tb_size_t                           current_rate;

}tb_async_transfer_done_t_t;

// the async impl close opening type
typedef struct __tb_async_transfer_clos_opening_t_t
{
    // the func
    tb_async_transfer_open_func_t       func;

    // the priv
    tb_cpointer_t                       priv;

    // the open state
    tb_size_t                           state;

}tb_async_transfer_clos_opening_t_t;

// the async impl type
typedef struct __tb_async_transfer_impl_t
{
    // the aicp
    tb_aicp_ref_t                       aicp;

    // the istream
    tb_async_stream_ref_t               istream;

    // the ostream
    tb_async_stream_ref_t               ostream;

    // the istream is owner?
    tb_uint8_t                          iowner      : 1;

    // the ostream is owner?
    tb_uint8_t                          oowner      : 1;

    // auto closing it?
    tb_uint8_t                          autoclosing : 1;

    /* state
     *
     * TB_STATE_CLOSED
     * TB_STATE_OPENED
     * TB_STATE_OPENING
     * TB_STATE_KILLING
     */
    tb_atomic_t                         state;

    /* pause state
     *
     * TB_STATE_OK
     * TB_STATE_PAUSED
     * TB_STATE_PAUSING
     */
    tb_atomic_t                         state_pause;

    // the limited rate
    tb_atomic_t                         limited_rate;

    // the ctrl
    tb_async_transfer_ctrl_t_t          ctrl;

    // the open
    tb_async_transfer_open_t_t          open;

    // the clos
    tb_async_transfer_clos_t_t          clos;

    // the done
    tb_async_transfer_done_t_t          done;

    // the clos opening
    tb_async_transfer_clos_opening_t_t  clos_opening;

}tb_async_transfer_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_void_t tb_async_transfer_clos_func(tb_async_transfer_impl_t* impl, tb_size_t state)
{
    // check
    tb_assert_and_check_return(impl && impl->clos.func);
         
    // trace
    tb_trace_d("closed");

    // closed
    tb_atomic_set(&impl->state, TB_STATE_CLOSED);

    // clear pause state
    tb_atomic_set(&impl->state_pause, TB_STATE_OK);

    // done func
    impl->clos.func(state, impl->clos.priv);
}
static tb_void_t tb_async_transfer_clos_opening_func(tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return(impl && impl->clos_opening.func);

    // trace
    tb_trace_d("clos: opening");
 
    // done
    impl->clos_opening.func(impl->clos_opening.state, 0, 0, impl->clos_opening.priv);
}
static tb_bool_t tb_async_transfer_open_func(tb_async_transfer_impl_t* impl, tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_async_transfer_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(impl, tb_false);

    // ok?
    tb_bool_t ok = tb_true;
    if (state == TB_STATE_OK) 
    {
        // opened
        tb_atomic_set(&impl->state, TB_STATE_OPENED);

        // done func
        if (func) ok = func(state, offset, size, priv);
    }
    // failed? 
    else 
    {
        // init func and state
        impl->clos_opening.func   = func;
        impl->clos_opening.priv   = priv;
        impl->clos_opening.state  = state;

        // close it
        ok = tb_async_transfer_clos((tb_async_transfer_ref_t)impl, tb_async_transfer_clos_opening_func, impl);
    }

    // ok?
    return ok;
}
static tb_void_t tb_async_transfer_done_clos_func(tb_size_t state, tb_cpointer_t priv);
static tb_bool_t tb_async_transfer_done_func(tb_async_transfer_impl_t* impl, tb_size_t state)
{
    // check
    tb_assert_and_check_return_val(impl && impl->istream && impl->done.func, tb_false);

    // open failed? closed?
    if (TB_STATE_CLOSED == tb_atomic_get(&impl->state))
    {
        // done func 
        return impl->done.func(state, 0, 0, 0, 0, impl->done.priv);
    }

    // trace
    tb_trace_d("done: %llu bytes, rate: %lu bytes/s, state: %s", tb_async_stream_offset(impl->istream), impl->done.current_rate, tb_state_cstr(state));

    // auto closing it?
    if (impl->autoclosing)
    {
        // killed or failed or closed? close it
        if ((state != TB_STATE_OK && state != TB_STATE_PAUSED) || (TB_STATE_KILLING == tb_atomic_get(&impl->state))) 
        {
            // save the closed state
            impl->done.closed_state    = (TB_STATE_KILLING == tb_atomic_get(&impl->state))? TB_STATE_KILLED : state;
            impl->done.closed_size     = tb_async_stream_size(impl->istream);
            impl->done.closed_offset   = tb_async_stream_offset(impl->istream);
            return tb_async_transfer_clos((tb_async_transfer_ref_t)impl, tb_async_transfer_done_clos_func, impl);
        }
    }

    // done
    return impl->done.func(state, tb_async_stream_offset(impl->istream), tb_async_stream_size(impl->istream), impl->done.saved_size, impl->done.current_rate, impl->done.priv);
}
static tb_void_t tb_async_transfer_done_clos_func(tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return(impl && impl->done.func);

    // trace
    tb_trace_d("done: closed");
 
    // done
    impl->done.func(impl->done.closed_state, impl->done.closed_offset, impl->done.closed_size, impl->done.saved_size, impl->done.current_rate, impl->done.priv);
}
static tb_bool_t tb_async_transfer_open_done_func(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_cpointer_t priv)
{
    // the impl
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->done.func, tb_false);

    // trace
    tb_trace_d("open_done: offset: %llu, size: %lld, state: %s", offset, size, tb_state_cstr(state));

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
        
        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // done it
        if (!tb_async_transfer_done((tb_async_transfer_ref_t)impl, impl->done.func, impl->done.priv)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed? 
    if (state != TB_STATE_OK) 
    {   
        // done func for closing it
        ok = tb_async_transfer_done_func(impl, state);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_async_transfer_istream_read_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv);
static tb_bool_t tb_async_transfer_ostream_writ_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return_val(stream && impl && impl->aicp && impl->istream, tb_false);

    // trace
    tb_trace_d("writ: real: %lu, size: %lu, state: %s", real, size, tb_state_cstr(state));

    // the time
    tb_hong_t time = tb_aicp_time(impl->aicp);

    // done
    tb_bool_t bwrit = tb_false;
    do
    {
        // ok?
        tb_check_break(state == TB_STATE_OK);
            
        // reset state
        state = TB_STATE_UNKNOWN_ERROR;

        // done func at first once
        if (!impl->done.saved_size && !tb_async_transfer_done_func(impl, TB_STATE_OK)) break;

        // update saved size
        impl->done.saved_size += real;
    
        // < 1s?
        tb_size_t delay = 0;
        tb_size_t limited_rate = tb_atomic_get(&impl->limited_rate);
        if (time < impl->done.base_time1s + 1000)
        {
            // save size for 1s
            impl->done.saved_size1s += real;

            // save current rate if < 1s from base_time
            if (time < impl->done.base_time + 1000) impl->done.current_rate = impl->done.saved_size1s;
                    
            // compute the delay for limit rate
            if (limited_rate) delay = impl->done.saved_size1s >= limited_rate? (tb_size_t)(impl->done.base_time1s + 1000 - time) : 0;
        }
        else
        {
            // save current rate
            impl->done.current_rate = impl->done.saved_size1s;

            // update base_time1s
            impl->done.base_time1s = time;

            // reset size
            impl->done.saved_size1s = 0;

            // reset delay
            delay = 0;

            // done func
            if (!tb_async_transfer_done_func(impl, TB_STATE_OK)) break;
        }

        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // not finished? continue to writ
        tb_size_t state_pause = TB_STATE_OK;
        if (real < size) bwrit = tb_true;
        // pausing or paused?
        else if (   (TB_STATE_PAUSED == (state_pause = tb_atomic_fetch_and_pset(&impl->state_pause, TB_STATE_PAUSING, TB_STATE_PAUSED)))
                ||  (state_pause == TB_STATE_PAUSING))
        {
            // done func
            if (!tb_async_transfer_done_func(impl, TB_STATE_PAUSED)) break;
        }
        // continue?
        else 
        {
            // trace
            tb_trace_d("delay: %lu ms", delay);

            // continue to read it
            if (!tb_async_stream_read_after(impl->istream, delay, limited_rate, tb_async_transfer_istream_read_func, (tb_pointer_t)impl)) break;
        }

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed? 
    if (state != TB_STATE_OK) 
    {
        // compute the total rate
        impl->done.current_rate = (impl->done.saved_size && (time > impl->done.base_time))? (tb_size_t)((impl->done.saved_size * 1000) / (time - impl->done.base_time)) : (tb_size_t)impl->done.saved_size;

        // done func
        tb_async_transfer_done_func(impl, state);

        // break;
        bwrit = tb_false;
    }

    // continue to writ or break it
    return bwrit;
}
static tb_bool_t tb_async_transfer_ostream_sync_func(tb_async_stream_ref_t stream, tb_size_t state, tb_bool_t bclosing, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return_val(stream && impl && impl->aicp && impl->istream, tb_false);

    // trace
    tb_trace_d("sync: state: %s", tb_state_cstr(state));

    // the time
    tb_hong_t time = tb_aicp_time(impl->aicp);

    // compute the total rate
    impl->done.current_rate = (impl->done.saved_size && (time > impl->done.base_time))? (tb_size_t)((impl->done.saved_size * 1000) / (time - impl->done.base_time)) : (tb_size_t)impl->done.saved_size;

    // done func
    return tb_async_transfer_done_func(impl, state == TB_STATE_OK? TB_STATE_CLOSED : state);
}
static tb_bool_t tb_async_transfer_istream_read_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return_val(stream && impl && impl->aicp && impl->ostream, tb_false);

    // trace
    tb_trace_d("read: size: %lu, state: %s", real, tb_state_cstr(state));

    // done
    tb_bool_t bread = tb_false;
    do
    {
        // ok?
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;

        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // check
        tb_assert_and_check_break(data);

        // no data? continue it
        if (!real)
        {
            bread = tb_true;
            state = TB_STATE_OK;
            break;
        }

        // writ it
        if (!tb_async_stream_writ(impl->ostream, data, real, tb_async_transfer_ostream_writ_func, impl)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // closed or failed?
    if (state != TB_STATE_OK) 
    {
        // sync it if closed
        tb_bool_t bend = tb_true;
        if (state == TB_STATE_CLOSED)
            bend = tb_async_stream_sync(impl->ostream, tb_true, tb_async_transfer_ostream_sync_func, impl)? tb_false : tb_true;

        // end? 
        if (bend)
        {
            // the time
            tb_hong_t time = tb_aicp_time(impl->aicp);

            // compute the total rate
            impl->done.current_rate = (impl->done.saved_size && (time > impl->done.base_time))? (tb_size_t)((impl->done.saved_size * 1000) / (time - impl->done.base_time)) : (tb_size_t)impl->done.saved_size;

            // done func
            tb_async_transfer_done_func(impl, state);
        }

        // break
        bread = tb_false;
    }

    // continue to read or break it
    return bread;
}
static tb_bool_t tb_async_transfer_ostream_open_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return_val(stream && impl && impl->open.func, tb_false);

    // trace
    tb_trace_d("open: ostream: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok?
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;

        // check
        tb_assert_and_check_break(impl->istream);
 
        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // done func
        ok = tb_async_transfer_open_func(impl, TB_STATE_OK, tb_async_stream_offset(impl->istream), tb_async_stream_size(impl->istream), impl->open.func, impl->open.priv);

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        ok = tb_async_transfer_open_func(impl, state, 0, 0, impl->open.func, impl->open.priv);
    }

    // ok
    return ok;
}
static tb_bool_t tb_async_transfer_istream_open_func(tb_async_stream_ref_t stream, tb_size_t state, tb_hize_t offset, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return_val(stream && impl && impl->open.func, tb_false);

    // trace
    tb_trace_d("open: istream: %s, offset: %llu, state: %s", tb_url_cstr(tb_async_stream_url(stream)), offset, tb_state_cstr(state));

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok?
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
            
        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // open it
        if (!tb_async_stream_open(impl->ostream, tb_async_transfer_ostream_open_func, impl)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        ok = tb_async_transfer_open_func(impl, state, 0, 0, impl->open.func, impl->open.priv);
    }

    // ok?
    return ok;
}
static tb_void_t tb_async_transfer_ostream_clos_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return(stream && impl);

    // trace
    tb_trace_d("clos: ostream: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // done func
    tb_async_transfer_clos_func(impl, state);
}
static tb_void_t tb_async_transfer_istream_clos_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)priv;
    tb_assert_and_check_return(stream && impl);

    // trace
    tb_trace_d("clos: istream: %s, state: %s", tb_url_cstr(tb_async_stream_url(stream)), tb_state_cstr(state));

    // done
    do
    {
        // ok?
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
           
        // clos it
        if (!tb_async_stream_clos(impl->ostream, tb_async_transfer_ostream_clos_func, impl)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK) 
    {
        // trace
        tb_trace_e("clos: failed: %s", tb_state_cstr(state));

        // done func
        tb_async_transfer_clos_func(impl, state);
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_async_transfer_ref_t tb_async_transfer_init(tb_aicp_ref_t aicp, tb_bool_t autoclosing)
{
    // using the default aicp
    if (!aicp) aicp = tb_aicp();
    tb_assert_and_check_return_val(aicp, tb_null);

    // make impl
    tb_async_transfer_impl_t* impl = tb_malloc0_type(tb_async_transfer_impl_t);
    tb_assert_and_check_return_val(impl, tb_null);

    // init state
    impl->state         = TB_STATE_CLOSED;
    impl->state_pause   = TB_STATE_OK;
    impl->autoclosing   = autoclosing? 1 : 0;

    // init aicp
    impl->aicp          = aicp;

    // ok?
    return (tb_async_transfer_ref_t)impl;
}
tb_bool_t tb_async_transfer_init_istream(tb_async_transfer_ref_t transfer, tb_async_stream_ref_t stream)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl, tb_false);

    // muse be closed
    tb_assert_and_check_return_val(TB_STATE_CLOSED == tb_atomic_get(&impl->state), tb_false);

    // exit the previous stream first
    if (impl->istream && impl->istream != stream)
    {
        if (impl->iowner) tb_async_stream_exit(impl->istream);
        impl->istream = tb_null;
    }

    // init stream
    impl->istream   = stream;
    impl->iowner    = 0;

    // ok
    return tb_true;
}
tb_bool_t tb_async_transfer_init_istream_from_url(tb_async_transfer_ref_t transfer, tb_char_t const* url)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && impl->aicp && url, tb_false);

    // muse be closed
    tb_assert_and_check_return_val(TB_STATE_CLOSED == tb_atomic_get(&impl->state), tb_false);

    // check stream type
    if (impl->istream)
    {
        // probe protocol
        tb_size_t protocol = tb_url_protocol_probe(url);
        tb_assert_static((tb_size_t)TB_URL_PROTOCOL_FILE == (tb_size_t)TB_STREAM_TYPE_FILE);
        tb_assert_static((tb_size_t)TB_URL_PROTOCOL_HTTP == (tb_size_t)TB_STREAM_TYPE_HTTP);
        tb_assert_static((tb_size_t)TB_URL_PROTOCOL_SOCK == (tb_size_t)TB_STREAM_TYPE_SOCK);
        tb_assert_static((tb_size_t)TB_URL_PROTOCOL_DATA == (tb_size_t)TB_STREAM_TYPE_DATA);

        // protocol => type
        tb_size_t type = protocol;
        if (!type || type > TB_STREAM_TYPE_DATA)
        {
            tb_trace_e("unknown stream for url: %s", url);
            return tb_false;
        }

        // exit the previous stream first if be different stream type
        if (tb_async_stream_type(impl->istream) != type)
        {
            if (impl->iowner) tb_async_stream_exit(impl->istream);
            impl->istream = tb_null;
        }
    }

    // using the previous stream?
    if (impl->istream)
    {
        // ctrl stream
        if (!tb_async_stream_ctrl(impl->istream, TB_STREAM_CTRL_SET_URL, url)) return tb_false;
    }
    else 
    {
        // init stream
        impl->istream = tb_async_stream_init_from_url(impl->aicp, url);
        tb_assert_and_check_return_val(impl->istream, tb_false);

        // init owner
        impl->iowner = 1;
    }

    // ok
    return tb_true;
}
tb_bool_t tb_async_transfer_init_istream_from_data(tb_async_transfer_ref_t transfer, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // muse be closed
    tb_assert_and_check_return_val(TB_STATE_CLOSED == tb_atomic_get(&impl->state), tb_false);

    // exit the previous stream first if be not data stream
    if (impl->istream && tb_async_stream_type(impl->istream) != TB_STREAM_TYPE_DATA)
    {
        if (impl->iowner) tb_async_stream_exit(impl->istream);
        impl->istream = tb_null;
    }

    // using the previous stream?
    if (impl->istream)
    {
        // ctrl stream
        if (!tb_async_stream_ctrl(impl->istream, TB_STREAM_CTRL_DATA_SET_DATA, data, size)) return tb_false;
    }
    else 
    {
        // init stream
        impl->istream = tb_async_stream_init_from_data(impl->aicp, (tb_byte_t*)data, size);
        tb_assert_and_check_return_val(impl->istream, tb_false);

        // init owner
        impl->iowner = 1;
    }

    // ok
    return tb_true;
}
tb_bool_t tb_async_transfer_init_ostream(tb_async_transfer_ref_t transfer, tb_async_stream_ref_t stream)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl, tb_false);

    // muse be closed
    tb_assert_and_check_return_val(TB_STATE_CLOSED == tb_atomic_get(&impl->state), tb_false);

    // exit the previous stream first
    if (impl->ostream && impl->ostream != stream)
    {
        if (impl->oowner) tb_async_stream_exit(impl->ostream);
        impl->ostream = tb_null;
    }

    // init stream
    impl->ostream   = stream;
    impl->oowner    = 0;

    // ok
    return tb_true;
}
tb_bool_t tb_async_transfer_init_ostream_from_url(tb_async_transfer_ref_t transfer, tb_char_t const* url)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && impl->aicp && url, tb_false);

    // muse be closed
    tb_assert_and_check_return_val(TB_STATE_CLOSED == tb_atomic_get(&impl->state), tb_false);

    // check stream type
    if (impl->ostream)
    {
        // probe protocol
        tb_size_t protocol = tb_url_protocol_probe(url);
        tb_assert_static((tb_size_t)TB_URL_PROTOCOL_FILE == (tb_size_t)TB_STREAM_TYPE_FILE);
        tb_assert_static((tb_size_t)TB_URL_PROTOCOL_HTTP == (tb_size_t)TB_STREAM_TYPE_HTTP);
        tb_assert_static((tb_size_t)TB_URL_PROTOCOL_SOCK == (tb_size_t)TB_STREAM_TYPE_SOCK);
        tb_assert_static((tb_size_t)TB_URL_PROTOCOL_DATA == (tb_size_t)TB_STREAM_TYPE_DATA);

        // protocol => type
        tb_size_t type = protocol;
        if (!type || type > TB_STREAM_TYPE_DATA)
        {
            tb_trace_e("unknown stream for url: %s", url);
            return tb_false;
        }

        // exit the previous stream first if be different stream type
        if (tb_async_stream_type(impl->ostream) != type)
        {
            if (impl->oowner) tb_async_stream_exit(impl->ostream);
            impl->ostream = tb_null;
        }
    }

    // using the previous stream?
    if (impl->ostream)
    {
        // ctrl stream
        if (!tb_async_stream_ctrl(impl->ostream, TB_STREAM_CTRL_SET_URL, url)) return tb_false;
    }
    else 
    {
        // init stream
        impl->ostream = tb_async_stream_init_from_url(impl->aicp, url);
        tb_assert_and_check_return_val(impl->ostream, tb_false);

        // ctrl stream for file
        if (tb_async_stream_type(impl->ostream) == TB_STREAM_TYPE_FILE) 
        {
            // ctrl mode
            if (!tb_async_stream_ctrl(impl->ostream, TB_STREAM_CTRL_FILE_SET_MODE, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC)) return tb_false;
        }

        // init owner
        impl->oowner = 1;
    }

    // ok
    return tb_true;
}
tb_bool_t tb_async_transfer_init_ostream_from_data(tb_async_transfer_ref_t transfer, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // muse be closed
    tb_assert_and_check_return_val(TB_STATE_CLOSED == tb_atomic_get(&impl->state), tb_false);

    // exit the previous stream first if be not data stream
    if (impl->ostream && tb_async_stream_type(impl->ostream) != TB_STREAM_TYPE_DATA)
    {
        if (impl->oowner) tb_async_stream_exit(impl->ostream);
        impl->ostream = tb_null;
    }

    // using the previous stream?
    if (impl->ostream)
    {
        // ctrl stream
        if (!tb_async_stream_ctrl(impl->ostream, TB_STREAM_CTRL_DATA_SET_DATA, data, size)) return tb_false;
    }
    else 
    {
        // init stream
        impl->ostream = tb_async_stream_init_from_data(impl->aicp, data, size);
        tb_assert_and_check_return_val(impl->ostream, tb_false);

        // init owner
        impl->oowner = 1;
    }

    // ok
    return tb_true;
}
tb_bool_t tb_async_transfer_ctrl_istream(tb_async_transfer_ref_t transfer, tb_size_t ctrl, ...)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && impl->istream, tb_false);

    // init args
    tb_va_list_t args;
    tb_va_start(args, ctrl);

    // ctrl it
    tb_bool_t ok = tb_async_stream_ctrl_with_args(impl->istream, ctrl, args);

    // exit args
    tb_va_end(args);

    // ok?
    return ok;
}
tb_bool_t tb_async_transfer_ctrl_ostream(tb_async_transfer_ref_t transfer, tb_size_t ctrl, ...)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && impl->ostream, tb_false);

    // init args
    tb_va_list_t args;
    tb_va_start(args, ctrl);

    // ctrl it
    tb_bool_t ok = tb_async_stream_ctrl_with_args(impl->ostream, ctrl, args);

    // exit args
    tb_va_end(args);

    // ok?
    return ok;
}
tb_bool_t tb_async_transfer_open(tb_async_transfer_ref_t transfer, tb_hize_t offset, tb_async_transfer_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && impl->aicp && func, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // set opening
        tb_size_t state = tb_atomic_fetch_and_pset(&impl->state, TB_STATE_CLOSED, TB_STATE_OPENING);

        // opened? done func directly
        if (state == TB_STATE_OPENED)
        {
            // check
            tb_assert_and_check_break(impl->istream && impl->ostream);

            // done func
            func(TB_STATE_OK, tb_async_stream_offset(impl->istream), tb_async_stream_size(impl->istream), priv);

            // ok
            ok = tb_true;
            break;
        }

        // must be closed
        tb_assert_and_check_break(state == TB_STATE_CLOSED);

        // clear pause state
        tb_atomic_set(&impl->state_pause, TB_STATE_OK);

        // init func
        impl->open.func = func;
        impl->open.priv = priv;

        // check
        tb_assert_and_check_break(impl->istream);
        tb_assert_and_check_break(impl->ostream);

        // init some rate info
        impl->done.base_time      = tb_aicp_time(impl->aicp);
        impl->done.base_time1s    = impl->done.base_time;
        impl->done.saved_size     = 0;
        impl->done.saved_size1s   = 0;
        impl->done.current_rate   = 0;

        // ctrl stream
        if (impl->ctrl.func && !impl->ctrl.func(impl->istream, impl->ostream, impl->ctrl.priv)) break;

        // open and seek istream
        if (!tb_async_stream_open_seek(impl->istream, offset, tb_async_transfer_istream_open_func, impl)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed? restore state
    if (!ok) tb_atomic_set(&impl->state, TB_STATE_CLOSED);

    // ok?
    return ok;
}
tb_bool_t tb_async_transfer_clos(tb_async_transfer_ref_t transfer, tb_async_transfer_clos_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && func, tb_false);
    
    // try closing ok?
    if (tb_async_transfer_clos_try(transfer))
    {
        // done func directly
        func(TB_STATE_OK, priv);
        return tb_true;
    }

    // init func
    impl->clos.func = func;
    impl->clos.priv = priv;

    // clos istream
    if (impl->istream) return tb_async_stream_clos(impl->istream, tb_async_transfer_istream_clos_func, impl);
    // clos ostream
    else if (impl->ostream) return tb_async_stream_clos(impl->ostream, tb_async_transfer_ostream_clos_func, impl);
    // done func directly
    else tb_async_transfer_clos_func(impl, TB_STATE_OK);

    // ok
    return tb_true;
}
tb_bool_t tb_async_transfer_clos_try(tb_async_transfer_ref_t transfer)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("clos: try: ..");
       
    // done
    tb_bool_t ok = tb_false;
    do
    {
        // closed?
        if (TB_STATE_CLOSED == tb_atomic_get(&impl->state))
        {
            ok = tb_true;
            break;
        }

        // try closing istream
        if (impl->istream && !tb_async_stream_clos_try(impl->istream)) break;

        // try closing ostream
        if (impl->ostream && !tb_async_stream_clos_try(impl->ostream)) break;

        // closed
        tb_atomic_set(&impl->state, TB_STATE_CLOSED);

        // clear pause state
        tb_atomic_set(&impl->state_pause, TB_STATE_OK);

        // ok
        ok = tb_true;
        
    } while (0);

    // trace
    tb_trace_d("clos: try: %s", ok? "ok" : "no");
         
    // ok?
    return ok;
}
tb_bool_t tb_async_transfer_ctrl(tb_async_transfer_ref_t transfer, tb_async_transfer_ctrl_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && func, tb_false);
    
    // check state
    tb_assert_and_check_return_val(TB_STATE_CLOSED == tb_atomic_get(&impl->state), tb_false);

    // init func
    impl->ctrl.func = func;
    impl->ctrl.priv = priv;

    // ok
    return tb_true;
}
tb_bool_t tb_async_transfer_done(tb_async_transfer_ref_t transfer, tb_async_transfer_done_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && func, tb_false);
    
    // check state
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->state), tb_false);

    // check stream
    tb_assert_and_check_return_val(impl->istream && impl->ostream, tb_false);

    // init func
    impl->done.func = func;
    impl->done.priv = priv;

    // read it
    return tb_async_stream_read(impl->istream, (tb_size_t)tb_atomic_get(&impl->limited_rate), tb_async_transfer_istream_read_func, impl);
}
tb_bool_t tb_async_transfer_open_done(tb_async_transfer_ref_t transfer, tb_hize_t offset, tb_async_transfer_done_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && func, tb_false);

    // no opened? open it first
    if (TB_STATE_CLOSED == tb_atomic_get(&impl->state))
    {
        impl->done.func = func;
        impl->done.priv = priv;
        return tb_async_transfer_open(transfer, offset, tb_async_transfer_open_done_func, impl);
    }

    // done it
    return tb_async_transfer_done(transfer, func, priv);
}
tb_void_t tb_async_transfer_kill(tb_async_transfer_ref_t transfer)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return(impl);

    // kill it
    tb_size_t state = tb_atomic_fetch_and_set(&impl->state, TB_STATE_KILLING);
    tb_check_return(state != TB_STATE_KILLING);

    // trace
    tb_trace_d("kill: ..");

    // kill istream
    if (impl->istream) tb_async_stream_kill(impl->istream);

    // kill ostream
    if (impl->ostream) tb_async_stream_kill(impl->ostream);
}
tb_bool_t tb_async_transfer_exit(tb_async_transfer_ref_t transfer)
{
    // chec:w
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("exit: ..");

    // kill it first
    tb_async_transfer_kill(transfer);

    // try closing it
    tb_size_t tryn = 30;
    tb_bool_t ok = tb_false;
    while (!(ok = tb_async_transfer_clos_try(transfer)) && tryn--)
    {
        // wait some time
        tb_msleep(200);
    }

    // close failed?
    if (!ok)
    {
        // trace
        tb_trace_e("exit: failed!");
        return tb_false;
    }

    // exit istream
    if (impl->istream && impl->iowner) tb_async_stream_exit(impl->istream);
    impl->istream = tb_null;

    // exit ostream
    if (impl->ostream && impl->oowner) tb_async_stream_exit(impl->ostream);
    impl->ostream = tb_null;

    // exit impl
    tb_free(impl);

    // trace
    tb_trace_d("exit: ok");

    // ok
    return tb_true;
}
tb_void_t tb_async_transfer_pause(tb_async_transfer_ref_t transfer)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return(impl);

    // pause it
    tb_atomic_pset(&impl->state_pause, TB_STATE_OK, TB_STATE_PAUSING);
}
tb_bool_t tb_async_transfer_resume(tb_async_transfer_ref_t transfer)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // done
    tb_bool_t ok = tb_false;
    tb_size_t state_pause = TB_STATE_OK;
    do
    {
        // must be opened?
        tb_check_break(TB_STATE_OPENED == tb_atomic_get(&impl->state));

        // resume it
        tb_size_t state_pause = tb_atomic_fetch_and_set(&impl->state_pause, TB_STATE_OK);

        // pausing or ok? return ok directly
        tb_check_return_val(state_pause == TB_STATE_PAUSED, tb_true);

        // check
        tb_assert_and_check_break(impl->istream);
        tb_assert_and_check_break(impl->ostream);

        // init some rate info
        impl->done.base_time      = tb_aicp_time(impl->aicp);
        impl->done.base_time1s    = impl->done.base_time;
        impl->done.saved_size1s   = 0;
        impl->done.current_rate   = 0;

        // read it
        if (!tb_async_stream_read(impl->istream, (tb_size_t)tb_atomic_get(&impl->limited_rate), tb_async_transfer_istream_read_func, impl)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed? restore state
    if (!ok && state_pause != TB_STATE_OK) tb_atomic_pset(&impl->state_pause, TB_STATE_OK, state_pause);

    // ok?
    return ok;
}
tb_void_t tb_async_transfer_limitrate(tb_async_transfer_ref_t transfer, tb_size_t rate)
{
    // check
    tb_async_transfer_impl_t* impl = (tb_async_transfer_impl_t*)transfer;
    tb_assert_and_check_return(impl);

    // set the limited rate
    tb_atomic_set(&impl->limited_rate, rate);
}

