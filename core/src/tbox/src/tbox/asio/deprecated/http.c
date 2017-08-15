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
 * @ingroup     asio
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "aicp_http"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "http.h"
#include "aico.h"
#include "aicp.h"
#include "../../zip/zip.h"
#include "../../string/string.h"
#include "../../stream/stream.h"
#include "../../network/network.h"
#include "../../platform/platform.h"
#include "../../algorithm/algorithm.h"
#include "../../container/container.h"
#include "../../network/impl/http/date.h"
#include "../../network/impl/http/option.h"
#include "../../network/impl/http/status.h"
#include "../../network/impl/http/method.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the aicp http impl open and read type
typedef struct __tb_aicp_http_open_read_t
{
    // the func
    tb_aicp_http_read_func_t        func;

    // the priv
    tb_cpointer_t                   priv;

    // the size
    tb_size_t                       size;

}tb_aicp_http_open_read_t;

// the aicp http impl open and seek type
typedef struct __tb_aicp_http_open_seek_t
{
    // the func
    tb_aicp_http_seek_func_t        func;

    // the priv
    tb_cpointer_t                   priv;

    // the offset
    tb_hize_t                       offset;

}tb_aicp_http_open_seek_t;

// the aicp http impl close opening type
typedef struct __tb_aicp_http_clos_opening_t
{
    // the func
    tb_aicp_http_open_func_t        func;

    // the priv
    tb_cpointer_t                   priv;

    // the state
    tb_size_t                       state;

}tb_aicp_http_clos_opening_t;

// the aicp http impl type
typedef struct __tb_aicp_http_impl_t
{
    // the option
    tb_http_option_t                option;

    // the status 
    tb_http_status_t                status;

    // the stream
    tb_async_stream_ref_t           stream;

    // the sstream for sock
    tb_async_stream_ref_t           sstream;

    // the cstream for chunked
    tb_async_stream_ref_t           cstream;

    // the zstream for gzip/deflate
    tb_async_stream_ref_t           zstream;

    // the request head 
    tb_hash_map_ref_t                   head;

    // the cookies
    tb_string_t                     cookies;

    // the transfer for post
    tb_async_transfer_ref_t         transfer;

    /* the state
     *
     * TB_STATE_CLOSED
     * TB_STATE_OPENED
     * TB_STATE_OPENING
     * TB_STATE_KILLING
     */
    tb_atomic_t                     state;

    // the line data
    tb_string_t                     line_data;

    // the line size
    tb_size_t                       line_size;

    // the cache data
    tb_buffer_t                     cache_data;

    // the cache read
    tb_size_t                       cache_read;

    // the redirect tryn
    tb_size_t                       redirect_tryn;

    // the content read 
    tb_hize_t                       content_read;

    // the clos opening
    tb_aicp_http_clos_opening_t     clos_opening;

    // the open and read, writ, seek, ...
    union
    {
        tb_aicp_http_open_read_t    read;
        tb_aicp_http_open_seek_t    seek;

    }                               open_and;

    // the func
    union
    {
        tb_aicp_http_open_func_t    open;
        tb_aicp_http_read_func_t    read;
        tb_aicp_http_seek_func_t    seek;
        tb_aicp_http_task_func_t    task;
        tb_aicp_http_clos_func_t    clos;

    }                               func;

    // the priv
    tb_cpointer_t                   priv;

}tb_aicp_http_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */
static tb_bool_t tb_aicp_http_open_done(tb_aicp_http_impl_t* impl);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_char_t const* tb_aicp_http_head_format(tb_aicp_http_impl_t* impl, tb_hize_t post_size, tb_size_t* head_size, tb_size_t* state)
{
    // check
    tb_assert_and_check_return_val(impl && head_size, tb_null);

    // clear line data
    tb_string_clear(&impl->line_data);

    // init the head value
    tb_char_t           data[8192];
    tb_static_string_t  value;
    if (!tb_static_string_init(&value, data, sizeof(data))) return tb_null;

    // init method
    tb_char_t const* method = tb_http_method_cstr(impl->option.method);
    tb_assert_and_check_return_val(method, tb_null);

    // init path
    tb_char_t const* path = tb_url_path(&impl->option.url);
    tb_assert_and_check_return_val(path, tb_null);

    // init args
    tb_char_t const* args = tb_url_args(&impl->option.url);

    // init host
    tb_char_t const* host = tb_url_host(&impl->option.url);
    tb_assert_and_check_return_val(host, tb_null);
    tb_hash_map_insert(impl->head, "Host", host);

    // init accept
    tb_hash_map_insert(impl->head, "Accept", "*/*");

    // init connection
    tb_hash_map_insert(impl->head, "Connection", impl->status.balived? "keep-alive" : "close");

    // init cookies
    tb_bool_t cookie = tb_false;
    if (impl->option.cookies)
    {
        // update cookie
        if (tb_cookies_get(impl->option.cookies, host, path, tb_url_ssl(&impl->option.url), &impl->cookies))
        {
            tb_hash_map_insert(impl->head, "Cookie", tb_string_cstr(&impl->cookies));
            cookie = tb_true;
        }
    }

    // no cookie? remove it
    if (!cookie) tb_hash_map_remove(impl->head, "Cookie");

    // init range
    if (impl->option.range.bof && impl->option.range.eof >= impl->option.range.bof)
        tb_static_string_cstrfcpy(&value, "bytes=%llu-%llu", impl->option.range.bof, impl->option.range.eof);
    else if (impl->option.range.bof && !impl->option.range.eof)
        tb_static_string_cstrfcpy(&value, "bytes=%llu-", impl->option.range.bof);
    else if (!impl->option.range.bof && impl->option.range.eof)
        tb_static_string_cstrfcpy(&value, "bytes=0-%llu", impl->option.range.eof);
    else if (impl->option.range.bof > impl->option.range.eof)
    {
        // save state
        if (state) *state = TB_STATE_HTTP_RANGE_INVALID;
        return tb_null;
    }

    // update range
    if (tb_static_string_size(&value)) tb_hash_map_insert(impl->head, "Range", tb_static_string_cstr(&value));
    // remove range
    else tb_hash_map_remove(impl->head, "Range");

    // init post
    if (impl->option.method == TB_HTTP_METHOD_POST)
    {
        // append post size
        tb_static_string_cstrfcpy(&value, "%llu", post_size);
        tb_hash_map_insert(impl->head, "Content-Length", tb_static_string_cstr(&value));
    }
    // remove post
    else tb_hash_map_remove(impl->head, "Content-Length");

    // replace the custom head 
    tb_char_t const* head_data = (tb_char_t const*)tb_buffer_data(&impl->option.head_data);
    tb_char_t const* head_tail = head_data + tb_buffer_size(&impl->option.head_data);
    while (head_data < head_tail)
    {
        // the name and data
        tb_char_t const* name = head_data;
        tb_char_t const* data = head_data + tb_strlen(name) + 1;
        tb_check_break(data < head_tail);

        // replace it
        tb_hash_map_insert(impl->head, name, data);

        // next
        head_data = data + tb_strlen(data) + 1;
    }

    // exit the head value
    tb_static_string_exit(&value);

    // check head
    tb_assert_and_check_return_val(tb_hash_map_size(impl->head), tb_null);

    // append method
    tb_string_cstrcat(&impl->line_data, method);

    // append ' '
    tb_string_chrcat(&impl->line_data, ' ');

    // encode path
    tb_url_encode2(path, tb_strlen(path), data, sizeof(data) - 1);
    path = data;

    // append path
    tb_string_cstrcat(&impl->line_data, path);

    // append args if exists
    if (args) 
    {
        // append '?'
        tb_string_chrcat(&impl->line_data, '?');

        // encode args
        tb_url_encode2(args, tb_strlen(args), data, sizeof(data) - 1);
        args = data;

        // append args
        tb_string_cstrcat(&impl->line_data, args);
    }

    // append ' '
    tb_string_chrcat(&impl->line_data, ' ');

    // append version, HTTP/1.1
    tb_string_cstrfcat(&impl->line_data, "HTTP/1.%1u\r\n", impl->option.version);

    // append key: value
    tb_for_all (tb_hash_map_item_ref_t, item, impl->head)
    {
        if (item && item->name && item->data) 
            tb_string_cstrfcat(&impl->line_data, "%s: %s\r\n", (tb_char_t const*)item->name, (tb_char_t const*)item->data);
    }

    // append end
    tb_string_cstrcat(&impl->line_data, "\r\n");

    // save the head size
    *head_size = tb_string_size(&impl->line_data);
    
    // ok
    return tb_string_cstr(&impl->line_data);
}
static tb_bool_t tb_aicp_http_open_read_func(tb_aicp_http_ref_t http, tb_size_t state, tb_http_status_t const* status, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_open_read_t* open_read = (tb_aicp_http_open_read_t*)priv;
    tb_assert_and_check_return_val(http && status && open_read && open_read->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
    
        // read it
        if (!tb_aicp_http_read(http, open_read->size, open_read->func, open_read->priv)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);
 
    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        ok = open_read->func(http, state, tb_null, 0, open_read->size, open_read->priv);
    }
 
    // ok?
    return ok;
}
static tb_bool_t tb_aicp_http_open_seek_func(tb_aicp_http_ref_t http, tb_size_t state, tb_http_status_t const* status, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_open_seek_t* open_seek = (tb_aicp_http_open_seek_t*)priv;
    tb_assert_and_check_return_val(http && status && open_seek && open_seek->func, tb_false);

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;
    
        // seek it
        if (!tb_aicp_http_seek(http, open_seek->offset, open_seek->func, open_seek->priv)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);
 
    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        ok = open_seek->func(http, state, 0, open_seek->priv);
    }
 
    // ok?
    return ok;
}
/*
 * HTTP/1.1 206 Partial Content
 * Date: Fri, 23 Apr 2010 05:25:45 GMT
 * Server: Apache/2.2.9 (Ubuntu) PHP/5.2.6-2ubuntu4.5 with Suhosin-Patch
 * Last-Modified: Mon, 08 Mar 2010 09:58:09 GMT
 * ETag: "6cc014-8f47f-481471a322e40"
 * Accept-Ranges: bytes
 * Content-Length: 586879
 * Content-Range: bytes 0-586878/586879
 * Connection: close
 * Content-Type: application/x-shockwave-flash
 */
static tb_bool_t tb_aicp_http_head_resp_done(tb_aicp_http_impl_t* impl)
{
    // check
    tb_assert_and_check_return_val(impl && impl->sstream, tb_false);

    // the line and size
    tb_char_t const*    line = tb_string_cstr(&impl->line_data);
    tb_size_t           size = tb_string_size(&impl->line_data);
    tb_assert_and_check_return_val(line && size, tb_false);

    // the first line? 
    tb_char_t const* p = line;
    if (!impl->line_size)
    {
        // check http response
        if (tb_strnicmp(p, "HTTP/1.", 7))
        {
            // failed
            tb_assert(0);
            return tb_false;
        }

        // seek to the http version
        p += 7;
        tb_assert_and_check_return_val(*p, tb_false);

        // parse version
        tb_assert_and_check_return_val((*p - '0') < 2, tb_false);
        impl->status.version = *p - '0';
    
        // seek to the http code
        p++; while (tb_isspace(*p)) p++;

        // parse code
        tb_assert_and_check_return_val(*p && tb_isdigit(*p), tb_false);
        impl->status.code = tb_stou32(p);

        // save state
        if (impl->status.code == 200 || impl->status.code == 206)
            impl->status.state = TB_STATE_OK;
        else if (impl->status.code == 204)
            impl->status.state = TB_STATE_HTTP_RESPONSE_204;
        else if (impl->status.code >= 300 && impl->status.code <= 307)
            impl->status.state = TB_STATE_HTTP_RESPONSE_300 + (impl->status.code - 300);
        else if (impl->status.code >= 400 && impl->status.code <= 416)
            impl->status.state = TB_STATE_HTTP_RESPONSE_400 + (impl->status.code - 400);
        else if (impl->status.code >= 500 && impl->status.code <= 507)
            impl->status.state = TB_STATE_HTTP_RESPONSE_500 + (impl->status.code - 500);
        else impl->status.state = TB_STATE_HTTP_RESPONSE_UNK;

        // check state code: 4xx & 5xx
        if (impl->status.code >= 400 && impl->status.code < 600) return tb_false;
    }
    // key: value?
    else
    {
        // seek to value
        while (*p && *p != ':') p++;
        tb_assert_and_check_return_val(*p, tb_false);
        p++; while (*p && tb_isspace(*p)) p++;

        // no value
        tb_check_return_val(*p, tb_true);

        // parse content size
        if (!tb_strnicmp(line, "Content-Length", 14))
        {
            impl->status.content_size = tb_stou64(p);
            if (impl->status.document_size < 0) 
                impl->status.document_size = impl->status.content_size;
        }
        // parse content range: "bytes $from-$to/$document_size"
        else if (!tb_strnicmp(line, "Content-Range", 13))
        {
            tb_hize_t from = 0;
            tb_hize_t to = 0;
            tb_hize_t document_size = 0;
            if (!tb_strncmp(p, "bytes ", 6)) 
            {
                p += 6;
                from = tb_stou64(p);
                while (*p && *p != '-') p++;
                if (*p && *p++ == '-') to = tb_stou64(p);
                while (*p && *p != '/') p++;
                if (*p && *p++ == '/') document_size = tb_stou64(p);
            }
            // no stream, be able to seek
            impl->status.bseeked = 1;
            impl->status.document_size = document_size;
            if (impl->status.content_size < 0) 
            {
                if (from && to > from) impl->status.content_size = to - from;
                else if (!from && to) impl->status.content_size = to;
                else if (from && !to && document_size > from) impl->status.content_size = document_size - from;
                else impl->status.content_size = document_size;
            }
        }
        // parse accept-ranges: "bytes "
        else if (!tb_strnicmp(line, "Accept-Ranges", 13))
        {
            // no stream, be able to seek
            impl->status.bseeked = 1;
        }
        // parse content type
        else if (!tb_strnicmp(line, "Content-Type", 12)) 
        {
            tb_string_cstrcpy(&impl->status.content_type, p);
            tb_assert_and_check_return_val(tb_string_size(&impl->status.content_type), tb_false);
        }
        // parse transfer encoding
        else if (!tb_strnicmp(line, "Transfer-Encoding", 17))
        {
            if (!tb_stricmp(p, "chunked")) impl->status.bchunked = 1;
        }
        // parse content encoding
        else if (!tb_strnicmp(line, "Content-Encoding", 16))
        {
            if (!tb_stricmp(p, "gzip")) impl->status.bgzip = 1;
            else if (!tb_stricmp(p, "deflate")) impl->status.bdeflate = 1;
        }
        // parse location
        else if (!tb_strnicmp(line, "Location", 8)) 
        {
            // redirect? check code: 301 - 307
            tb_assert_and_check_return_val(impl->status.code > 300 && impl->status.code < 308, tb_false);

            // save location
            tb_string_cstrcpy(&impl->status.location, p);
        }
        // parse connection
        else if (!tb_strnicmp(line, "Connection", 10))
        {
            // keep alive?
            impl->status.balived = !tb_stricmp(p, "close")? 0 : 1;

            // ctrl stream for sock
            if (!tb_async_stream_ctrl(impl->sstream, TB_STREAM_CTRL_SOCK_KEEP_ALIVE, impl->status.balived? tb_true : tb_false)) return tb_false;
        }
        // parse cookies
        else if (impl->option.cookies && !tb_strnicmp(line, "Set-Cookie", 10))
        {
            // the host
            tb_char_t const* host = tb_null;
            tb_aicp_http_ctrl((tb_aicp_http_ref_t)impl, TB_HTTP_OPTION_GET_HOST, &host);

            // the path
            tb_char_t const* path = tb_null;
            tb_aicp_http_ctrl((tb_aicp_http_ref_t)impl, TB_HTTP_OPTION_GET_PATH, &path);

            // is ssl?
            tb_bool_t bssl = tb_false;
            tb_aicp_http_ctrl((tb_aicp_http_ref_t)impl, TB_HTTP_OPTION_GET_SSL, &bssl);
                
            // set cookies
            tb_cookies_set(impl->option.cookies, host, path, bssl, p);
        }
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_aicp_http_open_func(tb_aicp_http_impl_t* impl, tb_size_t state, tb_aicp_http_open_func_t func, tb_cpointer_t priv);
static tb_bool_t tb_aicp_http_head_redt_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.open, tb_false);

    // trace
    tb_trace_d("head: redt: real: %lu, size: %lu, state: %s", real, size, tb_state_cstr(state));

    // done
    do
    {
        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // ok? 
        if (state == TB_STATE_OK)
        {
            // save read
            impl->content_read += real;

            // continue?
            if (impl->status.content_size < 0 || impl->content_read < (tb_hize_t)impl->status.content_size) return tb_true;
        }

        // ok? 
        tb_check_break(state == TB_STATE_OK || state == TB_STATE_CLOSED);

        // redirect failed
        state = TB_STATE_HTTP_REDIRECT_FAILED;

        // done location url
        tb_char_t const* location = tb_string_cstr(&impl->status.location);
        tb_assert_and_check_break(location);

        // trace
        tb_trace_d("redirect: %s", location);

        // only file path?
        if (tb_url_protocol_probe(location) == TB_URL_PROTOCOL_FILE) tb_url_path_set(&impl->option.url, location);
        // full url?
        else
        {
            // set url
            if (!tb_url_cstr_set(&impl->option.url, location)) break;
        }

        // done open
        if (!tb_aicp_http_open_done(impl)) break;

        // ok
        return tb_false;

    } while (0);

    // done func
    tb_aicp_http_open_func(impl, state, impl->func.open, impl->priv);

    // break
    return tb_false;
}
static tb_bool_t tb_aicp_http_head_read_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.open, tb_false);

    // trace
    tb_trace_d("head: read: %s, real: %lu, size: %lu, state: %s", tb_url_cstr(&impl->option.url), real, size, tb_state_cstr(state));

    // done
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;

        // walk 
        tb_long_t           ok = 0;
        tb_char_t           ch = '\0';
        tb_char_t const*    p = (tb_char_t const*)data;
        tb_char_t const*    e = p + real;
        while (p < e)
        {
            // the char
            ch = *p++;

            // error end?
            if (!ch)
            {
                ok = -1;
                tb_assert(0);
                break;
            }

            // append char to line
            if (ch != '\n') tb_string_chrcat(&impl->line_data, ch);
            // is line end?
            else
            {
                // strip '\r' if exists
                tb_char_t const*    pb = tb_string_cstr(&impl->line_data);
                tb_size_t           pn = tb_string_size(&impl->line_data);
                if (!pb || !pn)
                {
                    ok = -1;
                    tb_assert(0);
                    break;
                }

                if (pb[pn - 1] == '\r')
                    tb_string_strip(&impl->line_data, pn - 1);

                // trace
                tb_trace_d("response: %s", pb);
     
                // do callback
                if (impl->option.head_func && !impl->option.head_func(pb, impl->option.head_priv)) 
                {
                    ok = -1;
                    tb_assert(0);
                    break;
                }
                
                // end?
                if (!tb_string_size(&impl->line_data)) 
                {
                    // ok
                    ok = 1;
                    break;
                }

                // done the head response
                if (!tb_aicp_http_head_resp_done(impl)) 
                {   
                    // save the error state
                    if (impl->status.state != TB_STATE_OK) state = impl->status.state;

                    // error
                    ok = -1;
                    break;
                }

                // clear line data
                tb_string_clear(&impl->line_data);

                // line++
                impl->line_size++;
            }
        }

        // continue ?
        if (!ok) return tb_true;
        // end?
        else if (ok > 0) 
        {
            // trace
            tb_trace_d("head: read: end, left: %lu", e - p);
 
            // trace
            tb_trace_d("response: ok");

            // redirect?
            if (tb_string_size(&impl->status.location) && impl->redirect_tryn++ < impl->option.redirect)
            {
                // save the redirect read
                impl->content_read = e - p;

                // read the left data
                if (impl->status.content_size < 0 || impl->content_read < (tb_hize_t)impl->status.content_size)
                {
                    if (!tb_async_stream_read(impl->stream, 0, tb_aicp_http_head_redt_func, impl)) break;
                }
                // no left data, redirect it directly
                else tb_aicp_http_head_redt_func(impl->stream, TB_STATE_OK, tb_null, 0, 0, impl);
                return tb_false;
            }

            // switch to cstream if chunked
            if (impl->status.bchunked)
            {
                // init cstream
                if (impl->cstream)
                {
                    if (!tb_async_stream_ctrl(impl->cstream, TB_STREAM_CTRL_FLTR_SET_STREAM, impl->stream)) break;
                }
                else impl->cstream = tb_async_stream_init_filter_from_chunked(impl->stream, tb_true);
                tb_assert_and_check_break(impl->cstream);

                // push the left data to filter
                if (p < e)
                {
                    // the filter
                    tb_filter_ref_t filter = tb_null;
                    if (!tb_async_stream_ctrl(impl->cstream, TB_STREAM_CTRL_FLTR_GET_FILTER, &filter)) break;
                    tb_assert_and_check_break(filter);

                    // push data
                    if (!tb_filter_push(filter, (tb_byte_t const*)p, e - p)) break;
                    p = e;
                }

                // try to open cstream directly, because the stream have been opened 
                if (!tb_async_stream_open_try(impl->cstream)) break;

                // using cstream
                impl->stream = impl->cstream;

                // disable seek
                impl->status.bseeked = 0;
            }

            // switch to zstream if gzip or deflate
            if (impl->option.bunzip && (impl->status.bgzip || impl->status.bdeflate))
            {
#ifdef TB_CONFIG_PACKAGE_HAVE_ZLIB
                // init zstream
                if (impl->zstream)
                {
                    if (!tb_async_stream_ctrl(impl->zstream, TB_STREAM_CTRL_FLTR_SET_STREAM, impl->stream)) break;
                }
                else impl->zstream = tb_async_stream_init_filter_from_zip(impl->stream, impl->status.bgzip? TB_ZIP_ALGO_GZIP : TB_ZIP_ALGO_ZLIB, TB_ZIP_ACTION_INFLATE);
                tb_assert_and_check_break(impl->zstream);

                // the filter
                tb_filter_ref_t filter = tb_null;
                if (!tb_async_stream_ctrl(impl->zstream, TB_STREAM_CTRL_FLTR_GET_FILTER, &filter)) break;
                tb_assert_and_check_break(filter);

                // ctrl filter
                if (!tb_filter_ctrl(filter, TB_FILTER_CTRL_ZIP_SET_ALGO, impl->status.bgzip? TB_ZIP_ALGO_GZIP : TB_ZIP_ALGO_ZLIB, TB_ZIP_ACTION_INFLATE)) break;

                // limit the filter input size
                if (impl->status.content_size > 0) tb_filter_limit(filter, impl->status.content_size);

                // push the left data to filter
                if (p < e)
                {
                    // push data
                    if (!tb_filter_push(filter, (tb_byte_t const*)p, e - p)) break;
                    p = e;
                }

                // try to open zstream directly, because the stream have been opened 
                if (!tb_async_stream_open_try(impl->zstream)) break;

                // using zstream
                impl->stream = impl->zstream;

                // disable seek
                impl->status.bseeked = 0;
#else
                // trace
                tb_trace_w("gzip is not supported now! please enable it from config if you need it.");

                // not supported
                state = TB_STATE_HTTP_GZIP_NOT_SUPPORTED;
                break;
#endif
            }

            // cache the left data
            if (p < e) tb_buffer_memncat(&impl->cache_data, (tb_byte_t const*)p, e - p);
            p = e;

            // ok
            state = TB_STATE_OK;

            // dump status
#if defined(__tb_debug__) && TB_TRACE_MODULE_DEBUG
            tb_http_status_dump(&impl->status);
#endif
        }
        // error?
        else 
        {
            // trace
            tb_trace_d("head: read: %s, error, state: %s", tb_url_cstr(&impl->option.url), tb_state_cstr(state));
        }

    } while (0);

    // done func
    tb_aicp_http_open_func(impl, state, impl->func.open, impl->priv);

    // break 
    return tb_false;
}
static tb_bool_t tb_aicp_http_head_post_func(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_hize_t save, tb_size_t rate, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.open, tb_false);

    // trace
    tb_trace_d("head: post: percent: %llu%%, size: %lu, state: %s", size > 0? (offset * 100 / size) : 0, save, tb_state_cstr(state));

    // done
    tb_bool_t bpost = tb_false;
    do
    {
        // done func
        if (impl->option.post_func && !impl->option.post_func(state, offset, size, save, rate, impl->option.post_priv)) 
        {
            state = TB_STATE_UNKNOWN_ERROR;
            break;
        }
            
        // ok? continue to post
        if (state == TB_STATE_OK) bpost = tb_true;
        // closed? read head
        else if (state == TB_STATE_CLOSED)
        {
            // reset state
            state = TB_STATE_UNKNOWN_ERROR;

            // clear line size
            impl->line_size = 0;

            // clear line data
            tb_string_clear(&impl->line_data);

            // clear cache data
            tb_buffer_clear(&impl->cache_data);
            impl->cache_read = 0;

            // post read 
            if (!tb_async_stream_read(impl->stream, 0, tb_aicp_http_head_read_func, impl)) break;
        }
        // failed?
        else break;

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK)
    {
        // done func
        tb_aicp_http_open_func(impl, state, impl->func.open, impl->priv);
    }
 
    // ok?
    return bpost;
}
static tb_bool_t tb_aicp_http_head_writ_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.open, tb_false);

    // trace
    tb_trace_d("head: writ: %s, real: %lu, size: %lu, state: %s", tb_url_cstr(&impl->option.url), real, size, tb_state_cstr(state));

    // done
    tb_bool_t bwrit = tb_false;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;

        // not finished? continue it
        if (real < size)
        {
            // continue to writ
            bwrit = tb_true;
        }
        // finished? post data
        else if (impl->option.method == TB_HTTP_METHOD_POST)
        {
            // check
            tb_assert_and_check_break(impl->transfer);
 
            // post data
            if (!tb_async_transfer_done(impl->transfer, tb_aicp_http_head_post_func, impl)) break;
        }
        // finished? read data
        else
        {
            // clear line size
            impl->line_size = 0;

            // clear line data
            tb_string_clear(&impl->line_data);

            // clear cache data
            tb_buffer_clear(&impl->cache_data);
            impl->cache_read = 0;

            // post read 
            if (!tb_async_stream_read(impl->stream, 0, tb_aicp_http_head_read_func, impl)) break;
        }

        // ok
        state = TB_STATE_OK;

    } while (0);
 
    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        tb_aicp_http_open_func(impl, state, impl->func.open, impl->priv);
    }
 
    // ok?
    return bwrit;
}
static tb_bool_t tb_aicp_http_post_open_func(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.open, tb_false);

    // trace
    tb_trace_d("post: open: offset: %lu, size: %lu, state: %s", offset, size, tb_state_cstr(state));

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;

        // no post size?
        if (size < 0)
        {
            state = TB_STATE_HTTP_POST_FAILED;
            break;
        }

        // the head data and size
        tb_size_t           head_size = 0;
        tb_char_t const*    head_data = tb_aicp_http_head_format(impl, size, &head_size, &state);
        tb_check_break(head_data && head_size);
        
        // trace
        tb_trace_d("request[%lu]:\n%s", head_size, head_data);

        // post writ head
        if (!tb_async_stream_writ(impl->stream, (tb_byte_t const*)head_data, head_size, tb_aicp_http_head_writ_func, impl)) break;

        // ok
        state = TB_STATE_OK;

    } while (0);
 
    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        tb_aicp_http_open_func(impl, state, impl->func.open, impl->priv);
    }
 
    // ok?
    return ok;
}
static tb_bool_t tb_aicp_http_sock_open_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.open, tb_false);

    // trace
    tb_trace_d("sock: open: state: %s", tb_state_cstr(state));

    // done
    tb_bool_t ok = tb_true;
    do
    {
        // ok? 
        tb_check_break(state == TB_STATE_OK);

        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // reset state
        state = TB_STATE_UNKNOWN_ERROR;

        // get?
        if (impl->option.method == TB_HTTP_METHOD_GET)
        {
            // the head data and size
            tb_size_t           head_size = 0;
            tb_char_t const*    head_data = tb_aicp_http_head_format(impl, 0, &head_size, tb_null);
            tb_check_break(head_data && head_size);
            
            // trace
            tb_trace_d("request:\n%s", head_data);

            // post writ head
            ok = tb_async_stream_open_writ(impl->stream, (tb_byte_t const*)head_data, head_size, tb_aicp_http_head_writ_func, impl);
        }
        // post?
        else if (impl->option.method == TB_HTTP_METHOD_POST)
        {
            // init transfer
            if (!impl->transfer) impl->transfer = tb_async_transfer_init(tb_async_stream_aicp(impl->stream), tb_false);
            tb_assert_and_check_break(impl->transfer);

            // init transfer istream
            tb_char_t const* url = tb_url_cstr(&impl->option.post_url);
            if (impl->option.post_data && impl->option.post_size)
            {
                if (!tb_async_transfer_init_istream_from_data(impl->transfer, impl->option.post_data, impl->option.post_size)) break;
            }
            else if (url) 
            {
                if (!tb_async_transfer_init_istream_from_url(impl->transfer, url)) break;
            }

            // init transfer ostream
            if (!tb_async_transfer_init_ostream(impl->transfer, impl->stream)) break;

            // limit rate
            if (impl->option.post_lrate) tb_async_transfer_limitrate(impl->transfer, impl->option.post_lrate);

            // open transfer
            ok = tb_async_transfer_open(impl->transfer, 0, tb_aicp_http_post_open_func, impl);
        }
        else tb_assert_and_check_break(0);

        // ok
        state = TB_STATE_OK;

    } while (0);
 
    // failed?
    if (state != TB_STATE_OK) 
    {
        // done func
        tb_aicp_http_open_func(impl, state, impl->func.open, impl->priv);
    }
 
    // ok?
    return ok;
}
static tb_bool_t tb_aicp_http_read_func(tb_async_stream_ref_t stream, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.read, tb_false);

    // ok? update the content read 
    if (state == TB_STATE_OK) impl->content_read += real;

    // trace
    tb_trace_d("read: %s, real: %lu, offset: %llu <? %llu, state: %s", tb_url_cstr(&impl->option.url), real, impl->content_read, impl->status.content_size, tb_state_cstr(state));

    // done func
    tb_bool_t ok = impl->func.read((tb_aicp_http_ref_t)impl, state, data, real, size, impl->priv);

    // end?
    if (ok && state == TB_STATE_OK && impl->status.content_size >= 0 && impl->content_read >= (tb_hize_t)impl->status.content_size)
    {
        // done func: closed
        impl->func.read((tb_aicp_http_ref_t)impl, TB_STATE_CLOSED, data, 0, size, impl->priv);

        // break reading
        ok = tb_false;
    }

    // ok?
    return ok;
}
static tb_bool_t tb_aicp_http_task_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.task, tb_false);

    // trace
    tb_trace_d("task: state: %s", tb_state_cstr(state));

    // done func
    return impl->func.task((tb_aicp_http_ref_t)impl, state, impl->priv);
}
static tb_void_t tb_aicp_http_clos_clear(tb_aicp_http_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl && impl->stream);

    // reset stream
    impl->stream = impl->sstream;

    // clear the content read size
    impl->content_read = 0;

    // closed
    tb_atomic_set(&impl->state, TB_STATE_CLOSED);
}
static tb_void_t tb_aicp_http_clos_func(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return(impl && impl->stream && impl->func.clos);

    // trace
    tb_trace_d("clos: notify: ..");

    // clear it
    tb_aicp_http_clos_clear(impl);

    // done func
    impl->func.clos((tb_aicp_http_ref_t)impl, state, impl->priv);

    // trace
    tb_trace_d("clos: notify: ok");
}
static tb_void_t tb_aicp_http_clos_transfer_func(tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return(impl && impl->stream && impl->func.clos);

    // trace
    tb_trace_d("clos: transfer: notify: ..");

    // done func directly, because the stream have been closed by transfer
    tb_aicp_http_clos_func(impl->stream, state, impl);

    // trace
    tb_trace_d("clos: transfer: notify: ok");
}
static tb_void_t tb_aicp_http_clos_opening_func(tb_aicp_http_ref_t http, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return(impl && impl->clos_opening.func);

    // trace
    tb_trace_d("clos: opening");

    // done
    impl->status.state = impl->clos_opening.state;
    impl->clos_opening.func(http, impl->status.state, &impl->status, impl->clos_opening.priv);
}
static tb_void_t tb_aicp_http_open_clos(tb_async_stream_ref_t stream, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return(impl && impl->stream && impl->func.open);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // check
        tb_assert_and_check_break(state == TB_STATE_OK);

        // killed?
        if (TB_STATE_KILLING == tb_atomic_get(&impl->state))
        {
            state = TB_STATE_KILLED;
            break;
        }

        // reset state
        state = TB_STATE_HTTP_UNKNOWN_ERROR;

        // reset stream
        impl->stream = impl->sstream;

        // the host is changed?
        tb_bool_t           host_changed = tb_true;
        tb_char_t const*    host_old = tb_null;
        tb_char_t const*    host_new = tb_url_host(&impl->option.url);
        tb_async_stream_ctrl(impl->stream, TB_STREAM_CTRL_GET_HOST, &host_old);
        if (host_old && host_new && !tb_stricmp(host_old, host_new)) host_changed = tb_false;

        // trace
        tb_trace_d("connect: host: %s", host_changed? "changed" : "keep");

        // ctrl stream
        if (!tb_async_stream_ctrl(impl->stream, TB_STREAM_CTRL_SET_URL, tb_url_cstr(&impl->option.url))) break;
        if (!tb_async_stream_ctrl(impl->stream, TB_STREAM_CTRL_SET_TIMEOUT, impl->option.timeout)) break;

        // dump option
#if defined(__tb_debug__) && TB_TRACE_MODULE_DEBUG
        tb_http_option_dump(&impl->option);
#endif

        // clear status
        tb_http_status_cler(&impl->status, host_changed);

        // open the stream
        ok = tb_async_stream_open(impl->stream, tb_aicp_http_sock_open_func, impl);

    } while (0);

    // failed?
    if (!ok)
    {
        // done func
        tb_aicp_http_open_func(impl, state, impl->func.open, impl->priv);
    }
}
static tb_void_t tb_aicp_http_open_clos_transfer(tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)priv;
    tb_assert_and_check_return(impl && impl->stream);

    // done func directly, because the stream have been closed by transfer
    tb_aicp_http_open_clos(impl->stream, state, impl);
}
static tb_bool_t tb_aicp_http_open_done(tb_aicp_http_impl_t* impl)
{
    // check
    tb_assert_and_check_return_val(impl && impl->stream && impl->func.open, tb_false);

    // close transfer
    if (impl->transfer) return tb_async_transfer_clos(impl->transfer, tb_aicp_http_open_clos_transfer, impl);
    // close stream 
    else return tb_async_stream_clos(impl->stream, tb_aicp_http_open_clos, impl);
}
static tb_bool_t tb_aicp_http_open_func(tb_aicp_http_impl_t* impl, tb_size_t state, tb_aicp_http_open_func_t func, tb_cpointer_t priv)
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
        impl->status.state = state;
        if (func) ok = func((tb_aicp_http_ref_t)impl, state, &impl->status, priv);
    }
    // failed? 
    else 
    {
        // init func and state
        impl->clos_opening.func   = func;
        impl->clos_opening.priv   = priv;
        impl->clos_opening.state  = state;

        // close it
        ok = tb_aicp_http_clos((tb_aicp_http_ref_t)impl, tb_aicp_http_clos_opening_func, tb_null);
    }

    // ok?
    return ok;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_aicp_http_ref_t tb_aicp_http_init(tb_aicp_ref_t aicp)
{
    // check
    tb_assert_and_check_return_val(aicp, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_aicp_http_impl_t*    impl = tb_null;
    do
    {
        // make impl
        impl = tb_malloc0_type(tb_aicp_http_impl_t);
        tb_assert_and_check_break(impl);

        // init state
        impl->state = TB_STATE_CLOSED;

        // init stream
        impl->stream = impl->sstream = tb_async_stream_init_sock(aicp);
        tb_assert_and_check_break(impl->stream);

        // init head
        impl->head = tb_hash_map_init(8, tb_element_str(tb_false), tb_element_str(tb_false));
        tb_assert_and_check_break(impl->head);

        // init cookies data
        if (!tb_string_init(&impl->cookies)) break;

        // init line data
        if (!tb_string_init(&impl->line_data)) break;

        // init cache data
        if (!tb_buffer_init(&impl->cache_data)) break;
        impl->cache_read = 0;

        // init option
        if (!tb_http_option_init(&impl->option)) break;

        // init status
        if (!tb_http_status_init(&impl->status)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        if (impl) tb_aicp_http_exit((tb_aicp_http_ref_t)impl);
        impl = tb_null;
    }

    // ok?
    return (tb_aicp_http_ref_t)impl;
}
tb_void_t tb_aicp_http_kill(tb_aicp_http_ref_t http)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return(impl);

    // kill it
    tb_size_t state = tb_atomic_fetch_and_set(&impl->state, TB_STATE_KILLING);
    tb_check_return(state != TB_STATE_KILLING);

    // trace
    tb_trace_d("kill: ..");

    // kill transfer
    if (impl->transfer) tb_async_transfer_kill(impl->transfer);

    // kill stream
    if (impl->stream) tb_async_stream_kill(impl->stream);
}
tb_bool_t tb_aicp_http_exit(tb_aicp_http_ref_t http)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("exit: ..");

    // kill it first
    tb_aicp_http_kill(http);

    // try closing it
    tb_size_t tryn = 30;
    tb_bool_t ok = tb_false;
    while (!(ok = tb_aicp_http_clos_try(http)) && tryn--)
    {
        // wait some time
        tb_msleep(200);
    }

    // close failed?
    if (!ok)
    {
        // trace
        tb_trace_e("exit: %s: failed!", tb_url_cstr(&impl->option.url));
        return tb_false;
    }

    // exit transfer
    if (impl->transfer) tb_async_transfer_exit(impl->transfer);
    impl->transfer = tb_null;

    // exit zstream
    if (impl->zstream) tb_async_stream_exit(impl->zstream);
    impl->zstream = tb_null;

    // exit cstream
    if (impl->cstream) tb_async_stream_exit(impl->cstream);
    impl->cstream = tb_null;

    // exit sstream
    if (impl->sstream) tb_async_stream_exit(impl->sstream);
    impl->sstream = tb_null;

    // exit stream
    impl->stream = tb_null;

    // exit status
    tb_http_status_exit(&impl->status);

    // exit option
    tb_http_option_exit(&impl->option);

    // exit line data
    tb_string_exit(&impl->line_data);

    // exit cache data
    tb_buffer_exit(&impl->cache_data);

    // exit cookies data
    tb_string_exit(&impl->cookies);

    // exit head
    if (impl->head) tb_hash_map_exit(impl->head);
    impl->head = tb_null;

    // free it
    tb_free(impl);

    // trace
    tb_trace_d("exit: ok");

    // ok
    return tb_true;
}
tb_bool_t tb_aicp_http_open(tb_aicp_http_ref_t http, tb_aicp_http_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && func, tb_false);
    
    // set opening
    tb_size_t state = tb_atomic_fetch_and_pset(&impl->state, TB_STATE_CLOSED, TB_STATE_OPENING);

    // opened? done func directly
    if (state == TB_STATE_OPENED)
    {
        impl->status.state = TB_STATE_OK;
        func(http, impl->status.state, &impl->status, priv);
        return tb_true;
    }

    // must be closed
    tb_assert_and_check_return_val(state == TB_STATE_CLOSED, tb_false);

    // init open
    impl->func.open = func;
    impl->priv      = priv;

    // clear redirect
    impl->redirect_tryn = 0;

    // done open
    return tb_aicp_http_open_done(impl);
}
tb_bool_t tb_aicp_http_clos(tb_aicp_http_ref_t http, tb_aicp_http_clos_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);

    // trace
    tb_trace_d("clos: ..");

    // try closing ok?
    if (tb_aicp_http_clos_try(http))
    {
        // done func
        func(http, TB_STATE_OK, priv);
        return tb_true;
    }

    // init func
    impl->func.clos = func;
    impl->priv      = priv;

    // close transfer
    if (impl->transfer) return tb_async_transfer_clos(impl->transfer, tb_aicp_http_clos_transfer_func, impl);
    // close stream
    else return tb_async_stream_clos(impl->stream, tb_aicp_http_clos_func, impl);
}
tb_bool_t tb_aicp_http_clos_try(tb_aicp_http_ref_t http)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && impl->stream, tb_false);

    // trace
    tb_trace_d("clos: try: %s: ..", tb_url_cstr(&impl->option.url));

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

        // try closing transfer
        if (impl->transfer && !tb_async_transfer_clos_try(impl->transfer)) break;

        // try closing it
        if (!tb_async_stream_clos_try(impl->stream)) break;

        // clear it
        tb_aicp_http_clos_clear(impl);

        // ok
        ok = tb_true;
    
    } while (0);

    // trace
    tb_trace_d("clos: try: %s: %s", tb_url_cstr(&impl->option.url), ok? "ok" : "no");

    // ok?
    return ok;
}
tb_bool_t tb_aicp_http_read(tb_aicp_http_ref_t http, tb_size_t size, tb_aicp_http_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);

    // post read
    return tb_aicp_http_read_after(http, 0, size, func, priv);
}
tb_bool_t tb_aicp_http_read_after(tb_aicp_http_ref_t http, tb_size_t delay, tb_size_t size, tb_aicp_http_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);
 
    // check state
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->state), tb_false);

    // read the cache data first, note: must be reentrant
    tb_byte_t const*    cache_data = tb_buffer_data(&impl->cache_data);
    tb_size_t           cache_size = tb_buffer_size(&impl->cache_data);
    if (cache_data && cache_size && impl->cache_read < cache_size)
    {
        // read cache
        impl->cache_read = cache_size;

        // update the content read 
        impl->content_read += cache_size;

        // done func
        tb_bool_t ok = func(http, TB_STATE_OK, cache_data, cache_size, cache_size, priv);

        // clear cache data
        tb_buffer_clear(&impl->cache_data);
        impl->cache_read = 0;

        // break?
        tb_check_return_val(ok, tb_true);
    }

    // init read
    impl->func.read = func;
    impl->priv      = priv;

    // post read
    return tb_async_stream_read_after(impl->stream, delay, size, tb_aicp_http_read_func, impl);
}
tb_bool_t tb_aicp_http_seek(tb_aicp_http_ref_t http, tb_hize_t offset, tb_aicp_http_seek_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);
 
    // set opening
    tb_size_t state = tb_atomic_fetch_and_pset(&impl->state, TB_STATE_CLOSED, TB_STATE_OPENING);

    // killed?
    tb_assert_and_check_return_val(state != TB_STATE_KILLING, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // trace
        tb_trace_d("seek: %llu", offset);

        // init open
        impl->func.open = tb_aicp_http_open_seek_func;
        impl->priv      = &impl->open_and.seek;

        // init open and seek
        impl->open_and.seek.func = func;
        impl->open_and.seek.priv = priv;
        impl->open_and.seek.offset = offset;

        // clear redirect
        impl->redirect_tryn = 0;

        // set range
        impl->option.range.bof = offset;
        impl->option.range.eof = impl->status.document_size > 0? impl->status.document_size - 1 : 0;

        // done open
        if (!tb_aicp_http_open_done(impl)) break;

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
tb_bool_t tb_aicp_http_task(tb_aicp_http_ref_t http, tb_size_t delay, tb_aicp_http_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && impl->stream && func, tb_false);
 
    // check state
    tb_assert_and_check_return_val(TB_STATE_OPENED == tb_atomic_get(&impl->state), tb_false);

    // init task
    impl->func.task = func;
    impl->priv      = priv;

    // post task
    return tb_async_stream_task(impl->stream, delay, tb_aicp_http_task_func, impl);
}
tb_bool_t tb_aicp_http_open_read(tb_aicp_http_ref_t http, tb_size_t size, tb_aicp_http_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && func, tb_false);

    // init open and read
    impl->open_and.read.func = func;
    impl->open_and.read.priv = priv;
    impl->open_and.read.size = size;
    return tb_aicp_http_open(http, tb_aicp_http_open_read_func, &impl->open_and.read);
}
tb_bool_t tb_aicp_http_open_seek(tb_aicp_http_ref_t http, tb_hize_t offset, tb_aicp_http_seek_func_t func, tb_cpointer_t priv)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && func, tb_false);

    // open and seek
    return tb_aicp_http_seek(http, offset, func, priv);
}
tb_aicp_ref_t tb_aicp_http_aicp(tb_aicp_http_ref_t http)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && impl->stream, tb_null);

    // the aicp 
    return tb_async_stream_aicp(impl->stream);
}
tb_bool_t tb_aicp_http_ctrl(tb_aicp_http_ref_t http, tb_size_t option, ...)
{
    // check
    tb_aicp_http_impl_t* impl = (tb_aicp_http_impl_t*)http;
    tb_assert_and_check_return_val(impl && impl->sstream && option, tb_false);

    // check
    if (TB_HTTP_OPTION_CODE_IS_SET(option) && !tb_async_stream_is_closed(impl->sstream))
    {
        // abort
        tb_assert(0);
        return tb_false;
    }

    // init args
    tb_va_list_t args;
    tb_va_start(args, option);

    // done
    tb_bool_t ok = tb_http_option_ctrl(&impl->option, option, args);

    // exit args
    tb_va_end(args);
 
    // ok?
    return ok;
}
