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
 * @file        prefix.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "async_stream"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_void_t tb_async_stream_clos_opening(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("clos: opening: %s, state: %s", tb_url_cstr(&impl->url), tb_state_cstr(impl->clos_opening.state));

    // closed
    tb_atomic_set(&impl->istate, TB_STATE_CLOSED);

    // done func
    if (impl->clos_opening.func) impl->clos_opening.func(stream, impl->clos_opening.state, impl->clos_opening.priv);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * private interfaces
 */
tb_void_t tb_async_stream_clear(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return(impl);

    // clear rcache
    tb_buffer_clear(&impl->rcache_data);

    // clear wcache
    tb_buffer_clear(&impl->wcache_data);

    // clear istate
    tb_atomic_set(&impl->istate, TB_STATE_CLOSED);
}
tb_void_t tb_async_stream_open_done(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return(impl);

    // opened or closed?
    tb_atomic_set(&impl->istate, TB_STATE_OPENED);
}
tb_bool_t tb_async_stream_open_func(tb_async_stream_ref_t stream, tb_size_t state, tb_async_stream_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // ok?
    tb_bool_t ok = tb_true;
    if (state == TB_STATE_OK) 
    {
        // opened
        tb_atomic_set(&impl->istate, TB_STATE_OPENED);

        // done func
        if (func) ok = func(stream, state, priv);
    }
    // failed? 
    else 
    {
        // try closing ok?
        if (impl->clos_try && impl->clos_try(stream))
        {
            // closed
            tb_atomic_set(&impl->istate, TB_STATE_CLOSED);

            // done func
            if (func) func(stream, state, priv);
        }
        else
        {
            // check
            tb_assert_and_check_return_val(impl->clos, tb_false);

            // init func and state
            impl->clos_opening.func   = func;
            impl->clos_opening.priv   = priv;
            impl->clos_opening.state  = state;

            // close it
            ok = impl->clos(stream, tb_async_stream_clos_opening, tb_null);
        }
    }

    // ok?
    return ok;
}

