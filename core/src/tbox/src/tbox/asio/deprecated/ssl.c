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
 * @file        ssl.c
 * @ingroup     asio
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "aicp_ssl"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "ssl.h"
#include "aico.h"
#include "aicp.h"
#include "../../network/network.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the aicp impl open type
typedef struct __tb_aicp_ssl_open_t
{
    // the func
    tb_aicp_ssl_open_func_t     func;

    // the priv 
    tb_cpointer_t               priv;

}tb_aicp_ssl_open_t;

// the aicp impl clos type
typedef struct __tb_aicp_ssl_clos_t
{
    // the func
    tb_aicp_ssl_clos_func_t     func;

    // the priv 
    tb_cpointer_t               priv;

}tb_aicp_ssl_clos_t;

// the aicp impl read type
typedef struct __tb_aicp_ssl_read_t
{
    // the func
    tb_aicp_ssl_read_func_t     func;

    // the data
    tb_byte_t*                  data;

    // the size
    tb_size_t                   size;

    // the priv 
    tb_cpointer_t               priv;

    // the delay
    tb_size_t                   delay;

}tb_aicp_ssl_read_t;

// the aicp impl writ type
typedef struct __tb_aicp_ssl_writ_t
{
    // the func
    tb_aicp_ssl_writ_func_t     func;

    // the data
    tb_byte_t const*            data;

    // the size
    tb_size_t                   size;

    // the priv 
    tb_cpointer_t               priv;

}tb_aicp_ssl_writ_t;

// the aicp impl task type
typedef struct __tb_aicp_ssl_task_t
{
    // the func
    tb_aicp_ssl_task_func_t     func;

    // the priv 
    tb_cpointer_t               priv;

}tb_aicp_ssl_task_t;

/// the aicp impl close opening type
typedef struct __tb_aicp_ssl_clos_opening_t
{
    /// the func
    tb_aicp_ssl_open_func_t     func;

    /// the priv
    tb_cpointer_t               priv;

    /// the open state
    tb_size_t                   state;

}tb_aicp_ssl_clos_opening_t;

// the aicp impl type
typedef struct __tb_aicp_ssl_impl_t
{
    // the ssl 
    tb_ssl_ref_t                ssl;

    // the aicp
    tb_aicp_ref_t               aicp;

    // the aico
    tb_aico_ref_t               aico;

    // the func
    union
    {
        tb_aicp_ssl_open_t      open;
        tb_aicp_ssl_read_t      read;
        tb_aicp_ssl_writ_t      writ;
        tb_aicp_ssl_task_t      task;
        tb_aicp_ssl_clos_t      clos;

    }                           func;

    // the open and func
    union
    {
        tb_aicp_ssl_read_t      read;
        tb_aicp_ssl_writ_t      writ;

    }                           open_and;

    // the clos opening
    tb_aicp_ssl_clos_opening_t  clos_opening;

    // the post
    struct 
    {
        // the post func
        tb_bool_t               (*func)(tb_aice_ref_t aice);

        // the post delay
        tb_size_t               delay;

        // the real size
        tb_long_t               real;

        // the read or writ data
        tb_byte_t*              data;

        // the read or writ size
        tb_size_t               size;

        // post read?
        tb_bool_t               read;

        // have post?
        tb_bool_t               post;

    }                           post;

    // the timeout
    tb_long_t                   timeout;

    /* the state
     *
     * TB_STATE_CLOSED
     * TB_STATE_OPENED
     * TB_STATE_OPENING
     * TB_STATE_KILLING
     */
    tb_atomic_t                 state;

    // the read data
    tb_buffer_t                 read_data;

    // the writ data
    tb_buffer_t                 writ_data;

}tb_aicp_ssl_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_long_t tb_aicp_ssl_fill_read(tb_aicp_ssl_impl_t* impl, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(impl, -1);

    // done
    tb_long_t real = -1;
    do
    {
        // check
        tb_assert_and_check_break(impl->aico);
        tb_assert_and_check_break(data && size && impl->post.real >= 0);

        // save real
        tb_size_t read_real = impl->post.real;

        // clear real
        impl->post.real = -1;

        // check
        tb_assert_and_check_break(read_real <= size);

        // the data and size
        tb_byte_t*  read_data = tb_buffer_data(&impl->read_data);
        tb_size_t   read_size = tb_buffer_size(&impl->read_data);
        tb_assert_and_check_break(read_data && read_size && size <= read_size);

        // copy data
        tb_memcpy(data, read_data, read_real);

        // trace
        tb_trace_d("[aico:%p]: read: fill: %lu: ok", impl->aico, read_real);

        // read ok
        real = read_real;

    } while (0);

    // ok?
    return real;
}
static tb_long_t tb_aicp_ssl_fill_writ(tb_aicp_ssl_impl_t* impl, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(impl, -1);

    // done
    tb_long_t real = -1;
    do
    {
        // check
        tb_assert_and_check_break(impl->aico);
        tb_assert_and_check_break(size && impl->post.real >= 0);

        // save real
        tb_size_t writ_real = impl->post.real;

        // clear real
        impl->post.real = -1;

        // check
        tb_assert_and_check_break(writ_real <= size);

        // trace
        tb_trace_d("[aico:%p]: writ: try: %lu: ok", impl->aico, writ_real);

        // writ ok
        real = writ_real;

    } while (0);

    // ok?
    return real;
}
static tb_bool_t tb_aicp_ssl_done_post(tb_aicp_ssl_impl_t* impl)
{
    // check
    tb_assert_and_check_return_val(impl, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // check
        tb_assert_and_check_break(impl->post.post && impl->post.data && impl->post.size && impl->post.func);

        // check
        tb_assert_and_check_break(impl->aico);

        // post read?
        if (impl->post.read)
        {
            // trace
            tb_trace_d("[aico:%p]: post: read: %lu: ..", impl->aico, impl->post.size);

            // post read
            if (!tb_aico_recv_after(impl->aico, impl->post.delay, impl->post.data, impl->post.size, impl->post.func, impl)) break;
        }
        // post writ?
        else
        {
            // trace
            tb_trace_d("[aico:%p]: post: writ: %lu: ..", impl->aico, impl->post.size);

            // post writ
            if (!tb_aico_send_after(impl->aico, impl->post.delay, impl->post.data, impl->post.size, impl->post.func, impl)) break;
        }

        // delay only for first
        impl->post.delay = 0;

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
static tb_void_t tb_aicp_ssl_clos_clear(tb_aicp_ssl_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl);

    // close impl
    if (impl->ssl && impl->aico) 
    {       
        // init bio sock, need some blocking time for closing
        tb_ssl_set_bio_sock(impl->ssl, tb_aico_sock(impl->aico));

        // close it
        tb_ssl_clos(impl->ssl);
    }

    // clear data
    tb_buffer_clear(&impl->read_data);
    tb_buffer_clear(&impl->writ_data);

    // clear real
    impl->post.real = 0;
    impl->post.real = 0;

    // closed
    tb_atomic_set(&impl->state, TB_STATE_CLOSED);
}
static tb_void_t tb_aicp_ssl_clos_opening(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("[aico:%p]: clos: opening: state: %s", impl->aico, tb_state_cstr(impl->clos_opening.state));

    // done func
    if (impl->clos_opening.func) impl->clos_opening.func(ssl, impl->clos_opening.state, impl->clos_opening.priv);
}
static tb_bool_t tb_aicp_ssl_open_func(tb_aicp_ssl_impl_t* impl, tb_size_t state, tb_aicp_ssl_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(impl, tb_false);

    // ok?
    tb_bool_t ok = tb_true;
    if (state == TB_STATE_OK || !impl->aico) 
    {
        // opened
        tb_atomic_set(&impl->state, TB_STATE_OPENED);

        // done func
        if (func) ok = func((tb_aicp_ssl_ref_t)impl, state, priv);
    }
    // failed? 
    else 
    {
        // init func and state
        impl->clos_opening.func   = func;
        impl->clos_opening.priv   = priv;
        impl->clos_opening.state  = state;

        // close it
        tb_aicp_ssl_clos((tb_aicp_ssl_ref_t)impl, tb_aicp_ssl_clos_opening, tb_null);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_aicp_ssl_open_done(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && (aice->code == TB_AICE_CODE_RECV || aice->code == TB_AICE_CODE_SEND), tb_false);

    // the impl
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.open.func, tb_false);

    // the real
    tb_size_t real = aice->code == TB_AICE_CODE_RECV? aice->u.recv.real : aice->u.send.real;

    // trace
    tb_trace_d("[aico:%p]: open: done: real: %lu, state: %s", impl->aico, real, tb_state_cstr(aice->state));

    // done
    tb_size_t state = TB_STATE_SOCK_SSL_UNKNOWN_ERROR;
    do
    {
        // clear post
        impl->post.post  = tb_false;
        impl->post.data  = tb_null;
        impl->post.size  = 0;
        
        // failed or closed?
        if (aice->state != TB_STATE_OK)
        {
            state = aice->state;
            break;
        }

        // save the real size
        impl->post.real = real;

        // trace
        tb_trace_d("[aico:%p]: open: done: try: ..", impl->aico);
    
        // try opening it
        tb_long_t ok = tb_ssl_open_try(impl->ssl);

        // trace
        tb_trace_d("[aico:%p]: open: done: try: %ld", impl->aico, ok);
    
        // ok?
        if (ok > 0)
        {
            // done func
            tb_aicp_ssl_open_func(impl, TB_STATE_OK, impl->func.open.func, impl->func.open.priv);
        }
        // failed?
        else if (ok < 0)
        {
            // save state
            state = tb_ssl_state(impl->ssl);
            break;
        }
        // have post? continue it
        else if (impl->post.post)
        {
            // post it
            if (!tb_aicp_ssl_done_post(impl))
            {
                // trace
                tb_trace_e("[aico:%p]: open: done: post failed!", impl->aico);
                break;
            }
        }
        else
        {
            // trace
            tb_trace_d("[aico:%p]: open: done: no post!", impl->aico);
        }

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK)
    {
        // done func
        tb_aicp_ssl_open_func(impl, state, impl->func.open.func, impl->func.open.priv);
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_aicp_ssl_read_done(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && (aice->code == TB_AICE_CODE_RECV || aice->code == TB_AICE_CODE_SEND), tb_false);

    // the impl
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.read.func, tb_false);

    // the real
    tb_size_t real = aice->code == TB_AICE_CODE_RECV? aice->u.recv.real : aice->u.send.real;

    // trace
    tb_trace_d("[aico:%p]: read: done: real: %lu, state: %s", impl->aico, real, tb_state_cstr(aice->state));

    // done
    tb_size_t state = TB_STATE_SOCK_SSL_UNKNOWN_ERROR;
    do
    {
        // clear post
        impl->post.post  = tb_false;
        impl->post.data  = tb_null;
        impl->post.size  = 0;

        // failed or closed?
        if (aice->state != TB_STATE_OK)
        {
            state = aice->state;
            break;
        }

        // save the real size
        impl->post.real = real;

        // trace
        tb_trace_d("[aico:%p]: read: done: try: %lu: ..", impl->aico, impl->func.read.size);
    
        // try reading it
        tb_long_t real = tb_ssl_read(impl->ssl, impl->func.read.data, impl->func.read.size);

        // trace
        tb_trace_d("[aico:%p]: read: done: try: %lu: %ld", impl->aico, impl->func.read.size, real);
    
        // ok?
        if (real > 0)
        {
            // done func
            impl->func.read.func((tb_aicp_ssl_ref_t)impl, TB_STATE_OK, impl->func.read.data, real, impl->func.read.size, impl->func.read.priv);
        }
        // failed?
        else if (real < 0)
        {
            // save state
            state = tb_ssl_state(impl->ssl);
            break;
        }
        // have post? continue it
        else if (impl->post.post)
        {
            // post it
            if (!tb_aicp_ssl_done_post(impl))
            {
                // trace
                tb_trace_e("[aico:%p]: read: done: post failed!", impl->aico);
                break;
            }
        }
        else
        {
            // trace
            tb_trace_d("[aico:%p]: read: done: no post!", impl->aico);
    
            // done func
            impl->func.read.func((tb_aicp_ssl_ref_t)impl, TB_STATE_OK, impl->func.read.data, 0, impl->func.read.size, impl->func.read.priv);
        }

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK)
    {
        // done func
        impl->func.read.func((tb_aicp_ssl_ref_t)impl, state, impl->func.read.data, 0, impl->func.read.size, impl->func.read.priv);
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_aicp_ssl_writ_done(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && (aice->code == TB_AICE_CODE_RECV || aice->code == TB_AICE_CODE_SEND), tb_false);

    // the impl
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.writ.func, tb_false);

    // the real
    tb_size_t real = aice->code == TB_AICE_CODE_RECV? aice->u.recv.real : aice->u.send.real;

    // trace
    tb_trace_d("[aico:%p]: writ: done: real: %lu, state: %s", impl->aico, real, tb_state_cstr(aice->state));

    // done
    tb_size_t state = TB_STATE_SOCK_SSL_UNKNOWN_ERROR;
    do
    {
        // clear post
        impl->post.post  = tb_false;
        impl->post.data  = tb_null;
        impl->post.size  = 0;

        // failed or closed?
        if (aice->state != TB_STATE_OK)
        {
            state = aice->state;
            break;
        }

        // save the real size
        impl->post.real = real;

        // trace
        tb_trace_d("[aico:%p]: writ: done: try: %lu: ..", impl->aico, impl->func.writ.size);

        // try writing it
        tb_long_t real = tb_ssl_writ(impl->ssl, impl->func.writ.data, impl->func.writ.size);

        // trace
        tb_trace_d("[aico:%p]: writ: done: try: %lu: %ld", impl->aico, impl->func.writ.size, real);
    
        // ok?
        if (real > 0)
        {
            // done func
            impl->func.writ.func((tb_aicp_ssl_ref_t)impl, TB_STATE_OK, impl->func.writ.data, real, impl->func.writ.size, impl->func.writ.priv);
        }
        // failed?
        else if (real < 0)
        {
            // save state
            state = tb_ssl_state(impl->ssl);
            break;
        }
        // have post? continue it
        else if (impl->post.post)
        {
            // post it
            if (!tb_aicp_ssl_done_post(impl))
            {
                // trace
                tb_trace_e("[aico:%p]: writ: done: post failed!", impl->aico);
                break;
            }
        }
        else
        {
            // trace
            tb_trace_d("[aico:%p]: writ: done: no post!", impl->aico);
    
            // done func
            impl->func.writ.func((tb_aicp_ssl_ref_t)impl, TB_STATE_OK, impl->func.writ.data, 0, impl->func.writ.size, impl->func.writ.priv);
        }

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK)
    {
        // done func
        impl->func.writ.func((tb_aicp_ssl_ref_t)impl, state, impl->func.writ.data, 0, impl->func.writ.size, impl->func.writ.priv);
    }

    // ok
    return tb_true;
}
static tb_long_t tb_aicp_ssl_read_func(tb_cpointer_t priv, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->post.func && !impl->post.post, -1);

    // done
    tb_size_t state = TB_STATE_SOCK_SSL_UNKNOWN_ERROR;
    do
    {
        // fill to read it?
        if (impl->post.real >= 0) return tb_aicp_ssl_fill_read(impl, data, size);

        // resize data
        if (tb_buffer_size(&impl->read_data) < size)
            tb_buffer_resize(&impl->read_data, size);

        // the data and size
        tb_byte_t*  read_data = tb_buffer_data(&impl->read_data);
        tb_size_t   read_size = tb_buffer_size(&impl->read_data);
        tb_assert_and_check_break(read_data && read_size && size <= read_size);

        // post read
        impl->post.post = tb_true;
        impl->post.read = tb_true;
        impl->post.data = read_data;
        impl->post.size = size;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // read failed or continue?
    return state != TB_STATE_OK? -1 : 0;
}
static tb_long_t tb_aicp_ssl_writ_func(tb_cpointer_t priv, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->post.func && !impl->post.post, -1);

    // done
    tb_size_t state = TB_STATE_SOCK_SSL_UNKNOWN_ERROR;
    do
    {
        // fill to writ it?
        if (impl->post.real >= 0) return tb_aicp_ssl_fill_writ(impl, data, size);

        // save data
        tb_buffer_memncpy(&impl->writ_data, data, size);

        // the data and size
        tb_byte_t*  writ_data = tb_buffer_data(&impl->writ_data);
        tb_size_t   writ_size = tb_buffer_size(&impl->writ_data);
        tb_assert_and_check_break(writ_data && writ_size && size == writ_size);

        // post writ
        impl->post.post = tb_true;
        impl->post.read = tb_false;
        impl->post.data = writ_data;
        impl->post.size = writ_size;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // ok?
    return state != TB_STATE_OK? -1 : 0;
}
static tb_bool_t tb_aicp_ssl_open_and_read(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_read_t* read = (tb_aicp_ssl_read_t*)priv;
    tb_assert_and_check_return_val(ssl && read && read->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // check
        tb_check_break(state == TB_STATE_OK);

        // clear state
        state = TB_STATE_SOCK_SSL_UNKNOWN_ERROR;

        // post read
        if (!tb_aicp_ssl_read(ssl, read->data, read->size, read->func, read->priv)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK)
    {
        // done func
        ok = read->func(ssl, state, read->data, 0, read->size, read->priv);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_aicp_ssl_open_and_writ(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_writ_t* writ = (tb_aicp_ssl_writ_t*)priv;
    tb_assert_and_check_return_val(ssl && writ && writ->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // check
        tb_check_break(state == TB_STATE_OK);

        // clear state
        state = TB_STATE_SOCK_SSL_UNKNOWN_ERROR;

        // post writ
        if (!tb_aicp_ssl_writ(ssl, writ->data, writ->size, writ->func, writ->priv)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK)
    {
        // done func
        ok = writ->func(ssl, state, writ->data, 0, writ->size, writ->priv);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_aicp_ssl_done_task(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_RUNTASK, tb_false);

    // the impl
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.task.func, tb_false);

    // trace
    tb_trace_d("[aico:%p]: task: done: state: %s", impl->aico, tb_state_cstr(aice->state));

    // done func
    impl->func.task.func((tb_aicp_ssl_ref_t)impl, aice->state, impl->post.delay, impl->func.task.priv);

    // ok
    return tb_true;
}
static tb_bool_t tb_aicp_ssl_done_clos(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_RUNTASK, tb_false);

    // the impl
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.clos.func, tb_false);

    // trace
    tb_trace_d("[aico:%p]: clos: notify: ..", impl->aico);

    // clear impl
    tb_aicp_ssl_clos_clear(impl);

    // done func
    impl->func.clos.func((tb_aicp_ssl_ref_t)impl, TB_STATE_OK, impl->func.clos.priv);

    // trace
    tb_trace_d("[aico:%p]: clos: notify: ok", impl->aico);

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_aicp_ssl_ref_t tb_aicp_ssl_init(tb_aicp_ref_t aicp, tb_bool_t bserver)
{
    // check
    tb_assert_and_check_return_val(aicp, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_aicp_ssl_impl_t* impl = tb_null;
    do
    {
        // make impl
        impl = tb_malloc0_type(tb_aicp_ssl_impl_t);
        tb_assert_and_check_break(impl);

        // init state
        impl->state = TB_STATE_CLOSED;

        // init aicp
        impl->aicp = aicp;

        // init impl
        impl->ssl = tb_ssl_init(bserver);
        tb_assert_and_check_break(impl->ssl);

        // init read data
        if (!tb_buffer_init(&impl->read_data)) break;

        // init writ data
        if (!tb_buffer_init(&impl->writ_data)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_aicp_ssl_exit((tb_aicp_ssl_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_aicp_ssl_ref_t)impl;
}
tb_void_t tb_aicp_ssl_kill(tb_aicp_ssl_ref_t ssl)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return(impl);

    // kill it
    tb_size_t state = tb_atomic_fetch_and_set(&impl->state, TB_STATE_KILLING);
    tb_check_return(state != TB_STATE_KILLING);

    // trace
    tb_trace_d("[aico:%p]: kill: ..", impl->aico);

    // kill aico
    if (impl->aico) tb_aico_kill(impl->aico);
}
tb_bool_t tb_aicp_ssl_exit(tb_aicp_ssl_ref_t ssl)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("[aico:%p]: exit: ..", impl->aico);

    // try closing it
    tb_size_t tryn = 30;
    tb_bool_t ok = tb_false;
    while (!(ok = tb_aicp_ssl_clos_try(ssl)) && tryn--)
    {
        // wait some time
        tb_msleep(200);
    }

    // close failed?
    if (!ok)
    {
        // trace
        tb_trace_e("[aico:%p]: exit: failed!", impl->aico);
        return tb_false;
    }

    // exit impl
    if (impl->ssl) tb_ssl_exit(impl->ssl);
    impl->ssl = tb_null;

    // exit data
    tb_buffer_exit(&impl->read_data);
    tb_buffer_exit(&impl->writ_data);

    // trace
    tb_trace_d("[aico:%p]: exit: ok", impl->aico);
    
    // exit it
    tb_free(impl);

    // ok
    return tb_true;
}
tb_void_t tb_aicp_ssl_set_aico(tb_aicp_ssl_ref_t ssl, tb_aico_ref_t aico)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return(impl);

    // save aico
    impl->aico = aico;
}
tb_void_t tb_aicp_ssl_set_timeout(tb_aicp_ssl_ref_t ssl, tb_long_t timeout)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return(impl);

    // save timeout
    impl->timeout = timeout;
}
tb_bool_t tb_aicp_ssl_open(tb_aicp_ssl_ref_t ssl, tb_aicp_ssl_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl && func, tb_false);

    // done
    do
    {
        // set opening
        tb_size_t state = tb_atomic_fetch_and_pset(&impl->state, TB_STATE_CLOSED, TB_STATE_OPENING);

        // opened? done func directly
        if (state == TB_STATE_OPENED) 
        {
            func(ssl, TB_STATE_OK, priv);
            break;
        }

        // must be closed
        tb_assert_and_check_return_val(state == TB_STATE_CLOSED, tb_false);

        // check
        tb_assert_and_check_return_val(impl->aicp && impl->ssl && impl->aico, tb_false);

        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            // done func
            tb_aicp_ssl_open_func(impl, TB_STATE_KILLED, func, priv);
            break;
        }

        // init timeout
        if (impl->timeout)
        {
            tb_aico_timeout_set(impl->aico, TB_AICO_TIMEOUT_RECV, impl->timeout);
            tb_aico_timeout_set(impl->aico, TB_AICO_TIMEOUT_SEND, impl->timeout);
        }

        // save func
        impl->func.open.func = func;
        impl->func.open.priv = priv;

        // init post
        impl->post.func  = tb_aicp_ssl_open_done;
        impl->post.delay = 0;
        impl->post.post  = tb_false;
        impl->post.data  = tb_null;
        impl->post.size  = 0;
        impl->post.real  = -1;

        // init post func
        tb_ssl_set_bio_func(impl->ssl, tb_aicp_ssl_read_func, tb_aicp_ssl_writ_func, tb_null, impl);

        // try opening it
        tb_long_t r = tb_ssl_open_try(impl->ssl);

        // ok
        if (r > 0)
        {
            // done func
            tb_aicp_ssl_open_func(impl, TB_STATE_OK, func, priv);
        }
        // failed?
        else if (r < 0)
        {
            // done func
            tb_aicp_ssl_open_func(impl, tb_ssl_state(impl->ssl), func, priv);
        }
        // have post? continue it
        else if (impl->post.post)
        {
            // post it
            if (!tb_aicp_ssl_done_post(impl))
            {
                // trace
                tb_trace_e("[aico:%p]: open: post failed!", impl->aico);
        
                // done func
                tb_aicp_ssl_open_func(impl, TB_STATE_SOCK_SSL_UNKNOWN_ERROR, func, priv);
            }
        }
        else
        {
            // trace
            tb_trace_e("[aico:%p]: open: no post!", impl->aico);
    
            // done func
            tb_aicp_ssl_open_func(impl, TB_STATE_SOCK_SSL_UNKNOWN_ERROR, func, priv);
        }

    } while (0);

    // post or done func ok
    return tb_true;
}
tb_bool_t tb_aicp_ssl_clos(tb_aicp_ssl_ref_t ssl, tb_aicp_ssl_clos_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl && func, tb_false);

    // trace
    tb_trace_d("[aico:%p]: clos: ..", impl->aico);

    // try closing ok?
    if (tb_aicp_ssl_clos_try(ssl))
    {
        // done func
        func(ssl, TB_STATE_OK, priv);
        return tb_true;
    }

    // init func
    impl->func.clos.func = func;
    impl->func.clos.priv = priv;

    // clos aico
    if (impl->aico && tb_aico_task_run(impl->aico, 0, tb_aicp_ssl_done_clos, impl));
    else
    {
        // clear impl
        tb_aicp_ssl_clos_clear(impl);

        // done func
        impl->func.clos.func(ssl, TB_STATE_OK, impl->func.clos.priv);
    }

    // ok
    return tb_true;
}
tb_bool_t tb_aicp_ssl_clos_try(tb_aicp_ssl_ref_t ssl)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("[aico:%p]: clos: try: ..", impl->aico);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // closed? ok
        if (TB_STATE_CLOSED == tb_atomic_get(&impl->state)) break;

        // no aico? ok
        if (!impl->aico) break;

        // failed
        ok = tb_false;

    } while (0);

    // ok? closed
    if (ok) tb_atomic_set(&impl->state, TB_STATE_CLOSED);

    // trace
    tb_trace_d("[aico:%p]: clos: try: %s", impl->aico, ok? "ok" : "no");

    // ok?
    return ok;
}
tb_bool_t tb_aicp_ssl_read(tb_aicp_ssl_ref_t ssl, tb_byte_t* data, tb_size_t size, tb_aicp_ssl_read_func_t func, tb_cpointer_t priv)
{
    return tb_aicp_ssl_read_after(ssl, 0, data, size, func, priv);
}
tb_bool_t tb_aicp_ssl_writ(tb_aicp_ssl_ref_t ssl, tb_byte_t const* data, tb_size_t size, tb_aicp_ssl_writ_func_t func, tb_cpointer_t priv)
{
    return tb_aicp_ssl_writ_after(ssl, 0, data, size, func, priv);
}
tb_bool_t tb_aicp_ssl_read_after(tb_aicp_ssl_ref_t ssl, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_aicp_ssl_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl && data && size && func, tb_false);

    // trace
    tb_trace_d("[aico:%p]: read: %lu, after: %lu", impl->aico, size, delay);
            
    // opened?
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->state), tb_false);

    // check
    tb_assert_and_check_return_val(impl->aicp && impl->ssl && impl->aico, tb_false);
 
    // done
    do
    {
        // save func
        impl->func.read.func     = func;
        impl->func.read.priv     = priv;
        impl->func.read.data     = data;
        impl->func.read.size     = size;

        // init post
        impl->post.func  = tb_aicp_ssl_read_done;
        impl->post.delay = delay;
        impl->post.post  = tb_false;
        impl->post.data  = tb_null;
        impl->post.size  = 0;
        impl->post.real = -1;

        // init post func
        tb_ssl_set_bio_func(impl->ssl, tb_aicp_ssl_read_func, tb_aicp_ssl_writ_func, tb_null, impl);

        // try reading it
        tb_long_t real = tb_ssl_read(impl->ssl, data, size);

        // ok
        if (real > 0)
        {
            // done func
            func(ssl, TB_STATE_OK, data, real, size, priv);
        }
        // failed?
        else if (real < 0)
        {
            // done func
            func(ssl, tb_ssl_state(impl->ssl), data, 0, size, priv);
        }
        // have post? continue it
        else if (impl->post.post)
        {
            // post it
            if (!tb_aicp_ssl_done_post(impl))
            {
                // trace
                tb_trace_e("[aico:%p]: read: post failed!", impl->aico);
        
                // done func
                func(ssl, TB_STATE_SOCK_SSL_UNKNOWN_ERROR, data, 0, size, priv);
            }
        }
        else
        {
            // trace
            tb_trace_e("[aico:%p]: read: no post!", impl->aico);
    
            // done func
            func(ssl, TB_STATE_SOCK_SSL_UNKNOWN_ERROR, data, 0, size, priv);
        }

    } while (0);

    // post or done func ok
    return tb_true;
}
tb_bool_t tb_aicp_ssl_writ_after(tb_aicp_ssl_ref_t ssl, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_aicp_ssl_writ_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl && data && size && func, tb_false);

    // trace
    tb_trace_d("[aico:%p]: writ: %lu, after: %lu", impl->aico, size, delay);

    // opened?
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->state), tb_false);

    // check
    tb_assert_and_check_return_val(impl->aicp && impl->ssl && impl->aico, tb_false);

    // done
    do
    {
        // save func
        impl->func.writ.func     = func;
        impl->func.writ.priv     = priv;
        impl->func.writ.data     = data;
        impl->func.writ.size     = size;

        // init post
        impl->post.func  = tb_aicp_ssl_writ_done;
        impl->post.delay = delay;
        impl->post.post  = tb_false;
        impl->post.data  = tb_null;
        impl->post.size  = 0;
        impl->post.real  = -1;

        // init post func
        tb_ssl_set_bio_func(impl->ssl, tb_aicp_ssl_read_func, tb_aicp_ssl_writ_func, tb_null, impl);

        // try writing it
        tb_long_t real = tb_ssl_writ(impl->ssl, data, size);

        // ok
        if (real > 0)
        {
            // done func
            func(ssl, TB_STATE_OK, data, real, size, priv);
        }
        // failed?
        else if (real < 0)
        {
            // done func
            func(ssl, tb_ssl_state(impl->ssl), data, 0, size, priv);
        }
        // have post? continue it
        else if (impl->post.post)
        {
            // post it
            if (!tb_aicp_ssl_done_post(impl))
            {
                // trace
                tb_trace_e("[aico:%p]: writ: post failed!", impl->aico);
        
                // done func
                func(ssl, TB_STATE_SOCK_SSL_UNKNOWN_ERROR, data, 0, size, priv);
            }
        }
        else
        {
            // trace
            tb_trace_e("[aico:%p]: writ: no post!", impl->aico);
    
            // done func
            func(ssl, TB_STATE_SOCK_SSL_UNKNOWN_ERROR, data, 0, size, priv);
        }

    } while (0);

    // post or done func ok
    return tb_true;
}
tb_bool_t tb_aicp_ssl_task(tb_aicp_ssl_ref_t ssl, tb_size_t delay, tb_aicp_ssl_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // save func
    impl->func.task.func     = func;
    impl->func.task.priv     = priv;
    impl->post.delay         = delay;

    // run task
    return tb_aico_task_run(impl->aico, delay, tb_aicp_ssl_done_task, impl);
}
tb_bool_t tb_aicp_ssl_open_read(tb_aicp_ssl_ref_t ssl, tb_byte_t* data, tb_size_t size, tb_aicp_ssl_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl && data && size && func, tb_false);

    // not opened? open it first
    if (TB_STATE_CLOSED == tb_atomic_get(&impl->state))
    {
        impl->open_and.read.func = func;
        impl->open_and.read.data = data;
        impl->open_and.read.size = size;
        impl->open_and.read.priv = priv;
        return tb_aicp_ssl_open(ssl, tb_aicp_ssl_open_and_read, &impl->open_and.read);
    }

    // read it
    return tb_aicp_ssl_read(ssl, data, size, func, priv);
}
tb_bool_t tb_aicp_ssl_open_writ(tb_aicp_ssl_ref_t ssl, tb_byte_t const* data, tb_size_t size, tb_aicp_ssl_writ_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl && data && size && func, tb_false);

    // not opened? open it first
    if (TB_STATE_CLOSED == tb_atomic_get(&impl->state))
    {
        impl->open_and.writ.func = func;
        impl->open_and.writ.data = data;
        impl->open_and.writ.size = size;
        impl->open_and.writ.priv = priv;
        return tb_aicp_ssl_open(ssl, tb_aicp_ssl_open_and_writ, &impl->open_and.writ);
    }

    // writ it
    return tb_aicp_ssl_writ(ssl, data, size, func, priv);
}
tb_aicp_ref_t tb_aicp_ssl_aicp(tb_aicp_ssl_ref_t ssl)
{
    // check
    tb_aicp_ssl_impl_t* impl = (tb_aicp_ssl_impl_t*)ssl;
    tb_assert_and_check_return_val(impl, tb_null);

    // the aicp
    return impl->aicp;
}

