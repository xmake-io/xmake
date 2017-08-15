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
 * @file        async_stream.c
 * @ingroup     stream
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
#include "async_stream.h"
#include "impl/async_stream/prefix.h"
#include "../../network/network.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_async_stream_cache_sync_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->sync && impl->wcache_and.sync.func, tb_false);

    // move cache
    if (real) tb_buffer_memmov(&impl->wcache_data, real);

    // not finished? continue it
    if (state == TB_STATE_OK && real < size) return tb_true;

    // not finished? continue it
    tb_bool_t ok = tb_false;
    if (state == TB_STATE_OK && real < size) ok = tb_true;
    // ok? sync it
    else if (state == TB_STATE_OK && real == size)
    {
        // check
        tb_assert_and_check_return_val(!tb_buffer_size(&impl->wcache_data), tb_false);

        // post sync
        ok = impl->sync(stream, impl->wcache_and.sync.bclosing, impl->wcache_and.sync.func, priv);

        // failed? done func
        if (!ok) ok = impl->wcache_and.sync.func(stream, TB_STATE_UNKNOWN_ERROR, impl->wcache_and.sync.bclosing, priv);
    }
    // failed?
    else
    {
        // failed? done func
        ok = impl->wcache_and.sync.func(stream, state != TB_STATE_OK? state : TB_STATE_UNKNOWN_ERROR, impl->wcache_and.sync.bclosing, priv);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_cache_writ_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->wcache_and.writ.func, tb_false);

    // done
    tb_bool_t bwrit = tb_true;
    do
    {
        // check
        tb_check_break(state == TB_STATE_OK);

        // finished?
        if (real == size)
        {
            // trace
            tb_trace_d("cache: writ: %lu: ok", impl->wcache_and.writ.size);

            // clear cache
            tb_buffer_clear(&impl->wcache_data);
    
            // done func
            impl->wcache_and.writ.func(stream, TB_STATE_OK, impl->wcache_and.writ.data, impl->wcache_and.writ.size, impl->wcache_and.writ.size, priv);

            // break
            bwrit = tb_false;
        }

    } while (0);

    // failed? 
    if (state != TB_STATE_OK)
    {
        // trace
        tb_trace_d("cache: writ: %lu: failed: %s", impl->wcache_and.writ.size, tb_state_cstr(state));

        // done func
        impl->wcache_and.writ.func(stream, state, impl->wcache_and.writ.data, 0, impl->wcache_and.writ.size, priv);

        // break
        bwrit = tb_false;
    }

    // continue writing?
    return bwrit;
}
static tb_bool_t tb_async_stream_cache_writ_done(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->writ && data && size && func, tb_false);
    
    // using cache?
    tb_bool_t ok = tb_false;
    if (impl->wcache_maxn)
    {
        // writ data to cache 
        if (data && size) tb_buffer_memncat(&impl->wcache_data, data, size);

        // the writ data and size
        tb_byte_t const*    writ_data = tb_buffer_data(&impl->wcache_data);
        tb_size_t           writ_size = tb_buffer_size(&impl->wcache_data);
    
        // no full? writ ok
        if (writ_size < impl->wcache_maxn)
        {
            // trace
            tb_trace_d("cache: writ: %lu: ok", size);

            // done func
            func(stream, TB_STATE_OK, data, size, size, priv);
            ok = tb_true;
        }
        else
        {
            // trace
            tb_trace_d("cache: writ: %lu: ..", size);

            // writ it
            impl->wcache_and.writ.func = func;
            impl->wcache_and.writ.data = data;
            impl->wcache_and.writ.size = size;
            ok = impl->writ(stream, delay, writ_data, writ_size, tb_async_stream_cache_writ_func, priv);
        }
    }
    // writ it
    else ok = impl->writ(stream, delay, data, size, func, priv);

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_cache_read_done(tb_async_stream_ref_t stream, tb_size_t delay, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->read && func, tb_false);

    // have writed cache? need sync it first
    tb_assert_and_check_return_val(!impl->wcache_maxn || !tb_buffer_size(&impl->wcache_data), tb_false);

    // using cache?
    tb_byte_t* data = tb_null;
    if (impl->rcache_maxn)
    {
        // grow data
        if (impl->rcache_maxn > tb_buffer_maxn(&impl->rcache_data)) 
            tb_buffer_resize(&impl->rcache_data, impl->rcache_maxn);

        // the cache data
        data = tb_buffer_data(&impl->rcache_data);
        tb_assert_and_check_return_val(data, tb_false);

        // the maxn
        tb_size_t maxn = tb_buffer_maxn(&impl->rcache_data);

        // adjust the size
        if (!size || size > maxn) size = maxn;
    }

    // read it
    return impl->read(stream, delay, data, size, func, priv);
}
static tb_bool_t tb_async_stream_open_read_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t*         impl = tb_async_stream_impl(stream);
    tb_async_stream_open_read_t*    open_read = (tb_async_stream_open_read_t*)priv;
    tb_assert_and_check_return_val(impl && impl->read && open_read && open_read->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
        
        // killed?
        if (tb_async_stream_is_killed(stream))
        {
            state = TB_STATE_KILLED;
            break;
        }
    
        // read it
        if (!tb_async_stream_cache_read_done(stream, 0, open_read->size, open_read->func, open_read->priv)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);
 
    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        ok = open_read->func(stream, state, tb_null, 0, open_read->size, open_read->priv);
    }
 
    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_open_writ_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t*         impl = tb_async_stream_impl(stream);
    tb_async_stream_open_writ_t*    owrit = (tb_async_stream_open_writ_t*)priv;
    tb_assert_and_check_return_val(impl && impl->writ && owrit && owrit->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
            
        // killed?
        if (tb_async_stream_is_killed(stream))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // check
        tb_assert_and_check_break(owrit->data && owrit->size);

        // writ it
        if (!tb_async_stream_cache_writ_done(stream, 0, owrit->data, owrit->size, owrit->func, owrit->priv)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed? 
    if (state != TB_STATE_OK)
    {   
        // done func
        ok = owrit->func(stream, state, owrit->data, 0, owrit->size, owrit->priv);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_open_seek_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t*         impl = tb_async_stream_impl(stream);
    tb_async_stream_open_seek_t*    open_seek = (tb_async_stream_open_seek_t*)priv;
    tb_assert_and_check_return_val(impl && impl->seek && open_seek && open_seek->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
        
        // killed?
        if (tb_async_stream_is_killed(stream))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // offset be not modified?
        if (tb_async_stream_offset(stream) == open_seek->offset)
        {
            // done func
            ok = open_seek->func(stream, TB_STATE_OK, open_seek->offset, open_seek->priv);
        }
        else
        {
            // seek it
            if (!impl->seek(stream, open_seek->offset, open_seek->func, open_seek->priv)) break;
        }

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed? 
    if (state != TB_STATE_OK) 
    {   
        // done func
        ok = open_seek->func(stream, state, 0, open_seek->priv);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_sync_read_func(tb_async_stream_ref_t stream, tb_size_t state, tb_bool_t bclosing, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t*         impl = tb_async_stream_impl(stream);
    tb_async_stream_sync_read_t*    sync_read = (tb_async_stream_sync_read_t*)priv;
    tb_assert_and_check_return_val(impl && impl->read && sync_read && sync_read->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
        
        // killed?
        if (tb_async_stream_is_killed(stream))
        {
            state = TB_STATE_KILLED;
            break;
        }
    
        // read it
        if (!tb_async_stream_cache_read_done(stream, 0, sync_read->size, sync_read->func, sync_read->priv)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);
 
    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        ok = sync_read->func(stream, state, tb_null, 0, sync_read->size, sync_read->priv);
    }
 
    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_sync_seek_func(tb_async_stream_ref_t stream, tb_size_t state, tb_bool_t bclosing, tb_cpointer_t priv)
{
    // check
    tb_async_stream_impl_t*         impl = tb_async_stream_impl(stream);
    tb_async_stream_sync_seek_t*    sync_seek = (tb_async_stream_sync_seek_t*)priv;
    tb_assert_and_check_return_val(impl && impl->seek && sync_seek && sync_seek->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
        
        // killed?
        if (tb_async_stream_is_killed(stream))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // offset be not modified?
        if (tb_async_stream_offset(stream) == sync_seek->offset)
        {
            // done func
            ok = sync_seek->func(stream, TB_STATE_OK, sync_seek->offset, sync_seek->priv);
        }
        else
        {
            // seek it
            if (!impl->seek(stream, sync_seek->offset, sync_seek->func, sync_seek->priv)) break;
        }

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed? 
    if (state != TB_STATE_OK) 
    {   
        // done func
        ok = sync_seek->func(stream, state, 0, sync_seek->priv);
    }

    // ok?
    return ok;
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_async_stream_ref_t tb_async_stream_init( tb_aicp_ref_t aicp
                                        ,   tb_size_t type
                                        ,   tb_size_t type_size
                                        ,   tb_size_t rcache
                                        ,   tb_size_t wcache
                                        ,   tb_bool_t (*open_try)(tb_async_stream_ref_t stream)
                                        ,   tb_bool_t (*clos_try)(tb_async_stream_ref_t stream)
                                        ,   tb_bool_t (*open)(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv)
                                        ,   tb_bool_t (*clos)(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv)
                                        ,   tb_bool_t (*exit)(tb_async_stream_ref_t stream)
                                        ,   tb_void_t (*kill)(tb_async_stream_ref_t stream)
                                        ,   tb_bool_t (*ctrl)(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
                                        ,   tb_bool_t (*read)(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv)
                                        ,   tb_bool_t (*writ)(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv)
                                        ,   tb_bool_t (*seek)(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv)
                                        ,   tb_bool_t (*sync)(tb_async_stream_ref_t stream, tb_bool_t bclosing, tb_async_stream_sync_func_t func, tb_cpointer_t priv)
                                        ,   tb_bool_t (*task)(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv))
{
    // check
    tb_assert_and_check_return_val(type_size, tb_null);
    tb_assert_and_check_return_val(open && clos && ctrl && kill, tb_null);
    tb_assert_and_check_return_val(read || writ, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_impl_t* impl = tb_null;
    tb_async_stream_ref_t   stream = tb_null;
    do
    {
        // make impl
        impl = (tb_async_stream_impl_t*)tb_align8_malloc0(sizeof(tb_async_stream_impl_t) + type_size);
        tb_assert_and_check_break(impl);

        // init stream
        stream = (tb_async_stream_ref_t)&impl[1];

        // init type
        impl->type = (tb_uint8_t)type;

        // init timeout, 10s
        impl->timeout = TB_STREAM_DEFAULT_TIMEOUT;

        // init internal state
        impl->istate = TB_STATE_CLOSED;

        // init aicp
        impl->aicp = aicp? aicp : tb_aicp();
        tb_assert_and_check_break(impl->aicp);

        // init url
        if (!tb_url_init(&impl->url)) break;

        // init rcache
        if (!tb_buffer_init(&impl->rcache_data)) break;
        impl->rcache_maxn = rcache;

        // init wcache
        if (!tb_buffer_init(&impl->wcache_data)) break;
        impl->wcache_maxn = wcache;

        // init func
        impl->open_try  = open_try;
        impl->clos_try  = clos_try;
        impl->open      = open;
        impl->clos      = clos;
        impl->exit      = exit;
        impl->kill      = kill;
        impl->ctrl      = ctrl;
        impl->read      = read;
        impl->writ      = writ;
        impl->seek      = seek;
        impl->sync      = sync;
        impl->task      = task;

        // ok
        ok = tb_true;

    } while (0);

    // failed? 
    if (!ok)
    {
        // exit it
        if (stream) tb_async_stream_exit(stream);
        stream = tb_null;
    }

    // ok?
    return stream;
}
tb_async_stream_ref_t tb_async_stream_init_from_url(tb_aicp_ref_t aicp, tb_char_t const* url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // the init
    static tb_async_stream_ref_t (*s_init[])(tb_aicp_ref_t) = 
    {
        tb_null
    ,   tb_async_stream_init_file
    ,   tb_async_stream_init_sock
    ,   tb_async_stream_init_http
    ,   tb_async_stream_init_data
    };

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
        return tb_null;
    }
    tb_assert_and_check_return_val(type && type < tb_arrayn(s_init) && s_init[type], tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_async_stream_ref_t  stream = tb_null;
    do
    {
        // init stream
        stream = s_init[type](aicp);
        tb_assert_and_check_break(stream);

        // init url
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_URL, url)) break;

        // ok 
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit stream
        if (stream) tb_async_stream_exit(stream);
        stream = tb_null;
    }

    // ok?
    return stream;
}
tb_bool_t tb_async_stream_exit(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("exit: %s: ..", tb_url_cstr(&impl->url));

    // kill it first
    tb_async_stream_kill(stream);

    // try closing it
    tb_size_t tryn = 30;
    tb_bool_t ok = tb_false;
    while (!(ok = tb_async_stream_clos_try(stream)) && tryn--)
    {
        // wait some time
        tb_msleep(200);
    }

    // close failed?
    if (!ok)
    {
        // trace
        tb_trace_e("exit: %s: failed!", tb_url_cstr(&impl->url));
        return tb_false;
    }

    // exit it
    if (impl->exit && !impl->exit(stream)) return tb_false;

    // exit url
    tb_url_exit(&impl->url);

    // exit rcache
    tb_buffer_exit(&impl->rcache_data);

    // exit wcache
    tb_buffer_exit(&impl->wcache_data);

    // free it
    tb_align8_free(impl);

    // trace
    tb_trace_d("exit: ok");

    // ok
    return tb_true;
}
tb_url_ref_t tb_async_stream_url(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_null);

    // get the url
    return &impl->url;
}
tb_size_t tb_async_stream_type(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, TB_STREAM_TYPE_NONE);

    // the type
    return impl->type;
}
tb_hong_t tb_async_stream_size(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // get the size
    tb_hong_t size = -1;
    return tb_async_stream_ctrl((tb_async_stream_ref_t)stream, TB_STREAM_CTRL_GET_SIZE, &size)? size : -1;
}
tb_hize_t tb_async_stream_left(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);
    
    // the size
    tb_hong_t size = tb_async_stream_size(stream);
    tb_check_return_val(size >= 0, -1);

    // the offset
    tb_hize_t offset = tb_async_stream_offset(stream);
    tb_assert_and_check_return_val(offset <= size, 0);

    // the left
    return size - offset;
}
tb_bool_t tb_async_stream_beof(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_true);

    // size
    tb_hong_t size = tb_async_stream_size(stream);
    tb_hize_t offt = tb_async_stream_offset(stream);

    // eof?
    return (size > 0 && offt >= size)? tb_true : tb_false;
}
tb_hize_t tb_async_stream_offset(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // get the offset
    tb_hize_t offset = 0;
    return tb_async_stream_ctrl((tb_async_stream_ref_t)stream, TB_STREAM_CTRL_GET_OFFSET, &offset)? offset : 0;
}
tb_bool_t tb_async_stream_is_opened(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // the state
    tb_size_t state = tb_atomic_get(&impl->istate);

    // is opened?
    return (TB_STATE_OPENED == state || TB_STATE_KILLING == state)? tb_true : tb_false;
}
tb_bool_t tb_async_stream_is_closed(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // the state
    tb_size_t state = tb_atomic_get(&impl->istate);

    // is closed?
    return (TB_STATE_CLOSED == state || TB_STATE_KILLED == state)? tb_true : tb_false;
}
tb_bool_t tb_async_stream_is_killed(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // the state
    tb_size_t state = tb_atomic_get(&impl->istate);

    // is killed?
    return (TB_STATE_KILLED == state || TB_STATE_KILLING == state)? tb_true : tb_false;
}
tb_long_t tb_async_stream_timeout(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, -1);

    // get the timeout
    tb_long_t timeout = -1;
    return tb_async_stream_ctrl(stream, TB_STREAM_CTRL_GET_TIMEOUT, &timeout)? timeout : -1;
}
tb_bool_t tb_async_stream_ctrl(tb_async_stream_ref_t stream, tb_size_t ctrl, ...)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->ctrl, tb_false);

    // init args
    tb_va_list_t args;
    tb_va_start(args, ctrl);

    // ctrl it
    tb_bool_t ok = tb_async_stream_ctrl_with_args(stream, ctrl, args);

    // exit args
    tb_va_end(args);

    // ok?
    return ok;
}
tb_bool_t tb_async_stream_ctrl_with_args(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{   
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->ctrl, tb_false);

    // save args
    tb_va_list_t args_saved;
    tb_va_copy(args_saved, args);

    // ctrl
    tb_bool_t ok = tb_false;
    switch (ctrl)
    {
    case TB_STREAM_CTRL_SET_URL:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);

            // set url
            tb_char_t const* url = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            if (url && tb_url_cstr_set(&impl->url, url)) ok = tb_true;
        }
        break;
    case TB_STREAM_CTRL_GET_URL:
        {
            // get url
            tb_char_t const** purl = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            if (purl)
            {
                tb_char_t const* url = tb_url_cstr(&impl->url);
                if (url)
                {
                    *purl = url;
                    ok = tb_true;
                }
            }
        }
        break;
    case TB_STREAM_CTRL_SET_HOST:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);

            // set host
            tb_char_t const* host = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            if (host)
            {
                tb_url_host_set(&impl->url, host);
                ok = tb_true;
            }
        }
        break;
    case TB_STREAM_CTRL_GET_HOST:
        {
            // get host
            tb_char_t const** phost = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            if (phost)
            {
                tb_char_t const* host = tb_url_host(&impl->url);
                if (host)
                {
                    *phost = host;
                    ok = tb_true;
                }
            }
        }
        break;
    case TB_STREAM_CTRL_SET_PORT:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);

            // set port
            tb_size_t port = (tb_size_t)tb_va_arg(args, tb_size_t);
            if (port)
            {
                tb_url_port_set(&impl->url, (tb_uint16_t)port);
                ok = tb_true;
            }
        }
        break;
    case TB_STREAM_CTRL_GET_PORT:
        {
            // get port
            tb_size_t* pport = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            if (pport)
            {
                *pport = tb_url_port(&impl->url);
                ok = tb_true;
            }
        }
        break;
    case TB_STREAM_CTRL_SET_PATH:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);

            // set path
            tb_char_t const* path = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            if (path)
            {
                tb_url_path_set(&impl->url, path);
                ok = tb_true;
            }
        }
        break;
    case TB_STREAM_CTRL_GET_PATH:
        {
            // get path
            tb_char_t const** ppath = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            if (ppath)
            {
                tb_char_t const* path = tb_url_path(&impl->url);
                if (path)
                {
                    *ppath = path;
                    ok = tb_true;
                }
            }
        }
        break;
    case TB_STREAM_CTRL_SET_SSL:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);

            // set ssl
            tb_bool_t bssl = (tb_bool_t)tb_va_arg(args, tb_bool_t);
            tb_url_ssl_set(&impl->url, bssl);
            ok = tb_true;
        }
        break;
    case TB_STREAM_CTRL_GET_SSL:
        {
            // get ssl
            tb_bool_t* pssl = (tb_bool_t*)tb_va_arg(args, tb_bool_t*);
            if (pssl)
            {
                *pssl = tb_url_ssl(&impl->url);
                ok = tb_true;
            }
        }
        break;
    case TB_STREAM_CTRL_SET_TIMEOUT:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);

            // set timeout
            tb_long_t timeout = (tb_long_t)tb_va_arg(args, tb_long_t);
            impl->timeout = timeout? timeout : TB_STREAM_DEFAULT_TIMEOUT;
            ok = tb_true;
        }
        break;
    case TB_STREAM_CTRL_GET_TIMEOUT:
        {
            // get timeout
            tb_long_t* ptimeout = (tb_long_t*)tb_va_arg(args, tb_long_t*);
            if (ptimeout)
            {
                *ptimeout = impl->timeout;
                ok = tb_true;
            }
        }
        break;
    default:
        break;
    }

    // restore args
    tb_va_copy(args, args_saved);

    // ctrl stream
    ok = (impl->ctrl(stream, ctrl, args) || ok)? tb_true : tb_false;

    // ok?
    return ok;
}
tb_void_t tb_async_stream_kill(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("kill: %s: state: %s: ..", tb_url_cstr(&impl->url), tb_state_cstr(tb_atomic_get(&impl->istate)));

    // opened? kill it
    if (TB_STATE_OPENED == tb_atomic_fetch_and_pset(&impl->istate, TB_STATE_OPENED, TB_STATE_KILLING))
    {
        // kill it
        if (impl->kill) impl->kill(stream);

        // trace
        tb_trace_d("kill: %s: ok", tb_url_cstr(&impl->url));
    }
    // opening? kill it
    else if (TB_STATE_OPENING == tb_atomic_fetch_and_pset(&impl->istate, TB_STATE_OPENING, TB_STATE_KILLING))
    {
        // kill it
        if (impl->kill) impl->kill(stream);

        // trace
        tb_trace_d("kill: %s: ok", tb_url_cstr(&impl->url));
    }
    else 
    {
        // closed? killed
        tb_atomic_pset(&impl->istate, TB_STATE_CLOSED, TB_STATE_KILLED);
    }
}
tb_bool_t tb_async_stream_open_try(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // not supported?
    if (!impl->open_try) return tb_async_stream_is_opened(stream);
     
    // trace
    tb_trace_d("open: try: %s: ..", tb_url_cstr(&impl->url));

    // set opening
    tb_size_t state = tb_atomic_fetch_and_pset(&impl->istate, TB_STATE_CLOSED, TB_STATE_OPENING);

    // opened?
    tb_check_return_val(state != TB_STATE_OPENED, tb_true);

    // must be closed
    tb_assert_and_check_return_val(state == TB_STATE_CLOSED, tb_false);

    // try opening it
    tb_bool_t ok = impl->open_try(stream);

    // trace
    tb_trace_d("open: try: %s: %s", tb_url_cstr(&impl->url), ok? "ok" : "no");

    // ok?
    return ok;
}
tb_bool_t tb_async_stream_open_(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->open && func, tb_false);
    
    // trace
    tb_trace_d("open: %s: ..", tb_url_cstr(&impl->url));

    // try opening ok? done func directly
    if (tb_async_stream_open_try(stream))
    {
        // done func
        func(stream, TB_STATE_OK, priv);
        return tb_true;
    }

    // set opening
    tb_size_t state = tb_atomic_fetch_and_pset(&impl->istate, TB_STATE_CLOSED, TB_STATE_OPENING);

    // must be closed
    tb_assert_and_check_return_val(state == TB_STATE_CLOSED, tb_false);

    // open it
    return impl->open(stream, func, priv);
}
tb_bool_t tb_async_stream_clos_try(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // not supported?
    if (!impl->clos_try) return tb_async_stream_is_closed(stream);
     
    // trace
    tb_trace_d("clos: try: %s: ..", tb_url_cstr(&impl->url));

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // closed?
        if (TB_STATE_CLOSED == tb_atomic_get(&impl->istate))
        {
            ok = tb_true;
            break;
        }

        // try closing it
        ok = impl->clos_try(stream);

    } while (0);

    // trace
    tb_trace_d("clos: try: %s: %s", tb_url_cstr(&impl->url), ok? "ok" : "no");
         
    // ok?
    return ok;
}
tb_bool_t tb_async_stream_clos_(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->clos && func, tb_false);

    // trace
    tb_trace_d("clos: %s: ..", tb_url_cstr(&impl->url));

    // try closing ok? done func directly
    if (tb_async_stream_clos_try(stream))
    {
        // done func
        func(stream, TB_STATE_OK, priv);
        return tb_true;
    }

    // save debug info
#ifdef __tb_debug__
    impl->func = func_;
    impl->file = file_;
    impl->line = line_;
#endif

    // clos it
    return impl->clos(stream, func, priv);
}
tb_bool_t tb_async_stream_read_(tb_async_stream_ref_t stream, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // read it
    return tb_async_stream_read_after_(stream, 0, size, func, priv __tb_debug_args__);
}
tb_bool_t tb_async_stream_writ_(tb_async_stream_ref_t stream, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // writ it
    return tb_async_stream_writ_after_(stream, 0, data, size, func, priv __tb_debug_args__);
}
tb_bool_t tb_async_stream_seek_(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->seek && func, tb_false);
   
    // check state
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->istate), tb_false);

    // save debug info
#ifdef __tb_debug__
    impl->func = func_;
    impl->file = file_;
    impl->line = line_;
#endif

    // have writed cache? sync it first
    if (impl->wcache_maxn && tb_buffer_size(&impl->wcache_data))
    {
        // init sync and seek
        impl->sync_and.seek.func = func;
        impl->sync_and.seek.priv = priv;
        impl->sync_and.seek.offset = offset;
        return tb_async_stream_sync_(stream, tb_false, tb_async_stream_sync_seek_func, &impl->sync_and.seek __tb_debug_args__);
    }

    // offset be not modified?
    if (tb_async_stream_offset(stream) == offset)
    {
        func(stream, TB_STATE_OK, offset, priv);
        return tb_true;
    }

    // seek it
    return impl->seek(stream, offset, func, priv);
}
tb_bool_t tb_async_stream_sync_(tb_async_stream_ref_t stream, tb_bool_t bclosing, tb_async_stream_sync_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->sync && func, tb_false);
    
    // check state
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->istate), tb_false);

    // save debug info
#ifdef __tb_debug__
    impl->func = func_;
    impl->file = file_;
    impl->line = line_;
#endif
    
    // using cache?
    tb_bool_t ok = tb_false;
    if (impl->wcache_maxn)
    {
        // sync the cache data 
        tb_byte_t*  data = tb_buffer_data(&impl->wcache_data);
        tb_size_t   size = tb_buffer_size(&impl->wcache_data);
        if (data && size)
        {
            // writ the cache data
            impl->wcache_and.sync.func        = func;
            impl->wcache_and.sync.bclosing    = bclosing;
            ok = impl->writ(stream, 0, data, size, tb_async_stream_cache_sync_func, priv);
        }
        // sync it
        else ok = impl->sync(stream, bclosing, func, priv);
    }
    // sync it
    else ok = impl->sync(stream, bclosing, func, priv);

    // ok?
    return ok;
}
tb_bool_t tb_async_stream_task_(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->task && func, tb_false);
    
    // check state
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->istate), tb_false);

    // save debug info
#ifdef __tb_debug__
    impl->func = func_;
    impl->file = file_;
    impl->line = line_;
#endif
 
    // task it
    return impl->task(stream, delay, func, priv);
}
tb_bool_t tb_async_stream_open_read_(tb_async_stream_ref_t stream, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->open && impl->read && func, tb_false);

    // no opened? open it first
    if (TB_STATE_CLOSED == tb_atomic_get(&impl->istate))
    {
        // init open and read
        impl->open_and.read.func = func;
        impl->open_and.read.priv = priv;
        impl->open_and.read.size = size;
        return tb_async_stream_open_(stream, tb_async_stream_open_read_func, &impl->open_and.read __tb_debug_args__);
    }

    // read it
    return tb_async_stream_read_(stream, size, func, priv __tb_debug_args__);
}
tb_bool_t tb_async_stream_open_writ_(tb_async_stream_ref_t stream, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->open && impl->writ && data && size && func, tb_false);

    // no opened? open it first
    if (TB_STATE_CLOSED == tb_atomic_get(&impl->istate))
    {
        // init open and writ
        impl->open_and.writ.func = func;
        impl->open_and.writ.priv = priv;
        impl->open_and.writ.data = data;
        impl->open_and.writ.size = size;
        return tb_async_stream_open_(stream, tb_async_stream_open_writ_func, &impl->open_and.writ __tb_debug_args__);
    }

    // writ it
    return tb_async_stream_writ_(stream, data, size, func, priv __tb_debug_args__);
}
tb_bool_t tb_async_stream_open_seek_(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->open && impl->seek && func, tb_false);

    // no opened? open it first
    if (TB_STATE_CLOSED == tb_atomic_get(&impl->istate))
    {
        // init open and seek
        impl->open_and.seek.func = func;
        impl->open_and.seek.priv = priv;
        impl->open_and.seek.offset = offset;
        return tb_async_stream_open_(stream, tb_async_stream_open_seek_func, &impl->open_and.seek __tb_debug_args__);
    }

    // seek it
    return tb_async_stream_seek_(stream, offset, func, priv __tb_debug_args__);
}
tb_bool_t tb_async_stream_read_after_(tb_async_stream_ref_t stream, tb_size_t delay, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->read && func, tb_false);
    
    // check state
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->istate), tb_false);

    // save debug info
#ifdef __tb_debug__
    impl->func = func_;
    impl->file = file_;
    impl->line = line_;
#endif

    // have writed cache? sync it first
    if (impl->wcache_maxn && tb_buffer_size(&impl->wcache_data))
    {
        // init sync and read
        impl->sync_and.read.func = func;
        impl->sync_and.read.priv = priv;
        impl->sync_and.read.size = size;
        return tb_async_stream_sync_(stream, tb_false, tb_async_stream_sync_read_func, &impl->sync_and.read __tb_debug_args__);
    }

    // read it
    return tb_async_stream_cache_read_done(stream, delay, size, func, priv);
}
tb_bool_t tb_async_stream_writ_after_(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl && impl->writ && data && size && func, tb_false);
    
    // check state
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->istate), tb_false);

    // save debug info
#ifdef __tb_debug__
    impl->func = func_;
    impl->file = file_;
    impl->line = line_;
#endif

    // writ it 
    return tb_async_stream_cache_writ_done(stream, delay, data, size, func, priv);
}
tb_aicp_ref_t tb_async_stream_aicp(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_null);

    // the aicp
    return impl->aicp;
}
#ifdef __tb_debug__
tb_char_t const* tb_async_stream_func(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_null);

    // the func
    return impl->func;
}
tb_char_t const* tb_async_stream_file(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, tb_null);

    // the file
    return impl->file;
}
tb_size_t tb_async_stream_line(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_impl_t* impl = tb_async_stream_impl(stream);
    tb_assert_and_check_return_val(impl, 0);

    // the line
    return impl->line;
}
#endif
