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
 * @file        iocp_object.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "iocp_object"
#define TB_TRACE_MODULE_DEBUG           (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "iocp_object.h"
#include "interface/interface.h"
#include "../thread_local.h"
#include "../impl/sockdata.h"
#include "../posix/sockaddr.h"
#include "../../libc/libc.h"
#include "../../container/container.h"
#include "../../algorithm/algorithm.h"
#ifdef TB_CONFIG_MODULE_HAVE_COROUTINE
#   include "../../coroutine/coroutine.h"
#   include "../../coroutine/impl/impl.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the iocp object cache maximum count
#ifdef __tb_small__
#   define TB_IOCP_OBJECT_CACHE_MAXN     (64)
#else
#   define TB_IOCP_OBJECT_CACHE_MAXN     (256)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private declaration
 */
__tb_extern_c_enter__

// bind iocp port for object
tb_bool_t tb_poller_iocp_bind_object(tb_poller_ref_t poller, tb_iocp_object_ref_t object);

__tb_extern_c_leave__

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the iocp object cache in the local thread (contains killing/killed object)
static tb_thread_local_t g_iocp_object_cache_local = TB_THREAD_LOCAL_INIT;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t tb_iocp_object_cache_clean(tb_iterator_ref_t iterator, tb_cpointer_t item, tb_cpointer_t value)
{
    // the cache
    tb_list_entry_head_ref_t cache = (tb_list_entry_head_ref_t)value;
    tb_assert(cache);

    // the object
    tb_iocp_object_ref_t object = (tb_iocp_object_ref_t)item;
    tb_assert(object);

    // remove it?
    if (tb_list_entry_size(cache) > TB_IOCP_OBJECT_CACHE_MAXN && object->state != TB_STATE_KILLING)
    {
        // trace
        tb_trace_d("clean %s object(%p) in cache(%lu)", tb_state_cstr(object->state), object->sock, tb_list_entry_size(cache));
        return tb_true;
    }
    return tb_false;
}
static tb_void_t tb_iocp_object_cache_free(tb_cpointer_t priv)
{
    tb_list_entry_head_ref_t cache = (tb_list_entry_head_ref_t)priv;
    if (cache) 
    {
        // trace
        tb_trace_d("exit iocp cache(%lu)", tb_list_entry_size(cache));

        // exit all cached iocp objects
        while (tb_list_entry_size(cache))
        {
            // get the next entry from head
            tb_list_entry_ref_t entry = tb_list_entry_head(cache);
            tb_assert(entry);

            // remove it from the cache
            tb_list_entry_remove_head(cache);

            // exit this iocp object
            tb_iocp_object_ref_t object = (tb_iocp_object_ref_t)tb_list_entry(cache, entry);
            if (object) 
            {
                // trace
                tb_trace_d("exit %s object(%p) in cache", tb_state_cstr(object->state), object->sock);

                // clear object first
                tb_iocp_object_clear(object);

                // free object
                tb_free(object);
            }
        } 

        // exit cache entry
        tb_list_entry_exit(cache);

        // free cache
        tb_free(cache);
    }
}
static tb_list_entry_head_ref_t tb_iocp_object_cache()
{
    // init local iocp object cache local data
    if (!tb_thread_local_init(&g_iocp_object_cache_local, tb_iocp_object_cache_free)) return tb_null;
 
    // init local iocp object cache
    tb_list_entry_head_ref_t cache = (tb_list_entry_head_ref_t)tb_thread_local_get(&g_iocp_object_cache_local);
    if (!cache)
    {
        // make cache 
        cache = tb_malloc0_type(tb_list_entry_head_t);
        if (cache)
        {
            // init cache entry
            tb_list_entry_init(cache, tb_iocp_object_t, entry, tb_null);

            // save cache to local thread
            tb_thread_local_set(&g_iocp_object_cache_local, cache);
        }
    }
    return cache;
}
static tb_iocp_object_ref_t tb_iocp_object_cache_alloc()
{
    // get cache
    tb_list_entry_head_ref_t cache = tb_iocp_object_cache();
    tb_assert_and_check_return_val(cache, tb_null);

    // find a free iocp object
    tb_iocp_object_ref_t result = tb_null;
    tb_for_all_if (tb_iocp_object_ref_t, object, tb_list_entry_itor(cache), object)
    {
        if (object->state != TB_STATE_KILLING)
        {
            result = object;
            break;
        }
    }

    // found? 
    if (result) 
    {
        // trace
        tb_trace_d("alloc an new iocp object from cache(%lu)", tb_list_entry_size(cache));

        // check
        tb_assert(result->state == TB_STATE_OK);

        // remove this object from the cache
        tb_list_entry_remove(cache, &result->entry);

        // init it
        tb_memset(result, 0, sizeof(tb_iocp_object_t));
    }
    return result;
}
static __tb_inline__ tb_sockdata_ref_t tb_iocp_object_sockdata()
{
    // we only enable iocp in coroutine
#if defined(TB_CONFIG_MODULE_HAVE_COROUTINE)
    return (tb_co_scheduler_self() || tb_lo_scheduler_self_())? tb_sockdata() : tb_null;
#else
    return tb_null;
#endif
}
static tb_bool_t tb_iocp_object_cancel(tb_iocp_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && object->state == TB_STATE_WAITING && object->sock, tb_false);

    // get the local socket data
    tb_sockdata_ref_t sockdata = tb_iocp_object_sockdata();
    tb_assert_and_check_return_val(sockdata, tb_false);

    // get the iocp object cache
    tb_list_entry_head_ref_t cache = tb_iocp_object_cache();
    tb_assert_and_check_return_val(cache, tb_false);

    // trace
    tb_trace_d("sock(%p): cancel io ..", object->sock);

    // cancel io
    if (!CancelIo((HANDLE)(tb_size_t)tb_sock2fd(object->sock)))
    {
        // trace
        tb_trace_e("sock(%p): cancel io failed(%d)!", object->sock, GetLastError());
        return tb_false;
    }

    // move this object to the cache
    object->state = TB_STATE_KILLING;
    tb_list_entry_insert_tail(cache, &object->entry);

    // remove this object from the local socket data
    tb_sockdata_remove(sockdata, object->sock);

    // trace
    tb_trace_d("insert to the iocp object cache(%lu)", tb_list_entry_size(cache));

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_iocp_object_ref_t tb_iocp_object_get_or_new(tb_socket_ref_t sock)
{
    // check
    tb_assert_and_check_return_val(sock, tb_null);

    // get or new object 
    tb_iocp_object_ref_t object = tb_null;
    do
    { 
        // get the local socket data
        tb_sockdata_ref_t sockdata = tb_iocp_object_sockdata();
        tb_check_break(sockdata);

        // attempt to get object first if exists
        object = (tb_iocp_object_ref_t)tb_sockdata_get(sockdata, sock);

        // new an object if not exists
        if (!object) 
        {
            // attempt to alloc object from the cache first
            object = tb_iocp_object_cache_alloc();

            // alloc object from the heap if no cache
            if (!object) object = tb_malloc0_type(tb_iocp_object_t);
            tb_assert_and_check_break(object);

            // init object
            object->sock = sock;
            tb_iocp_object_clear(object);

            // save object
            tb_sockdata_insert(sockdata, sock, (tb_cpointer_t)object);
        }

    } while (0);

    // done
    return object;
}
tb_iocp_object_ref_t tb_iocp_object_get(tb_socket_ref_t sock)
{
    tb_sockdata_ref_t sockdata = tb_iocp_object_sockdata();
    return sockdata? (tb_iocp_object_ref_t)tb_sockdata_get(sockdata, sock) : tb_null;
}
tb_void_t tb_iocp_object_remove(tb_socket_ref_t sock)
{
    // get the local socket data
    tb_sockdata_ref_t sockdata = tb_iocp_object_sockdata();
    tb_check_return(sockdata);

    // get cache
    tb_list_entry_head_ref_t cache = tb_iocp_object_cache();
    tb_assert_and_check_return(cache);

    // get iocp object
    tb_iocp_object_ref_t object = (tb_iocp_object_ref_t)tb_sockdata_get(sockdata, sock);
    if (object)
    {
        // trace
        tb_trace_d("sock(%p): removing, state: %s", sock, tb_state_cstr(object->state));

        // clean some objects in cache
        tb_remove_if(tb_list_entry_itor(cache), tb_iocp_object_cache_clean, cache);

        // no waiting io or cancel failed? remove and free this iocp object directly
        if (object->state != TB_STATE_WAITING || !tb_iocp_object_cancel(object))
        {
            // trace
            tb_trace_d("sock(%p): removed directly, state: %s", sock, tb_state_cstr(object->state));

            // remove this object from the local socket data
            tb_sockdata_remove(sockdata, sock);

            // clear and free the object data
            tb_iocp_object_clear(object);

            // insert to iocp object cache
            if (tb_list_entry_size(cache) < TB_IOCP_OBJECT_CACHE_MAXN)
                tb_list_entry_insert_head(cache, &object->entry);
            else tb_free(object);
        }
    }
}
tb_void_t tb_iocp_object_clear(tb_iocp_object_ref_t object)
{
    // check
    tb_assert(object);

    // free the private buffer for iocp
    if (object->buffer)
    {
        tb_free(object->buffer);
        object->buffer = tb_null;
    }

    // trace
    tb_trace_d("sock(%p): clear %s ..", object->sock, tb_state_cstr(object->state));

    // clear object code and state
    object->code  = TB_IOCP_OBJECT_CODE_NONE;
    object->state = TB_STATE_OK;
}
tb_socket_ref_t tb_iocp_object_accept(tb_iocp_object_ref_t object, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(object, tb_null);

    // always be accept, need not clear object each time
    tb_assert(object->code == TB_IOCP_OBJECT_CODE_NONE || object->code == TB_IOCP_OBJECT_CODE_ACPT);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_ACPT)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("accept(%p): state: %s, result: %p", object->sock, tb_state_cstr(object->state), object->u.acpt.result);

            // get result
            object->state = TB_STATE_OK;
            if (addr) tb_ipaddr_copy(addr, &object->u.acpt.addr);
            return object->u.acpt.result;
        }
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING)
        {
            // trace
            tb_trace_d("accept(%p): state: %s, continue ..", object->sock, tb_state_cstr(object->state));
            return tb_null;
        }
    }

    // trace
    tb_trace_d("accept(%p): state: %s ..", object->sock, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, tb_null);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return tb_null;

    // post a accept event 
    tb_bool_t ok = tb_false;
    tb_bool_t init_ok = tb_false;
    tb_bool_t AcceptEx_ok = tb_false;
    do
    {
        // init olap
        tb_memset(&object->olap, 0, sizeof(OVERLAPPED));

        // make address buffer
        if (!object->buffer) object->buffer = tb_malloc0(((sizeof(struct sockaddr_storage)) << 1));
        tb_assert_and_check_break(object->buffer);

        // get bound address family
        struct sockaddr_storage bound_addr;
        socklen_t len = sizeof(bound_addr);
        tb_size_t family = TB_IPADDR_FAMILY_IPV4;
        if (getsockname((SOCKET)tb_sock2fd(object->sock), (struct sockaddr *)&bound_addr, &len) != -1 && bound_addr.ss_family == AF_INET6)
            family = TB_IPADDR_FAMILY_IPV6;

        // make accept socket
        object->u.acpt.result = tb_socket_init(TB_SOCKET_TYPE_TCP, family);
        tb_assert_and_check_break(object->u.acpt.result);
        init_ok = tb_true;

        // the client fd
        SOCKET clientfd = tb_sock2fd(object->u.acpt.result);

        /* do AcceptEx
         *
         * @note this socket have been bound to local address in tb_socket_connect()
         */
        DWORD real = 0;
        AcceptEx_ok = tb_mswsock()->AcceptEx(   (SOCKET)tb_sock2fd(object->sock)
                                            ,   clientfd
                                            ,   (tb_byte_t*)object->buffer
                                            ,   0
                                            ,   sizeof(struct sockaddr_storage)
                                            ,   sizeof(struct sockaddr_storage)
                                            ,   &real
                                            ,   (LPOVERLAPPED)&object->olap)? tb_true : tb_false;

        // trace
        tb_trace_d("accept(%p): AcceptEx: %d, lasterror: %d", object->sock, AcceptEx_ok, tb_ws2_32()->WSAGetLastError());
        tb_check_break(AcceptEx_ok);

        // update the accept context, otherwise shutdown and getsockname will be failed
        SOCKET acceptfd = (SOCKET)tb_sock2fd(object->sock);
        tb_ws2_32()->setsockopt(clientfd, SOL_SOCKET, SO_UPDATE_ACCEPT_CONTEXT, (tb_char_t*)&acceptfd, sizeof(acceptfd));

        // non-block
        ULONG nb = 1;
        tb_ws2_32()->ioctlsocket(clientfd, FIONBIO, &nb);

        /* disable the nagle's algorithm to fix 40ms ack delay in some case (.e.g send-send-40ms-recv)
         *
         * 40ms is the tcp ack delay, which indicates that you are likely 
         * encountering a bad interaction between delayed acks and the nagle's algorithm. 
         *
         * TCP_NODELAY simply disables the nagle's algorithm and is a one-time setting on the socket, 
         * whereas the other two must be set at the appropriate times during the life of the connection 
         * and can therefore be trickier to use.
         * 
         * so we set TCP_NODELAY to reduce response delay for the accepted socket in the server by default
         */
        tb_int_t enable = 1;
        tb_ws2_32()->setsockopt(clientfd, IPPROTO_TCP, TCP_NODELAY, (tb_char_t*)&enable, sizeof(enable));

        // skip the completion notification on success
        if (tb_kernel32_has_SetFileCompletionNotificationModes())
        {
            if (tb_kernel32()->SetFileCompletionNotificationModes((HANDLE)clientfd, FILE_SKIP_COMPLETION_PORT_ON_SUCCESS))
            {
                tb_iocp_object_ref_t client_object = tb_iocp_object_get_or_new(object->u.acpt.result);
                if (client_object)
                    client_object->skip_cpos = 1;
            }
        }

        // get accept socket addresses
        INT                         server_size = 0;
        INT                         client_size = 0;
        struct sockaddr_storage*    server_addr = tb_null;
        struct sockaddr_storage*    client_addr = tb_null;
        if (addr && tb_mswsock()->GetAcceptExSockaddrs)
        {
            // check
            tb_assert(object->buffer);

            // get server and client addresses
            tb_mswsock()->GetAcceptExSockaddrs( (tb_byte_t*)object->buffer
                                            ,   0
                                            ,   sizeof(struct sockaddr_storage)
                                            ,   sizeof(struct sockaddr_storage)
                                            ,   (LPSOCKADDR*)&server_addr
                                            ,   &server_size
                                            ,   (LPSOCKADDR*)&client_addr
                                            ,   &client_size);

            // exists client address?
            if (client_addr)
            {
                // save address
                tb_sockaddr_save(addr, client_addr);

                // trace
                tb_trace_d("accept(%p): client address: %{ipaddr}", object->sock, addr);
            }
        }

        // trace
        tb_trace_d("accept(%p): result: %p, state: finished directly", object->sock, object->u.acpt.result);

        // ok
        ok = tb_true;

    } while (0);

    // AcceptEx failed?
    if (!ok)
    {
        // pending? continue it
        if (init_ok && WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()) 
        {
            object->code  = TB_IOCP_OBJECT_CODE_ACPT;
            object->state = TB_STATE_WAITING;
        }
        // failed?
        else
        {
            // free result socket
            if (object->u.acpt.result) tb_socket_exit(object->u.acpt.result);
            object->u.acpt.result = tb_null;
        }
    }

    // ok?
    return ok? object->u.acpt.result : tb_null;
}
tb_long_t tb_iocp_object_connect(tb_iocp_object_ref_t object, tb_ipaddr_ref_t addr)
{
    // check
    tb_assert_and_check_return_val(object && addr, -1);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_CONN)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            /* clear the previous object data first
             *
             * @note conn.addr and conn.result cannot be cleared
             */
            tb_iocp_object_clear(object);
            if (tb_ipaddr_is_equal(&object->u.conn.addr, addr))
            {
                // skip the completion notification on success
                if (tb_kernel32_has_SetFileCompletionNotificationModes())
                {
                    if (tb_kernel32()->SetFileCompletionNotificationModes((HANDLE)(SOCKET)tb_sock2fd(object->sock), FILE_SKIP_COMPLETION_PORT_ON_SUCCESS))
                        object->skip_cpos = 1;
                }

                // trace
                tb_trace_d("connect(%p): %{ipaddr}, skip: %d, state: %s, result: %ld", object->sock, addr, object->skip_cpos, tb_state_cstr(object->state), object->u.conn.result);

                // ok
                return object->u.conn.result;
            }
        }
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING && tb_ipaddr_is_equal(&object->u.conn.addr, addr))
        {
            // trace
            tb_trace_d("connect(%p, %{ipaddr}): %s, continue ..", object->sock, addr, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("connect(%p, %{ipaddr}): %s ..", object->sock, addr, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // post a connection event 
    tb_long_t ok = -1;
    tb_bool_t init_ok = tb_false;
    tb_bool_t ConnectEx_ok = tb_false;
    do
    {
        // init olap
        tb_memset(&object->olap, 0, sizeof(OVERLAPPED));

        // load client address
        tb_size_t               caddr_size = 0;
        struct sockaddr_storage caddr_data = {0};
        if (!(caddr_size = tb_sockaddr_load(&caddr_data, addr))) break;

        // load local address
        tb_size_t               laddr_size = 0;
        struct sockaddr_storage laddr_data = {0};
        tb_ipaddr_t             laddr;
        if (!tb_ipaddr_set(&laddr, tb_null, 0, (tb_uint8_t)tb_ipaddr_family(addr))) break;
        if (!(laddr_size = tb_sockaddr_load(&laddr_data, &laddr))) break;

        // bind it first for ConnectEx
        if (SOCKET_ERROR == tb_ws2_32()->bind((SOCKET)tb_sock2fd(object->sock), (LPSOCKADDR)&laddr_data, (tb_int_t)laddr_size)) 
        {
            // trace
            tb_trace_e("connect(%p, %{ipaddr}): bind failed, error: %u", object->sock, addr, GetLastError());
            break;
        }
        init_ok = tb_true;

        /* do ConnectEx
         *
         * @note this socket have been bound to local address in tb_socket_connect()
         */
        DWORD real = 0;
        ConnectEx_ok = tb_mswsock()->ConnectEx( (SOCKET)tb_sock2fd(object->sock)
                                            ,   (struct sockaddr const*)&caddr_data
                                            ,   (tb_int_t)caddr_size
                                            ,   tb_null
                                            ,   0
                                            ,   &real
                                            ,   (LPOVERLAPPED)&object->olap)? tb_true : tb_false;

        // trace
        tb_trace_d("connect(%p): ConnectEx: %d, lasterror: %d", object->sock, ConnectEx_ok, tb_ws2_32()->WSAGetLastError());
        tb_check_break(ConnectEx_ok);

        // skip the completion notification on success
        if (tb_kernel32_has_SetFileCompletionNotificationModes())
        {
            if (tb_kernel32()->SetFileCompletionNotificationModes((HANDLE)(SOCKET)tb_sock2fd(object->sock), FILE_SKIP_COMPLETION_PORT_ON_SUCCESS))
                object->skip_cpos = 1;
        }

        // trace
        tb_trace_d("connect(%p): %{ipaddr}, skip: %d, state: finished directly", object->sock, addr, object->skip_cpos);

        // ok
        ok = 1;

    } while (0);

    // ConnectEx failed?
    if (ok < 0)
    {
        // pending? continue to wait it
        if (init_ok && WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()) 
        {
            ok = 0;
            object->code          = TB_IOCP_OBJECT_CODE_CONN;
            object->state         = TB_STATE_WAITING;
            object->u.conn.addr   = *addr;
            object->u.conn.result = -1;
        }
        // already connected?
        else if (tb_ws2_32()->WSAGetLastError() == WSAEISCONN) ok = 1;
    }

    // failed?
    if (ok < 0) tb_iocp_object_clear(object);
    return ok;
}
tb_long_t tb_iocp_object_recv(tb_iocp_object_ref_t object, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(object && data && size, -1);

    // continue to the previous operation
    if (object->code == TB_IOCP_OBJECT_CODE_RECV)
    {
        // attempt to get the result if be finished
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("recv(%p): state: %s, result: %ld", object->sock, tb_state_cstr(object->state), object->u.recv.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            return object->u.recv.result;
        }
        else if (object->state == TB_STATE_WAITING)
        {
            // check
            tb_assert_and_check_return_val(object->u.recv.data == data, -1);

            // trace
            tb_trace_d("recv(%p): state: %s, continue ..", object->sock, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("recv(%p, %lu): %s ..", object->sock, size, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // attach buffer data
    object->u.recv.data = data;
    object->u.recv.size = (tb_iovec_size_t)size;

    // attempt to recv data directly
    DWORD flag = 0;
    DWORD real = 0;
    tb_long_t ok = tb_ws2_32()->WSARecv((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.recv, 1, &real, &flag, (LPOVERLAPPED)&object->olap, tb_null);

    // finished and skip iocp notification? return it directly
    if (!ok && object->skip_cpos)
    {
        // trace
        tb_trace_d("recv(%p): WSARecv: %u bytes, skip: %d, state: finished directly", object->sock, real, object->skip_cpos);
        return (tb_long_t)(real > 0? real : (tb_long_t)-1);
    }

    // trace
    tb_trace_d("recv(%p): WSARecv: %ld, skip: %d, lasterror: %d", object->sock, ok, object->skip_cpos, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue to wait it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_RECV;
        object->state = TB_STATE_WAITING;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
tb_long_t tb_iocp_object_send(tb_iocp_object_ref_t object, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(object && data, -1);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_SEND)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("send(%p): state: %s, result: %ld", object->sock, tb_state_cstr(object->state), object->u.send.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            return object->u.send.result;
        }     
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING)
        {
            // check
            tb_assert_and_check_return_val(object->u.send.data == data, -1);

            // trace
            tb_trace_d("send(%p): state: %s, continue ..", object->sock, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("send(%p, %lu): %s ..", object->sock, size, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // attempt buffer data
    object->u.send.data = data;
    object->u.send.size = (tb_iovec_size_t)size;

    // attempt to send data directly
    DWORD real = 0;
    tb_long_t ok = tb_ws2_32()->WSASend((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.send, 1, &real, 0, (LPOVERLAPPED)&object->olap, tb_null);

    // finished and skip iocp notification? return it directly
    if (!ok && object->skip_cpos)
    {
        // trace
        tb_trace_d("send(%p): WSASend: %u bytes, skip: %d, state: finished directly", object->sock, real, object->skip_cpos);
        return (tb_long_t)(real > 0? real : (tb_long_t)-1);
    }

    // trace
    tb_trace_d("send(%p): WSASend: %ld, skip: %d, lasterror: %d", object->sock, ok, object->skip_cpos, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue to wait it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_SEND;
        object->state = TB_STATE_WAITING;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
tb_long_t tb_iocp_object_urecv(tb_iocp_object_ref_t object, tb_ipaddr_ref_t addr, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(object && data && size, -1);

    // continue to the previous operation
    if (object->code == TB_IOCP_OBJECT_CODE_URECV)
    {
        // attempt to get the result if be finished
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("urecv(%p): state: %s, result: %ld", object->sock, tb_state_cstr(object->state), object->u.urecv.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            if (addr) tb_ipaddr_copy(addr, &object->u.urecv.addr);
            return object->u.urecv.result;
        }
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING)
        {
            // check
            tb_assert_and_check_return_val(object->u.urecv.data == data, -1);

            // trace
            tb_trace_d("urecv(%p): state: %s, continue ..", object->sock, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("urecv(%p, %lu): %s ..", object->sock, size, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // attach buffer data
    object->u.urecv.data = data;
    object->u.urecv.size = (tb_iovec_size_t)size;

    // make buffer for address, size and flags
    if (!object->buffer) object->buffer = tb_malloc0(sizeof(struct sockaddr_storage) + sizeof(tb_int_t) + sizeof(DWORD));
    tb_assert_and_check_return_val(object->buffer, -1);

    // init size
    tb_int_t* psize = (tb_int_t*)((tb_byte_t*)object->buffer + sizeof(struct sockaddr_storage));
    *psize = sizeof(struct sockaddr_storage);

    // init flag
    DWORD* pflag = (DWORD*)((tb_byte_t*)object->buffer + sizeof(struct sockaddr_storage) + sizeof(tb_int_t));
    *pflag = 0;

    /* post to recv event 
     *
     * It's not safe to skip completion notifications for UDP:
     * https://blogs.technet.com/b/winserverperformance/archive/2008/06/26/designing-applications-for-high-performance-part-iii.aspx
     */
    tb_long_t ok = tb_ws2_32()->WSARecvFrom((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.urecv, 1, tb_null, pflag, (struct sockaddr*)object->buffer, psize, (LPOVERLAPPED)&object->olap, tb_null);

    // trace
    tb_trace_d("urecv(%p): WSARecvFrom: %ld, lasterror: %d", object->sock, ok, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_URECV;
        object->state = TB_STATE_WAITING;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
tb_long_t tb_iocp_object_usend(tb_iocp_object_ref_t object, tb_ipaddr_ref_t addr, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(object && addr && data, -1);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_USEND)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("usend(%p, %{ipaddr}): state: %s, result: %ld", object->sock, addr, tb_state_cstr(object->state), object->u.usend.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            return object->u.usend.result;
        }  
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING && tb_ipaddr_is_equal(&object->u.usend.addr, addr))
        {
            // check
            tb_assert_and_check_return_val(object->u.usend.data == data, -1);

            // trace
            tb_trace_d("usend(%p, %{ipaddr}): state: %s, continue ..", object->sock, addr, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("usend(%p, %{ipaddr}, %lu): %s ..", object->sock, addr, size, tb_state_cstr(object->state));

    // has waiting io?
    if (object->state == TB_STATE_WAITING)
    {
        // get bound iocp port and user private data
        HANDLE port = object->port;
        tb_cpointer_t priv = object->priv;

        // cancel the previous io (urecv) first
        if (!tb_iocp_object_cancel(object)) return -1;

        // create a new iocp object
        object = tb_iocp_object_get_or_new(object->sock);
        tb_assert_and_check_return_val(object, -1);

        // restore the previous bound iocp port and user private data
        object->port = port;
        object->priv = priv;
    }

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // attach buffer data and address
    object->u.usend.addr = *addr;
    object->u.usend.data = data;
    object->u.usend.size = (tb_iovec_size_t)size;

    // load address
    tb_size_t               n = 0;
	struct sockaddr_storage d = {0};
    if (!(n = tb_sockaddr_load(&d, &object->u.usend.addr))) return tb_false;

    /* attempt to send data directly
     *
     * It's not safe to skip completion notifications for UDP:
     * https://blogs.technet.com/b/winserverperformance/archive/2008/06/26/designing-applications-for-high-performance-part-iii.aspx
     *
     * So we attempt to send data firstly without overlapped.
     */
    DWORD real = 0;
    tb_long_t ok = tb_ws2_32()->WSASendTo((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.usend, 1, &real, 0, (struct sockaddr*)&d, (tb_int_t)n, tb_null, tb_null);
    if (!ok && real)
    {
        // trace
        tb_trace_d("usend(%p, %{ipaddr}): WSASendTo: %u bytes, state: finished directly", object->sock, addr, real);
        return (tb_long_t)real;
    }

    // post a send event
    ok = tb_ws2_32()->WSASendTo((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.usend, 1, tb_null, 0, (struct sockaddr*)&d, (tb_int_t)n, (LPOVERLAPPED)&object->olap, tb_null);

    // trace
    tb_trace_d("usend(%p, %{ipaddr}): WSASendTo: %ld, lasterror: %d", object->sock, addr, ok, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_USEND;
        object->state = TB_STATE_WAITING;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
tb_hong_t tb_iocp_object_sendf(tb_iocp_object_ref_t object, tb_file_ref_t file, tb_hize_t offset, tb_hize_t size)
{
    // check
    tb_assert_and_check_return_val(object && file, -1);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_SENDF)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("sendfile(%p): state: %s, result: %ld", object->sock, tb_state_cstr(object->state), object->u.sendf.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            return object->u.sendf.result;
        }
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING)
        {
            // check
            tb_assert_and_check_return_val(object->u.sendf.file == file, -1);
            tb_assert_and_check_return_val(object->u.sendf.offset == offset, -1);

            // trace
            tb_trace_d("sendfile(%p): state: %s, continue ..", object->sock, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("sendfile(%p, %llu at %llu): %s ..", object->sock, size, offset, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // do send file
    object->olap.Offset     = (DWORD)offset;
    object->olap.OffsetHigh = (DWORD)(offset >> 32);
    BOOL ok = tb_mswsock()->TransmitFile((SOCKET)tb_sock2fd(object->sock), (HANDLE)file, (DWORD)size, (1 << 16), (LPOVERLAPPED)&object->olap, tb_null, 0);

    // trace
    tb_trace_d("sendfile(%p): TransmitFile: %d, lasterror: %d", object->sock, ok, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_SENDF;
        object->state = TB_STATE_WAITING;
        object->u.sendf.file    = file;
        object->u.sendf.offset  = offset;
        object->u.sendf.size    = size;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
tb_long_t tb_iocp_object_recvv(tb_iocp_object_ref_t object, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(object && list && size, -1);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_RECVV)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("recvv(%p): state: %s, result: %ld", object->sock, tb_state_cstr(object->state), object->u.recvv.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            return object->u.recvv.result;
        }
        else if (object->state == TB_STATE_WAITING)
        {
            // check
            tb_assert_and_check_return_val(object->u.recvv.list == list, -1);

            // trace
            tb_trace_d("recvv(%p): state: %s, continue ..", object->sock, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("recvv(%p, %lu): %s ..", object->sock, size, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // attach buffer data
    object->u.recvv.list = list;
    object->u.recvv.size = (tb_iovec_size_t)size;

    // attempt to recv data directly
    DWORD flag = 0;
    DWORD real = 0;
    tb_long_t ok = tb_ws2_32()->WSARecv((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.recvv.list, (DWORD)object->u.recvv.size, &real, &flag, (LPOVERLAPPED)&object->olap, tb_null);

    // finished and skip iocp notification? return it directly
    if (!ok && object->skip_cpos)
    {
        // trace
        tb_trace_d("recvv(%p): WSARecv: %u bytes, skip: %d, state: finished directly", object->sock, real, object->skip_cpos);
        return (tb_long_t)(real > 0? real : (tb_long_t)-1);
    }

    // trace
    tb_trace_d("recvv(%p): WSARecv: %ld, skip: %d, lasterror: %d", object->sock, ok, object->skip_cpos, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue to wait it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_RECVV;
        object->state = TB_STATE_WAITING;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
tb_long_t tb_iocp_object_sendv(tb_iocp_object_ref_t object, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(object && list && size, -1);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_SENDV)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("sendv(%p): state: %s, result: %ld", object->sock, tb_state_cstr(object->state), object->u.sendv.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            return object->u.sendv.result;
        }
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING)
        {
            // check
            tb_assert_and_check_return_val(object->u.sendv.list == list, -1);

            // trace
            tb_trace_d("sendv(%p): state: %s, continue ..", object->sock, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("sendv(%p, %lu): %s ..", object->sock, size, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // attach buffer data
    object->u.sendv.list = list;
    object->u.sendv.size = (tb_iovec_size_t)size;

    // attempt to send data directly
    DWORD real = 0;
    tb_long_t ok = tb_ws2_32()->WSASend((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.sendv.list, (DWORD)object->u.sendv.size, &real, 0, (LPOVERLAPPED)&object->olap, tb_null);

    // finished and skip iocp notification? return it directly
    if (!ok && object->skip_cpos)
    {
        // trace
        tb_trace_d("sendv(%p): WSASend: %u bytes, skip: %d, state: finished directly", object->sock, real, object->skip_cpos);
        return (tb_long_t)(real > 0? real : (tb_long_t)-1);
    }

    // trace
    tb_trace_d("sendv(%p): WSASend: %ld, skip: %d, lasterror: %d", object->sock, ok, object->skip_cpos, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue to wait it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_SENDV;
        object->state = TB_STATE_WAITING;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
tb_long_t tb_iocp_object_urecvv(tb_iocp_object_ref_t object, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(object && list && size, -1);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_URECVV)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("urecvv(%p): state: %s, result: %ld", object->sock, tb_state_cstr(object->state), object->u.urecvv.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            if (addr) tb_ipaddr_copy(addr, &object->u.urecvv.addr);
            return object->u.urecvv.result;
        }
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING)
        {
            // check
            tb_assert_and_check_return_val(object->u.urecvv.list == list, -1);

            // trace
            tb_trace_d("urecvv(%p): state: %s, continue ..", object->sock, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("urecvv(%p, %lu): %s ..", object->sock, size, tb_state_cstr(object->state));

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // attach buffer data
    object->u.urecvv.list = list;
    object->u.urecvv.size = (tb_iovec_size_t)size;

    // make buffer for address, size and flags
    if (!object->buffer) object->buffer = tb_malloc0(sizeof(struct sockaddr_storage) + sizeof(tb_int_t) + sizeof(DWORD));
    tb_assert_and_check_return_val(object->buffer, tb_false);

    // init size
    tb_int_t* psize = (tb_int_t*)((tb_byte_t*)object->buffer + sizeof(struct sockaddr_storage));
    *psize = sizeof(struct sockaddr_storage);

    // init flag
    DWORD* pflag = (DWORD*)((tb_byte_t*)object->buffer + sizeof(struct sockaddr_storage) + sizeof(tb_int_t));
    *pflag = 0;

    /* post to recv event 
     *
     * It's not safe to skip completion notifications for UDP:
     * https://blogs.technet.com/b/winserverperformance/archive/2008/06/26/designing-applications-for-high-performance-part-iii.aspx
     */
    tb_long_t ok = tb_ws2_32()->WSARecvFrom((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.urecvv.list, (DWORD)object->u.urecvv.size, tb_null, pflag, (struct sockaddr*)object->buffer, psize, (LPOVERLAPPED)&object->olap, tb_null);

    // trace
    tb_trace_d("urecvv(%p): WSARecvFrom: %ld, lasterror: %d", object->sock, ok, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_URECVV;
        object->state = TB_STATE_WAITING;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
tb_long_t tb_iocp_object_usendv(tb_iocp_object_ref_t object, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(object && addr && list, -1);

    // attempt to get the result if be finished
    if (object->code == TB_IOCP_OBJECT_CODE_USENDV)
    {
        if (object->state == TB_STATE_FINISHED)
        {
            // trace
            tb_trace_d("usendv(%p, %{ipaddr}): state: %s, result: %ld", object->sock, addr, tb_state_cstr(object->state), object->u.usendv.result);

            // clear the previous object data first, but the result cannot be cleared
            tb_iocp_object_clear(object);
            return object->u.usendv.result;
        }
        // waiting timeout before?
        else if (object->state == TB_STATE_WAITING && tb_ipaddr_is_equal(&object->u.usendv.addr, addr))
        {
            // check
            tb_assert_and_check_return_val(object->u.usendv.list == list, -1);

            // trace
            tb_trace_d("usendv(%p, %{ipaddr}): state: %s, continue ..", object->sock, addr, tb_state_cstr(object->state));
            return 0;
        }
    }

    // trace
    tb_trace_d("usendv(%p, %{ipaddr}, %lu): %s ..", object->sock, addr, size, tb_state_cstr(object->state));

    // has waiting io?
    if (object->state == TB_STATE_WAITING)
    {
        // get bound iocp port and user private data
        HANDLE port = object->port;
        tb_cpointer_t priv = object->priv;

        // cancel the previous io (urecv) first
        if (!tb_iocp_object_cancel(object)) return -1;

        // create a new iocp object
        object = tb_iocp_object_get_or_new(object->sock);
        tb_assert_and_check_return_val(object, -1);

        // restore the previous bound iocp port and user private data
        object->port = port;
        object->priv = priv;
    }

    // check state
    tb_assert_and_check_return_val(object->state != TB_STATE_WAITING, -1);

    // bind iocp object first 
    if (!tb_poller_iocp_bind_object(tb_null, object)) return -1;

    // attach buffer data and address
    object->u.usendv.addr = *addr;
    object->u.usendv.list = list;
    object->u.usendv.size = (tb_iovec_size_t)size;

    // load address
    tb_size_t               n = 0;
	struct sockaddr_storage d = {0};
    if (!(n = tb_sockaddr_load(&d, &object->u.usendv.addr))) return -1;

    /* attempt to send data directly
     *
     * It's not safe to skip completion notifications for UDP:
     * https://blogs.technet.com/b/winserverperformance/archive/2008/06/26/designing-applications-for-high-performance-part-iii.aspx
     *
     * So we attempt to send data firstly without overlapped.
     */
    DWORD real = 0;
    tb_long_t ok = tb_ws2_32()->WSASendTo((SOCKET)tb_sock2fd(object->sock), (WSABUF*)object->u.usendv.list, (DWORD)object->u.usendv.size, &real, 0, (struct sockaddr*)&d, (tb_int_t)n, tb_null, tb_null);
    if (!ok && real)
    {
        // trace
        tb_trace_d("usendv(%p, %{ipaddr}): WSASendTo: %u bytes, state: finished directly", object->sock, addr, real);
        return (tb_long_t)real;
    }

    // post a send event
    ok = tb_ws2_32()->WSASendTo((SOCKET)tb_sock2fd(object->sock), (WSABUF*)&object->u.usendv.list, (DWORD)object->u.usendv.size, tb_null, 0, (struct sockaddr*)&d, (tb_int_t)n, (LPOVERLAPPED)&object->olap, tb_null);

    // trace
    tb_trace_d("usendv(%p, %{ipaddr}): WSASendTo: %ld, lasterror: %d", object->sock, addr, ok, tb_ws2_32()->WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == tb_ws2_32()->WSAGetLastError()))) 
    {
        object->code  = TB_IOCP_OBJECT_CODE_USENDV;
        object->state = TB_STATE_WAITING;
        return 0;
    }

    // failed
    tb_iocp_object_clear(object);
    return -1;
}
