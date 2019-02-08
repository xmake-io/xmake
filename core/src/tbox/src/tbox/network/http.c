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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        http.c
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "http"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "http.h"
#include "impl/http/date.h"
#include "impl/http/option.h"
#include "impl/http/status.h"
#include "impl/http/method.h"
#include "../zip/zip.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../string/string.h"
#include "../stream/stream.h"
#include "../platform/platform.h"
#include "../algorithm/algorithm.h"
#include "../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the http type
typedef struct __tb_http_t
{
    // the option
    tb_http_option_t    option;

    // the status 
    tb_http_status_t    status;

    // the stream
    tb_stream_ref_t     stream;

    // the sstream for sock
    tb_stream_ref_t     sstream;

    // the cstream for chunked
    tb_stream_ref_t     cstream;

    // the zstream for gzip/deflate
    tb_stream_ref_t     zstream;

    // the head
    tb_hash_map_ref_t   head;

    // is opened?
    tb_bool_t           bopened;

    // the request data
    tb_string_t         request;

    // the cookies
    tb_string_t         cookies;

    // the request/response data for decreasing stack size
    tb_char_t           data[8192];

}tb_http_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_http_connect(tb_http_t* http)
{
    // check
    tb_assert_and_check_return_val(http && http->stream, tb_false);
    
    // done
    tb_bool_t ok = tb_false;
    do
    {
        // the host is changed?
        tb_bool_t           host_changed = tb_true;
        tb_char_t const*    host_old = tb_null;
        tb_char_t const*    host_new = tb_url_host(&http->option.url);
        tb_stream_ctrl(http->stream, TB_STREAM_CTRL_GET_HOST, &host_old);
        if (host_old && host_new && !tb_stricmp(host_old, host_new)) host_changed = tb_false;

        // trace
        tb_trace_d("connect: host: %s", host_changed? "changed" : "keep");

        // set url and timeout
        if (!tb_stream_ctrl(http->stream, TB_STREAM_CTRL_SET_URL, tb_url_cstr(&http->option.url))) break;
        if (!tb_stream_ctrl(http->stream, TB_STREAM_CTRL_SET_TIMEOUT, http->option.timeout)) break;

        // reset keep-alive and close socket first before connecting anthor host
        if (host_changed && !tb_stream_ctrl(http->stream, TB_STREAM_CTRL_SOCK_KEEP_ALIVE, tb_false)) break;

        // dump option
#if defined(__tb_debug__) && TB_TRACE_MODULE_DEBUG
        tb_http_option_dump(&http->option);
#endif
        
        // trace
        tb_trace_d("connect: ..");

        // clear status
        tb_http_status_cler(&http->status, host_changed);

        // open stream
        if (!tb_stream_open(http->stream)) break;

        // ok
        ok = tb_true;

    } while (0);


    // failed? save state
    if (!ok) http->status.state = tb_stream_state(http->stream);

    // trace
    tb_trace_d("connect: %s, state: %s", ok? "ok" : "failed", tb_state_cstr(http->status.state));

    // ok?
    return ok;
}
static tb_bool_t tb_http_request_post(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_hize_t save, tb_size_t rate, tb_cpointer_t priv)
{
    // check
    tb_http_t* http = (tb_http_t*)priv;
    tb_assert_and_check_return_val(http && http->stream, tb_false);

    // trace
    tb_trace_d("post: percent: %llu%%, size: %lu, state: %s", size > 0? (offset * 100 / size) : 0, save, tb_state_cstr(state));

    // done func
    if (http->option.post_func && !http->option.post_func(state, offset, size, save, rate, http->option.post_priv)) 
        return tb_false;

    // ok?
    return tb_true;
}
static tb_bool_t tb_http_request(tb_http_t* http)
{
    // check
    tb_assert_and_check_return_val(http && http->stream, tb_false);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     pstream = tb_null;
    tb_hong_t           post_size = 0;
    do
    {
        // clear line data
        tb_string_clear(&http->request);

        // init the head value
        tb_static_string_t value;
        if (!tb_static_string_init(&value, http->data, sizeof(http->data))) break;

        // init method
        tb_char_t const* method = tb_http_method_cstr(http->option.method);
        tb_assert_and_check_break(method);

        // init path
        tb_char_t const* path = tb_url_path(&http->option.url);
        tb_assert_and_check_break(path);

        // init args
        tb_char_t const* args = tb_url_args(&http->option.url);

        // init host
        tb_char_t const* host = tb_url_host(&http->option.url);
        tb_assert_and_check_break(host);
        tb_hash_map_insert(http->head, "Host", host);

        // init accept
        tb_hash_map_insert(http->head, "Accept", "*/*");

        // init connection
        tb_hash_map_insert(http->head, "Connection", http->status.balived? "keep-alive" : "close");

        // init cookies
        tb_bool_t cookie = tb_false;
        if (http->option.cookies)
        {
            // set cookie
            if (tb_cookies_get(http->option.cookies, host, path, tb_url_ssl(&http->option.url), &http->cookies))
            {
                tb_hash_map_insert(http->head, "Cookie", tb_string_cstr(&http->cookies));
                cookie = tb_true;
            }
        }

        // no cookie? remove it
        if (!cookie) tb_hash_map_remove(http->head, "Cookie");

        // init range
        if (http->option.range.bof && http->option.range.eof >= http->option.range.bof)
            tb_static_string_cstrfcpy(&value, "bytes=%llu-%llu", http->option.range.bof, http->option.range.eof);
        else if (http->option.range.bof && !http->option.range.eof)
            tb_static_string_cstrfcpy(&value, "bytes=%llu-", http->option.range.bof);
        else if (!http->option.range.bof && http->option.range.eof)
            tb_static_string_cstrfcpy(&value, "bytes=0-%llu", http->option.range.eof);
        else if (http->option.range.bof > http->option.range.eof)
        {
            http->status.state = TB_STATE_HTTP_RANGE_INVALID;
            break;
        }

        // update range
        if (tb_static_string_size(&value)) 
            tb_hash_map_insert(http->head, "Range", tb_static_string_cstr(&value));
        // remove range
        else tb_hash_map_remove(http->head, "Range");

        // init post
        if (http->option.method == TB_HTTP_METHOD_POST)
        {
            // done
            tb_bool_t post_ok = tb_false;
            do
            {
                // init pstream
                tb_char_t const* url = tb_url_cstr(&http->option.post_url);
                if (http->option.post_data && http->option.post_size)
                    pstream = tb_stream_init_from_data(http->option.post_data, http->option.post_size);
                else if (url) pstream = tb_stream_init_from_url(url);
                tb_assert_and_check_break(pstream);

                // open pstream
                if (!tb_stream_open(pstream)) break;

                // the post size
                post_size = tb_stream_size(pstream);
                tb_assert_and_check_break(post_size >= 0);

                // append post size
                tb_static_string_cstrfcpy(&value, "%lld", post_size);
                tb_hash_map_insert(http->head, "Content-Length", tb_static_string_cstr(&value));

                // ok
                post_ok = tb_true;

            } while (0);

            // init post failed?
            if (!post_ok) 
            {
                http->status.state = TB_STATE_HTTP_POST_FAILED;
                break;
            }
        }
        // remove post
        else tb_hash_map_remove(http->head, "Content-Length");

        // replace the custom head 
        tb_char_t const* head_data = (tb_char_t const*)tb_buffer_data(&http->option.head_data);
        tb_char_t const* head_tail = head_data + tb_buffer_size(&http->option.head_data);
        while (head_data < head_tail)
        {
            // the name and data
            tb_char_t const* name = head_data;
            tb_char_t const* data = head_data + tb_strlen(name) + 1;
            tb_check_break(data < head_tail);

            // replace it
            tb_hash_map_insert(http->head, name, data);

            // next
            head_data = data + tb_strlen(data) + 1;
        }

        // exit the head value
        tb_static_string_exit(&value);

        // check head
        tb_assert_and_check_break(tb_hash_map_size(http->head));

        // append method
        tb_string_cstrcat(&http->request, method);

        // append ' '
        tb_string_chrcat(&http->request, ' ');

        // encode path
        tb_url_encode2(path, tb_strlen(path), http->data, sizeof(http->data) - 1);
        path = http->data;

        // append path
        tb_string_cstrcat(&http->request, path);

        // append args if exists
        if (args) 
        {
            // append '?'
            tb_string_chrcat(&http->request, '?');

            // encode args
            tb_url_encode2(args, tb_strlen(args), http->data, sizeof(http->data) - 1);
            args = http->data;

            // append args
            tb_string_cstrcat(&http->request, args);
        }

        // append ' '
        tb_string_chrcat(&http->request, ' ');

        // append version, HTTP/1.1
        tb_string_cstrfcat(&http->request, "HTTP/1.%1u\r\n", http->status.balived? http->status.version : http->option.version);

        // append key: value
        tb_for_all (tb_hash_map_item_ref_t, item, http->head)
        {
            if (item && item->name && item->data) 
                tb_string_cstrfcat(&http->request, "%s: %s\r\n", (tb_char_t const*)item->name, (tb_char_t const*)item->data);
        }

        // append end
        tb_string_cstrcat(&http->request, "\r\n");

        // the request data and size
        tb_char_t const*    request_data = tb_string_cstr(&http->request);
        tb_size_t           request_size = tb_string_size(&http->request);
        tb_assert_and_check_break(request_data && request_size);
        
        // trace
        tb_trace_d("request[%lu]:\n%s", request_size, request_data);

        // writ request
        if (!tb_stream_bwrit(http->stream, (tb_byte_t const*)request_data, request_size)) break;

        // writ post
        if (http->option.method == TB_HTTP_METHOD_POST)
        {
            // post stream
            if (tb_transfer(pstream, http->stream, http->option.post_lrate, tb_http_request_post, http) != post_size)
            {
                http->status.state = TB_STATE_HTTP_POST_FAILED;
                break;
            }
        }

        // sync request
        if (!tb_stream_sync(http->stream, tb_false)) break;
    
        // ok
        ok = tb_true;
    }
    while (0);

    // failed?
    if (!ok && !http->status.state) http->status.state = TB_STATE_HTTP_REQUEST_FAILED;

    // exit pstream
    if (pstream) tb_stream_exit(pstream);
    pstream = tb_null;

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
static tb_bool_t tb_http_response_done(tb_http_t* http, tb_char_t const* line, tb_size_t indx)
{
    // check
    tb_assert_and_check_return_val(http && http->sstream && line, tb_false);

    // the first line? 
    tb_char_t const* p = line;
    if (!indx)
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
        http->status.version = *p - '0';
    
        // seek to the http code
        p++; while (tb_isspace(*p)) p++;

        // parse code
        tb_assert_and_check_return_val(*p && tb_isdigit(*p), tb_false);
        http->status.code = tb_stou32(p);

        // save state
        if (http->status.code == 200 || http->status.code == 206)
            http->status.state = TB_STATE_OK;
        else if (http->status.code == 204)
            http->status.state = TB_STATE_HTTP_RESPONSE_204;
        else if (http->status.code >= 300 && http->status.code <= 307)
            http->status.state = TB_STATE_HTTP_RESPONSE_300 + (http->status.code - 300);
        else if (http->status.code >= 400 && http->status.code <= 416)
            http->status.state = TB_STATE_HTTP_RESPONSE_400 + (http->status.code - 400);
        else if (http->status.code >= 500 && http->status.code <= 507)
            http->status.state = TB_STATE_HTTP_RESPONSE_500 + (http->status.code - 500);
        else http->status.state = TB_STATE_HTTP_RESPONSE_UNK;

        // check state code: 4xx & 5xx
        if (http->status.code >= 400 && http->status.code < 600) return tb_false;
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
            http->status.content_size = tb_stou64(p);
            if (http->status.document_size < 0) 
                http->status.document_size = http->status.content_size;
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
            http->status.bseeked = 1;
            http->status.document_size = document_size;
            if (http->status.content_size < 0) 
            {
                if (from && to > from) http->status.content_size = to - from;
                else if (!from && to) http->status.content_size = to;
                else if (from && !to && document_size > from) http->status.content_size = document_size - from;
                else http->status.content_size = document_size;
            }
        }
        // parse accept-ranges: "bytes "
        else if (!tb_strnicmp(line, "Accept-Ranges", 13))
        {
            // no stream, be able to seek
            http->status.bseeked = 1;
        }
        // parse content type
        else if (!tb_strnicmp(line, "Content-Type", 12)) 
        {
            tb_string_cstrcpy(&http->status.content_type, p);
            tb_assert_and_check_return_val(tb_string_size(&http->status.content_type), tb_false);
        }
        // parse transfer encoding
        else if (!tb_strnicmp(line, "Transfer-Encoding", 17))
        {
            if (!tb_stricmp(p, "chunked")) http->status.bchunked = 1;
        }
        // parse content encoding
        else if (!tb_strnicmp(line, "Content-Encoding", 16))
        {
            if (!tb_stricmp(p, "gzip")) http->status.bgzip = 1;
            else if (!tb_stricmp(p, "deflate")) http->status.bdeflate = 1;
        }
        // parse location
        else if (!tb_strnicmp(line, "Location", 8)) 
        {
            // redirect? check code: 301 - 307
            tb_assert_and_check_return_val(http->status.code > 300 && http->status.code < 308, tb_false);

            // save location
            tb_string_cstrcpy(&http->status.location, p);
        }
        // parse connection
        else if (!tb_strnicmp(line, "Connection", 10))
        {
            // keep alive?
            http->status.balived = !tb_stricmp(p, "close")? 0 : 1;

            // ctrl stream for sock
            if (!tb_stream_ctrl(http->sstream, TB_STREAM_CTRL_SOCK_KEEP_ALIVE, http->status.balived? tb_true : tb_false)) return tb_false;
        }
        // parse cookies
        else if (http->option.cookies && !tb_strnicmp(line, "Set-Cookie", 10))
        {
            // the host
            tb_char_t const* host = tb_null;
            tb_http_ctrl((tb_http_ref_t)http, TB_HTTP_OPTION_GET_HOST, &host);

            // the path
            tb_char_t const* path = tb_null;
            tb_http_ctrl((tb_http_ref_t)http, TB_HTTP_OPTION_GET_PATH, &path);

            // is ssl?
            tb_bool_t bssl = tb_false;
            tb_http_ctrl((tb_http_ref_t)http, TB_HTTP_OPTION_GET_SSL, &bssl);
                
            // set cookies
            tb_cookies_set(http->option.cookies, host, path, bssl, p);
        }
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_http_response(tb_http_t* http)
{
    // check
    tb_assert_and_check_return_val(http && http->stream, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // read line
        tb_long_t real = 0;
        tb_size_t indx = 0;
        while ((real = tb_stream_bread_line(http->stream, http->data, sizeof(http->data) - 1)) >= 0)
        {
            // trace
            tb_trace_d("response: %s", http->data);
 
            // do callback
            if (http->option.head_func && !http->option.head_func(http->data, http->option.head_priv)) break;
            
            // end?
            if (!real)
            {
                // switch to cstream if chunked
                if (http->status.bchunked)
                {
                    // init cstream
                    if (http->cstream)
                    {
                        if (!tb_stream_ctrl(http->cstream, TB_STREAM_CTRL_FLTR_SET_STREAM, http->stream)) break;
                    }
                    else http->cstream = tb_stream_init_filter_from_chunked(http->stream, tb_true);
                    tb_assert_and_check_break(http->cstream);

                    // open cstream, need not async
                    if (!tb_stream_open(http->cstream)) break;

                    // using cstream
                    http->stream = http->cstream;

                    // disable seek
                    http->status.bseeked = 0;
                }

                // switch to zstream if gzip or deflate
                if (http->option.bunzip && (http->status.bgzip || http->status.bdeflate))
                {
#if defined(TB_CONFIG_PACKAGE_HAVE_ZLIB) && defined(TB_CONFIG_MODULE_HAVE_ZIP)
                    // init zstream
                    if (http->zstream)
                    {
                        if (!tb_stream_ctrl(http->zstream, TB_STREAM_CTRL_FLTR_SET_STREAM, http->stream)) break;
                    }
                    else http->zstream = tb_stream_init_filter_from_zip(http->stream, http->status.bgzip? TB_ZIP_ALGO_GZIP : TB_ZIP_ALGO_ZLIB, TB_ZIP_ACTION_INFLATE);
                    tb_assert_and_check_break(http->zstream);

                    // the filter
                    tb_filter_ref_t filter = tb_null;
                    if (!tb_stream_ctrl(http->zstream, TB_STREAM_CTRL_FLTR_GET_FILTER, &filter)) break;
                    tb_assert_and_check_break(filter);

                    // ctrl filter
                    if (!tb_filter_ctrl(filter, TB_FILTER_CTRL_ZIP_SET_ALGO, http->status.bgzip? TB_ZIP_ALGO_GZIP : TB_ZIP_ALGO_ZLIB, TB_ZIP_ACTION_INFLATE)) break;

                    // limit the filter input size
                    if (http->status.content_size > 0) tb_filter_limit(filter, http->status.content_size);

                    // open zstream, need not async
                    if (!tb_stream_open(http->zstream)) break;

                    // using zstream
                    http->stream = http->zstream;

                    // disable seek
                    http->status.bseeked = 0;
#else
                    // trace
                    tb_trace_w("gzip is not supported now! please enable it from config if you need it.");

                    // not supported
                    http->status.state = TB_STATE_HTTP_GZIP_NOT_SUPPORTED;
                    break;
#endif
                }

                // trace
                tb_trace_d("response: ok");

                // dump status
#if defined(__tb_debug__) && TB_TRACE_MODULE_DEBUG
                tb_http_status_dump(&http->status);
#endif

                // ok
                ok = tb_true;
                break;
            }

            // done it
            if (!tb_http_response_done(http, http->data, indx++)) break;
        }

    } while (0);

    // ok?
    return ok;
}
static tb_bool_t tb_http_redirect(tb_http_t* http)
{
    // check
    tb_assert_and_check_return_val(http && http->stream, tb_false);

    // done
    tb_size_t i = 0;
    tb_bool_t ok = tb_true;
    for (i = 0; i < http->option.redirect && tb_string_size(&http->status.location); i++)
    {
        // read the redirect content
        if (http->status.content_size > 0)
        {
            tb_byte_t data[TB_STREAM_BLOCK_MAXN];
            tb_hize_t read = 0;
            tb_hize_t size = http->status.content_size;
            while (read < size) 
            {
                // the need
                tb_size_t need = (tb_size_t)tb_min(size - read, (tb_hize_t)TB_STREAM_BLOCK_MAXN);

                // read it
                if (!tb_stream_bread(http->stream, data, need)) break;

                // save size
                read += need;
            }

            // check
            tb_assert_pass_and_check_break(read == size);
        }

        // close stream
        if (http->stream && !tb_stream_clos(http->stream)) break;

        // switch to sstream
        http->stream = http->sstream;

        // get location url
        tb_char_t const* location = tb_string_cstr(&http->status.location);
        tb_assert_and_check_break(location);

        // trace
        tb_trace_d("redirect: %s", location);

        // only path?
        tb_size_t protocol = tb_url_protocol_probe(location);
        if (protocol == TB_URL_PROTOCOL_FILE) tb_url_path_set(&http->option.url, location);
        // full http url?
        else if (protocol == TB_URL_PROTOCOL_HTTP)
        {
            // set url
            if (!tb_url_cstr_set(&http->option.url, location)) break;
        }
        else 
        {
            // trace
            tb_trace_e("unsupported protocol for location %s", location);
            break;
        }

        // connect it
        if (!(ok = tb_http_connect(http))) break;

        // request it
        if (!(ok = tb_http_request(http))) break;

        // response it
        if (!(ok = tb_http_response(http))) break;
    }

    // ok?
    return ok && !tb_string_size(&http->status.location);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_http_ref_t tb_http_init()
{
    // done
    tb_bool_t   ok = tb_false;
    tb_http_t*  http = tb_null;
    do
    {
        // make http
        http = tb_malloc0_type(tb_http_t);
        tb_assert_and_check_break(http);

        // init stream
        http->stream = http->sstream = tb_stream_init_sock();
        tb_assert_and_check_break(http->stream);

        // init head
        http->head = tb_hash_map_init(8, tb_element_str(tb_false), tb_element_str(tb_false));
        tb_assert_and_check_break(http->head);

        // init request data
        if (!tb_string_init(&http->request)) break;

        // init cookies data
        if (!tb_string_init(&http->cookies)) break;

        // init option
        if (!tb_http_option_init(&http->option)) break;

        // init status
        if (!tb_http_status_init(&http->status)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        if (http) tb_http_exit((tb_http_ref_t)http);
        http = tb_null;
    }

    // ok?
    return (tb_http_ref_t)http;
}
tb_void_t tb_http_kill(tb_http_ref_t self)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return(http);

    // kill stream
    if (http->stream) tb_stream_kill(http->stream);
}
tb_void_t tb_http_exit(tb_http_ref_t self)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return(http);

    // close it
    tb_http_clos(self);

    // exit zstream
    if (http->zstream) tb_stream_exit(http->zstream);
    http->zstream = tb_null;

    // exit cstream
    if (http->cstream) tb_stream_exit(http->cstream);
    http->cstream = tb_null;

    // exit sstream
    if (http->sstream) tb_stream_exit(http->sstream);
    http->sstream = tb_null;

    // exit stream
    http->stream = tb_null;
    
    // exit status
    tb_http_status_exit(&http->status);

    // exit option
    tb_http_option_exit(&http->option);

    // exit cookies data
    tb_string_exit(&http->cookies);

    // exit request data
    tb_string_exit(&http->request);

    // exit head
    if (http->head) tb_hash_map_exit(http->head);
    http->head = tb_null;

    // free it
    tb_free(http);
}
tb_long_t tb_http_wait(tb_http_ref_t self, tb_size_t events, tb_long_t timeout)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return_val(http && http->stream, -1);

    // opened?
    tb_assert_and_check_return_val(http->bopened, -1);

    // wait it
    tb_long_t wait = tb_stream_wait(http->stream, events, timeout);

    // failed? save state
    if (wait < 0 && !http->status.state) http->status.state = tb_stream_state(http->stream);

    // ok?
    return wait;
}
tb_bool_t tb_http_open(tb_http_ref_t self)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return_val(http, tb_false);
    
    // opened?
    tb_assert_and_check_return_val(!http->bopened, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // connect it
        if (!tb_http_connect(http)) break;

        // request it
        if (!tb_http_request(http)) break;

        // response it
        if (!tb_http_response(http)) break;

        // redirect it
        if (!tb_http_redirect(http)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed? close it
    if (!ok) 
    {
        // close stream
        if (http->stream) tb_stream_clos(http->stream);

        // switch to sstream
        http->stream = http->sstream;
    }

    // is opened?
    http->bopened = ok;

    // ok?
    return ok;
}
tb_bool_t tb_http_clos(tb_http_ref_t self)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return_val(http, tb_false);
    
    // opened?
    tb_check_return_val(http->bopened, tb_true);

    // close stream
    if (http->stream && !tb_stream_clos(http->stream)) return tb_false;

    // switch to sstream
    http->stream = http->sstream;

    // clear opened
    http->bopened = tb_false;

    // ok
    return tb_true;
}
tb_bool_t tb_http_seek(tb_http_ref_t self, tb_hize_t offset)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return_val(http, tb_false);

    // opened?
    tb_assert_and_check_return_val(http->bopened, tb_false);

    // seeked?
    tb_check_return_val(http->status.bseeked, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // close stream
        if (http->stream && !tb_stream_clos(http->stream)) break;

        // switch to sstream
        http->stream = http->sstream;

        // trace
        tb_trace_d("seek: %llu", offset);

        // set range
        http->option.range.bof = offset;
        http->option.range.eof = http->status.document_size > 0? http->status.document_size - 1 : 0;

        // connect it
        if (!tb_http_connect(http)) break;

        // request it
        if (!tb_http_request(http)) break;

        // response it
        if (!tb_http_response(http)) break;

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
tb_long_t tb_http_read(tb_http_ref_t self, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return_val(http && http->stream, -1);

    // opened?
    tb_assert_and_check_return_val(http->bopened, -1);

    // read
    return tb_stream_read(http->stream, data, size);
}
tb_bool_t tb_http_bread(tb_http_ref_t self, tb_byte_t* data, tb_size_t size)
{   
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return_val(http && http->stream, tb_false);

    // opened?
    tb_assert_and_check_return_val(http->bopened, tb_false);

    // read
    tb_size_t read = 0;
    while (read < size)
    {
        // read data
        tb_long_t real = tb_stream_read(http->stream, data + read, size - read);

        // update size
        if (real > 0) read += real;
        // no data?
        else if (!real)
        {
            // wait
            tb_long_t e = tb_http_wait(self, TB_SOCKET_EVENT_RECV, http->option.timeout);
            tb_assert_and_check_break(e >= 0);

            // timeout?
            tb_check_break(e);

            // has read?
            tb_assert_and_check_break(e & TB_SOCKET_EVENT_RECV);
        }
        else break;
    }

    // ok?
    return read == size? tb_true : tb_false;
}
tb_bool_t tb_http_ctrl(tb_http_ref_t self, tb_size_t option, ...)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return_val(http && option, tb_false);

    // check
    if (TB_HTTP_OPTION_CODE_IS_SET(option) && http->bopened)
    {
        // abort
        tb_assert(0);
        return tb_false;
    }

    // init args
    tb_va_list_t args;
    tb_va_start(args, option);

    // done
    tb_bool_t ok = tb_http_option_ctrl(&http->option, option, args);

    // exit args
    tb_va_end(args);
 
    // ok?
    return ok;
}
tb_http_status_t const* tb_http_status(tb_http_ref_t self)
{
    // check
    tb_http_t* http = (tb_http_t*)self;
    tb_assert_and_check_return_val(http, tb_null);

    // the status
    return &http->status;
}

