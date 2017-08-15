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
 * @file        sock.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "async_stream_sock"
#define TB_TRACE_MODULE_DEBUG               (1)

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
typedef struct __tb_async_stream_sock_impl_t
{
    // the aico
    tb_aico_ref_t                       aico;

    // the aicp dns
    tb_aicp_dns_ref_t                   hdns;

#ifdef TB_SSL_ENABLE
    // the aicp ssl
    tb_aicp_ssl_ref_t                   hssl;
#endif

    // the sock type
    tb_uint32_t                         type    : 31;

    // keep alive after being closed?
    tb_uint32_t                         balived : 1;

    // is reading now?
    tb_uint32_t                         bread   : 1;

    // the offset
    tb_atomic64_t                       offset;

    // the func
    union
    {
        tb_async_stream_open_func_t     open;
        tb_async_stream_read_func_t     read;
        tb_async_stream_writ_func_t     writ;
        tb_async_stream_task_func_t     task;
        tb_async_stream_clos_func_t     clos;

    }                                   func;

    // the priv
    tb_cpointer_t                       priv;

}tb_async_stream_sock_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_async_stream_sock_impl_t* tb_async_stream_sock_impl_cast(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_async_stream_type(stream) == TB_STREAM_TYPE_SOCK, tb_null);

    // ok?
    return (tb_async_stream_sock_impl_t*)stream;
}
static tb_void_t tb_async_stream_sock_impl_clos_clear(tb_async_stream_sock_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl);

    // clear the mode
    impl->bread = 0;

    // clear the offset
    tb_atomic64_set0(&impl->offset);

    // clear base
    tb_async_stream_clear((tb_async_stream_ref_t)impl);
}
static tb_void_t tb_async_stream_sock_impl_clos_func(tb_aico_ref_t aico, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast((tb_async_stream_ref_t)priv);
    tb_assert_and_check_return(impl && impl->func.clos);

    // trace
    tb_trace_d("clos[%p]: notify: %s: ..", aico, tb_url_cstr(tb_async_stream_url((tb_async_stream_ref_t)impl)));

    // clear it
    tb_async_stream_sock_impl_clos_clear(impl);

    /* done clos func
     *
     * note: cannot use this stream after closing, the stream may be exited in the closing func
     */
    impl->func.clos((tb_async_stream_ref_t)impl, TB_STATE_OK, impl->priv);

    // trace
    tb_trace_d("clos[%p]: notify: ok", aico);
}
static tb_bool_t tb_async_stream_sock_impl_clos_aico_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_CLOS, tb_false);

    // the impl
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast((tb_async_stream_ref_t)aice->priv);
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("clos[%p]: aico: notify: %s: ..", aice->aico, tb_url_cstr(tb_async_stream_url((tb_async_stream_ref_t)impl)));

    // clear aico
#ifdef TB_SSL_ENABLE
    if (impl->hssl) tb_aicp_ssl_set_aico(impl->hssl, tb_null);
#endif

    // done func directly
    tb_async_stream_sock_impl_clos_func(tb_null, impl);

    // trace
    tb_trace_d("clos[%p]: aico: notify: ok", aice->aico);

    // ok
    return tb_true;
}
#ifdef TB_SSL_ENABLE
static tb_void_t tb_async_stream_sock_impl_clos_ssl_func(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast((tb_async_stream_ref_t)priv);
    tb_assert_and_check_return(impl && impl->aico && impl->func.clos);

    // trace
    tb_trace_d("clos[%p]: ssl: notify: %s: ..", impl->aico, tb_url_cstr(tb_async_stream_url((tb_async_stream_ref_t)impl)));

    // close it if be not alived
    if (!impl->balived)
    {
        // clos aico 
        tb_aico_clos(impl->aico, tb_async_stream_sock_impl_clos_aico_func, impl);
    }
    // done func directly
    else tb_async_stream_sock_impl_clos_func(tb_null, impl);

    // trace
    tb_trace_d("clos: ssl: notify: ok");
}
#endif
static tb_bool_t tb_async_stream_sock_impl_clos_try(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // trace
    tb_trace_d("clos[%p]: try: %s: ..", impl->aico, tb_url_cstr(tb_async_stream_url(stream)));

    // try closing ssl first
#ifdef TB_SSL_ENABLE
    if (!impl->hssl || tb_aicp_ssl_clos_try(impl->hssl))
#endif
    {
        // alived or no aico or closed?
        if (impl->balived || !impl->aico || tb_aico_clos_try(impl->aico)) 
        {
            // clear it
            tb_async_stream_sock_impl_clos_clear(impl);

            // trace
            tb_trace_d("clos[%p]: try: %s: ok", impl->aico, tb_url_cstr(tb_async_stream_url(stream)));

            // ok
            return tb_true;
        }
    }

    // trace
    tb_trace_d("clos[%p]: try: %s: no", impl->aico, tb_url_cstr(tb_async_stream_url(stream)));

    // failed
    return tb_false;
}
static tb_bool_t tb_async_stream_sock_impl_clos(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv)
{   
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // trace
#ifdef TB_SSL_ENABLE
    tb_trace_d("clos[%p]: %s: balived: %d, hssl: %p, hdns: %p: ..", impl->aico, tb_url_cstr(tb_async_stream_url(stream)), impl->balived, impl->hssl, impl->hdns);
#else
    tb_trace_d("clos[%p]: %s: balived: %d, hdns: %p: ..", impl->aico, tb_url_cstr(tb_async_stream_url(stream)), impl->balived, impl->hdns);
#endif

    // init clos
    impl->func.clos  = func;
    impl->priv       = priv;

    // clos ssl first
#ifdef TB_SSL_ENABLE
    if (impl->hssl) tb_aicp_ssl_clos(impl->hssl, tb_async_stream_sock_impl_clos_ssl_func, impl);
    else
#endif
    if (!impl->balived)
    {
        // clos aico 
        tb_aico_clos(impl->aico, tb_async_stream_sock_impl_clos_aico_func, impl);
    }
    // done func directly
    else tb_async_stream_sock_impl_clos_func(tb_null, impl);

    // ok
    return tb_true;
}
#ifdef TB_SSL_ENABLE
static tb_bool_t tb_async_stream_sock_impl_open_ssl_func(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast((tb_async_stream_ref_t)priv);
    tb_assert_and_check_return_val(ssl && impl->func.open, tb_false);

    // trace
    tb_trace_d("open[%p]: ssl: %s", impl->aico, tb_state_cstr(state));

    // open done
    tb_async_stream_open_func((tb_async_stream_ref_t)impl, state, impl->func.open, impl->priv);

    // ok
    return tb_true;
}
static tb_size_t tb_async_stream_sock_impl_open_ssl(tb_async_stream_sock_impl_t* impl)
{
    // check
    tb_assert_and_check_return_val(impl && impl->aico, TB_STATE_SOCK_SSL_UNKNOWN_ERROR);

    // init ssl
    if (!impl->hssl) impl->hssl = tb_aicp_ssl_init(tb_async_stream_aicp((tb_async_stream_ref_t)impl), tb_false);
    tb_assert_and_check_return_val(impl->hssl, TB_STATE_SOCK_SSL_UNKNOWN_ERROR);

    // killed?
    if (tb_async_stream_is_killed((tb_async_stream_ref_t)impl)) return TB_STATE_KILLED;

    // init ssl aico
    tb_aicp_ssl_set_aico(impl->hssl, impl->aico);

    // init ssl timeout
    tb_aicp_ssl_set_timeout(impl->hssl, tb_async_stream_timeout((tb_async_stream_ref_t)impl));

    // open ssl
    if (!tb_aicp_ssl_open(impl->hssl, tb_async_stream_sock_impl_open_ssl_func, impl)) return TB_STATE_SOCK_SSL_UNKNOWN_ERROR;

    // ok
    return TB_STATE_OK;
}
#endif
static tb_bool_t tb_async_stream_sock_impl_conn_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_CONN, tb_false);

    // the stream
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast((tb_async_stream_ref_t)aice->priv);
    tb_assert_and_check_return_val(impl && impl->func.open, tb_false);

    // trace
    tb_trace_d("open[%p]: conn: %s", impl->aico, tb_state_cstr(aice->state));

    // done
    tb_size_t state = TB_STATE_SOCK_UNKNOWN_ERROR;
    switch (aice->state)
    {
        // ok
    case TB_STATE_OK:
        {
#ifdef TB_SSL_ENABLE
            // ssl?
            if (tb_url_ssl(tb_async_stream_url((tb_async_stream_ref_t)impl)))
            {
                // open ssl
                state = tb_async_stream_sock_impl_open_ssl(impl);
                tb_check_break(state == TB_STATE_OK);
            }
            else
#endif
            {
                // open done
                tb_async_stream_open_func((tb_async_stream_ref_t)impl, TB_STATE_OK, impl->func.open, impl->priv);
            }
            
            // ok
            state = TB_STATE_OK;
        }
        break;
        // timeout
    case TB_STATE_TIMEOUT:
        state = TB_STATE_SOCK_CONNECT_TIMEOUT;
        break;
        // killed
    case TB_STATE_KILLED:
        state = TB_STATE_KILLED;
        break;
        // failed
    default:
        state = TB_STATE_SOCK_CONNECT_FAILED;
        break;
    }

    // failed? 
    if (state != TB_STATE_OK) 
    {
        // open done
        tb_async_stream_open_func((tb_async_stream_ref_t)impl, state, impl->func.open, impl->priv);
    }

    // ok
    return tb_true;
}
static tb_void_t tb_async_stream_sock_impl_dns_func(tb_aicp_dns_ref_t dns, tb_char_t const* host, tb_ipaddr_ref_t addr, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast((tb_async_stream_ref_t)priv);
    tb_assert_and_check_return(dns && impl && impl->func.open);

    // done
    tb_size_t state = TB_STATE_SOCK_UNKNOWN_ERROR;
    do
    {
        // addr ok?
        if (addr)
        {
            // trace
            tb_trace_d("open[%p]: host: %s, addr: %{ipaddr}", impl->aico, host, addr);

            // init aico
            if (!impl->aico) impl->aico = tb_aico_init(tb_async_stream_aicp((tb_async_stream_ref_t)impl));
            tb_assert_and_check_break(impl->aico);

            // open aico
            if (!tb_aico_open_sock_from_type(impl->aico, impl->type, tb_ipaddr_family(addr)))
            {
                // trace
                tb_trace_e("open sock failed!");

                // save state
                state = TB_STATE_SOCK_OPEN_FAILED;
                break;
            }

            // init timeout
            tb_long_t timeout = tb_async_stream_timeout((tb_async_stream_ref_t)impl);
            tb_aico_timeout_set(impl->aico, TB_AICO_TIMEOUT_CONN, timeout);
            tb_aico_timeout_set(impl->aico, TB_AICO_TIMEOUT_RECV, timeout);
            tb_aico_timeout_set(impl->aico, TB_AICO_TIMEOUT_SEND, timeout);

            // the url
            tb_url_ref_t url = tb_async_stream_url((tb_async_stream_ref_t)impl);
            tb_assert_and_check_break(url);

            // get address from the url
            tb_ipaddr_ref_t url_addr = tb_url_addr(url);
            tb_assert_and_check_break(url_addr);

            // update the ip address
            tb_ipaddr_ip_set(url_addr, addr);

            // the sock type: tcp or udp? for url: sock://ip:port/?udp=
            tb_char_t const* args = tb_url_args(url);
            if (args && !tb_strnicmp(args, "udp=", 4)) impl->type = TB_SOCKET_TYPE_UDP;
            else if (args && !tb_strnicmp(args, "tcp=", 4)) impl->type = TB_SOCKET_TYPE_TCP;
            tb_assert_and_check_break(impl->type == TB_SOCKET_TYPE_TCP || impl->type == TB_SOCKET_TYPE_UDP);

            // killed?
            if (tb_async_stream_is_killed((tb_async_stream_ref_t)impl))
            {
                // save state
                state = TB_STATE_KILLED;
                break;
            }

            // tcp?
            if (impl->type == TB_SOCKET_TYPE_TCP)
            {
                // done conn
                if (!tb_aico_conn(impl->aico, url_addr, tb_async_stream_sock_impl_conn_func, impl)) break;
            }
            // udp?
            else
            {
                // ssl? not supported
                if (tb_url_ssl(url))
                {
                    // trace
                    tb_trace_w("udp ssl is not supported!");
                }

                // open done
                tb_async_stream_open_func((tb_async_stream_ref_t)impl, TB_STATE_OK, impl->func.open, impl->priv);
            }

            // ok
            state = TB_STATE_OK;
        }
        // timeout or failed?
        else
        {
            // trace
            tb_trace_d("open[%p]: addr: %s failed", impl->aico, host);

            // dns failed
            state = TB_STATE_SOCK_DNS_FAILED;
        }

    } while (0);

    // failed?
    if (state != TB_STATE_OK) 
    {
        // open done
        tb_async_stream_open_func((tb_async_stream_ref_t)impl, state, impl->func.open, impl->priv);
    }
}
static tb_bool_t tb_async_stream_sock_impl_open(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->type && func, tb_false);

    // done
    tb_size_t state = TB_STATE_SOCK_UNKNOWN_ERROR;
    do
    {
        // clear the mode
        impl->bread = 0;

        // clear the offset
        tb_atomic64_set0(&impl->offset);

        // init func and priv
        impl->priv       = priv;
        impl->func.open  = func;

        // the url
        tb_url_ref_t url = tb_async_stream_url(stream);
        tb_assert_and_check_break(url);

#ifndef TB_SSL_ENABLE
        // ssl? not supported
        if (tb_url_ssl(url))
        {
            // trace
            tb_trace_w("ssl is not supported now! please enable it from config if you need it.");

            // save state
            state = TB_STATE_SOCK_SSL_NOT_SUPPORTED;
            break;
        }
#endif

        // keep alive and have been opened? reopen it directly
        if (impl->balived && impl->hdns && impl->aico)
        {
#ifdef TB_SSL_ENABLE
            // ssl?
            if (tb_url_ssl(url))
            {
                // open ssl
                state = tb_async_stream_sock_impl_open_ssl(impl);
                tb_assert_and_check_break(state != TB_STATE_SOCK_SSL_UNKNOWN_ERROR);
            }
            else
#endif
            // open done
            tb_async_stream_open_func(stream, TB_STATE_OK, func, priv);

            // ok
            state = TB_STATE_OK;
            break;
        }

        // get the host from url
        tb_char_t const* host = tb_url_host(url);
        tb_assert_and_check_break(host);

        // init dns
        if (!impl->hdns) impl->hdns = tb_aicp_dns_init(tb_async_stream_aicp(stream));
        tb_assert_and_check_break(impl->hdns);

        // killed?
        if (tb_async_stream_is_killed(stream))
        {
            // save state
            state = TB_STATE_KILLED;
            break;
        }

        // done addr
        if (!tb_aicp_dns_done(impl->hdns, host, tb_async_stream_timeout(stream), tb_async_stream_sock_impl_dns_func, stream))
        {
            // save state
            state = TB_STATE_SOCK_DNS_FAILED;
            break;
        }

        // ok
        state = TB_STATE_OK;

    } while (0);

    // failed?
    if (state != TB_STATE_OK) 
    {
        // open done
        tb_async_stream_open_func(stream, state, func, priv);
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_sock_impl_read_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_RECV, tb_false);

    // the stream
    tb_async_stream_sock_impl_t* impl = (tb_async_stream_sock_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.read, tb_false);
 
    // trace
    tb_trace_d("recv[%p]: real: %lu, size: %lu, state: %s", aice->aico, aice->u.recv.real, aice->u.recv.size, tb_state_cstr(aice->state));

    // done state
    tb_size_t state = TB_STATE_SOCK_UNKNOWN_ERROR;
    switch (aice->state)
    {
        // ok
    case TB_STATE_OK:
        tb_atomic64_fetch_and_add(&impl->offset, aice->u.recv.real);
        state = TB_STATE_OK;
        break;
        // closed
    case TB_STATE_CLOSED:
        state = TB_STATE_CLOSED;
        break;
        // killed
    case TB_STATE_KILLED:
        state = TB_STATE_KILLED;
        break;
        // timeout?
    case TB_STATE_TIMEOUT:
        state = TB_STATE_SOCK_RECV_TIMEOUT;
        break;
    default:
        tb_trace_e("recv: unknown state: %s", tb_state_cstr(aice->state));
        break;
    }

    // done func
    if (impl->func.read((tb_async_stream_ref_t)impl, state, aice->u.recv.data, aice->u.recv.real, aice->u.recv.size, impl->priv))
    {
        // continue?
        if (aice->state == TB_STATE_OK)
        {
            // continue to post read
            if (!tb_aico_recv(aice->aico, aice->u.recv.data, aice->u.recv.size, tb_async_stream_sock_impl_read_func, (tb_async_stream_ref_t)impl))
                impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_SOCK_RECV_FAILED, aice->u.recv.data, 0, aice->u.recv.size, impl->priv);
        }
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_sock_impl_read_udp_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_URECV, tb_false);

    // the stream
    tb_async_stream_sock_impl_t* impl = (tb_async_stream_sock_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.read, tb_false);
 
    // trace
    tb_trace_d("urecv[%p]: real: %lu, size: %lu, state: %s", aice->aico, aice->u.urecv.real, aice->u.urecv.size, tb_state_cstr(aice->state));

    // done state
    tb_size_t state = TB_STATE_SOCK_UNKNOWN_ERROR;
    switch (aice->state)
    {
        // ok
    case TB_STATE_OK:
        tb_atomic64_fetch_and_add(&impl->offset, aice->u.urecv.real);
        state = TB_STATE_OK;
        break;
        // closed
    case TB_STATE_CLOSED:
        state = TB_STATE_CLOSED;
        break;
        // killed
    case TB_STATE_KILLED:
        state = TB_STATE_KILLED;
        break;
        // timeout?
    case TB_STATE_TIMEOUT:
        state = TB_STATE_SOCK_RECV_TIMEOUT;
        break;
    default:
        tb_trace_e("read: unknown state: %s", tb_state_cstr(aice->state));
        break;
    }

    // done func
    if (impl->func.read((tb_async_stream_ref_t)impl, state, aice->u.urecv.data, aice->u.urecv.real, aice->u.urecv.size, impl->priv))
    {
        // continue?
        if (aice->state == TB_STATE_OK)
        {
            // continue to post read
            if (!tb_aico_urecv(aice->aico, aice->u.urecv.data, aice->u.urecv.size, tb_async_stream_sock_impl_read_udp_func, (tb_async_stream_ref_t)impl))
                impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_SOCK_RECV_FAILED, aice->u.urecv.data, 0, aice->u.urecv.size, impl->priv);
        }
    }

    // ok
    return tb_true;
}
#ifdef TB_SSL_ENABLE
static tb_bool_t tb_async_stream_sock_impl_read_ssl_func(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_byte_t* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(ssl, tb_false);

    // the stream
    tb_async_stream_sock_impl_t* impl = (tb_async_stream_sock_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.read, tb_false);
 
    // trace
    tb_trace_d("srecv[%p]: real: %lu, size: %lu, state: %s", impl->aico, real, size, tb_state_cstr(state));

    // save offset
    if (state == TB_STATE_OK) tb_atomic64_fetch_and_add(&impl->offset, real);

    // done func
    if (impl->func.read((tb_async_stream_ref_t)impl, state, data, real, size, impl->priv))
    {
        // ok? continue it
        if (state == TB_STATE_OK)
        {
            // continue to post read
            if (!tb_aicp_ssl_read(impl->hssl, data, size, tb_async_stream_sock_impl_read_ssl_func, (tb_async_stream_ref_t)impl))
                impl->func.read((tb_async_stream_ref_t)impl, TB_STATE_SOCK_SSL_READ_FAILED, data, 0, size, impl->priv);
        }
    }

    // ok
    return tb_true;
}
#endif
static tb_bool_t tb_async_stream_sock_impl_read(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && data && size && func, tb_false);

    // clear the offset if be writ mode now
    if (!impl->bread) tb_atomic64_set0(&impl->offset);

    // set read mode
    impl->bread = 1;

    // save func and priv
    impl->priv       = priv;
    impl->func.read  = func;

    // done
    tb_bool_t ok = tb_false;
    switch (impl->type)
    {
    case TB_SOCKET_TYPE_TCP:
        {
#ifdef TB_SSL_ENABLE
            // ssl?
            if (tb_url_ssl(tb_async_stream_url((tb_async_stream_ref_t)impl)))
            {
                // check
                tb_assert_and_check_break(impl->hssl);

                // post ssl read
                ok = tb_aicp_ssl_read_after(impl->hssl, delay, data, size, tb_async_stream_sock_impl_read_ssl_func, stream);
            }
            // post tcp read
            else
#endif
            {
                ok = tb_aico_recv_after(impl->aico, delay, data, size, tb_async_stream_sock_impl_read_func, stream);
            }
        }
        break;
    case TB_SOCKET_TYPE_UDP:
        {
            // post udp read
            ok = tb_aico_urecv_after(impl->aico, delay, data, size, tb_async_stream_sock_impl_read_udp_func, stream);
        }
        break;
    default:
        tb_trace_e("unknown socket type: %lu", impl->type);
        break;
    }

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_sock_impl_writ_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_SEND, tb_false);

    // the stream
    tb_async_stream_sock_impl_t* impl = (tb_async_stream_sock_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.writ, tb_false);

    // trace
    tb_trace_d("send[%p]: real: %lu, size: %lu, state: %s", aice->aico, aice->u.send.real, aice->u.send.size, tb_state_cstr(aice->state));

    // done state
    tb_size_t state = TB_STATE_SOCK_UNKNOWN_ERROR;
    switch (aice->state)
    {
        // ok
    case TB_STATE_OK:
        tb_assert_and_check_break(aice->u.send.data && aice->u.send.real <= aice->u.send.size);
        tb_atomic64_fetch_and_add(&impl->offset, aice->u.send.real);
        state = TB_STATE_OK;
        break;
        // closed
    case TB_STATE_CLOSED:
        state = TB_STATE_CLOSED;
        break;
        // killed
    case TB_STATE_KILLED:
        state = TB_STATE_KILLED;
        break;
        // timeout?
    case TB_STATE_TIMEOUT:
        state = TB_STATE_SOCK_SEND_TIMEOUT;
        break;
    default:
        tb_trace_e("writ: unknown state: %s", tb_state_cstr(aice->state));
        break;
    }
 
    // done func
    if (impl->func.writ((tb_async_stream_ref_t)impl, state, aice->u.send.data, aice->u.send.real, aice->u.send.size, impl->priv))
    {
        // continue?
        if (aice->state == TB_STATE_OK && aice->u.send.real < aice->u.send.size)
        {
            // continue to post writ
            if (!tb_aico_send(aice->aico, aice->u.send.data + aice->u.send.real, aice->u.send.size - aice->u.send.real, tb_async_stream_sock_impl_writ_func, (tb_async_stream_ref_t)impl))
                impl->func.writ((tb_async_stream_ref_t)impl, TB_STATE_SOCK_SEND_FAILED, aice->u.usend.data, 0, aice->u.usend.size, impl->priv);
        }
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_sock_impl_writ_udp_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_USEND, tb_false);

    // the stream
    tb_async_stream_sock_impl_t* impl = (tb_async_stream_sock_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.writ, tb_false);

    // trace
    tb_trace_d("usend[%p]: real: %lu, size: %lu, state: %s", aice->aico, aice->u.usend.real, aice->u.usend.size, tb_state_cstr(aice->state));

    // done state
    tb_size_t state = TB_STATE_SOCK_UNKNOWN_ERROR;
    switch (aice->state)
    {
    case TB_STATE_OK:
        {
            // check
            tb_assert_and_check_break(aice->u.usend.data && aice->u.usend.real <= aice->u.usend.size);

            // update offset
            tb_atomic64_fetch_and_add(&impl->offset, aice->u.usend.real);

            // ok
            state = TB_STATE_OK;
        }
        break;
        // closed
    case TB_STATE_CLOSED:
        state = TB_STATE_CLOSED;
        break;
        // killed
    case TB_STATE_KILLED:
        state = TB_STATE_KILLED;
        break;
        // timeout?
    case TB_STATE_TIMEOUT:
        state = TB_STATE_SOCK_SEND_TIMEOUT;
        break;
    default:
        {
            // trace
            tb_trace_e("writ: unknown state: %s", tb_state_cstr(aice->state));
        }
        break;
    }
 
    // done func
    if (impl->func.writ((tb_async_stream_ref_t)impl, state, aice->u.usend.data, aice->u.usend.real, aice->u.usend.size, impl->priv))
    {
        // continue?
        if (aice->state == TB_STATE_OK && aice->u.usend.real < aice->u.usend.size)
        {
            // continue to post writ
            if (!tb_aico_usend(aice->aico, &aice->u.usend.addr, aice->u.usend.data + aice->u.usend.real, aice->u.usend.size - aice->u.usend.real, tb_async_stream_sock_impl_writ_udp_func, (tb_async_stream_ref_t)impl))
                impl->func.writ((tb_async_stream_ref_t)impl, TB_STATE_SOCK_SEND_FAILED, aice->u.usend.data, 0, aice->u.usend.size, impl->priv);
        }
    }

    // ok
    return tb_true;
}
#ifdef TB_SSL_ENABLE
static tb_bool_t tb_async_stream_sock_impl_writ_ssl_func(tb_aicp_ssl_ref_t ssl, tb_size_t state, tb_byte_t const* data, tb_size_t real, tb_size_t size, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(ssl, tb_false);

    // the stream
    tb_async_stream_sock_impl_t* impl = (tb_async_stream_sock_impl_t*)priv;
    tb_assert_and_check_return_val(impl && impl->func.writ, tb_false);
 
    // trace
    tb_trace_d("ssend[%p]: real: %lu, size: %lu, state: %s", impl->aico, real, size, tb_state_cstr(state));

    // save offset
    if (state == TB_STATE_OK) tb_atomic64_fetch_and_add(&impl->offset, real);

    // done func
    if (impl->func.writ((tb_async_stream_ref_t)impl, state, data, real, size, impl->priv))
    {
        // ok? continue it
        if (state == TB_STATE_OK && real < size)
        {
            // continue to post writ
            if (!tb_aicp_ssl_writ(impl->hssl, data, size, tb_async_stream_sock_impl_writ_ssl_func, (tb_async_stream_ref_t)impl))
                impl->func.writ((tb_async_stream_ref_t)impl, TB_STATE_SOCK_SSL_WRIT_FAILED, data, 0, size, impl->priv);
        }
    }

    // ok
    return tb_true;
}
#endif
static tb_bool_t tb_async_stream_sock_impl_writ(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && data && size && func, tb_false);

    // clear the offset if be read mode now
    if (impl->bread) tb_atomic64_set0(&impl->offset);

    // set writ mode
    impl->bread = 0;

    // save func and priv
    impl->priv       = priv;
    impl->func.writ  = func;

    // done
    tb_bool_t ok = tb_false;
    switch (impl->type)
    {
    case TB_SOCKET_TYPE_TCP:
        {
#ifdef TB_SSL_ENABLE
            // ssl?
            if (tb_url_ssl(tb_async_stream_url((tb_async_stream_ref_t)impl)))
            {
                // check
                tb_assert_and_check_break(impl->hssl);

                // post ssl writ
                ok = tb_aicp_ssl_writ_after(impl->hssl, delay, data, size, tb_async_stream_sock_impl_writ_ssl_func, stream);
            }
            // post tcp writ
            else 
#endif
            {
                ok = tb_aico_send_after(impl->aico, delay, data, size, tb_async_stream_sock_impl_writ_func, stream);
            }
        }
        break;
    case TB_SOCKET_TYPE_UDP:
        {
            // post udp writ
            ok = tb_aico_usend_after(impl->aico, delay, tb_url_addr(tb_async_stream_url((tb_async_stream_ref_t)impl)), data, size, tb_async_stream_sock_impl_writ_udp_func, stream);
        }
        break;
    default:
        tb_trace_e("unknown socket type: %lu", impl->type);
        break;
    }

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_sock_impl_seek(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl && func, tb_false);

    // done func
    func(stream, TB_STATE_NOT_SUPPORTED, 0, priv);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_sock_impl_sync(tb_async_stream_ref_t stream, tb_bool_t bclosing, tb_async_stream_sync_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // done func
    func(stream, TB_STATE_OK, bclosing, priv);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_sock_impl_task_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_RUNTASK, tb_false);

    // the stream
    tb_async_stream_sock_impl_t* impl = (tb_async_stream_sock_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.task, tb_false);

    // done func
    tb_bool_t ok = impl->func.task((tb_async_stream_ref_t)impl, aice->state, impl->priv);

    // ok and continue?
    if (ok && aice->state == TB_STATE_OK)
    {
        // post task
        tb_aico_task_run(aice->aico, aice->u.runtask.delay, tb_async_stream_sock_impl_task_func, impl);
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_sock_impl_task(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // init func
    impl->func.task  = func;
    impl->priv       = priv;

    // post task
    return tb_aico_task_run(impl->aico, delay, tb_async_stream_sock_impl_task_func, stream);
}
static tb_void_t tb_async_stream_sock_impl_kill(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return(impl);

    // trace
#ifdef TB_SSL_ENABLE
    tb_trace_d("kill[%p]: %s: balived: %d, hssl: %p, hdns: %p: ..", impl->aico, tb_url_cstr(tb_async_stream_url(stream)), impl->balived, impl->hssl, impl->hdns);
#else
    tb_trace_d("kill[%p]: %s: balived: %d, hdns: %p: ..", impl->aico, tb_url_cstr(tb_async_stream_url(stream)), impl->balived, impl->hdns);
#endif

    // exit ssl
#ifdef TB_SSL_ENABLE
    if (impl->hssl) tb_aicp_ssl_kill(impl->hssl);
#endif
    // kill addr
    if (impl->hdns) tb_aicp_dns_kill(impl->hdns);

    // kill aico
    if (impl->aico) tb_aico_kill(impl->aico);
}
static tb_bool_t tb_async_stream_sock_impl_exit_aico_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_CLOS, tb_false);

    // the wait
    tb_atomic_t* wait = (tb_atomic_t*)aice->priv;
    tb_assert_and_check_return_val(wait, tb_false);

    // wait ok
    tb_atomic_set(wait, 1);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_sock_impl_exit(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // exit ssl
#ifdef TB_SSL_ENABLE
    if (impl->hssl) tb_aicp_ssl_exit(impl->hssl);
    impl->hssl = tb_null;
#endif

    // alived? wait closing it
    if (impl->balived && impl->aico)
    {
        // post to clos
        tb_atomic_t wait = 0;
        if (!tb_aico_clos(impl->aico, tb_async_stream_sock_impl_exit_aico_func, (tb_cpointer_t)&wait)) return tb_false;

        // wait closing?
        tb_size_t tryn = 15;
        while (!tb_atomic_get(&wait) && tryn--)
        {
            // trace
            tb_trace_d("exit[%p]: %s: wait: ..", impl->aico, tb_url_cstr(tb_async_stream_url(stream)));
        
            // wait some time
            tb_msleep(200);
        }

        // check
        tb_assert(tb_atomic_get(&wait));
        tb_check_return_val(tb_atomic_get(&wait), tb_false);
    }

    // exit aico
    if (impl->aico) tb_aico_exit(impl->aico);
    impl->aico = tb_null;

    // exit hdns
    if (impl->hdns) tb_aicp_dns_exit(impl->hdns);
    impl->hdns = tb_null;

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_sock_impl_ctrl(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_STREAM_CTRL_GET_OFFSET:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_opened(stream), tb_false);

            // get offset
            tb_hize_t* poffset = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(poffset, tb_false);
            *poffset = (tb_hize_t)tb_atomic64_get(&impl->offset);
            return tb_true;
        }
    case TB_STREAM_CTRL_SOCK_SET_TYPE:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);
            tb_assert_and_check_return_val(!impl->balived, tb_false);

            // the type
            tb_size_t type = (tb_size_t)tb_va_arg(args, tb_size_t);
            tb_assert_and_check_return_val(type == TB_SOCKET_TYPE_TCP || type == TB_SOCKET_TYPE_UDP, tb_false);

            // set type
            impl->type = type;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_SOCK_GET_TYPE:
        {
            tb_size_t* ptype = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(ptype, tb_false);
            *ptype = impl->type;
            return tb_true;
        }
    case TB_STREAM_CTRL_SOCK_KEEP_ALIVE:
        {
            // keep alive?
            tb_bool_t balived = (tb_bool_t)tb_va_arg(args, tb_bool_t);
            impl->balived = balived? 1 : 0;
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
tb_async_stream_ref_t tb_async_stream_init_sock(tb_aicp_ref_t aicp)
{
    // init stream
    tb_async_stream_ref_t stream = tb_async_stream_init(    aicp
                                                        ,   TB_STREAM_TYPE_SOCK
                                                        ,   sizeof(tb_async_stream_sock_impl_t)
                                                        ,   TB_STREAM_SOCK_CACHE_MAXN
                                                        ,   TB_STREAM_SOCK_CACHE_MAXN
                                                        ,   tb_null
                                                        ,   tb_async_stream_sock_impl_clos_try
                                                        ,   tb_async_stream_sock_impl_open
                                                        ,   tb_async_stream_sock_impl_clos
                                                        ,   tb_async_stream_sock_impl_exit
                                                        ,   tb_async_stream_sock_impl_kill
                                                        ,   tb_async_stream_sock_impl_ctrl
                                                        ,   tb_async_stream_sock_impl_read
                                                        ,   tb_async_stream_sock_impl_writ
                                                        ,   tb_async_stream_sock_impl_seek
                                                        ,   tb_async_stream_sock_impl_sync
                                                        ,   tb_async_stream_sock_impl_task);
    tb_assert_and_check_return_val(stream, tb_null);

    // init the stream impl
    tb_async_stream_sock_impl_t* impl = tb_async_stream_sock_impl_cast(stream);
    if (impl)
    {
        // init type
        impl->type = TB_SOCKET_TYPE_TCP;
    }

    // ok?
    return stream;
}
tb_async_stream_ref_t tb_async_stream_init_from_sock(tb_aicp_ref_t aicp, tb_char_t const* host, tb_uint16_t port, tb_size_t type, tb_bool_t bssl)
{
    // check
    tb_assert_and_check_return_val(host && port, tb_null);

    // ssl is not supported now.
    tb_assert_and_check_return_val(!bssl, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   stream = tb_null;
    do
    {
        // init stream
        stream = tb_async_stream_init_sock(aicp);
        tb_assert_and_check_return_val(stream, tb_null);

        // ctrl stream
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_HOST, host)) break;
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_PORT, port)) break;
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_SSL, bssl)) break;
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SOCK_SET_TYPE, type)) break;

        // check
        tb_assert_static(!(tb_offsetof(tb_async_stream_sock_impl_t, offset) & (sizeof(tb_atomic64_t) - 1)));

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
