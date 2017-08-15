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
 * @file        http.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "async_stream_http"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the http stream type
typedef struct __tb_async_stream_http_impl_t
{
    // the http 
    tb_aicp_http_ref_t                  http;

    // the size
    tb_atomic64_t                       size;

    // the offset
    tb_atomic64_t                       offset;

    // the func
    union
    {
        tb_async_stream_open_func_t     open;
        tb_async_stream_read_func_t     read;
        tb_async_stream_seek_func_t     seek;
        tb_async_stream_sync_func_t     sync;
        tb_async_stream_task_func_t     task;
        tb_async_stream_clos_func_t     clos;

    }                                   func;

    // the priv
    tb_cpointer_t                       priv;

}tb_async_stream_http_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_async_stream_http_impl_t* tb_async_stream_http_impl_cast(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_async_stream_type(stream) == TB_STREAM_TYPE_HTTP, tb_null);

    // ok?
    return (tb_async_stream_http_impl_t*)stream;
}
static tb_void_t tb_async_stream_http_impl_clos_clear(tb_async_stream_http_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl);

    // clear size 
    tb_atomic64_set(&impl->size, -1);

    // clear offset
    tb_atomic64_set0(&impl->offset);

    // clear base
    tb_async_stream_clear((tb_async_stream_ref_t)impl);
}
static tb_void_t tb_async_stream_http_impl_clos_func(tb_aicp_http_ref_t http, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast((tb_async_stream_ref_t)priv);
    tb_assert_and_check_return(impl && impl->func.clos);

    // trace
    tb_trace_d("clos: notify: ..");

    // clear it
    tb_async_stream_http_impl_clos_clear(impl);

    /* done clos func
     *
     * note: cannot use this stream after closing, the stream may be exited in the closing func
     */
    impl->func.clos((tb_async_stream_ref_t)impl, TB_STATE_OK, impl->priv);

    // trace
    tb_trace_d("clos: notify: ok");
}
static tb_bool_t tb_async_stream_http_impl_clos_try(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // try closing ok?
    if (!impl->http || tb_aicp_http_clos_try(impl->http))
    {
        // clear it
        tb_async_stream_http_impl_clos_clear(impl);

        // ok
        return tb_true;
    }

    // failed
    return tb_false;
}
static tb_bool_t tb_async_stream_http_impl_clos(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv)
{   
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->http && func, tb_false);

    // trace
    tb_trace_d("clos: %s: ..", tb_url_cstr(tb_async_stream_url(stream)));

    // init func
    impl->func.clos  = func;
    impl->priv       = priv;

    // close it
    return tb_aicp_http_clos(impl->http, tb_async_stream_http_impl_clos_func, impl);
}
static tb_bool_t tb_async_stream_http_impl_open_func(tb_aicp_http_ref_t http, tb_size_t state, tb_http_status_t const* status, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(http && status, tb_false);

    // the stream
    tb_async_stream_http_impl_t* impl = (tb_async_stream_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.open, tb_false);

    // save size
    tb_hong_t size = (!status->bgzip && !status->bdeflate && !status->bchunked)? status->document_size : -1;
    if (size >= 0) tb_atomic64_set(&impl->size, size);

    // open done
    return tb_async_stream_open_func((tb_async_stream_ref_t)impl, state, impl->func.open, impl->priv);
}
static tb_bool_t tb_async_stream_http_impl_open(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->http && func, tb_false);

    // save func and priv
    impl->priv       = priv;
    impl->func.open  = func;

    // init size and offset
    tb_atomic64_set(&impl->size, -1);
    tb_atomic64_set0(&impl->offset);
 
    // post open
    return tb_aicp_http_open(impl->http, tb_async_stream_http_impl_open_func, stream);
}
static tb_bool_t tb_async_stream_http_impl_read_func(tb_aicp_http_ref_t http, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(http, tb_false);

    // the stream
    tb_async_stream_http_impl_t* impl = (tb_async_stream_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.read, tb_false);

    // ok?
    tb_bool_t bend = tb_false;
    if (state == TB_STATE_OK) 
    {
        // save offset
        tb_hize_t offset = tb_atomic64_add_and_fetch(&impl->offset, real);

        // end? 
        tb_hong_t hsize = tb_atomic64_get(&impl->size);
        if (hsize >= 0 && offset == hsize) bend = tb_true;
    }

    // done func
    tb_bool_t ok = impl->func.read((tb_async_stream_ref_t)impl, state, data, real, size, impl->priv);

    // end? closed 
    if (ok && bend) ok = impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_CLOSED, data, 0, size, impl->priv);

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_http_impl_read(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->http && func, tb_false);

    // end? closed
    tb_hong_t hsize = tb_atomic64_get(&impl->size);
    if (hsize >= 0) 
    {
        tb_hize_t offset = tb_atomic64_get(&impl->offset);
        if (offset == hsize)
        {
            func(stream, TB_STATE_CLOSED, tb_null, 0, size, priv);
            return tb_true;
        }
    }

    // save func and priv
    impl->priv       = priv;
    impl->func.read  = func;

    // post read
    return tb_aicp_http_read_after(impl->http, delay, size, tb_async_stream_http_impl_read_func, stream);
}
static tb_bool_t tb_async_stream_http_impl_seek_func(tb_aicp_http_ref_t http, tb_size_t state, tb_hize_t offset, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(http, tb_false);

    // the stream
    tb_async_stream_http_impl_t* impl = (tb_async_stream_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.seek, tb_false);

    // save offset
    if (state == TB_STATE_OK) tb_atomic64_set(&impl->offset, offset);

    // done func
    return impl->func.seek((tb_async_stream_ref_t)impl, state, offset, impl->priv);
}
static tb_bool_t tb_async_stream_http_impl_seek(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->http && func, tb_false);

    // save func and priv
    impl->priv       = priv;
    impl->func.seek  = func;

    // post seek
    return tb_aicp_http_seek(impl->http, offset, tb_async_stream_http_impl_seek_func, stream);
}
static tb_bool_t tb_async_stream_http_impl_task_func(tb_aicp_http_ref_t http, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(http, tb_false);

    // the stream
    tb_async_stream_http_impl_t* impl = (tb_async_stream_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.task, tb_false);

    // done func
    return impl->func.task((tb_async_stream_ref_t)impl, state, impl->priv);
}
static tb_bool_t tb_async_stream_http_impl_task(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->http && func, tb_false);

    // save func and priv
    impl->priv       = priv;
    impl->func.task  = func;

    // post task
    return tb_aicp_http_task(impl->http, delay, tb_async_stream_http_impl_task_func, stream);
}
static tb_void_t tb_async_stream_http_impl_kill(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("kill: %s: ..", tb_url_cstr(tb_async_stream_url(stream)));

    // kill it
    if (impl->http) tb_aicp_http_kill(impl->http);
}
static tb_bool_t tb_async_stream_http_impl_exit(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // exit it
    if (impl->http) tb_aicp_http_exit(impl->http);
    impl->http = tb_null;

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_http_impl_ctrl(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->http, tb_false);

    // done
    switch (ctrl)
    {
    case TB_STREAM_CTRL_GET_SIZE:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_opened(stream) && impl->http, tb_false);

            // get size
            tb_hong_t* psize = (tb_hong_t*)tb_va_arg(args, tb_hong_t*);
            tb_assert_and_check_return_val(psize, tb_false);
            *psize = (tb_hong_t)tb_atomic64_get(&impl->size);
            return tb_true;
        }
    case TB_STREAM_CTRL_GET_OFFSET:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_opened(stream) && impl->http, tb_false);

            // get offset
            tb_hize_t* poffset = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(poffset, tb_false);
            *poffset = (tb_hize_t)tb_atomic64_get(&impl->offset);
            return tb_true;
        }
    case TB_STREAM_CTRL_SET_URL:
        {
            // url
            tb_char_t const* url = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(url, tb_false);
        
            // set url
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_URL, url);
        }
        break;
    case TB_STREAM_CTRL_GET_URL:
        {
            // purl
            tb_char_t const** purl = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(purl, tb_false);
    
            // get url
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_URL, purl);
        }
        break;
    case TB_STREAM_CTRL_SET_HOST:
        {
            // host
            tb_char_t const* host = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(host, tb_false);
    
            // set host
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_HOST, host);
        }
        break;
    case TB_STREAM_CTRL_GET_HOST:
        {
            // phost
            tb_char_t const** phost = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(phost, tb_false); 

            // get host
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_HOST, phost);
        }
        break;
    case TB_STREAM_CTRL_SET_PORT:
        {
            // port
            tb_size_t port = (tb_size_t)tb_va_arg(args, tb_size_t);
            tb_assert_and_check_return_val(port, tb_false);
    
            // set port
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_PORT, port);
        }
        break;
    case TB_STREAM_CTRL_GET_PORT:
        {
            // pport
            tb_size_t* pport = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pport, tb_false);
    
            // get port
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_PORT, pport);
        }
        break;
    case TB_STREAM_CTRL_SET_PATH:
        {
            // path
            tb_char_t const* path = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(path, tb_false);
    
            // set path
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_PATH, path);
        }
        break;
    case TB_STREAM_CTRL_GET_PATH:
        {
            // ppath
            tb_char_t const** ppath = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(ppath, tb_false);
    
            // get path
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_PATH, ppath);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_METHOD:
        {
            // method
            tb_size_t method = (tb_size_t)tb_va_arg(args, tb_size_t);
    
            // set method
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_METHOD, method);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_METHOD:
        {
            // pmethod
            tb_size_t* pmethod = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pmethod, tb_false);
    
            // get method
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_METHOD, pmethod);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_HEAD:
        {
            // key
            tb_char_t const* key = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(key, tb_false);

            // val
            tb_char_t const* val = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(val, tb_false);
    
            // set head
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_HEAD, key, val);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_HEAD:
        {
            // key
            tb_char_t const* key = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(key, tb_false);

            // pval
            tb_char_t const** pval = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(pval, tb_false);
    
            // get head
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_HEAD, key, pval);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_HEAD_FUNC:
        {
            // head_func
            tb_http_head_func_t head_func = (tb_http_head_func_t)tb_va_arg(args, tb_http_head_func_t);

            // set head_func
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_HEAD_FUNC, head_func);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_HEAD_FUNC:
        {
            // phead_func
            tb_http_head_func_t* phead_func = (tb_http_head_func_t*)tb_va_arg(args, tb_http_head_func_t*);
            tb_assert_and_check_return_val(phead_func, tb_false);

            // get head_func
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_HEAD_FUNC, phead_func);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_HEAD_PRIV:
        {
            // head_priv
            tb_pointer_t head_priv = (tb_pointer_t)tb_va_arg(args, tb_pointer_t);

            // set head_priv
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_HEAD_PRIV, head_priv);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_HEAD_PRIV:
        {
            // phead_priv
            tb_pointer_t* phead_priv = (tb_pointer_t*)tb_va_arg(args, tb_pointer_t*);
            tb_assert_and_check_return_val(phead_priv, tb_false);

            // get head_priv
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_HEAD_PRIV, phead_priv);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_RANGE:
        {
            tb_hize_t bof = (tb_hize_t)tb_va_arg(args, tb_hize_t);
            tb_hize_t eof = (tb_hize_t)tb_va_arg(args, tb_hize_t);
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_RANGE, bof, eof);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_RANGE:
        {
            // pbof
            tb_hize_t* pbof = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(pbof, tb_false);

            // peof
            tb_hize_t* peof = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(peof, tb_false);

            // ok
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_RANGE, pbof, peof);
        }
        break;
    case TB_STREAM_CTRL_SET_SSL:
        {
            // bssl
            tb_bool_t bssl = (tb_bool_t)tb_va_arg(args, tb_bool_t);
    
            // set ssl
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_SSL, bssl);
        }
        break;
    case TB_STREAM_CTRL_GET_SSL:
        {
            // pssl
            tb_bool_t* pssl = (tb_bool_t*)tb_va_arg(args, tb_bool_t*);
            tb_assert_and_check_return_val(pssl, tb_false);

            // get ssl
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_SSL, pssl);
        }
        break;
    case TB_STREAM_CTRL_SET_TIMEOUT:
        {
            // timeout
            tb_size_t timeout = (tb_size_t)tb_va_arg(args, tb_size_t);
            tb_assert_and_check_return_val(timeout, tb_false);
    
            // set timeout
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_TIMEOUT, timeout);
        }
        break;
    case TB_STREAM_CTRL_GET_TIMEOUT:
        {
            // ptimeout
            tb_size_t* ptimeout = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(ptimeout, tb_false);
    
            // get timeout
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_TIMEOUT, ptimeout);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_POST_URL:
        {
            // url
            tb_char_t const* url = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(url, tb_false);
            
            // set url
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_POST_URL, url);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_POST_URL:
        {
            // purl
            tb_char_t const** purl = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(purl, tb_false);

            // get url
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_POST_URL, purl);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_POST_DATA:
        {
            // post data
            tb_byte_t const*    data = (tb_byte_t const*)tb_va_arg(args, tb_byte_t const*);

            // post size
            tb_size_t           size = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set post data
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_POST_DATA, data, size);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_POST_DATA:
        {
            // pdata and psize
            tb_byte_t const**   pdata = (tb_byte_t const**)tb_va_arg(args, tb_byte_t const**);
            tb_size_t*          psize = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pdata && psize, tb_false);

            // get post data and size
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_POST_DATA, pdata, psize);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_POST_FUNC:
        {
            // func
            tb_http_post_func_t func = (tb_http_post_func_t)tb_va_arg(args, tb_http_post_func_t);

            // set post func
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_POST_FUNC, func);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_POST_FUNC:
        {
            // pfunc
            tb_http_post_func_t* pfunc = (tb_http_post_func_t*)tb_va_arg(args, tb_http_post_func_t*);
            tb_assert_and_check_return_val(pfunc, tb_false);

            // get post func
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_POST_FUNC, pfunc);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_POST_PRIV:
        {
            // post priv
            tb_cpointer_t priv = (tb_pointer_t)tb_va_arg(args, tb_pointer_t);

            // set post priv
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_POST_PRIV, priv);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_POST_PRIV:
        {
            // ppost priv
            tb_pointer_t* ppriv = (tb_pointer_t*)tb_va_arg(args, tb_pointer_t*);
            tb_assert_and_check_return_val(ppriv, tb_false);

            // get post priv
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_POST_PRIV, ppriv);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_POST_LRATE:
        {
            // post lrate
            tb_size_t lrate = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set post lrate
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_POST_LRATE, lrate);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_POST_LRATE:
        {
            // ppost lrate
            tb_size_t* plrate = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(plrate, tb_false);

            // get post lrate
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_POST_LRATE, plrate);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_AUTO_UNZIP:
        {
            // bunzip
            tb_bool_t bunzip = (tb_bool_t)tb_va_arg(args, tb_bool_t);

            // set bunzip
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_AUTO_UNZIP, bunzip);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_AUTO_UNZIP:
        {
            // pbunzip
            tb_bool_t* pbunzip = (tb_bool_t*)tb_va_arg(args, tb_bool_t*);
            tb_assert_and_check_return_val(pbunzip, tb_false);

            // get bunzip
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_AUTO_UNZIP, pbunzip);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_REDIRECT:
        {
            // redirect
            tb_size_t redirect = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set redirect
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_REDIRECT, redirect);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_REDIRECT:
        {
            // predirect
            tb_size_t* predirect = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(predirect, tb_false);

            // get redirect
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_REDIRECT, predirect);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_VERSION:
        {
            // version
            tb_size_t version = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set version
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_VERSION, version);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_VERSION:
        {
            // pversion
            tb_size_t* pversion = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pversion, tb_false);

            // get version
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_VERSION, pversion);
        }
        break;
    case TB_STREAM_CTRL_HTTP_SET_COOKIES:
        {
            // cookies
            tb_cookies_ref_t cookies = (tb_cookies_ref_t)tb_va_arg(args, tb_cookies_ref_t);

            // set cookies
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_SET_COOKIES, cookies);
        }
        break;
    case TB_STREAM_CTRL_HTTP_GET_COOKIES:
        {
            // pcookies
            tb_cookies_ref_t* pcookies = (tb_cookies_ref_t*)tb_va_arg(args, tb_cookies_ref_t*);
            tb_assert_and_check_return_val(pcookies, tb_false);

            // get version
            return tb_aicp_http_ctrl(impl->http, TB_HTTP_OPTION_GET_COOKIES, pcookies);
        }
        break;
    default:
        break;
    }
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_async_stream_ref_t tb_async_stream_init_http(tb_aicp_ref_t aicp)
{
    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   stream = tb_null;
    do
    {
        // init stream
        stream = tb_async_stream_init(  aicp
                                    ,   TB_STREAM_TYPE_HTTP
                                    ,   sizeof(tb_async_stream_http_impl_t)
                                    ,   0
                                    ,   0
                                    ,   tb_null
                                    ,   tb_async_stream_http_impl_clos_try
                                    ,   tb_async_stream_http_impl_open
                                    ,   tb_async_stream_http_impl_clos
                                    ,   tb_async_stream_http_impl_exit
                                    ,   tb_async_stream_http_impl_kill
                                    ,   tb_async_stream_http_impl_ctrl
                                    ,   tb_async_stream_http_impl_read
                                    ,   tb_null
                                    ,   tb_async_stream_http_impl_seek
                                    ,   tb_null
                                    ,   tb_async_stream_http_impl_task);
        tb_assert_and_check_break(stream);

        // init the stream impl
        tb_async_stream_http_impl_t* impl = tb_async_stream_http_impl_cast(stream);
        tb_assert_and_check_break(impl);

        // init http
        impl->http = tb_aicp_http_init(tb_async_stream_aicp(stream));
        tb_assert_and_check_break(impl->http);

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
tb_async_stream_ref_t tb_async_stream_init_from_http(tb_aicp_ref_t aicp, tb_char_t const* host, tb_uint16_t port, tb_char_t const* path, tb_bool_t bssl)
{
    // check
    tb_assert_and_check_return_val(host && port && path, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   stream = tb_null;
    do
    {
        // init stream
        stream = tb_async_stream_init_http(aicp);
        tb_assert_and_check_break(stream);

        // ctrl
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_HOST, host)) break;
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_PORT, port)) break;
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_PATH, path)) break;
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_SSL, bssl)) break;
    
        // check
        tb_assert_static(!(tb_offsetof(tb_async_stream_http_impl_t, size) & (sizeof(tb_atomic64_t) - 1)));
        tb_assert_static(!(tb_offsetof(tb_async_stream_http_impl_t, offset) & (sizeof(tb_atomic64_t) - 1)));

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

