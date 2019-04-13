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
 * @file        openssl.c
 * @ingroup     network
 *
 */
#define TB_TRACE_MODULE_NAME            "openssl"
#define TB_TRACE_MODULE_DEBUG           (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>
#include "../../../utils/utils.h"
#include "../../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
// the ssl type
typedef struct __tb_ssl_t
{
    // the ssl session
    SSL*                ssl;

    // the ssl context
    SSL_CTX*            ctx;

    // the ssl bio
    BIO*                bio;

    // is opened?
    tb_bool_t           bopened;

    // the state
    tb_size_t           state;

    // the last wait
    tb_long_t           lwait;

    // the timeout
    tb_long_t           timeout;

    // the read func
    tb_ssl_func_read_t  read;

    // the writ func
    tb_ssl_func_writ_t  writ;

    // the wait func
    tb_ssl_func_wait_t  wait;

    // the priv data
    tb_cpointer_t       priv;

}tb_ssl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */
static tb_int_t         tb_ssl_bio_method_init(BIO* bio);
static tb_int_t         tb_ssl_bio_method_exit(BIO* bio);
static tb_int_t         tb_ssl_bio_method_read(BIO* bio, tb_char_t* data, tb_int_t size);
static tb_int_t         tb_ssl_bio_method_writ(BIO* bio, tb_char_t const* data, tb_int_t size);
static tb_long_t        tb_ssl_bio_method_ctrl(BIO* bio, tb_int_t cmd, tb_long_t num, tb_pointer_t ptr);
static tb_int_t         tb_ssl_bio_method_puts(BIO* bio, tb_char_t const* data);
static tb_int_t         tb_ssl_bio_method_gets(BIO* bio, tb_char_t* data, tb_int_t size);

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
static BIO_METHOD* g_ssl_bio_method = tb_null;

/* //////////////////////////////////////////////////////////////////////////////////////
 * library implementation
 */
static tb_handle_t tb_ssl_library_init(tb_cpointer_t* ppriv)
{
    // init it
    SSL_library_init();

    // init bio method
    g_ssl_bio_method = BIO_meth_new(BIO_TYPE_SOURCE_SINK | 100, "ssl_bio");
    tb_assert_and_check_return_val(g_ssl_bio_method, tb_null);

    // init methods
    BIO_meth_set_write(g_ssl_bio_method, tb_ssl_bio_method_writ);
    BIO_meth_set_read(g_ssl_bio_method, tb_ssl_bio_method_read);
    BIO_meth_set_puts(g_ssl_bio_method, tb_ssl_bio_method_puts);
    BIO_meth_set_gets(g_ssl_bio_method, tb_ssl_bio_method_gets);
    BIO_meth_set_ctrl(g_ssl_bio_method, tb_ssl_bio_method_ctrl);
    BIO_meth_set_create(g_ssl_bio_method, tb_ssl_bio_method_init);
    BIO_meth_set_destroy(g_ssl_bio_method, tb_ssl_bio_method_exit);

    // ok
    return ppriv;
}
static tb_void_t tb_ssl_library_exit(tb_handle_t ssl, tb_cpointer_t priv)
{
    if (g_ssl_bio_method) BIO_meth_free(g_ssl_bio_method);
    g_ssl_bio_method = tb_null;
}
static tb_handle_t tb_ssl_library_load()
{
    return tb_singleton_instance(TB_SINGLETON_TYPE_LIBRARY_OPENSSL, tb_ssl_library_init, tb_ssl_library_exit, tb_null, tb_null);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_int_t tb_ssl_verify(tb_int_t ok, X509_STORE_CTX* ctx)
{
    return 1;
}
#ifdef __tb_debug__
static tb_char_t const* tb_ssl_error(tb_long_t error)
{
    // done
    switch (error)
    {
    case SSL_ERROR_NONE:
        return "SSL_ERROR_NONE";
    case SSL_ERROR_SSL:
        return "SSL_ERROR_SSL";
    case SSL_ERROR_WANT_READ:
        return "SSL_ERROR_WANT_READ";
    case SSL_ERROR_WANT_WRITE:
        return "SSL_ERROR_WANT_WRITE";
    case SSL_ERROR_WANT_X509_LOOKUP:
        return "SSL_ERROR_WANT_X509_LOOKUP";
    case SSL_ERROR_SYSCALL:
        return "SSL_ERROR_SYSCALL";
    case SSL_ERROR_ZERO_RETURN:
        return "SSL_ERROR_ZERO_RETURN";
    case SSL_ERROR_WANT_CONNECT:
        return "SSL_ERROR_WANT_CONNECT";
    case SSL_ERROR_WANT_ACCEPT:
        return "SSL_ERROR_WANT_ACCEPT";
    default:
        return "UNKOWN_ERROR_VALUE";
    }
    return "";
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
static tb_int_t tb_ssl_bio_method_init(BIO* bio)
{
    // check
    tb_assert_and_check_return_val(bio, 0);

    // trace
    tb_trace_d("bio: init");

    // init 
    BIO_set_init(bio, 1);
    BIO_set_data(bio, tb_null);
    BIO_set_shutdown(bio, 1);

    // ok
    return 1;
}
static tb_int_t tb_ssl_bio_method_exit(BIO* bio)
{
    // check
    tb_assert_and_check_return_val(bio, 0);

    // trace
    tb_trace_d("bio: exit");

    // exit 
    BIO_set_init(bio, 0);
    BIO_set_data(bio, tb_null);
    BIO_set_shutdown(bio, 0);

    // ok
    return 1;
}
static tb_int_t tb_ssl_bio_method_read(BIO* bio, tb_char_t* data, tb_int_t size)
{
    // check
    tb_assert_and_check_return_val(bio && data && size >= 0, -1);

    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)BIO_get_data(bio);
    tb_assert_and_check_return_val(ssl && ssl->read, -1);

    // writ 
    tb_long_t real = ssl->read(ssl->priv, (tb_byte_t*)data, size);

    // trace
    tb_trace_d("bio: read: real: %ld, size: %d", real, size);

    // ok? clear wait
    if (real > 0) ssl->lwait = 0;
    // peer closed?
    else if (!real && ssl->lwait > 0 && (ssl->lwait & TB_SOCKET_EVENT_RECV)) 
    {
        BIO_clear_retry_flags(bio);
        real = -1;
    }
    // no data? continue to read it
    else if (!real) 
    {
        BIO_clear_retry_flags(bio);
        BIO_set_retry_read(bio);
        real = -1;
    }
    // failed?
    else 
    {
        BIO_clear_retry_flags(bio);
        real = -1;
    }

    // ok?
    return (tb_int_t)real;
}
static tb_int_t tb_ssl_bio_method_writ(BIO* bio, tb_char_t const* data, tb_int_t size)
{
    // check
    tb_assert_and_check_return_val(bio && data && size >= 0, -1);

    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)BIO_get_data(bio);
    tb_assert_and_check_return_val(ssl && ssl->writ, -1);

    // writ 
    tb_long_t real = ssl->writ(ssl->priv, (tb_byte_t const*)data, size);

    // trace
    tb_trace_d("bio: writ: real: %ld, size: %d", real, size);

    // ok? clear wait
    if (real > 0) ssl->lwait = 0;
    // peer closed?
    else if (!real && ssl->lwait > 0 && (ssl->lwait & TB_SOCKET_EVENT_SEND)) 
    {
        BIO_clear_retry_flags(bio);
        real = -1;
    }
    // no data? continue to writ
    else if (!real) 
    {
        BIO_clear_retry_flags(bio);
        BIO_set_retry_write(bio);
        real = -1;
    }
    // failed?
    else
    {
        BIO_clear_retry_flags(bio);
        real = -1;
    }

    // ok?
    return (tb_int_t)real;
}
static tb_long_t tb_ssl_bio_method_ctrl(BIO* bio, tb_int_t cmd, tb_long_t num, tb_pointer_t ptr)
{
    // check
    tb_assert_and_check_return_val(bio, -1);

    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)BIO_get_data(bio);
    tb_assert_and_check_return_val(ssl, -1);

    // done
    tb_long_t ok = 0;
    switch (cmd)
    {
    case BIO_CTRL_FLUSH:
        {
            // trace
            tb_trace_d("bio: ctrl: flush");

            // ok
            ok = 1;
        }
        break;
    default:
        {
            // trace
            tb_trace_d("bio: ctrl: unknown: %d", cmd);
        }
        break;
    }
    // ok?
    return ok;
}
static tb_int_t tb_ssl_bio_method_puts(BIO* bio, tb_char_t const* data)
{
    // check
    tb_assert_and_check_return_val(bio && data, -1);

    // trace
    tb_trace_d("bio: puts: %s", data);

    // writ
    return tb_ssl_bio_method_writ(bio, data, tb_strlen(data));
}
static tb_int_t tb_ssl_bio_method_gets(BIO* bio, tb_char_t* data, tb_int_t size)
{
    // check
    tb_assert_and_check_return_val(bio && data, -1);

    // trace
    tb_trace_d("bio: gets: %d", size);

    // read it
    return tb_ssl_bio_method_read(bio, data, size);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_ssl_ref_t tb_ssl_init(tb_bool_t bserver)
{
    // done
    tb_bool_t   ok = tb_false;
    tb_ssl_t*   ssl = tb_null;
    do
    {
        // load openssl library
        if (!tb_ssl_library_load()) break;

        // check
        tb_assert_and_check_break(g_ssl_bio_method);

        // make ssl
        ssl = tb_malloc0_type(tb_ssl_t);
        tb_assert_and_check_break(ssl);

        // init timeout, 30s
        ssl->timeout = 30000;

        // init ctx
        ssl->ctx = SSL_CTX_new(SSLv23_method());
        tb_assert_and_check_break(ssl->ctx);
        
        // make ssl
        ssl->ssl = SSL_new(ssl->ctx);
        tb_assert_and_check_break(ssl->ssl);

        // init endpoint 
        if (bserver) SSL_set_accept_state(ssl->ssl);
        else SSL_set_connect_state(ssl->ssl);

        // init verify
        SSL_set_verify(ssl->ssl, 0, tb_ssl_verify);

        // init bio
        ssl->bio = BIO_new(g_ssl_bio_method);
        tb_assert_and_check_break(ssl->bio);

        // set bio to ssl
        BIO_set_data(ssl->bio, ssl);
        SSL_set_bio(ssl->ssl, ssl->bio, ssl->bio);

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
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return(ssl);

    // close it first
    tb_ssl_clos(self);

    // exit ssl
    if (ssl->ssl) SSL_free(ssl->ssl);
    ssl->ssl = tb_null;

    // exit ctx
    if (ssl->ctx) SSL_CTX_free(ssl->ctx);
    ssl->ctx = tb_null;

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
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return(ssl && read && writ);

    // save func
    ssl->read = read;
    ssl->writ = writ;
    ssl->wait = wait;
    ssl->priv = priv;
}
tb_void_t tb_ssl_set_timeout(tb_ssl_ref_t self, tb_long_t timeout)
{
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return(ssl);

    // save timeout
    ssl->timeout = timeout;
}
tb_bool_t tb_ssl_open(tb_ssl_ref_t self)
{
    // the ssl
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
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl && ssl->ssl, -1);

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

        // do handshake
        tb_long_t r = SSL_do_handshake(ssl->ssl);
    
        // trace
        tb_trace_d("open: handshake: %ld", r);

        // ok?
        if (r == 1) ok = 1;
        // continue ?
        else if (!r) ok = 0;
        else
        {
            // the error
            tb_long_t error = SSL_get_error(ssl->ssl, r);

            // wait?
            if (error == SSL_ERROR_WANT_WRITE || error == SSL_ERROR_WANT_READ)
            {
                // trace
                tb_trace_d("open: handshake: wait: %s: ..", error == SSL_ERROR_WANT_READ? "read" : "writ");

                // continue it
                ok = 0;

                // save state
                ssl->state = (error == SSL_ERROR_WANT_READ)? TB_STATE_SOCK_SSL_WANT_READ : TB_STATE_SOCK_SSL_WANT_WRIT;
            }
            // failed?
            else
            {
                // trace
                tb_trace_d("open: handshake: failed: %s", tb_ssl_error(error));
    
                // save state
                ssl->state = TB_STATE_SOCK_SSL_FAILED;
            }
        }

    } while (0);

    // ok?
    if (ok > 0)
    {
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
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl, tb_false);

    // open it
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
        if (!ssl->bopened || !ssl->ssl)
        {
            ok = 1;
            break;
        }

        // do shutdown
        tb_long_t r = SSL_shutdown(ssl->ssl);
    
        // trace
        tb_trace_d("clos: shutdown: %ld", r);

        // ok?
        if (r == 1) ok = 1;
        // continue?
        else if (!r) ok = 0;
        else
        {
            // the error
            tb_long_t error = SSL_get_error(ssl->ssl, r);

            // wait?
            if (error == SSL_ERROR_WANT_WRITE || error == SSL_ERROR_WANT_READ)
            {
                // trace
                tb_trace_d("clos: shutdown: wait: %s: ..", error == SSL_ERROR_WANT_READ? "read" : "writ");

                // continue it
                ok = 0;

                // save state
                ssl->state = (error == SSL_ERROR_WANT_READ)? TB_STATE_SOCK_SSL_WANT_READ : TB_STATE_SOCK_SSL_WANT_WRIT;
            }
            // failed?
            else
            {
                // trace
                tb_trace_d("clos: shutdown: failed: %s", tb_ssl_error(error));
    
                // save state
                ssl->state = TB_STATE_SOCK_SSL_FAILED;
            }
        }

    } while (0);

    // ok?
    if (ok > 0)
    {
        // closed
        ssl->bopened = tb_false;

        // clear ssl
        if (ssl->ssl) SSL_clear(ssl->ssl);
    }
    // failed?
    else if (ok < 0)
    {
        // save state
        if (ssl->state == TB_STATE_OK)
            ssl->state = TB_STATE_SOCK_SSL_FAILED;
    }

    // trace
    tb_trace_d("clos: shutdown: %s", ok > 0? "ok" : (!ok? ".." : "no"));

    // ok?
    return ok;
}
tb_long_t tb_ssl_read(tb_ssl_ref_t self, tb_byte_t* data, tb_size_t size)
{
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl && ssl->ssl && ssl->bopened && data, -1);

    // read it
    tb_long_t real = SSL_read(ssl->ssl, data, size);

    // trace
    tb_trace_d("read: %ld", real);

    // done
    if (real < 0)
    {
        // the error
        tb_long_t error = SSL_get_error(ssl->ssl, real);

        // want read? continue it
        if (error == SSL_ERROR_WANT_READ)
        {
            // trace
            tb_trace_d("read: want read");

            // save state
            ssl->state = TB_STATE_SOCK_SSL_WANT_READ;
            return 0;
        }
        // want writ? continue it
        else if (error == SSL_ERROR_WANT_WRITE)
        {
            // trace
            tb_trace_d("read: want writ");

            // save state
            ssl->state = TB_STATE_SOCK_SSL_WANT_WRIT;
            return 0;
        }
        // failed?
        else
        {
            // trace
            tb_trace_d("read: failed: %ld, %s", real, tb_ssl_error(error));

            // save state
            ssl->state = TB_STATE_SOCK_SSL_FAILED;
            return -1;
        }
    }
    // closed?
    else if (!real)
    {
        // trace
        tb_trace_d("read: closed");

        // save state
        ssl->state = TB_STATE_CLOSED;
        return -1;
    }

    // ok
    return real;
}
tb_long_t tb_ssl_writ(tb_ssl_ref_t self, tb_byte_t const* data, tb_size_t size)
{
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl && ssl->ssl && ssl->bopened && data, -1);

    // writ it
    tb_long_t real = SSL_write(ssl->ssl, data, size);

    // trace
    tb_trace_d("writ: %ld", real);

    // done
    if (real < 0)
    {
        // the error
        tb_long_t error = SSL_get_error(ssl->ssl, real);

        // want read? continue it
        if (error == SSL_ERROR_WANT_READ)
        {
            // trace
            tb_trace_d("writ: want read");

            // save state
            ssl->state = TB_STATE_SOCK_SSL_WANT_READ;
            return 0;
        }
        // want writ? continue it
        else if (error == SSL_ERROR_WANT_WRITE)
        {
            // trace
            tb_trace_d("writ: want writ");

            // save state
            ssl->state = TB_STATE_SOCK_SSL_WANT_WRIT;
            return 0;
        }
        // failed?
        else
        {
            // trace
            tb_trace_d("writ: failed: %ld, %s", real, tb_ssl_error(error));

            // save state
            ssl->state = TB_STATE_SOCK_SSL_FAILED;
            return -1;
        }
    }
    // closed?
    else if (!real)
    {
        // trace
        tb_trace_d("read: closed");

        // save state
        ssl->state = TB_STATE_CLOSED;
        return -1;
    }

    // ok
    return real;
}
tb_long_t tb_ssl_wait(tb_ssl_ref_t self, tb_size_t events, tb_long_t timeout)
{
    // the ssl
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
    // the ssl
    tb_ssl_t* ssl = (tb_ssl_t*)self;
    tb_assert_and_check_return_val(ssl, TB_STATE_UNKNOWN_ERROR);

    // the state
    return ssl->state;
}

