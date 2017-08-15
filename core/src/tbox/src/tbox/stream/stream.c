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
 * @file        stream.c
 * @ingroup     stream
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "stream"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "stream.h"
#include "impl/stream.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../memory/memory.h"
#include "../string/string.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_stream_ref_t tb_stream_init(     tb_size_t type
                                ,   tb_size_t type_size
                                ,   tb_size_t cache
                                ,   tb_bool_t (*open)(tb_stream_ref_t self)
                                ,   tb_bool_t (*clos)(tb_stream_ref_t self)
                                ,   tb_void_t (*exit)(tb_stream_ref_t self)
                                ,   tb_bool_t (*ctrl)(tb_stream_ref_t self, tb_size_t ctrl, tb_va_list_t args)
                                ,   tb_long_t (*wait)(tb_stream_ref_t self, tb_size_t wait, tb_long_t timeout)
                                ,   tb_long_t (*read)(tb_stream_ref_t self, tb_byte_t* data, tb_size_t size)
                                ,   tb_long_t (*writ)(tb_stream_ref_t self, tb_byte_t const* data, tb_size_t size)
                                ,   tb_bool_t (*seek)(tb_stream_ref_t self, tb_hize_t offset)
                                ,   tb_bool_t (*sync)(tb_stream_ref_t self, tb_bool_t bclosing)
                                ,   tb_void_t (*kill)(tb_stream_ref_t self))
{
    // check
    tb_assert_and_check_return_val(type_size, tb_null);
    tb_assert_and_check_return_val(open && clos && ctrl && wait, tb_null);
    tb_assert_and_check_return_val(read || writ, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_t*        stream = tb_null;
    tb_stream_ref_t     stream_ref = tb_null;
    do
    {
        // make stream
        stream = (tb_stream_t*)tb_malloc0(sizeof(tb_stream_t) + type_size);
        tb_assert_and_check_break(stream);

        // init stream referenced
        stream_ref = (tb_stream_ref_t)&stream[1];

        // init type
        stream->type = (tb_uint8_t)type;

        // init timeout, 10s
        stream->timeout = TB_STREAM_DEFAULT_TIMEOUT;

        // init internal state
        stream->istate = TB_STATE_CLOSED;

        // init url
        if (!tb_url_init(&stream->url)) break;

        // init cache
        if (!tb_queue_buffer_init(&stream->cache, cache)) break;

        // init func
        stream->open = open;
        stream->clos = clos;
        stream->exit = exit;
        stream->ctrl = ctrl;
        stream->wait = wait;
        stream->read = read;
        stream->writ = writ;
        stream->seek = seek;
        stream->sync = sync;
        stream->kill = kill;

        // ok
        ok = tb_true;

    } while (0);

    // failed? 
    if (!ok)
    {
        // exit it
        if (stream_ref) tb_stream_exit(stream_ref);
        stream_ref = tb_null;
    }

    // ok?
    return stream_ref;
}
tb_stream_ref_t tb_stream_init_from_url(tb_char_t const* url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // the init
    static tb_stream_ref_t (*s_init[])() = 
    {
        tb_null
    ,   tb_stream_init_file
    ,   tb_stream_init_sock
    ,   tb_stream_init_http
    ,   tb_stream_init_data
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
        tb_trace_e("unknown self for url: %s", url);
        return tb_null;
    }
    tb_assert_and_check_return_val(type && type < tb_arrayn(s_init) && s_init[type], tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     self = tb_null;
    do
    {
        // init self
        self = s_init[type]();
        tb_assert_and_check_break(self);

        // init url
        if (!tb_stream_ctrl(self, TB_STREAM_CTRL_SET_URL, url)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit self
        if (self) tb_stream_exit(self);
        self = tb_null;
    }

    // ok?
    return self;
}
tb_void_t tb_stream_exit(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return(stream);

    // close it
    tb_stream_clos(self);

    // exit it
    if (stream->exit) stream->exit(self);

    // exit cache
    tb_queue_buffer_exit(&stream->cache);

    // exit url
    tb_url_exit(&stream->url);

    // free it
    tb_free(stream);
}
tb_long_t tb_stream_wait(tb_stream_ref_t self, tb_size_t wait, tb_long_t timeout)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream && stream->wait, -1);

    // stoped?
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&stream->istate), -1);

    // wait it
    tb_long_t ok = stream->wait(self, wait, timeout);
    
    // wait failed? save state
    if (ok < 0 && !stream->state) stream->state = TB_STATE_WAIT_FAILED;

    // ok?
    tb_check_return_val(!ok, ok);

    // cached?
    if (tb_queue_buffer_maxn(&stream->cache))
    {
        // have read cache?
        if ((wait & TB_STREAM_WAIT_READ) && !stream->bwrited && !tb_queue_buffer_null(&stream->cache)) 
            ok |= TB_STREAM_WAIT_READ;
        // have writ cache?
        else if ((wait & TB_STREAM_WAIT_WRIT) && stream->bwrited && !tb_queue_buffer_full(&stream->cache))
            ok |= TB_STREAM_WAIT_WRIT;
    }

    // ok?
    return ok;
}
tb_size_t tb_stream_state(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, TB_STATE_UNKNOWN_ERROR);

    // the self state
    return stream->state;
}
tb_void_t tb_stream_state_set(tb_stream_ref_t self, tb_size_t state)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return(stream);

    // set the self state
    stream->state = state;
}
tb_size_t tb_stream_type(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, TB_STREAM_TYPE_NONE);

    // the type
    return stream->type;
}
tb_hong_t tb_stream_size(tb_stream_ref_t self)
{
    // check
    tb_assert_and_check_return_val(self, 0);

    // get the size
    tb_hong_t size = -1;
    return tb_stream_ctrl((tb_stream_ref_t)self, TB_STREAM_CTRL_GET_SIZE, &size)? size : -1;
}
tb_hize_t tb_stream_left(tb_stream_ref_t self)
{
    // check
    tb_assert_and_check_return_val(self, 0);
    
    // the size
    tb_hong_t size = tb_stream_size(self);
    tb_check_return_val(size >= 0, -1);

    // the offset
    tb_hize_t offset = tb_stream_offset(self);
    tb_assert_and_check_return_val(offset <= size, 0);

    // the left
    return size - offset;
}
tb_bool_t tb_stream_beof(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, tb_true);

    // wait failed? eof
    tb_check_return_val(stream->state != TB_STATE_WAIT_FAILED, tb_true);

    // size
    tb_hong_t size      = tb_stream_size(self);
    tb_hize_t offset    = tb_stream_offset(self);

    // eof?
    return (size > 0 && offset >= size)? tb_true : tb_false;
}
tb_hize_t tb_stream_offset(tb_stream_ref_t self)
{
    // check
    tb_assert_and_check_return_val(self, 0);

    // get the offset
    tb_hize_t offset = 0;
    return tb_stream_ctrl(self, TB_STREAM_CTRL_GET_OFFSET, &offset)? offset : 0;
}
tb_url_ref_t tb_stream_url(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, tb_null);

    // get the url
    return &stream->url;
}
tb_long_t tb_stream_timeout(tb_stream_ref_t self)
{
    // check
    tb_assert_and_check_return_val(self, -1);

    // get the timeout
    tb_long_t timeout = -1;
    return tb_stream_ctrl(self, TB_STREAM_CTRL_GET_TIMEOUT, &timeout)? timeout : -1;
}
tb_bool_t tb_stream_is_opened(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, tb_false);

    // the state
    tb_size_t state = tb_atomic_get(&stream->istate);
    
    // is opened?
    return (TB_STATE_OPENED == state || TB_STATE_KILLING == state)? tb_true : tb_false;
}
tb_bool_t tb_stream_is_closed(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, tb_false);

    // the state
    tb_size_t state = tb_atomic_get(&stream->istate);

    // is closed?
    return (TB_STATE_CLOSED == state || TB_STATE_KILLED == state)? tb_true : tb_false;
}
tb_bool_t tb_stream_is_killed(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, tb_false);

    // the state
    tb_size_t state = tb_atomic_get(&stream->istate);

    // is killed?
    return (TB_STATE_KILLED == state || TB_STATE_KILLING == state)? tb_true : tb_false;
}
tb_bool_t tb_stream_ctrl(tb_stream_ref_t self, tb_size_t ctrl, ...)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream && stream->ctrl, tb_false);

    // init args
    tb_va_list_t args;
    tb_va_start(args, ctrl);

    // ctrl it
    tb_bool_t ok = tb_stream_ctrl_with_args(self, ctrl, args);

    // exit args
    tb_va_end(args);

    // ok?
    return ok;
}
tb_bool_t tb_stream_ctrl_with_args(tb_stream_ref_t self, tb_size_t ctrl, tb_va_list_t args)
{   
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream && stream->ctrl, tb_false);

    // save args
    tb_va_list_t args_saved;
    tb_va_copy(args_saved, args);

    // done
    tb_bool_t ok = tb_false;
    switch (ctrl)
    {
    case TB_STREAM_CTRL_GET_OFFSET:
        {
            // the poffset
            tb_hize_t* poffset = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(poffset, tb_false);

            // get offset
            *poffset = stream->offset;

            // ok
            ok = tb_true;
        }
        break;
    case TB_STREAM_CTRL_SET_URL:
        {
            // check
            tb_assert_and_check_return_val(tb_stream_is_closed(self), tb_false);

            // set url
            tb_char_t const* url = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            if (url && tb_url_cstr_set(&stream->url, url)) ok = tb_true;
        }
        break;
    case TB_STREAM_CTRL_GET_URL:
        {
            // get url
            tb_char_t const** purl = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            if (purl)
            {
                tb_char_t const* url = tb_url_cstr(&stream->url);
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
            tb_assert_and_check_return_val(tb_stream_is_closed(self), tb_false);

            // set host
            tb_char_t const* host = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            if (host)
            {
                tb_url_host_set(&stream->url, host);
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
                tb_char_t const* host = tb_url_host(&stream->url);
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
            tb_assert_and_check_return_val(tb_stream_is_closed(self), tb_false);

            // set port
            tb_size_t port = (tb_size_t)tb_va_arg(args, tb_size_t);
            if (port)
            {
                tb_url_port_set(&stream->url, (tb_uint16_t)port);
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
                *pport = tb_url_port(&stream->url);
                ok = tb_true;
            }
        }
        break;
    case TB_STREAM_CTRL_SET_PATH:
        {
            // check
            tb_assert_and_check_return_val(tb_stream_is_closed(self), tb_false);

            // set path
            tb_char_t const* path = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            if (path)
            {
                tb_url_path_set(&stream->url, path);
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
                tb_char_t const* path = tb_url_path(&stream->url);
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
            tb_assert_and_check_return_val(tb_stream_is_closed(self), tb_false);

            // set ssl
            tb_bool_t bssl = (tb_bool_t)tb_va_arg(args, tb_bool_t);
            tb_url_ssl_set(&stream->url, bssl);
            ok = tb_true;
        }
        break;
    case TB_STREAM_CTRL_GET_SSL:
        {
            // get ssl
            tb_bool_t* pssl = (tb_bool_t*)tb_va_arg(args, tb_bool_t*);
            if (pssl)
            {
                *pssl = tb_url_ssl(&stream->url);
                ok = tb_true;
            }
        }
        break;
    case TB_STREAM_CTRL_SET_TIMEOUT:
        {
            // check
            tb_assert_and_check_return_val(tb_stream_is_closed(self), tb_false);

            // set timeout
            tb_long_t timeout = (tb_long_t)tb_va_arg(args, tb_long_t);
            stream->timeout = timeout? timeout : TB_STREAM_DEFAULT_TIMEOUT;
            ok = tb_true;
        }
        break;
    case TB_STREAM_CTRL_GET_TIMEOUT:
        {
            // get timeout
            tb_long_t* ptimeout = (tb_long_t*)tb_va_arg(args, tb_long_t*);
            if (ptimeout)
            {
                *ptimeout = stream->timeout;
                ok = tb_true;
            }
        }
        break;
    default:
        break;
    }

    // restore args
    tb_va_copy(args, args_saved);

    // ctrl self
    ok = (stream->ctrl(self, ctrl, args) || ok)? tb_true : tb_false;

    // ok?
    return ok;
}
tb_void_t tb_stream_kill(tb_stream_ref_t self)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return(stream);

    // trace
    tb_trace_d("kill: %s: state: %s: ..", tb_url_cstr(&stream->url), tb_state_cstr(tb_atomic_get(&stream->istate)));

    // opened? kill it
    if (TB_STATE_OPENED == tb_atomic_fetch_and_pset(&stream->istate, TB_STATE_OPENED, TB_STATE_KILLING))
    {
        // kill it
        if (stream->kill) stream->kill(self);

        // trace
        tb_trace_d("kill: %s: ok", tb_url_cstr(&stream->url));
    }
    // opening? kill it
    else if (TB_STATE_OPENING == tb_atomic_fetch_and_pset(&stream->istate, TB_STATE_OPENING, TB_STATE_KILLING))
    {
        // kill it
        if (stream->kill) stream->kill(self);

        // trace
        tb_trace_d("kill: %s: ok", tb_url_cstr(&stream->url));
    }
    else 
    {
        // closed? killed
        tb_atomic_pset(&stream->istate, TB_STATE_CLOSED, TB_STATE_KILLED);
    }
}
tb_bool_t tb_stream_open(tb_stream_ref_t self)
{
    // check self
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream && stream->open, tb_false);

    // already been opened?
    tb_check_return_val(!tb_stream_is_opened(self), tb_true);

    // closed?
    tb_assert_and_check_return_val(TB_STATE_CLOSED == tb_atomic_get(&stream->istate), tb_false);

    // init offset
    stream->offset = 0;

    // init state
    stream->state = TB_STATE_OK;

    // open it
    tb_bool_t ok = stream->open(self);

    // opened
    if (ok) tb_atomic_set(&stream->istate, TB_STATE_OPENED);

    // ok?
    return ok;
}
tb_bool_t tb_stream_clos(tb_stream_ref_t self)
{
    // check 
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, tb_false);

    // already been closed?
    tb_check_return_val(tb_stream_is_opened(self), tb_true);

    // flush writed data first
    if (stream->bwrited) tb_stream_sync(self, tb_true);

    // has close?
    if (stream->clos && !stream->clos(self)) return tb_false;

    // clear state
    stream->offset = 0;
    stream->bwrited = 0;
    stream->state = TB_STATE_OK;
    tb_atomic_set(&stream->istate, TB_STATE_CLOSED);

    // clear cache
    tb_queue_buffer_clear(&stream->cache);

    // ok
    return tb_true;
}
tb_bool_t tb_stream_need(tb_stream_ref_t self, tb_byte_t** data, tb_size_t size)
{
    // check 
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(data && size, tb_false);

    // check self
    tb_assert_and_check_return_val(stream && tb_stream_is_opened(self) && stream->read && stream->wait, tb_false);

    // stoped?
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&stream->istate), tb_false);

    // have writed cache? sync first
    if (stream->bwrited && !tb_queue_buffer_null(&stream->cache) && !tb_stream_sync(self, tb_false)) return tb_false;

    // switch to the read cache mode
    if (stream->bwrited && tb_queue_buffer_null(&stream->cache)) stream->bwrited = 0;

    // check the cache mode, must be read cache
    tb_assert_and_check_return_val(!stream->bwrited, tb_false);

    // not enough? grow the cache first
    if (tb_queue_buffer_maxn(&stream->cache) < size) tb_queue_buffer_resize(&stream->cache, size);

    // check
    tb_assert_and_check_return_val(tb_queue_buffer_maxn(&stream->cache) && size <= tb_queue_buffer_maxn(&stream->cache), tb_false);

    // enough?
    if (size <= tb_queue_buffer_size(&stream->cache)) 
    {
        // save data
        *data = tb_queue_buffer_head(&stream->cache);

        // ok
        return tb_true;
    }

    // enter cache for push
    tb_size_t   push = 0;
    tb_size_t   need = size - tb_queue_buffer_size(&stream->cache);
    tb_byte_t*  tail = tb_queue_buffer_push_init(&stream->cache, &push);
    tb_assert_and_check_return_val(tail && push, tb_false);
    if (push > need) push = need;

    // fill cache
    tb_size_t read = 0;
    while (read < push && (TB_STATE_OPENED == tb_atomic_get(&stream->istate)))
    {
        // read data
        tb_long_t real = stream->read(self, tail + read, push - read);
        
        // ok?
        if (real > 0)
        {
            // save read
            read += real;
        }
        // no data?
        else if (!real)
        {
            // wait
            real = stream->wait(self, TB_STREAM_WAIT_READ, tb_stream_timeout(self));

            // ok?
            tb_check_break(real > 0);
        }
        else break;
    }
    
    // leave cache for push
    tb_queue_buffer_push_exit(&stream->cache, read);

    // not enough?
    if (size > tb_queue_buffer_size(&stream->cache))
    {
        // killed? save state
        if (!stream->state && (TB_STATE_KILLING == tb_atomic_get(&stream->istate)))
            stream->state = TB_STATE_KILLED;

        // failed
        return tb_false;
    }

    // save data
    *data = tb_queue_buffer_head(&stream->cache);

    // ok
    return tb_true;
}
tb_long_t tb_stream_read(tb_stream_ref_t self, tb_byte_t* data, tb_size_t size)
{
    // check 
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(data, -1);

    // no size?
    tb_check_return_val(size, 0);

    // check self
    tb_assert_and_check_return_val(stream && tb_stream_is_opened(self) && stream->read, -1);

    // done
    tb_long_t read = 0;
    do
    {
        if (tb_queue_buffer_maxn(&stream->cache))
        {
            // switch to the read cache mode
            if (stream->bwrited && tb_queue_buffer_null(&stream->cache)) stream->bwrited = 0;

            // check the cache mode, must be read cache
            tb_assert_and_check_return_val(!stream->bwrited, -1);

            // read data from cache first
            read = tb_queue_buffer_read(&stream->cache, data, size);
            tb_check_return_val(read >= 0, -1);

            // ok?
            tb_check_break(!read);

            // cache is null now.
            tb_assert_and_check_return_val(tb_queue_buffer_null(&stream->cache), -1);

            // enter cache for push
            tb_size_t   push = 0;
            tb_byte_t*  tail = tb_queue_buffer_push_init(&stream->cache, &push);
            tb_assert_and_check_return_val(tail && push, -1);

            // push data to cache from self
            tb_assert(stream->read);
            tb_long_t   real = stream->read(self, tail, push);
            tb_check_return_val(real >= 0, -1);

            // read the left data from cache
            if (real > 0) 
            {
                // leave cache for push
                tb_queue_buffer_push_exit(&stream->cache, real);

                // read cache
                real = tb_queue_buffer_read(&stream->cache, data + read, tb_min(real, size - read));
                tb_check_return_val(real >= 0, -1);

                // save read 
                read += real;
            }
        }
        else 
        {
            // read it directly
            read = stream->read(self, data, size);
            tb_check_return_val(read >= 0, -1);
        }
    }
    while (0);

    // update offset
    stream->offset += read;

//  tb_trace_d("read: %d", read);
    return read;
}
tb_long_t tb_stream_writ(tb_stream_ref_t self, tb_byte_t const* data, tb_size_t size)
{
    // check 
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(data, -1);

    // no size?
    tb_check_return_val(size, 0);

    // check self
    tb_assert_and_check_return_val(stream && tb_stream_is_opened(self) && stream->writ, -1);

    // done
    tb_long_t writ = 0;
    do
    {
        if (tb_queue_buffer_maxn(&stream->cache))
        {
            // switch to the writ cache mode
            if (!stream->bwrited && tb_queue_buffer_null(&stream->cache)) stream->bwrited = 1;

            // check the cache mode, must be writ cache
            tb_assert_and_check_return_val(stream->bwrited, -1);

            // writ data to cache first
            writ = tb_queue_buffer_writ(&stream->cache, data, size);
            tb_check_return_val(writ >= 0, -1);
            
            // ok?
            tb_check_break(!writ);

            // cache is full now.
            tb_assert_and_check_return_val(tb_queue_buffer_full(&stream->cache), -1);

            // enter cache for pull
            tb_size_t   pull = 0;
            tb_byte_t*  head = tb_queue_buffer_pull_init(&stream->cache, &pull);
            tb_assert_and_check_return_val(head && pull, -1);

            // pull data to self from cache
            tb_long_t   real = stream->writ(self, head, pull);
            tb_check_return_val(real >= 0, -1);

            // writ the left data to cache
            if (real > 0)
            {
                // leave cache for pull
                tb_queue_buffer_pull_exit(&stream->cache, real);

                // writ cache
                real = tb_queue_buffer_writ(&stream->cache, data + writ, tb_min(real, size - writ));
                tb_check_return_val(real >= 0, -1);

                // save writ 
                writ += real;
            }
        }
        else 
        {
            // writ it directly
            writ = stream->writ(self, data, size);
            tb_check_return_val(writ >= 0, -1);
        }

    } while (0);

    // update offset
    stream->offset += writ;

//  tb_trace_d("writ: %d", writ);
    return writ;
}
tb_bool_t tb_stream_bread(tb_stream_ref_t self, tb_byte_t* data, tb_size_t size)
{
    // check 
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream && data, tb_false);
    tb_check_return_val(size, tb_true);

    // have writed cache? sync first
    if (stream->bwrited && !tb_queue_buffer_null(&stream->cache) && !tb_stream_sync(self, tb_false))
        return tb_false;

    // check the left
    tb_hize_t left = tb_stream_left(self);
    tb_check_return_val(size <= left, tb_false);

    // read data from cache
    tb_long_t read = 0;
    while (read < size && (TB_STATE_OPENED == tb_atomic_get(&stream->istate)))
    {
        // read data
        tb_long_t real = tb_stream_read(self, data + read, size - read);    
        if (real > 0) read += real;
        else if (!real)
        {
            // wait
            real = tb_stream_wait(self, TB_STREAM_WAIT_READ, tb_stream_timeout(self));
            tb_check_break(real > 0);

            // has read?
            tb_assert_and_check_break(real & TB_STREAM_WAIT_READ);
        }
        else break;
    }

    // killed? save state
    if (read != size && !stream->state && (TB_STATE_KILLING == tb_atomic_get(&stream->istate)))
        stream->state = TB_STATE_KILLED;

    // ok?
    return (read == size? tb_true : tb_false);
}
tb_bool_t tb_stream_bwrit(tb_stream_ref_t self, tb_byte_t const* data, tb_size_t size)
{
    // check 
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream && data, tb_false);
    tb_check_return_val(size, tb_true);

    // writ data to cache
    tb_long_t writ = 0;
    while (writ < size && (TB_STATE_OPENED == tb_atomic_get(&stream->istate)))
    {
        // writ data
        tb_long_t real = tb_stream_writ(self, data + writ, size - writ);    
        if (real > 0) writ += real;
        else if (!real)
        {
            // wait
            real = tb_stream_wait(self, TB_STREAM_WAIT_WRIT, tb_stream_timeout(self));
            tb_check_break(real > 0);

            // has writ?
            tb_assert_and_check_break(real & TB_STREAM_WAIT_WRIT);
        }
        else break;
    }

    // killed? save state
    if (writ != size && !stream->state && (TB_STATE_KILLING == tb_atomic_get(&stream->istate)))
        stream->state = TB_STATE_KILLED;

    // ok?
    return (writ == size? tb_true : tb_false);
}
tb_bool_t tb_stream_sync(tb_stream_ref_t self, tb_bool_t bclosing)
{
    // check 
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream && stream->writ && stream->wait && tb_stream_is_opened(self), tb_false);

    // stoped?
    tb_assert_and_check_return_val((TB_STATE_OPENED == tb_atomic_get(&stream->istate)), tb_false);

    // cached? sync cache first
    if (tb_queue_buffer_maxn(&stream->cache))
    {
        // have data?
        if (!tb_queue_buffer_null(&stream->cache))
        {
            // check: must be writed cache
            tb_assert_and_check_return_val(stream->bwrited, tb_false);

            // enter cache for pull
            tb_size_t   size = 0;
            tb_byte_t*  head = tb_queue_buffer_pull_init(&stream->cache, &size);
            tb_assert_and_check_return_val(head && size, tb_false);

            // writ cache data to self
            tb_size_t   writ = 0;
            while (writ < size && (TB_STATE_OPENED == tb_atomic_get(&stream->istate)))
            {
                // writ
                tb_long_t real = stream->writ(self, head + writ, size - writ);

                // ok?
                if (real > 0)
                {
                    // save writ
                    writ += real;
                }
                // no data?
                else if (!real)
                {
                    // wait
                    real = stream->wait(self, TB_STREAM_WAIT_WRIT, tb_stream_timeout(self));

                    // ok?
                    tb_check_break(real > 0);
                }
                // error or end?
                else break;
            }

            // leave cache for pull
            tb_queue_buffer_pull_exit(&stream->cache, writ);

            // cache be not cleared?
            if (!tb_queue_buffer_null(&stream->cache))
            {
                // killed? save state
                if (!stream->state && (TB_STATE_KILLING == tb_atomic_get(&stream->istate)))
                    stream->state = TB_STATE_KILLED;

                // failed
                return tb_false;
            }
        }
        else stream->bwrited = 1;
    }

    // sync
    return stream->sync? stream->sync(self, bclosing) : tb_true;
}
tb_bool_t tb_stream_seek(tb_stream_ref_t self, tb_hize_t offset)
{
    // check 
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream && tb_stream_is_opened(self), tb_false);

    // stoped?
    tb_assert_and_check_return_val((TB_STATE_OPENED == tb_atomic_get(&stream->istate)), tb_false);

    // sync writed data first, @note must be called before tb_stream_size()
    if (stream->bwrited && !tb_stream_sync(self, tb_false)) return tb_false;

    // limit offset
    tb_hong_t size = tb_stream_size(self);
    if (size >= 0 && offset > size) offset = size;

    // the offset be not changed?
    tb_hize_t curt = tb_stream_offset(self);
    tb_check_return_val(offset != curt, tb_true);

    // for writing
    if (stream->bwrited)
    {
        // check cache, must not cache or empty cache
        tb_assert_and_check_return_val(!tb_queue_buffer_maxn(&stream->cache) || tb_queue_buffer_null(&stream->cache), tb_false);

        // seek it
        tb_bool_t ok = stream->seek? stream->seek(self, offset) : tb_false;

        // save offset
        if (ok) stream->offset = offset;
    }
    // for reading
    else
    {
        // cached? try to seek it at the cache
        tb_bool_t ok = tb_false;
        if (tb_queue_buffer_maxn(&stream->cache))
        {
            tb_size_t   size = 0;
            tb_byte_t*  data = tb_queue_buffer_pull_init(&stream->cache, &size);
            if (data && size && offset > curt && offset < curt + size)
            {
                // seek it at the cache
                tb_queue_buffer_pull_exit(&stream->cache, (tb_size_t)(offset - curt));

                // save offset
                stream->offset = offset;
                
                // ok
                ok = tb_true;
            }
        }

        // seek it
        if (!ok)
        {
            // seek it
            ok = stream->seek? stream->seek(self, offset) : tb_false;

            // ok?
            if (ok)
            {
                // save offset
                stream->offset = offset;
    
                // clear cache
                tb_queue_buffer_clear(&stream->cache);
            }
        }

        // try to read and seek
        if (!ok && offset > curt)
        {
            // read some data for updating offset
            tb_byte_t data[TB_STREAM_BLOCK_MAXN];
            while (tb_stream_offset(self) != offset)
            {
                tb_size_t need = (tb_size_t)tb_min(offset - curt, TB_STREAM_BLOCK_MAXN);
                if (!tb_stream_bread(self, data, need)) return tb_false;
            }
        }
    }

    // ok?
    return tb_stream_offset(self) == offset? tb_true : tb_false;
}
tb_bool_t tb_stream_skip(tb_stream_ref_t self, tb_hize_t size)
{
    return tb_stream_seek(self, tb_stream_offset(self) + size);
}
tb_long_t tb_stream_bread_line(tb_stream_ref_t self, tb_char_t* data, tb_size_t size)
{
    // check
    tb_stream_t* stream = tb_stream_cast(self);
    tb_assert_and_check_return_val(stream, -1);

    // done
    tb_char_t   ch = 0;
    tb_char_t*  p = data;
    while ((TB_STATE_OPENED == tb_atomic_get(&stream->istate)))
    {
        // read char
        if (!tb_stream_bread_s8(self, (tb_sint8_t*)&ch)) break;

        // is line?
        if (ch == '\n') 
        {
            // finish line
            if (p > data && p[-1] == '\r')
                p--;
            *p = '\0';
    
            // ok
            return p - data;
        }
        // append char to line
        else 
        {
            if ((p - data) < size - 1) *p++ = ch;

            // line end?
            if (!ch) break;
        }
    }

    // killed?
    if ((TB_STATE_KILLING == tb_atomic_get(&stream->istate))) return -1;

    // end
    if (p < data + size) *p = '\0';

    // ok?
    return !tb_stream_beof(self)? p - data : -1;
}
tb_long_t tb_stream_bwrit_line(tb_stream_ref_t self, tb_char_t* data, tb_size_t size)
{
    // writ data
    tb_long_t writ = 0;
    if (size) 
    {
        if (!tb_stream_bwrit(self, (tb_byte_t*)data, size)) return -1;
    }
    else
    {
        tb_char_t* p = data;
        while (*p)
        {
            if (!tb_stream_bwrit(self, (tb_byte_t*)p, 1)) return -1;
            p++;
        }
    
        writ = p - data;
    }

    // writ "\r\n" or "\n"
#ifdef TB_CONFIG_OS_WINDOWS
    tb_char_t le[] = "\r\n";
    tb_size_t ln = 2;
#else
    tb_char_t le[] = "\n";
    tb_size_t ln = 1;
#endif
    if (!tb_stream_bwrit(self, (tb_byte_t*)le, ln)) return -1;
    writ += ln;

    // ok
    return writ;
}
tb_long_t tb_stream_printf(tb_stream_ref_t self, tb_char_t const* fmt, ...)
{
    // init data
    tb_char_t data[TB_STREAM_BLOCK_MAXN] = {0};
    tb_size_t size = 0;

    // format data
    tb_vsnprintf_format(data, TB_STREAM_BLOCK_MAXN, fmt, &size);
    tb_check_return_val(size, 0);

    // writ data
    return tb_stream_bwrit(self, (tb_byte_t*)data, size)? size : -1;
}
tb_byte_t* tb_stream_bread_all(tb_stream_ref_t self, tb_bool_t is_cstr, tb_size_t* psize)
{
    // attempt to get self size
    tb_bool_t   ok = tb_false;
    tb_byte_t*  data = tb_null;
    tb_hong_t   size = tb_stream_size(self);
    do
    {
        // has size?
        if (size > 0)
        {
            // check
            tb_assert(size < TB_MAXS32);

            // make data
            data = tb_malloc_bytes((tb_size_t)(is_cstr? size + 1 : size));
            tb_assert_and_check_break(data);

            // read data
            if (!tb_stream_bread(self, data, (tb_size_t)size)) break;

            // append '\0' if be c-string
            if (is_cstr) data[size] = '\0';

            // save size
            if (psize) *psize = (tb_size_t)size;

            // ok
            ok = tb_true;
        }
        // no size?
        else
        {
            // init maxn
            tb_size_t maxn = TB_STREAM_BLOCK_MAXN;

            // make data
            data = tb_malloc_bytes(is_cstr? maxn + 1 : maxn);
            tb_assert_and_check_break(data);

            // done
            tb_long_t read = 0;
            while (!tb_stream_beof(self))
            {
                // space is too small? grow it first
                if (maxn - read < TB_STREAM_BLOCK_MAXN)
                {
                    // grow maxn
                    maxn = tb_max(maxn << 1, maxn + TB_STREAM_BLOCK_MAXN);

                    // grow data
                    data = (tb_byte_t*)tb_ralloc(data, is_cstr? maxn + 1 : maxn);
                    tb_assert_and_check_break(data);
                }

                // read data
                tb_long_t real = tb_stream_read(self, data + read, maxn - read);    

                // ok?
                if (real > 0) 
                {
                    // update size
                    read += real;
                }
                // no data? continue it
                else if (!real)
                {
                    // wait
                    real = tb_stream_wait(self, TB_STREAM_WAIT_READ, tb_stream_timeout(self));
                    tb_check_break(real > 0);

                    // has read?
                    tb_assert_and_check_break(real & TB_STREAM_WAIT_READ);
                }
                // failed or end?
                else break;
            }

            // check
            tb_assert_and_check_break(data && read <= maxn);
            
            // append '\0' if be c-string
            if (is_cstr) data[read] = '\0';

            // save size
            if (psize) *psize = read;

            // ok
            ok = tb_true;
        }
    
    } while (0);

    // failed?
    if (!ok)
    {
        // exit data
        if (data) tb_free(data);
        data = tb_null;
    }

    // ok?
    return data;
}
tb_bool_t tb_stream_bread_u8(tb_stream_ref_t self, tb_uint8_t* pvalue)
{
    return tb_stream_bread(self, (tb_byte_t*)pvalue, 1);
}
tb_bool_t tb_stream_bread_s8(tb_stream_ref_t self, tb_sint8_t* pvalue)
{
    return tb_stream_bread(self, (tb_byte_t*)pvalue, 1);
}
tb_bool_t tb_stream_bread_u16_le(tb_stream_ref_t self, tb_uint16_t* pvalue)
{   
    // read data
    tb_byte_t b[2];
    tb_bool_t ok = tb_stream_bread(self, b, 2);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_u16_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_s16_le(tb_stream_ref_t self, tb_sint16_t* pvalue)
{   
    // read data
    tb_byte_t b[2];
    tb_bool_t ok = tb_stream_bread(self, b, 2);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_s16_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_u24_le(tb_stream_ref_t self, tb_uint32_t* pvalue)
{   
    // read data
    tb_byte_t b[3];
    tb_bool_t ok = tb_stream_bread(self, b, 3);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_u24_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_s24_le(tb_stream_ref_t self, tb_sint32_t* pvalue)
{   
    // read data
    tb_byte_t b[3];
    tb_bool_t ok = tb_stream_bread(self, b, 3);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_s24_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_u32_le(tb_stream_ref_t self, tb_uint32_t* pvalue)
{   
    // read data
    tb_byte_t b[4];
    tb_bool_t ok = tb_stream_bread(self, b, 4);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_u32_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_s32_le(tb_stream_ref_t self, tb_sint32_t* pvalue)
{   
    // read data
    tb_byte_t b[4];
    tb_bool_t ok = tb_stream_bread(self, b, 4);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_s32_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_u64_le(tb_stream_ref_t self, tb_uint64_t* pvalue)
{   
    // read data
    tb_byte_t b[8];
    tb_bool_t ok = tb_stream_bread(self, b, 8);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_u64_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_s64_le(tb_stream_ref_t self, tb_sint64_t* pvalue)
{   
    // read data
    tb_byte_t b[8];
    tb_bool_t ok = tb_stream_bread(self, b, 8);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_s64_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_u16_be(tb_stream_ref_t self, tb_uint16_t* pvalue)
{   
    // read data
    tb_byte_t b[2];
    tb_bool_t ok = tb_stream_bread(self, b, 2);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_u16_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_s16_be(tb_stream_ref_t self, tb_sint16_t* pvalue)
{   
    // read data
    tb_byte_t b[2];
    tb_bool_t ok = tb_stream_bread(self, b, 2);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_s16_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_u24_be(tb_stream_ref_t self, tb_uint32_t* pvalue)
{   
    // read data
    tb_byte_t b[3];
    tb_bool_t ok = tb_stream_bread(self, b, 3);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_u24_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_s24_be(tb_stream_ref_t self, tb_sint32_t* pvalue)
{   
    // read data
    tb_byte_t b[3];
    tb_bool_t ok = tb_stream_bread(self, b, 3);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_s24_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_u32_be(tb_stream_ref_t self, tb_uint32_t* pvalue)
{   
    // read data
    tb_byte_t b[4];
    tb_bool_t ok = tb_stream_bread(self, b, 4);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_u32_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_s32_be(tb_stream_ref_t self, tb_sint32_t* pvalue)
{   
    // read data
    tb_byte_t b[4];
    tb_bool_t ok = tb_stream_bread(self, b, 4);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_s32_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_u64_be(tb_stream_ref_t self, tb_uint64_t* pvalue)
{   
    // read data
    tb_byte_t b[8];
    tb_bool_t ok = tb_stream_bread(self, b, 8);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_u64_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_s64_be(tb_stream_ref_t self, tb_sint64_t* pvalue)
{   
    // read data
    tb_byte_t b[8];
    tb_bool_t ok = tb_stream_bread(self, b, 8);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_s64_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bwrit_u8(tb_stream_ref_t self, tb_uint8_t value)
{
    tb_byte_t b[1];
    tb_bits_set_u8(b, value);
    return tb_stream_bwrit(self, b, 1);
}
tb_bool_t tb_stream_bwrit_s8(tb_stream_ref_t self, tb_sint8_t value)
{
    tb_byte_t b[1];
    tb_bits_set_s8(b, value);
    return tb_stream_bwrit(self, b, 1);
}
tb_bool_t tb_stream_bwrit_u16_le(tb_stream_ref_t self, tb_uint16_t value)
{
    tb_byte_t b[2];
    tb_bits_set_u16_le(b, value);
    return tb_stream_bwrit(self, b, 2);
}
tb_bool_t tb_stream_bwrit_s16_le(tb_stream_ref_t self, tb_sint16_t value)
{
    tb_byte_t b[2];
    tb_bits_set_s16_le(b, value);
    return tb_stream_bwrit(self, b, 2);
}
tb_bool_t tb_stream_bwrit_u24_le(tb_stream_ref_t self, tb_uint32_t value)
{   
    tb_byte_t b[3];
    tb_bits_set_u24_le(b, value);
    return tb_stream_bwrit(self, b, 3);
}
tb_bool_t tb_stream_bwrit_s24_le(tb_stream_ref_t self, tb_sint32_t value)
{
    tb_byte_t b[3];
    tb_bits_set_s24_le(b, value);
    return tb_stream_bwrit(self, b, 3);
}
tb_bool_t tb_stream_bwrit_u32_le(tb_stream_ref_t self, tb_uint32_t value)
{   
    tb_byte_t b[4];
    tb_bits_set_u32_le(b, value);
    return tb_stream_bwrit(self, b, 4);
}
tb_bool_t tb_stream_bwrit_s32_le(tb_stream_ref_t self, tb_sint32_t value)
{
    tb_byte_t b[4];
    tb_bits_set_s32_le(b, value);
    return tb_stream_bwrit(self, b, 4);
}
tb_bool_t tb_stream_bwrit_u64_le(tb_stream_ref_t self, tb_uint64_t value)
{   
    tb_byte_t b[8];
    tb_bits_set_u64_le(b, value);
    return tb_stream_bwrit(self, b, 8);
}
tb_bool_t tb_stream_bwrit_s64_le(tb_stream_ref_t self, tb_sint64_t value)
{
    tb_byte_t b[8];
    tb_bits_set_s64_le(b, value);
    return tb_stream_bwrit(self, b, 8);
}
tb_bool_t tb_stream_bwrit_u16_be(tb_stream_ref_t self, tb_uint16_t value)
{
    tb_byte_t b[2];
    tb_bits_set_u16_be(b, value);
    return tb_stream_bwrit(self, b, 2);
}
tb_bool_t tb_stream_bwrit_s16_be(tb_stream_ref_t self, tb_sint16_t value)
{
    tb_byte_t b[2];
    tb_bits_set_s16_be(b, value);
    return tb_stream_bwrit(self, b, 2);
}
tb_bool_t tb_stream_bwrit_u24_be(tb_stream_ref_t self, tb_uint32_t value)
{   
    tb_byte_t b[3];
    tb_bits_set_u24_be(b, value);
    return tb_stream_bwrit(self, b, 3);
}
tb_bool_t tb_stream_bwrit_s24_be(tb_stream_ref_t self, tb_sint32_t value)
{
    tb_byte_t b[3];
    tb_bits_set_s24_be(b, value);
    return tb_stream_bwrit(self, b, 3);
}
tb_bool_t tb_stream_bwrit_u32_be(tb_stream_ref_t self, tb_uint32_t value)
{   
    tb_byte_t b[4];
    tb_bits_set_u32_be(b, value);
    return tb_stream_bwrit(self, b, 4);
}
tb_bool_t tb_stream_bwrit_s32_be(tb_stream_ref_t self, tb_sint32_t value)
{
    tb_byte_t b[4];
    tb_bits_set_s32_be(b, value);
    return tb_stream_bwrit(self, b, 4);
}
tb_bool_t tb_stream_bwrit_u64_be(tb_stream_ref_t self, tb_uint64_t value)
{   
    tb_byte_t b[8];
    tb_bits_set_u64_be(b, value);
    return tb_stream_bwrit(self, b, 8);
}
tb_bool_t tb_stream_bwrit_s64_be(tb_stream_ref_t self, tb_sint64_t value)
{
    tb_byte_t b[8];
    tb_bits_set_s64_be(b, value);
    return tb_stream_bwrit(self, b, 8);
}
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
tb_bool_t tb_stream_bread_float_le(tb_stream_ref_t self, tb_float_t* pvalue)
{
    // read data
    tb_byte_t b[4];
    tb_bool_t ok = tb_stream_bread(self, b, 4);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_float_le(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_float_be(tb_stream_ref_t self, tb_float_t* pvalue)
{
    // read data
    tb_byte_t b[4];
    tb_bool_t ok = tb_stream_bread(self, b, 4);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_float_be(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_double_ble(tb_stream_ref_t self, tb_double_t* pvalue)
{
    // read data
    tb_byte_t b[8];
    tb_bool_t ok = tb_stream_bread(self, b, 8);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_double_ble(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_double_bbe(tb_stream_ref_t self, tb_double_t* pvalue)
{
    // read data
    tb_byte_t b[8];
    tb_bool_t ok = tb_stream_bread(self, b, 8);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_double_bbe(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_double_lle(tb_stream_ref_t self, tb_double_t* pvalue)
{
    // read data
    tb_byte_t b[8];
    tb_bool_t ok = tb_stream_bread(self, b, 8);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_double_lle(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bread_double_lbe(tb_stream_ref_t self, tb_double_t* pvalue)
{
    // read data
    tb_byte_t b[8];
    tb_bool_t ok = tb_stream_bread(self, b, 8);

    // save value
    if (ok && pvalue) *pvalue = tb_bits_get_double_lbe(b);

    // ok?
    return ok;
}
tb_bool_t tb_stream_bwrit_float_le(tb_stream_ref_t self, tb_float_t value)
{
    tb_byte_t b[4];
    tb_bits_set_float_le(b, value);
    return tb_stream_bwrit(self, b, 4);
}
tb_bool_t tb_stream_bwrit_float_be(tb_stream_ref_t self, tb_float_t value)
{
    tb_byte_t b[4];
    tb_bits_set_float_be(b, value);
    return tb_stream_bwrit(self, b, 4);
}
tb_bool_t tb_stream_bwrit_double_ble(tb_stream_ref_t self, tb_double_t value)
{
    tb_byte_t b[8];
    tb_bits_set_double_ble(b, value);
    return tb_stream_bwrit(self, b, 8);
}
tb_bool_t tb_stream_bwrit_double_bbe(tb_stream_ref_t self, tb_double_t value)
{
    tb_byte_t b[8];
    tb_bits_set_double_bbe(b, value);
    return tb_stream_bwrit(self, b, 8);
}
tb_bool_t tb_stream_bwrit_double_lle(tb_stream_ref_t self, tb_double_t value)
{
    tb_byte_t b[8];
    tb_bits_set_double_lle(b, value);
    return tb_stream_bwrit(self, b, 8);
}
tb_bool_t tb_stream_bwrit_double_lbe(tb_stream_ref_t self, tb_double_t value)
{
    tb_byte_t b[8];
    tb_bits_set_double_lbe(b, value);
    return tb_stream_bwrit(self, b, 8);
}

#endif
