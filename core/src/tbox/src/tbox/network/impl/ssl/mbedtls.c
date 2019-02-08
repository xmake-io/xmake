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
 * @file        mbedtls.c
 * @ingroup     network
 *
 */
#define TB_TRACE_MODULE_NAME            "mbedtls"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <mbedtls/ssl.h>
#include <mbedtls/certs.h>
#include <mbedtls/debug.h>
#include <mbedtls/entropy.h>
#include <mbedtls/ctr_drbg.h>
#include <mbedtls/net_sockets.h>
#include "../../../libc/libc.h"
#include "../../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the ssl type
typedef struct __tb_ssl_t
{
    // the ssl ctr drbg context
    mbedtls_ssl_context         ssl;

    // the ssl entropy context
    mbedtls_entropy_context     entropy;

    // the ssl ctr drbg context
    mbedtls_ctr_drbg_context    ctr_drbg;

    // the ssl x509 crt
    mbedtls_x509_crt            x509_crt;

    // the ssl config
    mbedtls_ssl_config          conf;

    // is opened?
    tb_bool_t                   bopened;

    // the state
    tb_size_t                   state;

    // the last wait
    tb_long_t                   lwait;

    // the timeout
    tb_long_t                   timeout;

    // the read func
    tb_ssl_func_read_t          read;

    // the writ func
    tb_ssl_func_writ_t          writ;

    // the wait func
    tb_ssl_func_wait_t          wait;

    // the priv data
    tb_cpointer_t               priv;

}tb_ssl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static __tb_inline__ tb_void_t tb_ssl_error(tb_char_t const* info, tb_long_t error)
{
#ifdef MEBDTLS_ERROR_C
    tb_char_t error_info[256] = {0};
    mbedtls_strerror(error, error_info, sizeof(error_info));
    tb_trace_e("%s: error: %ld, %s", info, error, error_info);
#else
    tb_trace_e("%s: error: %ld", info, error);
#endif
}
#if TB_TRACE_MODULE_DEBUG && defined(__tb_debug__) && defined(MBEDTLS_DEBUG_C)
static tb_void_t tb_ssl_trace_info(tb_pointer_t ctx, tb_int_t level, tb_char_t const* file, tb_int_t line, tb_char_t const* info)
{
    if (level < 1) 
    {
        // strip file directory
        tb_char_t const* filesep = tb_strchr(file, '/');
        if (filesep) file = filesep + 1;

        // trace
        tb_printf("%s: %04d: %s", file, line, info);
    }
}
#endif
static tb_long_t tb_ssl_sock_read(tb_cpointer_t priv, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(priv, -1);

    // recv it
    return tb_socket_recv((tb_socket_ref_t)priv, data, size);
}
static tb_long_t tb_ssl_sock_writ(tb_cpointer_t priv, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(priv, -1);

    // send it
    return tb_socket_send((tb_socket_ref_t)priv, data, size);
}
static tb_long_t tb_ssl_sock_wait(tb_cpointer_t priv, tb_size_t events, tb_long_t timeout)
{
    // check
    tb_assert_and_check_return_val(priv, -1);

    // wait it
    return tb_socket_wait((tb_socket_ref_t)priv, events, timeout);
}
static tb_int_t tb_ssl_func_read(tb_pointer_t priv, tb_byte_t* data, size_t size)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)priv;
    tb_assert_and_check_return_val(ssl && ssl->read, -1);

    // recv it
    tb_long_t real = ssl->read(ssl->priv, data, (tb_size_t)size);

    // trace 
    tb_trace_d("read: %ld", real);

    // ok? clear wait
    if (real > 0) ssl->lwait = 0;
    // peer closed?
    else if (!real && ssl->lwait > 0 && (ssl->lwait & TB_SOCKET_EVENT_RECV)) real = MBEDTLS_ERR_NET_CONN_RESET;
    // no data? continue to read it
    else if (!real) real = MBEDTLS_ERR_SSL_WANT_READ;
    // failed?
    else real = MBEDTLS_ERR_NET_RECV_FAILED;

    // ok?
    return (tb_int_t)real;
}
static tb_int_t tb_ssl_func_writ(tb_pointer_t priv, tb_byte_t const* data, size_t size)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)priv;
    tb_assert_and_check_return_val(ssl && ssl->writ, -1);

    // send it
    tb_long_t real = ssl->writ(ssl->priv, data, (tb_size_t)size);

    // trace 
    tb_trace_d("writ: %ld", real);

    // ok? clear wait
    if (real > 0) ssl->lwait = 0;
    // peer closed?
    else if (!real && ssl->lwait > 0 && (ssl->lwait & TB_SOCKET_EVENT_SEND)) real = MBEDTLS_ERR_NET_CONN_RESET;
    // no data? continue to writ
    else if (!real) real = MBEDTLS_ERR_SSL_WANT_WRITE;
    // failed?
    else real = MBEDTLS_ERR_NET_SEND_FAILED;

    // ok?
    return (tb_int_t)real;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_ssl_ref_t tb_ssl_init(tb_bool_t bserver)
{
    // done
    tb_bool_t           ok = tb_false;
    tb_ssl_t*           ssl = tb_null;
    tb_char_t const*    pers = "tbox";
    tb_size_t           perslen = tb_strlen(pers);
    tb_int_t            error = -1;
    do
    {
        // make ssl
        ssl = tb_malloc0_type(tb_ssl_t);
        tb_assert_and_check_break(ssl);

        // init timeout, 30s
        ssl->timeout = 30000;

        // init ssl x509_crt
        mbedtls_x509_crt_init(&ssl->x509_crt);

        // init ssl ctr_drbg context
        mbedtls_ctr_drbg_init(&ssl->ctr_drbg);

        // init ssl context
        mbedtls_ssl_init(&ssl->ssl);

        // init ssl entropy context
        mbedtls_entropy_init(&ssl->entropy);
        if ((error = mbedtls_ctr_drbg_seed(&ssl->ctr_drbg, mbedtls_entropy_func, &ssl->entropy, (tb_byte_t const*)pers, perslen)))
        {
            tb_ssl_error("mbedtls_ctr_drbg_seed() failed", error);
            break;
        }

#ifdef MBEDTLS_CERTS_C
        // init ssl ca certificate
        if ((error = mbedtls_x509_crt_parse(&ssl->x509_crt, (tb_byte_t const*)mbedtls_test_cas_pem, mbedtls_test_cas_pem_len)))
        {
            tb_ssl_error("parse x509_crt failed", error);
            break;
        }
#endif
        // init ssl config
        mbedtls_ssl_config_init(&ssl->conf);

        // init ssl endpoint
        if ((error = mbedtls_ssl_config_defaults(&ssl->conf, bserver? MBEDTLS_SSL_IS_SERVER : MBEDTLS_SSL_IS_CLIENT, MBEDTLS_SSL_TRANSPORT_STREAM, MBEDTLS_SSL_PRESET_DEFAULT)))
        {
            tb_ssl_error("mbedtls_ssl_config_defaults() failed", error);
            break;
        }

        // SSLv3 is deprecated, set minimum to TLS 1.0
        mbedtls_ssl_conf_min_version(&ssl->conf, MBEDTLS_SSL_MAJOR_VERSION_3, MBEDTLS_SSL_MINOR_VERSION_1);

        // init ssl authmode: optional
        mbedtls_ssl_conf_authmode(&ssl->conf, MBEDTLS_SSL_VERIFY_OPTIONAL);

        // init ssl ca chain
        mbedtls_ssl_conf_ca_chain(&ssl->conf, &ssl->x509_crt, tb_null);

        // init ssl random generator
        mbedtls_ssl_conf_rng(&ssl->conf, mbedtls_ctr_drbg_random, &ssl->ctr_drbg);

        // enable ssl debug?
#if TB_TRACE_MODULE_DEBUG && defined(__tb_debug__) && defined(MBEDTLS_DEBUG_C)
        mbedtls_debug_set_threshold(4);
        mbedtls_ssl_conf_dbg(&ssl->conf, tb_ssl_trace_info, tb_null);
#endif

        // setup ssl config
        if ((error = mbedtls_ssl_setup(&ssl->ssl, &ssl->conf)))
        {
            tb_ssl_error("mbedtls_ssl_setup() failed", error);
            break;
        }

        // init state
        ssl->state = TB_STATE_OK;

        // ok
        ok = tb_true;

    } while (0);

    // failed? exit it
    if (!ok)
    {
        if (ssl) tb_ssl_exit((tb_ssl_ref_t)ssl);
        ssl = tb_null;
    }

    // ok?
    return (tb_ssl_ref_t)ssl;
}
tb_void_t tb_ssl_exit(tb_ssl_ref_t self)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return(ssl);

    // close it first
    tb_ssl_clos(self);

    // exit ssl x509 crt
    mbedtls_x509_crt_free(&ssl->x509_crt);

    // exit ssl
    mbedtls_ssl_free(&ssl->ssl);

    // exit ssl entropy
    mbedtls_entropy_free(&ssl->entropy);

    // exit ssl ctr drbg
    mbedtls_ctr_drbg_free(&ssl->ctr_drbg);

    // exit ssl config
    mbedtls_ssl_config_free(&ssl->conf);

    // exit it
    tb_free(ssl);
}
tb_void_t tb_ssl_set_bio_sock(tb_ssl_ref_t self, tb_socket_ref_t sock)
{
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return(ssl);

    // set bio: sock
    tb_ssl_set_bio_func(self, tb_ssl_sock_read, tb_ssl_sock_writ, tb_ssl_sock_wait, sock);
}
tb_void_t tb_ssl_set_bio_func(tb_ssl_ref_t self, tb_ssl_func_read_t read, tb_ssl_func_writ_t writ, tb_ssl_func_wait_t wait, tb_cpointer_t priv)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return(ssl && read && writ);

    // save func
    ssl->read = read;
    ssl->writ = writ;
    ssl->wait = wait;
    ssl->priv = priv;

    // set bio: func
    mbedtls_ssl_set_bio(&ssl->ssl, ssl, tb_ssl_func_writ, tb_ssl_func_read, tb_null);
}
tb_void_t tb_ssl_set_timeout(tb_ssl_ref_t self, tb_long_t timeout)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return(ssl);

    // save timeout
    ssl->timeout = timeout;
}
tb_bool_t tb_ssl_open(tb_ssl_ref_t self)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl && ssl->wait, tb_false);

    // open it
    tb_long_t ok = -1;
    while (!(ok = tb_ssl_open_try(self)))
    {
        // wait it
        ok = tb_ssl_wait(self, TB_SOCKET_EVENT_RECV | TB_SOCKET_EVENT_SEND, ssl->timeout);
        tb_check_break(ok > 0);
    }

    // ok?
    return ok > 0? tb_true : tb_false;
}
tb_long_t tb_ssl_open_try(tb_ssl_ref_t self)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl, -1);

    // done
    tb_long_t ok = -1;
    do
    {
        // init state
        ssl->state = TB_STATE_OK;

        // have been opened already?
        if (ssl->bopened)
        {
            ok = 1;
            break;
        }

        // done handshake
        tb_long_t error = mbedtls_ssl_handshake(&ssl->ssl);
        
        // trace
        tb_trace_d("open: handshake: %ld", error);

        // ok?
        if (!error) ok = 1;
        // peer closed
        else if (error == MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY || error == MBEDTLS_ERR_NET_CONN_RESET)
        {
            tb_trace_d("open: handshake: closed: %ld", error);
            ssl->state = TB_STATE_CLOSED;
        }
        // continue to wait it?
        else if (error == MBEDTLS_ERR_SSL_WANT_READ || error == MBEDTLS_ERR_SSL_WANT_WRITE)
        {
            // trace
            tb_trace_d("open: handshake: wait: %s: ..", error == MBEDTLS_ERR_SSL_WANT_READ? "read" : "writ");

            // continue it
            ok = 0;

            // save state
            ssl->state = (error == MBEDTLS_ERR_SSL_WANT_READ)? TB_STATE_SOCK_SSL_WANT_READ : TB_STATE_SOCK_SSL_WANT_WRIT;
        }
        // failed?
        else
        {
            // trace
            tb_ssl_error("open: handshake: failed", error);

            // save state
            ssl->state = TB_STATE_SOCK_SSL_FAILED;
        }

    } while (0);

    // ok?
    if (ok > 0 && !ssl->bopened)
    {
        // done ssl verify
#if TB_TRACE_MODULE_DEBUG && defined(__tb_debug__) 
        tb_long_t error = 0;
        if ((error = mbedtls_ssl_get_verify_result(&ssl->ssl)))
        {
            if ((error & MBEDTLS_X509_BADCERT_EXPIRED)) tb_trace_d("server certificate has expired");
            if ((error & MBEDTLS_X509_BADCERT_REVOKED)) tb_trace_d("server certificate has been revoked");
            if ((error & MBEDTLS_X509_BADCERT_CN_MISMATCH)) tb_trace_d("cn mismatch");
            if ((error & MBEDTLS_X509_BADCERT_NOT_TRUSTED)) tb_trace_d("self-signed or not signed by a trusted ca");
            tb_ssl_error("verify: failed", error);
        }
#endif

        // opened
        ssl->bopened = tb_true;
    }
    // failed?
    else if (ok < 0)
    {
        // save state
        if (ssl->state == TB_STATE_OK)
            ssl->state = TB_STATE_SOCK_SSL_FAILED;
    }

    // trace
    tb_trace_d("open: handshake: %s", ok > 0? "ok" : (!ok? ".." : "no"));

    // ok?
    return ok;
}
tb_bool_t tb_ssl_clos(tb_ssl_ref_t self)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl, tb_false);

    // close it
    tb_long_t ok = -1;
    while (!(ok = tb_ssl_clos_try(self)))
    {
        // wait it
        ok = tb_ssl_wait(self, TB_SOCKET_EVENT_RECV | TB_SOCKET_EVENT_SEND, ssl->timeout);
        tb_check_break(ok > 0);
    }

    // ok?
    return ok > 0? tb_true : tb_false;
}
tb_long_t tb_ssl_clos_try(tb_ssl_ref_t self)
{
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl, -1);

    // done
    tb_long_t ok = -1;
    do
    {
        // init state
        ssl->state = TB_STATE_OK;

        // have been closed already?
        if (!ssl->bopened)
        {
            ok = 1;
            break;
        }

        // done close notify
        tb_long_t error = mbedtls_ssl_close_notify(&ssl->ssl);

        // trace
        tb_trace_d("clos: close_notify: %ld", error);

        // ok?
        if (!error) ok = 1;
        // continue to wait it?
        else if (error == MBEDTLS_ERR_SSL_WANT_READ || error == MBEDTLS_ERR_SSL_WANT_WRITE)
        {
            // trace
            tb_trace_d("clos: close_notify: wait: %s: ..", error == MBEDTLS_ERR_SSL_WANT_READ? "read" : "writ");

            // continue it
            ok = 0;

            // save state
            ssl->state = (error == MBEDTLS_ERR_SSL_WANT_READ)? TB_STATE_SOCK_SSL_WANT_READ : TB_STATE_SOCK_SSL_WANT_WRIT;
        }
        // failed?
        else
        {
            // trace
            tb_ssl_error("clos: close_notify: failed", error);

            // save state
            ssl->state = TB_STATE_SOCK_SSL_FAILED;
        }

        // clear ssl
        if (ok > 0) mbedtls_ssl_session_reset(&ssl->ssl);

    } while (0);

    // ok?
    if (ok > 0)
    {
        // closed
        ssl->bopened = tb_false;
    }
    // failed?
    else if (ok < 0)
    {
        // save state
        if (ssl->state == TB_STATE_OK)
            ssl->state = TB_STATE_SOCK_SSL_FAILED;
    }

    // trace
    tb_trace_d("clos: close_notify: %s", ok > 0? "ok" : (!ok? ".." : "no"));

    // ok?
    return ok;
}
tb_long_t tb_ssl_read(tb_ssl_ref_t self, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl && ssl->bopened && data, -1);

    // read it
    tb_long_t real = mbedtls_ssl_read(&ssl->ssl, data, size);

    // want read? continue it
    if (real == MBEDTLS_ERR_SSL_WANT_READ || !real)
    {
        // trace
        tb_trace_d("read: want read");

        // save state
        ssl->state = TB_STATE_SOCK_SSL_WANT_READ;
        return 0;
    }
    // want writ? continue it
    else if (real == MBEDTLS_ERR_SSL_WANT_WRITE)
    {
        // trace
        tb_trace_d("read: want writ");

        // save state
        ssl->state = TB_STATE_SOCK_SSL_WANT_WRIT;
        return 0;
    }
    // peer closed?
    else if (real == MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY || real == MBEDTLS_ERR_NET_CONN_RESET)
    {
        // trace
        tb_trace_d("read: peer closed");

        // save state
        ssl->state = TB_STATE_CLOSED;
        return -1;
    }
    // failed?
    else if (real < 0)
    {
        // trace
        tb_ssl_error("read: failed:", real);

        // save state
        ssl->state = TB_STATE_SOCK_SSL_FAILED;
        return -1;
    }

    // trace
    tb_trace_d("read: %ld", real);

    // ok
    return real;
}
tb_long_t tb_ssl_writ(tb_ssl_ref_t self, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl && ssl->bopened && data, -1);

    // writ it
    tb_long_t real = mbedtls_ssl_write(&ssl->ssl, data, size);

    // want read? continue it
    if (real == MBEDTLS_ERR_SSL_WANT_READ)
    {
        // trace
        tb_trace_d("writ: want read");

        // save state
        ssl->state = TB_STATE_SOCK_SSL_WANT_READ;
        return 0;
    }
    // want writ? continue it
    else if (real == MBEDTLS_ERR_SSL_WANT_WRITE || !real)
    {
        // trace
        tb_trace_d("writ: want writ");

        // save state
        ssl->state = TB_STATE_SOCK_SSL_WANT_WRIT;
        return 0;
    }
    // peer closed?
    else if (real == MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY || real == MBEDTLS_ERR_NET_CONN_RESET)
    {
        // trace
        tb_trace_d("writ: peer closed");

        // save state
        ssl->state = TB_STATE_CLOSED;
        return -1;
    }
    // failed?
    else if (real < 0)
    {
        // trace
        tb_ssl_error("writ: failed", real);

        // save state
        ssl->state = TB_STATE_SOCK_SSL_FAILED;
        return -1;
    }

    // trace
    tb_trace_d("writ: %ld", real);

    // ok
    return real;
}
tb_long_t tb_ssl_wait(tb_ssl_ref_t self, tb_size_t events, tb_long_t timeout)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl && ssl->wait, -1);
    
    // the ssl state
    switch (ssl->state)
    {
        // wait read
    case TB_STATE_SOCK_SSL_WANT_READ:
        events = TB_SOCKET_EVENT_RECV;
        break;
        // wait writ
    case TB_STATE_SOCK_SSL_WANT_WRIT:
        events = TB_SOCKET_EVENT_SEND;
        break;
        // ok, wait it
    case TB_STATE_OK:
        break;
        // failed or closed?
    default:
        return -1;
    }

    // trace
    tb_trace_d("wait: %lu: ..", events);

    // wait it
    ssl->lwait = ssl->wait(ssl->priv, events, timeout);

    // timeout or failed? save state
    if (ssl->lwait < 0) ssl->state = TB_STATE_SOCK_SSL_WAIT_FAILED;
    else if (!ssl->lwait) ssl->state = TB_STATE_SOCK_SSL_TIMEOUT;

    // trace
    tb_trace_d("wait: %ld", ssl->lwait);

    // ok?
    return ssl->lwait;
}
tb_size_t tb_ssl_state(tb_ssl_ref_t self)
{
    // check
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl, TB_STATE_UNKNOWN_ERROR);

    // the state
    return ssl->state;
}
