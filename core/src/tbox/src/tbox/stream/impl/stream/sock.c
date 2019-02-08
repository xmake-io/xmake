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
 * \sock        sock.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "stream_sock"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the sock cache maxn
#ifdef __tb_small__
#   define TB_STREAM_SOCK_CACHE_MAXN  (8192)
#else
#   define TB_STREAM_SOCK_CACHE_MAXN  (8192 << 1)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the sock stream type
typedef struct __tb_stream_sock_t
{
    // the sock
    tb_socket_ref_t         sock;

#ifdef TB_SSL_ENABLE
    // the ssl 
    tb_ssl_ref_t            hssl;
#endif

    // the sock type
    tb_uint32_t             type : 22;

    // the try number
    tb_uint32_t             tryn : 8;

    // keep alive after being closed?
    tb_uint32_t             keep_alive : 1;

    // is owner of socket 
    tb_uint32_t             owner : 1;

    // the wait event
    tb_long_t               wait;

    // the read size
    tb_size_t               read;

    // the writ size
    tb_size_t               writ;
    
}tb_stream_sock_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_stream_sock_t* tb_stream_sock_cast(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_stream_type(stream) == TB_STREAM_TYPE_SOCK, tb_null);

    // ok?
    return (tb_stream_sock_t*)stream;
}
static tb_bool_t tb_stream_sock_open(tb_stream_ref_t stream)
{
    // check
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return_val(stream_sock && stream_sock->type, tb_false);

    // clear
    stream_sock->wait = 0;
    stream_sock->tryn = 0;
    stream_sock->read = 0;
    stream_sock->writ = 0;

    // the url
    tb_url_ref_t url = tb_stream_url(stream);
    tb_assert_and_check_return_val(url, tb_false);

#ifndef TB_SSL_ENABLE
    // ssl? not supported
    if (tb_url_ssl(url))
    {
        // trace
        tb_trace_w("ssl is not supported now! please enable it from config if you need it.");

        // save state
        tb_stream_state_set(stream, TB_STATE_SOCK_SSL_NOT_SUPPORTED);
        return tb_false;
    }
#endif

    // get address from the url
    tb_ipaddr_ref_t addr = tb_url_addr(url);
    tb_assert_and_check_return_val(addr, tb_false);

    // get the port
    tb_uint16_t port = tb_ipaddr_port(addr);
    tb_assert_and_check_return_val(port, tb_false);

    // no ip?
    if (tb_ipaddr_ip_is_empty(addr))
    {
        // look ip 
        tb_ipaddr_t ip_addr = {0};
        if (!tb_addrinfo_addr(tb_url_host(url), &ip_addr)) 
        {
            tb_stream_state_set(stream, TB_STATE_SOCK_DNS_FAILED);
            return tb_false;
        }

        // update address to the url
        tb_ipaddr_ip_set(addr, &ip_addr);
    }

    // tcp or udp? for url: sock://ip:port/?udp=
    tb_char_t const* args = tb_url_args(url);
    if (args && !tb_strnicmp(args, "udp=", 4)) stream_sock->type = TB_SOCKET_TYPE_UDP;
    else if (args && !tb_strnicmp(args, "tcp=", 4)) stream_sock->type = TB_SOCKET_TYPE_TCP;

    // exit sock first if not keep-alive
    if (!stream_sock->keep_alive && stream_sock->sock)
    {
        if (stream_sock->sock && !tb_socket_exit(stream_sock->sock)) return tb_false;
        stream_sock->sock = tb_null;
    }

    // make sock
    if (!stream_sock->sock) stream_sock->sock = tb_socket_init(stream_sock->type, tb_ipaddr_family(addr));
    
    // open sock failed?
    if (!stream_sock->sock)
    {
        // trace
        tb_trace_e("open sock failed!");

        // save state
        tb_stream_state_set(stream, TB_STATE_SOCK_OPEN_FAILED);
        return tb_false;
    }

    // done
    tb_bool_t ok = tb_false;
    switch (stream_sock->type)
    {
    case TB_SOCKET_TYPE_TCP:
        {
            // trace
            tb_trace_d("sock(%p): connect: %s[%{ipaddr}]: ..", stream_sock->sock, tb_url_host(url), addr);

            // connect it
            tb_long_t real = -1;
            while (     !(real = tb_socket_connect(stream_sock->sock, addr))
                    &&  !tb_stream_is_killed(stream))
            {
                // wait it
                real = tb_socket_wait(stream_sock->sock, TB_SOCKET_EVENT_CONN, tb_stream_timeout(stream));
                tb_check_break(real > 0);
            }

            // ok?
            if (real > 0)
            {
                ok = tb_true;
                tb_stream_state_set(stream, TB_STATE_OK);
            }
            else tb_stream_state_set(stream, !real? TB_STATE_SOCK_CONNECT_TIMEOUT : TB_STATE_SOCK_CONNECT_FAILED);

            // trace
            tb_trace_d("sock(%p): connect: %s", stream_sock->sock, ok? "ok" : "failed");
            
            // ok?
            if (ok)
            {
                // ssl? init it
                if (tb_url_ssl(url))
                {
#ifdef TB_SSL_ENABLE
                    // done
                    ok = tb_false;
                    do
                    {
                        // init ssl
                        if (!stream_sock->hssl) stream_sock->hssl = tb_ssl_init(tb_false);
                        tb_assert_and_check_break(stream_sock->hssl);

                        // init bio
                        tb_ssl_set_bio_sock(stream_sock->hssl, stream_sock->sock);

                        // init timeout
                        tb_ssl_set_timeout(stream_sock->hssl, tb_stream_timeout(stream));

                        // open ssl
                        if (!tb_ssl_open(stream_sock->hssl)) break;

                        // ok
                        ok = tb_true;

                    } while (0);

                    // trace
                    tb_trace_d("sock(%p): ssl: %s", stream_sock->sock, ok? "ok" : "no");
            
                    // ssl failed? save state 
                    if (!ok) tb_stream_state_set(stream, stream_sock->hssl? tb_ssl_state(stream_sock->hssl) : TB_STATE_SOCK_SSL_FAILED);
#endif
                }
            }
        }
        break;
    case TB_SOCKET_TYPE_UDP:
        {
            // ssl? not supported
            if (tb_url_ssl(url))
            {
                // trace
                tb_trace_w("udp ssl is not supported!");

                // save state
                tb_stream_state_set(stream, TB_STATE_SOCK_SSL_NOT_SUPPORTED);
            }
            else
            {
                // ok
                ok = tb_true;
                tb_stream_state_set(stream, TB_STATE_OK);
            }
        }
        break;
    default:
        {
            // trace
            tb_trace_e("unknown socket type: %lu", stream_sock->type);
        }
        break;
    }

    // open failed? close ssl and socket
    if (!ok)
    {
#ifdef TB_SSL_ENABLE
        // exit ssl
        if (stream_sock->hssl) tb_ssl_exit(stream_sock->hssl);
        stream_sock->hssl = tb_null;
#endif

        // exit sock
        if (stream_sock->sock) tb_socket_exit(stream_sock->sock);
        stream_sock->sock = tb_null;
    }

    // ok?
    return ok;
}
static tb_bool_t tb_stream_sock_open_ref(tb_stream_ref_t stream)
{
    // check
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return_val(stream_sock && stream_sock->type, tb_false);

    // clear
    stream_sock->wait = 0;
    stream_sock->tryn = 0;
    stream_sock->read = 0;
    stream_sock->writ = 0;

    // the url
    tb_url_ref_t url = tb_stream_url(stream);
    tb_assert_and_check_return_val(url, tb_false);

#ifndef TB_SSL_ENABLE
    // ssl? not supported
    if (tb_url_ssl(url))
    {
        // trace
        tb_trace_w("ssl is not supported now! please enable it from config if you need it.");

        // save state
        tb_stream_state_set(stream, TB_STATE_SOCK_SSL_NOT_SUPPORTED);
        return tb_false;
    }
#endif

    // done
    tb_bool_t ok = tb_false;
    switch (stream_sock->type)
    {
    case TB_SOCKET_TYPE_TCP:
        {
            // ssl? init it
            if (tb_url_ssl(url))
            {
#ifdef TB_SSL_ENABLE
                do
                {
                    // init ssl
                    if (!stream_sock->hssl) stream_sock->hssl = tb_ssl_init(tb_false);
                    tb_assert_and_check_break(stream_sock->hssl);

                    // init bio
                    tb_ssl_set_bio_sock(stream_sock->hssl, stream_sock->sock);

                    // init timeout
                    tb_ssl_set_timeout(stream_sock->hssl, tb_stream_timeout(stream));

                    // open ssl
                    if (!tb_ssl_open(stream_sock->hssl)) break;

                    // ok
                    ok = tb_true;

                } while (0);

                // trace
                tb_trace_d("sock(%p): ssl: %s", stream_sock->sock, ok? "ok" : "no");
        
                // ssl failed? save state 
                if (!ok) tb_stream_state_set(stream, stream_sock->hssl? tb_ssl_state(stream_sock->hssl) : TB_STATE_SOCK_SSL_FAILED);
#endif
            }
            else ok = tb_true;
        }
        break;
    case TB_SOCKET_TYPE_UDP:
        {
            // ssl? not supported
            if (tb_url_ssl(url))
            {
                // trace
                tb_trace_w("udp ssl is not supported!");

                // save state
                tb_stream_state_set(stream, TB_STATE_SOCK_SSL_NOT_SUPPORTED);
            }
            else
            {
                // ok
                ok = tb_true;
                tb_stream_state_set(stream, TB_STATE_OK);
            }
        }
        break;
    default:
        {
            // trace
            tb_trace_e("unknown socket type: %lu", stream_sock->type);
        }
        break;
    }

    // open failed? close ssl and socket
    if (!ok)
    {
#ifdef TB_SSL_ENABLE
        // exit ssl
        if (stream_sock->hssl) tb_ssl_exit(stream_sock->hssl);
        stream_sock->hssl = tb_null;
#endif
    }

    // ok?
    return ok;
}
static tb_bool_t tb_stream_sock_clos(tb_stream_ref_t stream)
{
    // check
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return_val(stream_sock, tb_false);

#ifdef TB_SSL_ENABLE
    // close ssl
    if (tb_url_ssl(tb_stream_url(stream)) && stream_sock->hssl)
        tb_ssl_clos(stream_sock->hssl);
#endif

    // keep alive? not close it
    tb_check_return_val(!stream_sock->keep_alive, tb_true);

    // exit socket
    if (stream_sock->owner) 
    {
        if (stream_sock->sock && !tb_socket_exit(stream_sock->sock)) return tb_false;
        stream_sock->sock = tb_null;
    }

    // clear 
    stream_sock->wait = 0;
    stream_sock->tryn = 0;
    stream_sock->read = 0;
    stream_sock->writ = 0;

    // ok
    return tb_true;
}
static tb_void_t tb_stream_sock_exit(tb_stream_ref_t stream)
{
    // check
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return(stream_sock);

#ifdef TB_SSL_ENABLE
    // exit ssl
    if (stream_sock->hssl) tb_ssl_exit(stream_sock->hssl);
    stream_sock->hssl = tb_null;
#endif

    // exit sock
    if (stream_sock->sock && stream_sock->owner) tb_socket_exit(stream_sock->sock);
    stream_sock->sock = tb_null;

    // clear 
    stream_sock->wait = 0;
    stream_sock->tryn = 0;
    stream_sock->read = 0;
    stream_sock->writ = 0;
}
static tb_void_t tb_stream_sock_kill(tb_stream_ref_t stream)
{
    // check
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return(stream_sock);

    // kill it
    if (stream_sock->sock) tb_socket_kill(stream_sock->sock, TB_SOCKET_KILL_RW);
}
static tb_long_t tb_stream_sock_read(tb_stream_ref_t stream, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return_val(stream_sock && stream_sock->sock, -1);

    // the url
    tb_url_ref_t url = tb_stream_url(stream);
    tb_assert_and_check_return_val(url, -1);

    // check
    tb_check_return_val(data, -1);
    tb_check_return_val(size, 0);

    // clear writ
    stream_sock->writ = 0;

    // read
    tb_long_t real = -1;
    switch (stream_sock->type)
    {
    case TB_SOCKET_TYPE_TCP:
        {
#ifdef TB_SSL_ENABLE
            // ssl?
            if (tb_url_ssl(url))
            {
                // check
                tb_assert_and_check_return_val(stream_sock->hssl, -1);
    
                // read data
                real = tb_ssl_read(stream_sock->hssl, data, size);

                // trace
                tb_trace_d("sock(%p): read: %ld <? %lu", stream_sock->sock, real, size);

                // failed or closed?
                tb_check_return_val(real >= 0, -1);
            }
            else
#endif
            {
                // read data
                real = tb_socket_recv(stream_sock->sock, data, size);

                // trace
                tb_trace_d("sock(%p): read: %ld <? %lu", stream_sock->sock, real, size);

                // failed or closed?
                tb_check_return_val(real >= 0, -1);

                // peer closed?
                if (!real && stream_sock->wait > 0 && (stream_sock->wait & TB_SOCKET_EVENT_RECV)) return -1;

                // clear wait
                if (real > 0) stream_sock->wait = 0;
            }
        }
        break;
    case TB_SOCKET_TYPE_UDP:
        {
            // read data
            real = tb_socket_urecv(stream_sock->sock, tb_null, data, size);

            // trace
            tb_trace_d("sock(%p): read: %ld <? %lu", stream_sock->sock, real, size);

            // failed or closed?
            tb_check_return_val(real >= 0, -1);

            // peer closed?
            if (!real && stream_sock->wait > 0 && (stream_sock->wait & TB_SOCKET_EVENT_RECV)) return -1;

            // clear wait
            if (real > 0) stream_sock->wait = 0;
        }
        break;
    default:
        break;
    }

    // update read
    if (real > 0) stream_sock->read += real;

    // ok?
    return real;
}
static tb_long_t tb_stream_sock_writ(tb_stream_ref_t stream, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return_val(stream_sock && stream_sock->sock, -1);

    // the url
    tb_url_ref_t url = tb_stream_url(stream);
    tb_assert_and_check_return_val(url, -1);

    // check
    tb_check_return_val(data, -1);
    tb_check_return_val(size, 0);

    // clear read
    stream_sock->read = 0;

    // writ 
    tb_long_t real = -1;
    switch (stream_sock->type)
    {
    case TB_SOCKET_TYPE_TCP:
        {
#ifdef TB_SSL_ENABLE
            // ssl?
            if (tb_url_ssl(url))
            {
                // check
                tb_assert_and_check_return_val(stream_sock->hssl, -1);

                // writ data
                real = tb_ssl_writ(stream_sock->hssl, data, size);

                // trace
                tb_trace_d("sock(%p): writ: %ld <? %lu", stream_sock->sock, real, size);

                // failed or closed?
                tb_check_return_val(real >= 0, -1);
            }
            else
#endif
            {
                // writ data
                real = tb_socket_send(stream_sock->sock, data, size);

                // trace
                tb_trace_d("sock(%p): writ: %ld <? %lu", stream_sock->sock, real, size);

                // failed or closed?
                tb_check_return_val(real >= 0, -1);

                // peer closed?
                if (!real && stream_sock->wait > 0 && (stream_sock->wait & TB_SOCKET_EVENT_SEND)) return -1;

                // clear wait
                if (real > 0) stream_sock->wait = 0;
            }
        }
        break;
    case TB_SOCKET_TYPE_UDP:
        {
            // get address from the url
            tb_ipaddr_ref_t addr = tb_url_addr(url);
            tb_assert_and_check_return_val(addr, -1);

            // writ data
            real = tb_socket_usend(stream_sock->sock, addr, data, size);

            // trace
            tb_trace_d("sock(%p): writ: %ld <? %lu", stream_sock->sock, real, size);

            // failed or closed?
            tb_check_return_val(real >= 0, -1);

            // no data?
            if (!real)
            {
                // abort? writ x, writ 0, or writ 0, writ 0
                tb_check_return_val(!stream_sock->writ && !stream_sock->tryn, -1);

                // tryn++
                stream_sock->tryn++;
            }
            else stream_sock->tryn = 0;
        }
        break;
    default:
        break;
    }

    // update writ
    if (real > 0) stream_sock->writ += real;

    // ok?
    return real;
}
static tb_long_t tb_stream_sock_wait(tb_stream_ref_t stream, tb_size_t wait, tb_long_t timeout)
{
    // check
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return_val(stream_sock && stream_sock->sock, -1);

#ifdef TB_SSL_ENABLE
    // ssl?
    if (tb_url_ssl(tb_stream_url(stream)))
    {
        // check
        tb_assert_and_check_return_val(stream_sock->hssl, -1);

        // wait 
        stream_sock->wait = tb_ssl_wait(stream_sock->hssl, wait, timeout);

        // timeout or failed? save state
        if (stream_sock->wait <= 0) tb_stream_state_set(stream, tb_ssl_state(stream_sock->hssl));
    }
    else
#endif
    {
        // wait 
        stream_sock->wait = tb_socket_wait(stream_sock->sock, wait, timeout);
    }

    // trace
    tb_trace_d("sock(%p): wait: %ld", stream_sock->sock, stream_sock->wait);

    // ok?
    return stream_sock->wait;
}
static tb_bool_t tb_stream_sock_ctrl(tb_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    tb_assert_and_check_return_val(stream_sock, tb_false);

    switch (ctrl)
    {
    case TB_STREAM_CTRL_SOCK_SET_TYPE:
        {
            // check
            tb_assert_and_check_return_val(tb_stream_is_closed(stream), tb_false);
            tb_assert_and_check_return_val(!stream_sock->keep_alive, tb_false);

            // the type
            tb_size_t type = (tb_size_t)tb_va_arg(args, tb_size_t);
            tb_assert_and_check_return_val(type == TB_SOCKET_TYPE_TCP || type == TB_SOCKET_TYPE_UDP, tb_false);
            
            // set type
            stream_sock->type = type;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_SOCK_GET_TYPE:
        {
            tb_size_t* ptype = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(ptype, tb_false);
            *ptype = stream_sock->type;
            return tb_true;
        }
    case TB_STREAM_CTRL_SOCK_KEEP_ALIVE:
        {
            // keep alive?
            tb_bool_t keep_alive = (tb_bool_t)tb_va_arg(args, tb_bool_t);
            stream_sock->keep_alive = keep_alive? 1 : 0;
            return tb_true;
        }
    default:
        break;
    }
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_stream_ref_t tb_stream_init_sock()
{
    // init stream
    tb_stream_ref_t stream = tb_stream_init(    TB_STREAM_TYPE_SOCK
                                            ,   sizeof(tb_stream_sock_t)
                                            ,   TB_STREAM_SOCK_CACHE_MAXN
                                            ,   tb_stream_sock_open
                                            ,   tb_stream_sock_clos
                                            ,   tb_stream_sock_exit
                                            ,   tb_stream_sock_ctrl
                                            ,   tb_stream_sock_wait
                                            ,   tb_stream_sock_read
                                            ,   tb_stream_sock_writ
                                            ,   tb_null
                                            ,   tb_null
                                            ,   tb_stream_sock_kill);
    tb_assert_and_check_return_val(stream, tb_null);

    // init the sock stream
    tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
    if (stream_sock)
    {
        // init sock type
        stream_sock->type = TB_SOCKET_TYPE_TCP;
    }

    // ok?
    return stream;
}
tb_stream_ref_t tb_stream_init_from_sock(tb_char_t const* host, tb_uint16_t port, tb_size_t type, tb_bool_t bssl)
{
    // check
    tb_assert_and_check_return_val(host && port, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream = tb_null;
    do
    {
        // init stream
        stream = tb_stream_init_sock();
        tb_assert_and_check_break(stream);

        // ctrl stream
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SET_HOST, host)) break;
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SET_PORT, port)) break;
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SET_SSL, bssl)) break;
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SOCK_SET_TYPE, type)) break;

        // init the sock stream
        tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
        tb_assert_and_check_break(stream_sock);

        // mark as owner of socket
        stream_sock->owner = 1;
   
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (stream) tb_stream_exit(stream);
        stream = tb_null;
    }

    // ok?
    return stream;
}
tb_stream_ref_t tb_stream_init_from_sock_ref(tb_socket_ref_t sock, tb_size_t type, tb_bool_t bssl)
{
    // check
    tb_assert_and_check_return_val(sock, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream = tb_null;
    do
    {
        // init stream
        stream = tb_stream_init(    TB_STREAM_TYPE_SOCK
                                ,   sizeof(tb_stream_sock_t)
                                ,   TB_STREAM_SOCK_CACHE_MAXN
                                ,   tb_stream_sock_open_ref
                                ,   tb_stream_sock_clos
                                ,   tb_stream_sock_exit
                                ,   tb_stream_sock_ctrl
                                ,   tb_stream_sock_wait
                                ,   tb_stream_sock_read
                                ,   tb_stream_sock_writ
                                ,   tb_null
                                ,   tb_null
                                ,   tb_stream_sock_kill);
        tb_assert_and_check_break(stream);

        // ctrl stream
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SET_HOST, "fd")) break;
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SET_PORT, (tb_uint16_t)tb_sock2fd(sock))) break;
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SET_SSL, bssl)) break;
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SOCK_SET_TYPE, type)) break;

        // init the sock stream
        tb_stream_sock_t* stream_sock = tb_stream_sock_cast(stream);
        tb_assert_and_check_break(stream_sock);

        // only be reference of socket
        stream_sock->owner = 0;

        // save socket
        stream_sock->sock = sock;
   
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (stream) tb_stream_exit(stream);
        stream = tb_null;
    }

    // ok?
    return stream;
}
