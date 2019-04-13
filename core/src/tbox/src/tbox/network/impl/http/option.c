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
 * @file        option.c
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "http_option"
#define TB_TRACE_MODULE_DEBUG           (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "option.h"
#include "method.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_http_option_init(tb_http_option_t* option)
{    
    // check
    tb_assert_and_check_return_val(option, tb_false);

    // init option using the default value
    option->method     = TB_HTTP_METHOD_GET;
    option->redirect   = TB_HTTP_DEFAULT_REDIRECT;
    option->timeout    = TB_HTTP_DEFAULT_TIMEOUT;
    option->version    = 1; // HTTP/1.1
    option->bunzip     = 0;
    option->cookies    = tb_null;

    // init url
    if (!tb_url_init(&option->url)) return tb_false;

    // init post url
    if (!tb_url_init(&option->post_url)) return tb_false;

    // init head data
    if (!tb_buffer_init(&option->head_data)) return tb_false;

    // ok
    return tb_true;
}
tb_void_t tb_http_option_exit(tb_http_option_t* option)
{
    // check
    tb_assert_and_check_return(option);

    // exit url
    tb_url_exit(&option->url);

    // exit post url
    tb_url_exit(&option->post_url);

    // exit head data
    tb_buffer_exit(&option->head_data);

    // clear cookies
    option->cookies = tb_null;
}
tb_bool_t tb_http_option_ctrl(tb_http_option_t* option, tb_size_t code, tb_va_list_t args)
{
    // check
    tb_assert_and_check_return_val(option, tb_false);

    // done
    switch (code)
    {
    case TB_HTTP_OPTION_SET_URL:
        {
            // url
            tb_char_t const* url = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(url, tb_false);
            
            // set url
            if (tb_url_cstr_set(&option->url, url)) return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_URL:
        {
            // purl
            tb_char_t const** purl = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(purl, tb_false);

            // get url
            tb_char_t const* url = tb_url_cstr(&option->url);
            tb_assert_and_check_return_val(url, tb_false);

            // ok
            *purl = url;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_HOST:
        {
            // host
            tb_char_t const* host = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(host, tb_false);

            // set host
            tb_url_host_set(&option->url, host);
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_HOST:
        {
            // phost
            tb_char_t const** phost = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(phost, tb_false); 

            // get host
            tb_char_t const* host = tb_url_host(&option->url);
            tb_assert_and_check_return_val(host, tb_false);

            // ok
            *phost = host;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_PORT:
        {   
            // port
            tb_size_t port = (tb_size_t)tb_va_arg(args, tb_size_t);
            tb_assert_and_check_return_val(port, tb_false);

            // set port
            tb_url_port_set(&option->url, (tb_uint16_t)port);
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_PORT:
        {
            // pport
            tb_size_t* pport = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pport, tb_false);

            // get port
            *pport = tb_url_port(&option->url);
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_PATH:
        {   
            // path
            tb_char_t const* path = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(path, tb_false);
 
            // set path
            tb_url_path_set(&option->url, path);
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_PATH:
        {
            // ppath
            tb_char_t const** ppath = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(ppath, tb_false);

            // get path
            tb_char_t const* path = tb_url_path(&option->url);
            tb_assert_and_check_return_val(path, tb_false);

            // ok
            *ppath = path;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_METHOD:
        {   
            // method
            tb_size_t method = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set method
            option->method = method;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_METHOD:
        {
            // pmethod
            tb_size_t* pmethod = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pmethod, tb_false);

            // get method
            *pmethod = option->method;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_HEAD:
        {
            // key
            tb_char_t const* key = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(key, tb_false);

            // val
            tb_char_t const* val = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(val, tb_false);
 
            // remove the previous key and value 
            tb_bool_t           head_same = tb_false;
            tb_char_t const*    head_head = (tb_char_t const*)tb_buffer_data(&option->head_data);
            tb_char_t const*    head_data = head_head;
            tb_char_t const*    head_tail = head_data + tb_buffer_size(&option->head_data);
            while (head_data < head_tail)
            {
                // the name and data
                tb_char_t const* name = head_data;
                tb_char_t const* data = head_data + tb_strlen(name) + 1;
                tb_char_t const* next = data + tb_strlen(data) + 1;
                tb_check_break(data < head_tail);

                // is this? 
                if (!tb_stricmp(name, key)) 
                {
                    // value is different? remove it
                    if (tb_stricmp(val, data)) tb_buffer_memmovp(&option->head_data, name - head_head, next - head_head);
                    else head_same = tb_true;
                    break;
                }

                // next
                head_data = next;
            }

            // set head
            if (!head_same)
            {
                tb_buffer_memncat(&option->head_data, (tb_byte_t const*)key, tb_strlen(key) + 1);
                tb_buffer_memncat(&option->head_data, (tb_byte_t const*)val, tb_strlen(val) + 1);
            }

            // ok
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_HEAD:
        {
            // key
            tb_char_t const* key = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(key, tb_false);

            // pval
            tb_char_t const** pval = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(pval, tb_false);

            // find head 
            tb_char_t const*    head_data = (tb_char_t const*)tb_buffer_data(&option->head_data);
            tb_char_t const*    head_tail = head_data + tb_buffer_size(&option->head_data);
            while (head_data < head_tail)
            {
                // the name and data
                tb_char_t const* name = head_data;
                tb_char_t const* data = head_data + tb_strlen(name) + 1;
                tb_check_break(data < head_tail);

                // is this?
                if (!tb_stricmp(name, key)) 
                {
                    // ok
                    *pval = data;
                    return tb_true;
                }

                // next
                head_data = data + tb_strlen(data) + 1;
            }

            // failed
            return tb_false;
        }
        break;
    case TB_HTTP_OPTION_SET_HEAD_FUNC:
        {
            // head_func
            tb_http_head_func_t head_func = (tb_http_head_func_t)tb_va_arg(args, tb_http_head_func_t);

            // set head_func
            option->head_func = head_func;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_HEAD_FUNC:
        {
            // phead_func
            tb_http_head_func_t* phead_func = (tb_http_head_func_t*)tb_va_arg(args, tb_http_head_func_t*);
            tb_assert_and_check_return_val(phead_func, tb_false);

            // get head_func
            *phead_func = option->head_func;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_HEAD_PRIV:
        {
            // head_priv
            tb_pointer_t head_priv = (tb_pointer_t)tb_va_arg(args, tb_pointer_t);

            // set head_priv
            option->head_priv = head_priv;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_HEAD_PRIV:
        {
            // phead_priv
            tb_pointer_t* phead_priv = (tb_pointer_t*)tb_va_arg(args, tb_pointer_t*);
            tb_assert_and_check_return_val(phead_priv, tb_false);

            // get head_priv
            *phead_priv = option->head_priv;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_RANGE:
        {
            // set range
            option->range.bof = (tb_hize_t)tb_va_arg(args, tb_hize_t);
            option->range.eof = (tb_hize_t)tb_va_arg(args, tb_hize_t);
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_RANGE:
        {
            // pbof
            tb_hize_t* pbof = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(pbof, tb_false);

            // peof
            tb_hize_t* peof = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(peof, tb_false);

            // ok
            *pbof = option->range.bof;
            *peof = option->range.eof;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_SSL:
        {   
            // bssl
            tb_bool_t bssl = (tb_bool_t)tb_va_arg(args, tb_bool_t);

            // set ssl
            tb_url_ssl_set(&option->url, bssl);
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_SSL:
        {
            // pssl
            tb_bool_t* pssl = (tb_bool_t*)tb_va_arg(args, tb_bool_t*);
            tb_assert_and_check_return_val(pssl, tb_false);

            // get ssl
            *pssl = tb_url_ssl(&option->url);
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_TIMEOUT:
        {   
            // the timeout
            tb_long_t timeout = (tb_long_t)tb_va_arg(args, tb_long_t);

            // set timeout
            option->timeout = timeout? timeout : TB_HTTP_DEFAULT_TIMEOUT;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_TIMEOUT:
        {
            // ptimeout
            tb_long_t* ptimeout = (tb_long_t*)tb_va_arg(args, tb_long_t*);
            tb_assert_and_check_return_val(ptimeout, tb_false);

            // get timeout
            *ptimeout = option->timeout;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_COOKIES:
        {   
            // set cookies
            option->cookies = (tb_cookies_ref_t)tb_va_arg(args, tb_cookies_ref_t);
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_COOKIES:
        {
            // ptimeout
            tb_cookies_ref_t* pcookies = (tb_cookies_ref_t*)tb_va_arg(args, tb_cookies_ref_t*);
            tb_assert_and_check_return_val(pcookies, tb_false);

            // get cookies
            *pcookies = option->cookies;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_POST_URL:
        {
            // url
            tb_char_t const* url = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(url, tb_false);

            // clear post data and size
            option->post_data = tb_null;
            option->post_size = 0;
            
            // set url
            if (tb_url_cstr_set(&option->post_url, url)) return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_POST_URL:
        {
            // purl
            tb_char_t const** purl = (tb_char_t const**)tb_va_arg(args, tb_char_t const**);
            tb_assert_and_check_return_val(purl, tb_false);

            // get url
            tb_char_t const* url = tb_url_cstr(&option->post_url);
            tb_assert_and_check_return_val(url, tb_false);

            // ok
            *purl = url;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_POST_DATA:
        {   
            // post data
            tb_byte_t const*    data = (tb_byte_t const*)tb_va_arg(args, tb_byte_t const*);

            // post size
            tb_size_t           size = (tb_size_t)tb_va_arg(args, tb_size_t);

            // clear post url
            tb_url_clear(&option->post_url);
            
            // set post data
            option->post_data = data;
            option->post_size = size;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_POST_DATA:
        {
            // pdata and psize
            tb_byte_t const**   pdata = (tb_byte_t const**)tb_va_arg(args, tb_byte_t const**);
            tb_size_t*          psize = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pdata && psize, tb_false);

            // get post data and size
            *pdata = option->post_data;
            *psize = option->post_size;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_POST_FUNC:
        {
            // func
            tb_http_post_func_t func = (tb_http_post_func_t)tb_va_arg(args, tb_http_post_func_t);

            // set post func
            option->post_func = func;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_POST_FUNC:
        {
            // pfunc
            tb_http_post_func_t* pfunc = (tb_http_post_func_t*)tb_va_arg(args, tb_http_post_func_t*);
            tb_assert_and_check_return_val(pfunc, tb_false);

            // get post func
            *pfunc = option->post_func;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_POST_PRIV:
        {   
            // post priv
            tb_cpointer_t priv = (tb_pointer_t)tb_va_arg(args, tb_pointer_t);

            // set post priv
            option->post_priv = priv;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_POST_PRIV:
        {
            // ppost priv
            tb_cpointer_t* ppriv = (tb_cpointer_t*)tb_va_arg(args, tb_cpointer_t*);
            tb_assert_and_check_return_val(ppriv, tb_false);

            // get post priv
            *ppriv = option->post_priv;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_POST_LRATE:
        {
            // post lrate
            tb_size_t lrate = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set post lrate
            option->post_lrate = lrate;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_POST_LRATE:
        {
            // ppost lrate
            tb_size_t* plrate = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(plrate, tb_false);

            // get post lrate
            *plrate = option->post_lrate;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_AUTO_UNZIP:
        {   
            // bunzip
            tb_bool_t bunzip = (tb_bool_t)tb_va_arg(args, tb_bool_t);

            // set bunzip
            option->bunzip = bunzip? 1 : 0;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_AUTO_UNZIP:
        {
            // pbunzip
            tb_bool_t* pbunzip = (tb_bool_t*)tb_va_arg(args, tb_bool_t*);
            tb_assert_and_check_return_val(pbunzip, tb_false);

            // get bunzip
            *pbunzip = option->bunzip? tb_true : tb_false;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_REDIRECT:
        {
            // redirect
            tb_size_t redirect = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set redirect
            option->redirect = redirect;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_REDIRECT:
        {
            // predirect
            tb_size_t* predirect = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(predirect, tb_false);

            // get redirect
            *predirect = option->redirect;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_SET_VERSION:
        {
            // version
            tb_size_t version = (tb_size_t)tb_va_arg(args, tb_size_t);

            // set version
            option->version = version;
            return tb_true;
        }
        break;
    case TB_HTTP_OPTION_GET_VERSION:
        {
            // pversion
            tb_size_t* pversion = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pversion, tb_false);

            // get version
            *pversion = option->version;
            return tb_true;
        }
        break;
    default:
        break;
    }

    // failed
    return tb_false;
}

#ifdef __tb_debug__
tb_void_t tb_http_option_dump(tb_http_option_t* option)
{
    // check
    tb_assert_and_check_return(option);

    // dump option
    tb_trace_i("======================================================================");
    tb_trace_i("option: ");
    tb_trace_i("option: url: %s",               tb_url_cstr(&option->url));
    tb_trace_i("option: version: HTTP/1.%1u",   option->version);
    tb_trace_i("option: method: %s",            tb_http_method_cstr(option->method));
    tb_trace_i("option: redirect: %d",          option->redirect);
    tb_trace_i("option: range: %llu-%llu",      option->range.bof, option->range.eof);
    tb_trace_i("option: bunzip: %s",            option->bunzip? "true" : "false");

    // dump head 
    tb_char_t const*    head_data = (tb_char_t const*)tb_buffer_data(&option->head_data);
    tb_char_t const*    head_tail = head_data + tb_buffer_size(&option->head_data);
    while (head_data < head_tail)
    {
        // the name and data
        tb_char_t const* name = head_data;
        tb_char_t const* data = head_data + tb_strlen(name) + 1;
        tb_check_break(data < head_tail);

        // trace
        tb_trace_i("option: head: %s: %s", name, data);

        // next
        head_data = data + tb_strlen(data) + 1;
    }

    // dump end
    tb_trace_i("");
}
#endif
