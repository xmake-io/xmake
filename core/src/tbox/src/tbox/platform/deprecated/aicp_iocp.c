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
 * @file        aicp_iocp.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../windows/interface/interface.h"
#include "../posix/sockaddr.h"
#include "../windows/ntstatus.h"
#include "../windows/socket_pool.h"
#include "../ltimer.h"
#include "../posix/sockaddr.h"
#include "../../asio/deprecated/asio.h"
#include "../../asio/deprecated/impl/prefix.h"
#include "../../libc/libc.h"
#include "../../math/math.h"
#include "../../utils/utils.h"
#include "../../memory/memory.h"
#include "../../platform/platform.h"
#include "../../algorithm/algorithm.h"
#include "../../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// update connect context
#ifndef SO_UPDATE_CONNECT_CONTEXT
#   define SO_UPDATE_CONNECT_CONTEXT                (0x7010)
#endif

// update accept context
#ifndef SO_UPDATE_ACCEPT_CONTEXT
#   define SO_UPDATE_ACCEPT_CONTEXT                 (0x700B)
#endif

// enable socket pool? only for the accepted socket
#define TB_IOCP_SOCKET_POOL_ENABLE

// the olap list maxn for GetQueuedCompletionStatusEx 
#ifdef __tb_small__
#   define TB_IOCP_OLAP_LIST_MAXN                   (63)
#else
#   define TB_IOCP_OLAP_LIST_MAXN                   (255)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the iocp func type
typedef struct __tb_iocp_func_t
{
    // the AcceptEx func
    tb_mswsock_AcceptEx_t                       AcceptEx;

    // the ConnectEx func
    tb_mswsock_ConnectEx_t                      ConnectEx;

    // the DisconnectEx func
    tb_mswsock_DisconnectEx_t                   DisconnectEx;

    // the TransmitFile func
    tb_mswsock_TransmitFile_t                   TransmitFile;

    // the GetAcceptExSockaddrs func
    tb_mswsock_GetAcceptExSockaddrs_t           GetAcceptExSockaddrs;

    // the GetQueuedCompletionStatusEx func
    tb_kernel32_GetQueuedCompletionStatusEx_t   GetQueuedCompletionStatusEx;
 
    // WSAGetLastError
    tb_ws2_32_WSAGetLastError_t                 WSAGetLastError;

    // WSASend
    tb_ws2_32_WSASend_t                         WSASend;

    // WSARecv
    tb_ws2_32_WSARecv_t                         WSARecv;

    // WSASendTo
    tb_ws2_32_WSASendTo_t                       WSASendTo;

    // WSARecvFrom
    tb_ws2_32_WSARecvFrom_t                     WSARecvFrom;

    // bind
    tb_ws2_32_bind_t                            bind;

}tb_iocp_func_t;

// the iocp impl type
typedef struct __tb_iocp_ptor_impl_t
{
    // the ptor base
    tb_aicp_ptor_impl_t                         base;

    // the i/o completion port
    HANDLE                                      port;

    // the timer for task
    tb_timer_ref_t                              timer;

    // the low precision timer for timeout
    tb_ltimer_ref_t                             ltimer;

    // the post loop
    tb_thread_ref_t                             loop;

    // the post wait
    tb_event_ref_t                              wait;

    /* the aice post
     *
     * index: 0: higher priority for conn, acpt and task
     * index: 1: lower priority for io aice 
     */
    tb_queue_ref_t                              post[2];
    
    // the killing aico list
    tb_vector_ref_t                             kill;

    // the post lock
    tb_spinlock_t                               lock;

    // the post func
    tb_iocp_func_t                              func;

}tb_iocp_ptor_impl_t;

// the iocp olap type
typedef struct __tb_iocp_olap_t
{
    // the base
    OVERLAPPED                                  base;
    
    /* the aice
     *
     * @note (WSABUF*)&aice.u.xxxx must be aligned
     */
    __tb_cpu_aligned__ tb_aice_t                aice;

}tb_iocp_olap_t;

// the iocp aico type
typedef __tb_cpu_aligned__ struct __tb_iocp_aico_t
{
    // the base
    tb_aico_impl_t                              base;

    // the impl
    tb_iocp_ptor_impl_t*                        impl;

    // the olap
    __tb_cpu_aligned__ tb_iocp_olap_t           olap;
    
    // the task
    tb_handle_t                                 task;

    // the address data for acpt, urecv and urecvv
    tb_cpointer_t                               addr;

    // is ltimer?
    tb_uint8_t                                  bltimer : 1;

    // DisconnectEx it
    tb_uint8_t                                  bDisconnectEx : 1;

}tb_iocp_aico_t;

// the iocp loop type
typedef struct __tb_iocp_loop_t
{
    // the self
    tb_size_t                                   self;

    // the olap list
    tb_OVERLAPPED_ENTRY_t                       list[TB_IOCP_OLAP_LIST_MAXN];

    // the aice spak 
    tb_queue_ref_t                              spak;                   

}tb_iocp_loop_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * timeout 
 */
static tb_void_t tb_iocp_spak_timeout(tb_bool_t killed, tb_cpointer_t priv)
{
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)priv;
    tb_assert_and_check_return(aico);

    // the impl
    tb_iocp_ptor_impl_t* impl = aico->impl;
    tb_assert_and_check_return(impl);

    // cancel it
    switch (aico->base.type)
    {
    case TB_AICO_TYPE_SOCK:
    case TB_AICO_TYPE_FILE:
        {
            // check
            tb_assert_and_check_break(aico->base.handle);

            // trace
            tb_trace_d("spak[%p]: code: %lu: timeout", aico, aico->olap.aice.code);

            // the handle
            HANDLE handle = aico->base.type == TB_AICO_TYPE_SOCK? (HANDLE)((SOCKET)aico->base.handle - 1) : aico->base.handle;

            // CancelIo it
            if (!CancelIo(handle))
            {
                // trace
                tb_trace_e("cancel[%p]: failed: %u", aico, GetLastError());
            }
        }
        break;
    default:
        tb_assert(0);
        break;
    }
}
static tb_void_t tb_iocp_spak_timeout_runtask(tb_bool_t killed, tb_cpointer_t priv)
{
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)priv;
    tb_assert_and_check_return(aico);

    // the impl
    tb_iocp_ptor_impl_t* impl = aico->impl;
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("runtask: timeout: when: %llu", aico->olap.aice.u.runtask.when);

    // post ok
    aico->olap.aice.state = killed? TB_STATE_KILLED : TB_STATE_OK;
    PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * spak 
 */
static tb_bool_t tb_iocp_post_acpt(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice);
static tb_long_t tb_iocp_spak_acpt(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t resp, tb_size_t real, tb_size_t error)
{
    // check?
    tb_assert_and_check_return_val(impl && resp, -1);

    // trace
    tb_trace_d("acpt[%p]: spak: %lu", resp->aico, error);

    // check
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)resp->aico;
    tb_assert(aico && aico->addr && resp->u.acpt.priv[0]);

    // done
    switch (error)
    {
        // ok or pending?
    case ERROR_SUCCESS:
    case WAIT_TIMEOUT:
    case ERROR_IO_PENDING:
        {
            // done state
            switch (resp->state)
            {
            case TB_STATE_OK:
            case TB_STATE_PENDING:
                resp->state = resp->u.acpt.priv[0]? TB_STATE_OK : TB_STATE_FAILED;
                break;
            default:
                // using the self state here
                break;
            }

            // ok?
            if (resp->state == TB_STATE_OK)
            {
                // init aico
                resp->u.acpt.aico = tb_aico_init(tb_aico_aicp(resp->aico));
                if (!resp->u.acpt.aico)
                {
                    resp->state = TB_STATE_FAILED;
                    break;
                }

#ifdef TB_IOCP_SOCKET_POOL_ENABLE
                // DisconnectEx it
                ((tb_iocp_aico_t*)resp->u.acpt.aico)->bDisconnectEx = 1;
#endif

                // open aico
                if (!tb_aico_open_sock(resp->u.acpt.aico, (tb_socket_ref_t)resp->u.acpt.priv[0])) 
                {
                    resp->state = TB_STATE_FAILED;
                    break;
                }

                // update the accept context, otherwise shutdown and getsockname will be failed
                SOCKET acpt = (SOCKET)tb_aico_sock(resp->aico) - 1;
                tb_long_t update_ok = setsockopt((SOCKET)resp->u.acpt.priv[0] - 1, SOL_SOCKET, SO_UPDATE_ACCEPT_CONTEXT, (tb_char_t*)&acpt, sizeof(acpt));
                tb_assert(!update_ok); tb_used(update_ok);
          
                // clear sock
                resp->u.acpt.priv[0] = tb_null;

                // done GetAcceptExSockaddrs
                INT                         server_size = 0;
                INT                         client_size = 0;
                struct sockaddr_storage*    server_addr = tb_null;
                struct sockaddr_storage*    client_addr = tb_null;
                if (impl->func.GetAcceptExSockaddrs)
                {
                    // done it
                    impl->func.GetAcceptExSockaddrs(    (tb_byte_t*)aico->addr
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
                        tb_sockaddr_save(&resp->u.acpt.addr, client_addr);
 
                        // trace
                        tb_trace_d("acpt[%p]: client_addr: %{ipaddr}", resp->aico, &resp->u.acpt.addr);
                    }
                }
            }
        }
        break;
        // canceled? timeout?
    case WSAEINTR:
    case ERROR_OPERATION_ABORTED:
        {
            resp->state = TB_STATE_TIMEOUT;
        }
        break;
        // unknown error
    default:
        {
            resp->state = TB_STATE_FAILED;

            // trace
            tb_trace_e("acpt[%p]: unknown error: %u", resp->aico, error);
        }
        break;
    }

    // continue to post acpt if ok
    if (resp->state == TB_STATE_OK) tb_iocp_post_acpt(impl, resp);

    // ok
    return 1;
}
static tb_long_t tb_iocp_spak_conn(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t resp, tb_size_t real, tb_size_t error)
{
    // check?
    tb_assert_and_check_return_val(resp, -1);

    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)resp->aico;
    tb_assert_and_check_return_val(aico, -1);

    // trace
    tb_trace_d("conn[%p]: spak: %lu", resp->aico, error);

    // done
    switch (error)
    {
        // ok or pending?
    case ERROR_SUCCESS:
    case WAIT_TIMEOUT:
    case ERROR_IO_PENDING:
        {
            // done state
            switch (resp->state)
            {
            case TB_STATE_OK:
            case TB_STATE_PENDING:
                resp->state = TB_STATE_OK;
                break;
            default:
                // using the self state here
                break;
            }
        }
        break;
        // failed?
    case WSAENOTCONN:
    case WSAECONNREFUSED:
    case ERROR_CONNECTION_REFUSED:
        {
            resp->state = TB_STATE_FAILED;
        }
        break;
        // timeout?
    case WSAEINTR:
    case ERROR_SEM_TIMEOUT:
    case ERROR_OPERATION_ABORTED:
        {
            resp->state = TB_STATE_TIMEOUT;
        }
        break;
        // unknown error
    default:
        {
            resp->state = TB_STATE_FAILED;

            // trace
            tb_trace_e("conn: unknown error: %u", error);
        }
        break;
    }

    // ok?
    if (resp->state == TB_STATE_OK)
    {
#if 0
        // update the connect context, otherwise shutdown and getsockname will be failed
        tb_long_t update_ok = setsockopt((SOCKET)tb_aico_sock(resp->aico)- 1, SOL_SOCKET, SO_UPDATE_CONNECT_CONTEXT, tb_null, 0);
        tb_assert(!update_ok); tb_used(update_ok);

        // DisconnectEx it
        aico->bDisconnectEx = 1;
#endif
    }

    // ok
    return 1;
}
static tb_long_t tb_iocp_spak_iorw(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t resp, tb_size_t real, tb_size_t error)
{
    // check?
    tb_assert_and_check_return_val(resp, -1);

    // ok?
    if (real)
    {
        // trace
        tb_trace_d("iorw[%p]: code: %lu, real: %lu", resp->aico, resp->code, real);

        // save address for urecv or urecvv
        if (resp->code == TB_AICE_CODE_URECV || resp->code == TB_AICE_CODE_URECVV)
        {
            // the aico
            tb_iocp_aico_t* aico = (tb_iocp_aico_t*)resp->aico;
            tb_assert_and_check_return_val(aico, -1);

            // the address
            struct sockaddr_storage* addr = (struct sockaddr_storage*)aico->addr;
            tb_assert_and_check_return_val(addr, -1);

            // save address
            tb_sockaddr_save(resp->code == TB_AICE_CODE_URECV? &resp->u.urecv.addr : &resp->u.urecvv.addr, addr);
        }

        // save the real size, @note: hack the real offset for the other io aice
        resp->u.recv.real = real;

        // ok
        resp->state = TB_STATE_OK;
        return 1;
    }

    // error? 
    switch (error)
    {       
        // ok or pending?
    case ERROR_SUCCESS:
    case WAIT_TIMEOUT:
    case ERROR_IO_PENDING:
        {
            // done state
            switch (resp->state)
            {
            case TB_STATE_OK:
            case TB_STATE_PENDING:
                resp->state = TB_STATE_CLOSED;
                break;
            default:
                // using the self state here
                break;
            }
        }
        break;
        // closed?
    case WSAECONNRESET:
    case ERROR_HANDLE_EOF:
    case ERROR_NETNAME_DELETED:
    case ERROR_BAD_COMMAND:
        {
            resp->state = TB_STATE_CLOSED;
        }
        break;
        // canceled? timeout 
    case WSAEINTR:
    case ERROR_OPERATION_ABORTED:
        {
            resp->state = TB_STATE_TIMEOUT;
        }
        break;
        // unknown error
    default:
        {
            // trace
            tb_trace_e("iorw[%p]: code: %lu, unknown error: %lu", resp->aico, resp->code, error);

            // failed
            resp->state = TB_STATE_FAILED;
        }
        break;
    }

    // ok
    return 1;
}
static tb_long_t tb_iocp_spak_fsync(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t resp, tb_size_t real, tb_size_t error)
{
    // check?
    tb_assert_and_check_return_val(resp, -1);

    // trace
    tb_trace_d("fsync[%p]: spak: %lu", resp->aico, error);

    // done 
    switch (error)
    {   
        // ok or pending?
    case ERROR_SUCCESS:
    case WAIT_TIMEOUT:
    case ERROR_IO_PENDING:
        {
            // done state
            switch (resp->state)
            {
            case TB_STATE_OK:
            case TB_STATE_PENDING:
                resp->state = TB_STATE_OK;
                break;
            default:
                break;
            }
        }
        break;
        // closed?
    case ERROR_HANDLE_EOF:
    case ERROR_NETNAME_DELETED:
        {
            resp->state = TB_STATE_CLOSED;
        }
        break;
        // unknown error
    default:
        {
            resp->state = TB_STATE_FAILED;
            tb_trace_e("fsync: unknown error: %u", error);
        }
        break;
    }

    // ok
    return 1;
}
static tb_long_t tb_iocp_spak_runtask(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t resp, tb_size_t real, tb_size_t error)
{
    // check?
    tb_assert_and_check_return_val(resp, -1);

    // trace
    tb_trace_d("runtask[%p]: spak: %lu", resp->aico, error);

    // done 
    switch (error)
    {   
        // ok or pending?
    case ERROR_SUCCESS:
    case WAIT_TIMEOUT:
    case ERROR_IO_PENDING:
        {
            // done state
            switch (resp->state)
            {
            case TB_STATE_OK:
            case TB_STATE_PENDING:
                resp->state = TB_STATE_OK;
                break;
            default:
                break;
            }
        }
        break;
        // unknown error
    default:
        {
            resp->state = TB_STATE_FAILED;

            // trace
            tb_trace_e("runtask: unknown error: %u", error);
        }
        break;
    }

    // ok
    return 1;
}
static tb_long_t tb_iocp_spak_clos(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t resp, tb_size_t real, tb_size_t error)
{
    // check?
    tb_assert_and_check_return_val(resp, -1);

    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)resp->aico;
    tb_assert_and_check_return_val(aico, -1);

    // trace
    tb_trace_d("clos[%p]: spak: %lu", resp->aico, error);

    // done 
    switch (error)
    {   
        // ok or pending?
    case ERROR_SUCCESS:
    case WAIT_TIMEOUT:
    case ERROR_IO_PENDING:
        {
            // trace
            tb_trace_d("clos[%p]: push to the socket pool", resp->aico);

            // put the socket to the socket pool
            if (aico->base.handle)
            {
                if (!tb_socket_pool_put((tb_socket_ref_t)aico->base.handle))
                    tb_socket_exit((tb_socket_ref_t)aico->base.handle);
            }
            aico->base.handle = tb_null;
        }
        break;
        // unknown error
    default:
        {
            // trace
            tb_trace_e("clos[%p]: unknown error: %u", resp->aico, error);

            // close the socket handle
            if (aico->base.handle) tb_socket_exit((tb_socket_ref_t)aico->base.handle);
            aico->base.handle = tb_null;
        }
        break;
    }

    // clear impl
    aico->impl = tb_null;

    // clear type
    aico->base.type = TB_AICO_TYPE_NONE;

    // clear timeout
    tb_size_t i = 0;
    tb_size_t n = tb_arrayn(aico->base.timeout);
    for (i = 0; i < n; i++) aico->base.timeout[i] = -1;

    // closed
    tb_atomic_set(&aico->base.state, TB_STATE_CLOSED);

    // clear bDisconnectEx
    aico->bDisconnectEx = 0;

    // clear olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // ok
    resp->state = TB_STATE_OK;
    return 1;
}
static tb_long_t tb_iocp_spak_done(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t resp, tb_size_t real, tb_size_t error)
{
    // check?
    tb_assert_and_check_return_val(resp && resp->aico, -1);

    // killed?
    if (tb_aico_impl_is_killed((tb_aico_impl_t*)resp->aico) && resp->code != TB_AICE_CODE_CLOS)
    {
        // save state
        resp->state = TB_STATE_KILLED;

        // trace
        tb_trace_d("spak: code: %u: killed", resp->code);

        // ok
        return 1;
    }

    // no pending? spak it directly
    tb_check_return_val(resp->state == TB_STATE_PENDING, 1);

    // init spak
    static tb_long_t (*s_spak[])(tb_iocp_ptor_impl_t* , tb_aice_ref_t , tb_size_t , tb_size_t ) = 
    {
        tb_null
    ,   tb_iocp_spak_acpt
    ,   tb_iocp_spak_conn
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_iorw
    ,   tb_iocp_spak_fsync
    ,   tb_iocp_spak_runtask
    ,   tb_iocp_spak_clos
    };
    tb_assert_and_check_return_val(resp->code < tb_arrayn(s_spak), -1);

    // trace
    tb_trace_d("spak[%p], code: %u: done: ..", resp->aico, resp->code);

    // done spak
    return (s_spak[resp->code])? s_spak[resp->code](impl, resp, real, error) : -1;
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * post
 */
static tb_void_t tb_iocp_post_timeout(tb_iocp_ptor_impl_t* impl, tb_iocp_aico_t* aico)
{
    // check
    tb_assert_and_check_return(impl && impl->ltimer && aico);
    
    // only for sock
    tb_check_return(aico->base.type == TB_AICO_TYPE_SOCK);

    // add timeout task
    tb_long_t timeout = tb_aico_impl_timeout_from_code((tb_aico_impl_t*)aico, aico->olap.aice.code);
    if (timeout >= 0)
    {
        // trace
        tb_trace_d("post: timeout[%p], code: %lu: ..", aico, aico->olap.aice.code);

        // check
        tb_assert_and_check_return(!aico->task);

        // add the new task
        aico->task = tb_ltimer_task_init(impl->ltimer, timeout, tb_false, tb_iocp_spak_timeout, aico);
        aico->bltimer = 1;
    }
}
static tb_void_t tb_iocp_post_timeout_cancel(tb_iocp_ptor_impl_t* impl, tb_iocp_aico_t* aico)
{
    // check
    tb_assert_and_check_return(impl && impl->ltimer && aico);
   
    // remove timeout task
    if (aico->task) 
    {
        if (aico->bltimer) tb_ltimer_task_exit(impl->ltimer, (tb_ltimer_task_ref_t)aico->task);
        else tb_timer_task_exit(impl->timer, (tb_timer_task_ref_t)aico->task);
        aico->bltimer = 0;
    }
    aico->task = tb_null;
}
static tb_bool_t tb_iocp_post_acpt(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->func.AcceptEx && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_ACPT, tb_false);

    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // trace
    tb_trace_d("accept[%p]: ..", aico);

    // done
    tb_bool_t       ok = tb_false;
    tb_bool_t       init_ok = tb_false;
    tb_bool_t       AcceptEx_ok = tb_false;
    do
    {
        // make address
        if (!aico->addr) aico->addr = tb_malloc0(((sizeof(struct sockaddr_storage)) << 1));
        tb_assert_and_check_break(aico->addr);
      
        // init olap
        tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

        // attempt to get the socket from the socket pool
        tb_socket_ref_t sock = tb_socket_pool_get();

        // init aice, hack: sizeof(tb_iocp_olap_t) >= (sizeof(struct sockaddr_storage) << 1)
        aico->olap.aice                 = *aice;
        aico->olap.aice.state           = TB_STATE_PENDING;
        aico->olap.aice.u.acpt.priv[0]  = sock? sock : tb_socket_init(TB_SOCKET_TYPE_TCP, TB_IPADDR_FAMILY_IPV4);
        tb_assert_static(tb_arrayn(aico->olap.aice.u.acpt.priv));
        tb_assert_and_check_break(aico->olap.aice.u.acpt.priv[0]);
        init_ok = tb_true;

        // post timeout first
        tb_iocp_post_timeout(impl, aico);

        // done AcceptEx
        DWORD real = 0;
        AcceptEx_ok = impl->func.AcceptEx(  (SOCKET)aico->base.handle - 1
                                        ,   (SOCKET)aico->olap.aice.u.acpt.priv[0] - 1
                                        ,   (tb_byte_t*)aico->addr
                                        ,   0
                                        ,   sizeof(struct sockaddr_storage)
                                        ,   sizeof(struct sockaddr_storage)
                                        ,   &real
                                        ,   (LPOVERLAPPED)&aico->olap)? tb_true : tb_false;
        tb_trace_d("accept[%p]: AcceptEx: %d, error: %d", aico, AcceptEx_ok, impl->func.WSAGetLastError());
        tb_check_break(AcceptEx_ok);

        // post ok
        aico->olap.aice.state = TB_STATE_OK;
        if (!PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) break;

        // ok
        ok = tb_true;

    } while (0);

    // AcceptEx failed? 
    if (init_ok && !AcceptEx_ok)
    {
        // pending? continue it
        if (WSA_IO_PENDING == impl->func.WSAGetLastError()) 
        {
            // ok
            ok = tb_true;
        }
        // failed? 
        else
        {
            // post failed
            aico->olap.aice.state = TB_STATE_FAILED;
            if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) ok = tb_true;

            // trace
            tb_trace_d("accept[%p]: AcceptEx: unknown error: %d", aico, impl->func.WSAGetLastError());
        }
    }

    // error? 
    if (!ok)
    {
        // exit sock
        if (aico->olap.aice.u.acpt.priv[0]) tb_socket_exit((tb_socket_ref_t)aico->olap.aice.u.acpt.priv[0]);
        aico->olap.aice.u.acpt.priv[0] = tb_null;

        // remove timeout task
        tb_iocp_post_timeout_cancel(impl, aico);
    }

    // ok?
    return ok;
}
static tb_bool_t tb_iocp_post_conn(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_CONN, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle && !aico->bDisconnectEx, tb_false);

    // trace
    tb_trace_d("connect[%p]: %{ipaddr}: ..", aico, &aice->u.conn.addr);

    // done
    tb_bool_t       ok = tb_false;
    tb_bool_t       init_ok = tb_false;
    tb_bool_t       ConnectEx_ok = tb_false;
    do
    {
        // init olap
        tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

        // init aice
        aico->olap.aice = *aice;

        // load local address
        tb_size_t               laddr_size = 0;
        struct sockaddr_storage laddr_data = {0};
        tb_ipaddr_t               laddr;
        if (!tb_ipaddr_set(&laddr, tb_null, 0, (tb_uint8_t)tb_ipaddr_family(&aice->u.conn.addr))) break;
        if (!(laddr_size = tb_sockaddr_load(&laddr_data, &laddr))) break;

        // bind it first for ConnectEx
        if (SOCKET_ERROR == impl->func.bind((SOCKET)aico->base.handle - 1, (LPSOCKADDR)&laddr_data, (tb_int_t)laddr_size)) 
        {
            // trace
            tb_trace_e("connect[%p]: bind failed, error: %u", aico, GetLastError());
            break;
        }
        init_ok = tb_true;

        // post timeout first
        tb_iocp_post_timeout(impl, aico);

        // load client address
        tb_size_t               caddr_size = 0;
        struct sockaddr_storage caddr_data = {0};
        if (!(caddr_size = tb_sockaddr_load(&caddr_data, &aice->u.conn.addr))) break;

        // done ConnectEx
        DWORD real = 0;
        ConnectEx_ok = impl->func.ConnectEx(    (SOCKET)aico->base.handle - 1
                                            ,   (struct sockaddr const*)&caddr_data
                                            ,   (tb_int_t)caddr_size
                                            ,   tb_null
                                            ,   0
                                            ,   &real
                                            ,   (LPOVERLAPPED)&aico->olap)? tb_true : tb_false;
        tb_trace_d("connect[%p]: ConnectEx: %d, error: %d", aico, ConnectEx_ok, impl->func.WSAGetLastError());
        tb_check_break(ConnectEx_ok);

        // post ok
        aico->olap.aice.state = TB_STATE_OK;
        if (!PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) break;

        // ok
        ok = tb_true;

    } while (0);

    // ConnectEx failed?
    if (init_ok && !ConnectEx_ok)
    {
        // pending? continue it
        if (WSA_IO_PENDING == impl->func.WSAGetLastError()) 
        {   
            // ok
            ok = tb_true;
        }
        // failed?
        else
        {
            // post failed
            aico->olap.aice.state = TB_STATE_FAILED;
            if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) ok = tb_true;

            // trace
            tb_trace_d("connect[%p]: ConnectEx: unknown error: %d", aico, impl->func.WSAGetLastError());
        }
    }

    // error? remove timeout task
    if (!ok) tb_iocp_post_timeout_cancel(impl, aico);

    // ok?
    return ok;
}
static tb_bool_t tb_iocp_post_recv(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_RECV, tb_false);
    tb_assert_and_check_return_val(aice->u.recv.data && aice->u.recv.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("recv[%p]: ..", aico);

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done recv
    DWORD       flag = 0;
    tb_long_t   ok = impl->func.WSARecv((SOCKET)aico->base.handle - 1, (WSABUF*)&aico->olap.aice.u.recv, 1, tb_null, &flag, (LPOVERLAPPED)&aico->olap, tb_null);
    tb_trace_d("recv[%p]: WSARecv: %ld, error: %d", aico, ok, impl->func.WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == impl->func.WSAGetLastError()))) return tb_true;

    // error?
    if (ok == SOCKET_ERROR)
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_send(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_SEND, tb_false);
    tb_assert_and_check_return_val(aice->u.send.data && aice->u.send.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("send[%p]: ..", aico);

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done send
    tb_long_t ok = impl->func.WSASend((SOCKET)aico->base.handle - 1, (WSABUF*)&aico->olap.aice.u.send, 1, tb_null, 0, (LPOVERLAPPED)&aico->olap, tb_null);
    tb_trace_d("send[%p]: WSASend: %ld, error: %d", aico, ok, impl->func.WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == impl->func.WSAGetLastError()))) return tb_true;

    // error?
    if (ok == SOCKET_ERROR)
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_urecv(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_URECV, tb_false);
    tb_assert_and_check_return_val(aice->u.urecv.data && aice->u.urecv.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // make addr
    if (!aico->addr) aico->addr = tb_malloc(sizeof(struct sockaddr_storage) + sizeof(tb_int_t) + sizeof(DWORD));
    tb_assert_and_check_return_val(aico->addr, tb_false);

    // init addr
    tb_memset((tb_pointer_t)aico->addr, 0, sizeof(struct sockaddr_storage));

    // init size
    tb_int_t* psize = (tb_int_t*)((tb_byte_t*)aico->addr + sizeof(struct sockaddr_storage));
    *psize = sizeof(struct sockaddr_storage);

    // init flag
    DWORD* pflag = (DWORD*)((tb_byte_t*)aico->addr + sizeof(struct sockaddr_storage) + sizeof(tb_int_t));
    *pflag = 0;

    // trace
    tb_trace_d("urecv[%p]: ..", aico);

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done recv
    tb_long_t   ok = impl->func.WSARecvFrom((SOCKET)aico->base.handle - 1, (WSABUF*)&aico->olap.aice.u.urecv, 1, tb_null, pflag, (struct sockaddr*)aico->addr, psize, (LPOVERLAPPED)&aico->olap, tb_null);
    tb_trace_d("urecv[%p]: WSARecvFrom: %ld, error: %d", aico, ok, impl->func.WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == impl->func.WSAGetLastError()))) return tb_true;

    // error?
    if (ok == SOCKET_ERROR)
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_usend(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_USEND, tb_false);
    tb_assert_and_check_return_val(aice->u.usend.data && aice->u.usend.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("usend[%p]: ..", aico);

    // load addr
    tb_size_t               n = 0;
	struct sockaddr_storage d = {0};
    if (!(n = tb_sockaddr_load(&d, &aice->u.usend.addr))) return tb_false;

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done send
    tb_long_t ok = impl->func.WSASendTo((SOCKET)aico->base.handle - 1, (WSABUF*)&aico->olap.aice.u.usend, 1, tb_null, 0, (struct sockaddr*)&d, (tb_int_t)n, (LPOVERLAPPED)&aico->olap, tb_null);
    tb_trace_d("usend[%p]: WSASendTo: %ld, error: %d", aico, ok, impl->func.WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == impl->func.WSAGetLastError()))) return tb_true;

    // error?
    if (ok == SOCKET_ERROR)
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_recvv(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_RECVV, tb_false);
    tb_assert_and_check_return_val(aice->u.recvv.list && aice->u.recvv.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("recvv[%p]: ..", aico);

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done recv
    DWORD       flag = 0;
    tb_long_t   ok = impl->func.WSARecv((SOCKET)aico->base.handle - 1, (WSABUF*)aico->olap.aice.u.recvv.list, (DWORD)aico->olap.aice.u.recvv.size, tb_null, &flag, (LPOVERLAPPED)&aico->olap, tb_null);
    tb_trace_d("recvv[%p]: WSARecv: %ld, error: %d", aico, ok, impl->func.WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == impl->func.WSAGetLastError()))) return tb_true;

    // error?
    if (ok == SOCKET_ERROR)
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_sendv(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_SENDV, tb_false);
    tb_assert_and_check_return_val(aice->u.sendv.list && aice->u.sendv.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("sendv[%p]: ..", aico);

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done send
    tb_long_t ok = impl->func.WSASend((SOCKET)aico->base.handle - 1, (WSABUF*)aico->olap.aice.u.sendv.list, (DWORD)aico->olap.aice.u.sendv.size, tb_null, 0, (LPOVERLAPPED)&aico->olap, tb_null);
    tb_trace_d("sendv[%p]: WSASend: %ld, error: %d", aico, ok, impl->func.WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == impl->func.WSAGetLastError()))) return tb_true;

    // error?
    if (ok == SOCKET_ERROR)
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_urecvv(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_URECVV, tb_false);
    tb_assert_and_check_return_val(aice->u.urecvv.list && aice->u.urecvv.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // make addr
    if (!aico->addr) aico->addr = tb_malloc0(sizeof(sockaddr_storage) + sizeof(tb_int_t) + sizeof(DWORD));
    tb_assert_and_check_return_val(aico->addr, tb_false);

    // init addr
    tb_memset((tb_pointer_t)aico->addr, 0, sizeof(sockaddr_storage));

    // init size
    tb_int_t* psize = (tb_int_t*)((tb_byte_t*)aico->addr + sizeof(sockaddr_storage));
    *psize = sizeof(sockaddr_storage);

    // init flag
    DWORD* pflag = (DWORD*)((tb_byte_t*)aico->addr + sizeof(sockaddr_storage) + sizeof(tb_int_t));
    *pflag = 0;

    // trace
    tb_trace_d("urecvv[%p]: ..", aico);

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done recv
    tb_long_t   ok = impl->func.WSARecvFrom((SOCKET)aico->base.handle - 1, (WSABUF*)aico->olap.aice.u.urecvv.list, (DWORD)aico->olap.aice.u.urecvv.size, tb_null, pflag, (struct sockaddr*)aico->addr, psize, (LPOVERLAPPED)&aico->olap, tb_null);
    tb_trace_d("urecvv[%p]: WSARecvFrom: %ld, error: %d", aico, ok, impl->func.WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == impl->func.WSAGetLastError()))) return tb_true;

    // error?
    if (ok == SOCKET_ERROR)
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_usendv(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_USENDV, tb_false);
    tb_assert_and_check_return_val(aice->u.usendv.list && aice->u.usendv.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("usendv[%p]: ..", aico);

    // load addr
    tb_size_t               n = 0;
	struct sockaddr_storage d = {0};
    if (!(n = tb_sockaddr_load(&d, &aice->u.usendv.addr))) return tb_false;

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done send
    tb_long_t ok = impl->func.WSASendTo((SOCKET)aico->base.handle - 1, (WSABUF*)aico->olap.aice.u.usendv.list, (DWORD)aico->olap.aice.u.usendv.size, tb_null, 0, (struct sockaddr*)&d, (tb_int_t)n, (LPOVERLAPPED)&aico->olap, tb_null);
    tb_trace_d("usendv[%p]: WSASendTo: %ld, error: %d", aico, ok, impl->func.WSAGetLastError());

    // ok or pending? continue it
    if (!ok || ((ok == SOCKET_ERROR) && (WSA_IO_PENDING == impl->func.WSAGetLastError()))) return tb_true;

    // error?
    if (ok == SOCKET_ERROR)
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_sendf(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_SENDF, tb_false);
    tb_assert_and_check_return_val(aice->u.sendf.file && aice->u.sendf.size, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));
    aico->olap.base.Offset  = (DWORD)aice->u.sendf.seek;

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("sendf[%p]: ..", aico);

    // not supported?
    if (!impl->func.TransmitFile)
    {
        // post not supported
        aico->olap.aice.state = TB_STATE_NOT_SUPPORTED;
        return PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)? tb_true : tb_false;
    }

    // post timeout first
    tb_iocp_post_timeout(impl, aico);

    // done send
    tb_long_t real = impl->func.TransmitFile((SOCKET)aico->base.handle - 1, (HANDLE)aice->u.sendf.file, (DWORD)aice->u.sendf.size, (1 << 16), (LPOVERLAPPED)&aico->olap, tb_null, 0);
    tb_trace_d("sendf[%p]: TransmitFile: %ld, size: %llu, error: %d", aico, real, aice->u.sendf.size, impl->func.WSAGetLastError());

    // pending? continue it
    if (!real || WSA_IO_PENDING == impl->func.WSAGetLastError()) return tb_true;

    // ok?
    if (real > 0)
    {
        // post ok
        aico->olap.aice.state = TB_STATE_OK;
        aico->olap.aice.u.sendf.real = real;
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }
    else
    {
        // done error
        switch (impl->func.WSAGetLastError())
        {
        // closed?
        case WSAECONNABORTED:
        case WSAECONNRESET:
            aico->olap.aice.state = TB_STATE_CLOSED;
            break;
        // failed?
        default:
            aico->olap.aice.state = TB_STATE_FAILED;
            break;
        }

        // post closed or failed
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }

    // remove timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_read(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_READ, tb_false);
    tb_assert_and_check_return_val(aice->u.read.data && aice->u.read.size, tb_false);

    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));
    aico->olap.base.Offset  = (DWORD)aice->u.read.seek;

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("read[%p]: ..", aico);

    // done read
    DWORD       real = 0;
    BOOL        ok = ReadFile((HANDLE)aico->base.handle, aice->u.read.data, (DWORD)aice->u.read.size, &real, (LPOVERLAPPED)&aico->olap);
    tb_trace_d("read[%p]: ReadFile: %u, size: %lu, error: %d, ok: %d", aico, real, aice->u.read.size, GetLastError(), ok);

    // finished or pending? continue it
    if (ok || ERROR_IO_PENDING == GetLastError()) return tb_true;

    // post failed
    aico->olap.aice.state = TB_STATE_FAILED;
    if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_writ(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_WRIT, tb_false);
    tb_assert_and_check_return_val(aice->u.writ.data && aice->u.writ.size, tb_false);

    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));
    aico->olap.base.Offset  = (DWORD)aice->u.writ.seek;

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("writ[%p]: ..", aico);

    // done writ
    DWORD       real = 0;
    BOOL        ok = WriteFile((HANDLE)aico->base.handle, aice->u.writ.data, (DWORD)aice->u.writ.size, &real, (LPOVERLAPPED)&aico->olap);
    tb_trace_d("writ[%p]: WriteFile: %u, size: %lu, error: %d, ok: %d", aico, real, aice->u.writ.size, GetLastError(), ok);

    // finished or pending? continue it
    if (ok || ERROR_IO_PENDING == GetLastError()) return tb_true;

    // post failed
    aico->olap.aice.state = TB_STATE_FAILED;
    if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_readv(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_READV, tb_false);
    tb_assert_and_check_return_val(aice->u.readv.list && aice->u.readv.size, tb_false);

    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));
    aico->olap.base.Offset  = (DWORD)aice->u.readv.seek;

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("readv[%p]: ..", aico);

    // done read
    DWORD       real = 0;
    BOOL        ok = ReadFile((HANDLE)aico->base.handle, aice->u.readv.list[0].data, (DWORD)aice->u.readv.list[0].size, &real, (LPOVERLAPPED)&aico->olap);
    tb_trace_d("readv[%p]: ReadFile: %u, error: %d", aico, real, GetLastError());

    // finished or pending? continue it
    if (ok || ERROR_IO_PENDING == GetLastError()) return tb_true;

    // post failed
    aico->olap.aice.state = TB_STATE_FAILED;
    if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_writv(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_WRITV, tb_false);
    tb_assert_and_check_return_val(aice->u.writv.list && aice->u.writv.size, tb_false);

    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));
    aico->olap.base.Offset  = (DWORD)aice->u.writv.seek;

    // init aice
    aico->olap.aice = *aice;

    // trace
    tb_trace_d("writv[%p]: ..", aico);

    // done writ
    DWORD       real = 0;
    BOOL        ok = WriteFile((HANDLE)aico->base.handle, aice->u.writv.list[0].data, (DWORD)aice->u.writv.list[0].size, &real, (LPOVERLAPPED)&aico->olap);
    tb_trace_d("writv[%p]: WriteFile: %u, error: %d", aico, real, GetLastError());

    // finished or pending? continue it
    if (ok || ERROR_IO_PENDING == GetLastError()) return tb_true;

    // post failed
    aico->olap.aice.state = TB_STATE_FAILED;
    if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_fsync(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_FSYNC, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && aico->base.handle, tb_false);

    // trace
    tb_trace_d("fsync[%p]: ..", aico);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // post ok
    aico->olap.aice.state = TB_STATE_OK;
    if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_runtask(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->timer && impl->ltimer && impl->wait && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_RUNTASK, tb_false);
    tb_assert_and_check_return_val(aice->state == TB_STATE_PENDING, tb_false);
    tb_assert_and_check_return_val(aice->u.runtask.when, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico && !aico->task, tb_false);

    // must be not acpt aico
    tb_assert_and_check_return_val(aico->olap.aice.code != TB_AICE_CODE_ACPT, tb_false);

    // init olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // now
    tb_hong_t now = tb_cache_time_mclock();

    // timeout?
    if (aice->u.runtask.when <= (tb_hize_t)now)
    {
        // trace
        tb_trace_d("runtask: when: %llu, now: %lld: ok", aice->u.runtask.when, now);

        // post ok
        aico->olap.aice.state = TB_STATE_OK;
        if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
    }
    else
    {
        // trace
        tb_trace_d("runtask: when: %llu, now: %lld: ..", aice->u.runtask.when, now);

        // add timeout task, is the higher precision timer?
        if (aico->base.handle)
        {
            // the top when
            tb_hize_t top = tb_timer_top(impl->timer);

            // add task
            aico->task = tb_timer_task_init_at(impl->timer, aice->u.runtask.when, 0, tb_false, tb_iocp_spak_timeout_runtask, aico);
            aico->bltimer = 0;

            // the top task is changed? spak the timer
            if (aico->task && aice->u.runtask.when < top)
                tb_event_post(impl->wait);
        }
        else
        {
            aico->task = tb_ltimer_task_init_at(impl->ltimer, aice->u.runtask.when, 0, tb_false, tb_iocp_spak_timeout_runtask, aico);
            aico->bltimer = 1;
        }

        // pending
        return tb_true;
    }

    // failed
    return tb_false;
}
static tb_bool_t tb_iocp_post_clos(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->timer && impl->ltimer && impl->base.aicp, tb_false);

    // check aice
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_CLOS, tb_false);
    
    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico, tb_false);

    // trace
    tb_trace_d("clos[%p]: handle: %p, state: %s", aico, aico->base.handle, tb_state_cstr(tb_atomic_get(&aico->base.state)));

    // remove the timeout task
    tb_iocp_post_timeout_cancel(impl, aico);

    // exit address
    if (aico->addr) tb_free(aico->addr);
    aico->addr = tb_null;

    // exit the private data for acpt aice
    if (aico->olap.aice.code == TB_AICE_CODE_ACPT)
    {
        // exit sock
        if (aico->olap.aice.u.acpt.priv[0]) tb_socket_exit((tb_socket_ref_t)aico->olap.aice.u.acpt.priv[0]);
        aico->olap.aice.u.acpt.priv[0] = tb_null;
    }
    // disconnect the socket for reusing it
    else if (   impl->func.DisconnectEx
            &&  aico->bDisconnectEx
            &&  !tb_aico_impl_is_killed((tb_aico_impl_t*)aico)) //< disable it if be killed, because DisconnectEx maybe cannot return immediately after calling CancelIo
    {
        // init aice
        aico->olap.aice = *aice;

        // disconnect it
        tb_bool_t ok = impl->func.DisconnectEx((SOCKET)aico->base.handle - 1, (LPOVERLAPPED)&aico->olap, TF_REUSE_SOCKET, 0);
        tb_trace_d("clos[%p]: DisconnectEx: %d, error: %d", aico, ok, impl->func.WSAGetLastError());
        if (!ok)
        { 
            // pending? continue it
            if (WSA_IO_PENDING == impl->func.WSAGetLastError()) return tb_true;

            // trace
            tb_trace_d("clos[%p]: DisconnectEx: unknown error: %d", aico, impl->func.WSAGetLastError());
        }
        else
        {
            // post ok
            aico->olap.aice.state = TB_STATE_OK;
            if (PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)) return tb_true;
        }
    }
 
    // exit the sock 
    if (aico->base.type == TB_AICO_TYPE_SOCK)
    {
        // close the socket handle
        if (aico->base.handle) tb_socket_exit((tb_socket_ref_t)aico->base.handle);
        aico->base.handle = tb_null;
    }
    // exit file
    else if (aico->base.type == TB_AICO_TYPE_FILE)
    {
        // exit the file handle
        if (aico->base.handle) tb_file_exit((tb_file_ref_t)aico->base.handle);
        aico->base.handle = tb_null;
    }

    // clear impl
    aico->impl = tb_null;

    // clear type
    aico->base.type = TB_AICO_TYPE_NONE;

    // clear timeout
    tb_size_t i = 0;
    tb_size_t n = tb_arrayn(aico->base.timeout);
    for (i = 0; i < n; i++) aico->base.timeout[i] = -1;

    // closed
    tb_atomic_set(&aico->base.state, TB_STATE_CLOSED);

    // clear bDisconnectEx
    aico->bDisconnectEx = 0;

    // clear olap
    tb_memset(&aico->olap, 0, sizeof(tb_iocp_olap_t));

    // init aice
    aico->olap.aice = *aice;

    // clos ok
    aico->olap.aice.state = TB_STATE_OK;

    // done the aice response function
    aice->func(&aico->olap.aice);

    // post ok
    return tb_true;
}
static tb_bool_t tb_iocp_post_done(tb_iocp_ptor_impl_t* impl, tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(impl && impl->port && impl->base.aicp && aice, tb_false);

    // the aico
    tb_iocp_aico_t* aico = (tb_iocp_aico_t*)aice->aico;
    tb_assert_and_check_return_val(aico, tb_false);
 
    // killed?
    if (tb_aico_impl_is_killed((tb_aico_impl_t*)aico) && aice->code != TB_AICE_CODE_CLOS)
    {
        // trace
        tb_trace_d("post[%p]: done: code: %u, type: %lu: killed", aico, aice->code, aico->base.type);

        // post the killed state
        aico->olap.aice = *aice;
        aico->olap.aice.state = TB_STATE_KILLED;
        return PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)? tb_true : tb_false;  
    }

    // no pending? post it directly
    if (aice->state != TB_STATE_PENDING)
    {
        // trace
        tb_trace_d("post[%p]: done: code: %u, type: %lu: directly", aico, aice->code, aico->base.type);

        // post it directly
        aico->olap.aice = *aice;
        return PostQueuedCompletionStatus(impl->port, 0, (ULONG_PTR)aico, (LPOVERLAPPED)&aico->olap)? tb_true : tb_false;  
    }

    // init post
    static tb_bool_t (*s_post[])(tb_iocp_ptor_impl_t* , tb_aice_ref_t) = 
    {
        tb_null
    ,   tb_iocp_post_acpt
    ,   tb_iocp_post_conn
    ,   tb_iocp_post_recv
    ,   tb_iocp_post_send
    ,   tb_iocp_post_urecv
    ,   tb_iocp_post_usend
    ,   tb_iocp_post_recvv
    ,   tb_iocp_post_sendv
    ,   tb_iocp_post_urecvv
    ,   tb_iocp_post_usendv
    ,   tb_iocp_post_sendf
    ,   tb_iocp_post_read
    ,   tb_iocp_post_writ
    ,   tb_iocp_post_readv
    ,   tb_iocp_post_writv
    ,   tb_iocp_post_fsync
    ,   tb_iocp_post_runtask
    ,   tb_iocp_post_clos
    };
    tb_assert_and_check_return_val(aice->code < tb_arrayn(s_post) && s_post[aice->code], tb_false);

    // trace
    tb_trace_d("post[%p]: done: code: %u, type: %lu: ..", aico, aice->code, aico->base.type);

    // post aice
    tb_bool_t ok = s_post[aice->code](impl, aice);
    if (!ok)
    {
        // trace
        tb_trace_e("post[%p]: done: code: %u, type: %lu: failed", aico, aice->code, aico->base.type);
    }

    // ok?
    return ok;
}
static tb_int_t tb_iocp_post_loop(tb_cpointer_t priv)
{
    // check
    tb_iocp_ptor_impl_t*    impl = (tb_iocp_ptor_impl_t*)priv;
    tb_aicp_impl_t*         aicp = impl? impl->base.aicp : tb_null;
    tb_assert_and_check_return_val(impl && impl->wait && aicp, -1);
    tb_assert_and_check_return_val(impl->timer && impl->ltimer, -1);
    tb_assert_and_check_return_val(impl->kill && impl->post[0] && impl->post[1], -1);

    // trace
    tb_trace_d("loop: init");

    // loop 
    tb_aice_t post = {0};
    while (1)
    {
        // clear post
        post.code = TB_AICE_CODE_NONE;

        // enter 
        tb_spinlock_enter(&impl->lock);

        // post aice from the higher priority queue first
        if (!tb_queue_null(impl->post[0])) 
        {
            // get resp
            tb_aice_ref_t aice = (tb_aice_ref_t)tb_queue_get(impl->post[0]);
            if (aice) 
            {
                // save post
                post = *aice;

                // trace
                tb_trace_d("loop: post: code: %lu, priority: 0, size: %lu", aice->code, tb_queue_size(impl->post[0]));

                // pop it
                tb_queue_pop(impl->post[0]);
            }
        }

        // no aice? post aice from the lower priority queue next
        if (post.code == TB_AICE_CODE_NONE && !tb_queue_null(impl->post[1]))
        {
            // get resp
            tb_aice_ref_t aice = (tb_aice_ref_t)tb_queue_get(impl->post[1]);
            if (aice) 
            {
                // save post
                post = *aice;

                // trace
                tb_trace_d("loop: post: code: %lu, priority: 1, size: %lu", aice->code, tb_queue_size(impl->post[1]));

                // pop it
                tb_queue_pop(impl->post[1]);
            }
        }

        // kill some handles
        tb_for_all (HANDLE, handle, impl->kill)
        {
            // trace
            tb_trace_d("loop: cancel[%p]: ..", handle);

            // CancelIo it
            if (!CancelIo(handle))
            {
                // trace
                tb_trace_e("loop: cancel[%p]: failed: %u", handle, GetLastError());
            }
        }

        // clear the killed list
        tb_vector_clear(impl->kill);

        // leave 
        tb_spinlock_leave(&impl->lock);

        // done post
        if (post.code != TB_AICE_CODE_NONE && !tb_iocp_post_done(impl, &post)) break;

        // spak ctime
        tb_cache_time_spak();

        // spak timer
        if (!tb_timer_spak(impl->timer)) break;

        // spak ltimer
        if (!tb_ltimer_spak(impl->ltimer)) break;

        // null? wait it
        tb_check_continue(post.code == TB_AICE_CODE_NONE);
        
        // killed? break it
        tb_check_break(!tb_atomic_get(&aicp->kill));

        // the delay
        tb_size_t delay = tb_timer_delay(impl->timer);

        // the ldelay
        tb_size_t ldelay = tb_ltimer_delay(impl->ltimer);
        tb_assert_and_check_break(ldelay != -1);

        // using the min delay
        if (ldelay < delay) delay = ldelay;

        // trace
        tb_trace_d("loop: wait: %lu ms: ..", delay);

        // wait some time
        if (delay && tb_event_wait(impl->wait, delay) < 0) break;
    }

    // trace
    tb_trace_d("loop: exit");

    // kill
    tb_atomic_set(&aicp->kill, 1);

    // exit
    return 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_iocp_ptor_addo(tb_aicp_ptor_impl_t* ptor, tb_aico_impl_t* aico)
{
    // check
    tb_iocp_ptor_impl_t* impl = (tb_iocp_ptor_impl_t*)ptor;
    tb_assert_and_check_return_val(impl && aico, tb_false);

    // check alignment
    tb_assert_and_check_return_val(!((tb_size_t)aico & (TB_CPU_BITBYTE - 1)), tb_false);

    // trace
    tb_trace_d("addo[%p], handle: %p", aico, aico->handle);

    // done
    switch (aico->type)
    {
    case TB_AICO_TYPE_SOCK:
        {
            // check
            tb_assert_and_check_return_val(impl->port && aico->handle, tb_false);

            // add aico to port
            HANDLE port = CreateIoCompletionPort((HANDLE)((SOCKET)aico->handle - 1), impl->port, (ULONG_PTR)aico, 0);
            if (    port != impl->port
                &&  !(   impl->func.DisconnectEx
                    &&  ((tb_iocp_aico_t*)aico)->bDisconnectEx))
            {
                // trace
                tb_trace_e("CreateIoCompletionPort failed: %d, aico: %p, handle: %p", GetLastError(), aico, aico->handle);
                return tb_false;
            }
        }
        break;
    case TB_AICO_TYPE_FILE:
        {
            // check
            tb_assert_and_check_return_val(impl->port && aico->handle, tb_false);

            // add aico to port
            HANDLE port = CreateIoCompletionPort((HANDLE)aico->handle, impl->port, (ULONG_PTR)aico, 0);
            if (port != impl->port)
            {
                // trace
                tb_trace_e("CreateIoCompletionPort failed: %d, aico: %p, handle: %p", GetLastError(), aico, aico->handle);
                return tb_false;
            }
        }
        break;
    case TB_AICO_TYPE_TASK:
        {
        }
        break;
    default:
        tb_assert_and_check_return_val(0, tb_false);
        break;
    }
    
    // init the iocp aico
    tb_iocp_aico_t* iocp_aico = (tb_iocp_aico_t*)aico;
    iocp_aico->impl = impl;
    iocp_aico->addr = tb_null;

    // ok
    return tb_true;
}
static tb_void_t tb_iocp_ptor_kilo(tb_aicp_ptor_impl_t* ptor, tb_aico_impl_t* aico)
{
    // check
    tb_iocp_ptor_impl_t* impl = (tb_iocp_ptor_impl_t*)ptor;
    tb_assert_and_check_return(impl && impl->wait && impl->kill && aico);
        
    // trace
    tb_trace_d("kill[%p]: handle: %p, type: %u", aico, aico->handle, aico->type);

    // the handle
    HANDLE handle = aico->type == TB_AICO_TYPE_SOCK? (HANDLE)((SOCKET)aico->handle - 1) : aico->handle;

    // the iocp aico
    tb_iocp_aico_t* iocp_aico = (tb_iocp_aico_t*)aico;

    // kill the task
    if (iocp_aico->task) 
    {
        // trace
        tb_trace_d("kill: aico: %p, type: %u, task: %p: ..", aico, aico->type, iocp_aico->task);

        // kill task
        if (iocp_aico->bltimer) tb_ltimer_task_kill(impl->ltimer, (tb_ltimer_task_ref_t)iocp_aico->task);
        else tb_timer_task_kill(impl->timer, (tb_timer_task_ref_t)iocp_aico->task);
    }
    // append the killing handle
    else 
    {
        // trace
        tb_trace_d("kill: aico: %p, type: %u, handle: %p: ..", aico, aico->type, handle);

        // kill handle
        tb_spinlock_enter(&impl->lock);
        tb_vector_insert_tail(impl->kill, (tb_cpointer_t)handle);
        tb_spinlock_leave(&impl->lock);
    }

    /* the iocp will wait long time if the lastest task wait period is too long
     * so spak the iocp manually for spak the timer
     */
    tb_event_post(impl->wait);
}
static tb_bool_t tb_iocp_ptor_post(tb_aicp_ptor_impl_t* ptor, tb_aice_ref_t aice)
{
    // check
    tb_iocp_ptor_impl_t* impl = (tb_iocp_ptor_impl_t*)ptor;
    tb_assert_and_check_return_val(impl && impl->wait && aice && aice->aico, tb_false);
    
    // the priority
    tb_size_t priority = tb_aice_impl_priority(aice);
    tb_assert_and_check_return_val(priority < tb_arrayn(impl->post) && impl->post[priority], tb_false);

    // enter 
    tb_spinlock_enter(&impl->lock);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // post aice
        if (tb_queue_full(impl->post[priority])) 
        {
            // trace
            tb_trace_e("post: code: %lu, priority: %lu, size: %lu: failed", aice->code, priority, tb_queue_size(impl->post[priority]));
            break;
        }

        // put
        tb_queue_put(impl->post[priority], aice);

        // trace
        tb_trace_d("post: code: %lu, priority: %lu, size: %lu: ..", aice->code, priority, tb_queue_size(impl->post[priority]));

        // ok
        ok = tb_true;

    } while (0);

    // leave 
    tb_spinlock_leave(&impl->lock);

    // work it 
    if (ok) tb_event_post(impl->wait);

    // ok?
    return ok;
}
static tb_void_t tb_iocp_ptor_kill(tb_aicp_ptor_impl_t* ptor)
{
    // check
    tb_iocp_ptor_impl_t* impl = (tb_iocp_ptor_impl_t*)ptor;
    tb_assert_and_check_return(impl && impl->port && impl->wait && ptor->aicp);

    // the workers
    tb_size_t work = tb_atomic_get(&ptor->aicp->work);
    
    // trace
    tb_trace_d("kill: %lu", work);

    // post the timer wait
    tb_event_post(impl->wait);

    // using GetQueuedCompletionStatusEx?
    if (impl->func.GetQueuedCompletionStatusEx)
    {
        // kill workers
        while (work--) 
        {
            // post kill
            PostQueuedCompletionStatus(impl->port, 0, 0, tb_null);
            
            // wait some time
            tb_msleep(200);
        }
    }
    else
    {
        // kill workers
        while (work--) PostQueuedCompletionStatus(impl->port, 0, 0, tb_null);
    }
}
static tb_void_t tb_iocp_ptor_exit(tb_aicp_ptor_impl_t* ptor)
{
    tb_iocp_ptor_impl_t* impl = (tb_iocp_ptor_impl_t*)ptor;
    if (impl)
    {
        // trace
        tb_trace_d("exit");

        // post the timer wait
        if (impl->wait) tb_event_post(impl->wait);

        // exit loop
        if (impl->loop)
        {
            tb_long_t wait = 0;
            if ((wait = tb_thread_wait(impl->loop, 5000, tb_null)) <= 0)
            {
                // trace
                tb_trace_e("loop[%p]: wait failed: %ld!", impl->loop, wait);
            }
            tb_thread_exit(impl->loop);
            impl->loop = tb_null;
        }

        // enter
        tb_spinlock_enter(&impl->lock);

        // exit post
        if (impl->post[0]) tb_queue_exit(impl->post[0]);
        if (impl->post[1]) tb_queue_exit(impl->post[1]);
        impl->post[0] = tb_null;
        impl->post[1] = tb_null;

        // exit kill
        if (impl->kill) tb_vector_exit(impl->kill);
        impl->kill = tb_null;

        // leave
        tb_spinlock_leave(&impl->lock);

        // exit port
        if (impl->port) CloseHandle(impl->port);
        impl->port = tb_null;

        // exit timer
        if (impl->timer) tb_timer_exit(impl->timer);
        impl->timer = tb_null;

        // exit ltimer
        if (impl->ltimer) tb_ltimer_exit(impl->ltimer);
        impl->ltimer = tb_null;

        // exit wait
        if (impl->wait) tb_event_exit(impl->wait);
        impl->wait = tb_null;

        // exit lock
        tb_spinlock_exit(&impl->lock);

        // free it
        tb_free(impl);
    }
}
static tb_void_t tb_iocp_ptor_loop_exit(tb_aicp_ptor_impl_t* ptor, tb_handle_t hloop)
{
    // check
    tb_iocp_ptor_impl_t* impl = (tb_iocp_ptor_impl_t*)ptor;
    tb_assert_and_check_return(impl);

    // the loop
    tb_iocp_loop_t* loop = (tb_iocp_loop_t*)hloop;
    tb_assert_and_check_return(loop);

    // exit spak
    if (loop->spak) tb_queue_exit(loop->spak);
    loop->spak = tb_null;

    // exit self
    loop->self = 0;

    // exit loop
    tb_free(loop);
}
static tb_handle_t tb_iocp_ptor_loop_init(tb_aicp_ptor_impl_t* ptor)
{
    // check
    tb_iocp_ptor_impl_t* impl = (tb_iocp_ptor_impl_t*)ptor;
    tb_assert_and_check_return_val(impl, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_iocp_loop_t* loop = tb_null;
    do
    {
        // make loop
        loop = tb_malloc0_type(tb_iocp_loop_t);
        tb_assert_and_check_break(loop);

        // init self
        loop->self = tb_thread_self();
        tb_assert_and_check_break(loop->self);

        // init spak
        if (impl->func.GetQueuedCompletionStatusEx)
        {
            loop->spak = tb_queue_init(64, tb_element_mem(sizeof(tb_OVERLAPPED_ENTRY_t), tb_null, tb_null));
            tb_assert_and_check_break(loop->spak);
        }

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (loop) tb_iocp_ptor_loop_exit(ptor, (tb_handle_t)loop);
        loop = tb_null;
    }

    // ok?
    return (tb_handle_t)loop;
}
static tb_long_t tb_iocp_ptor_loop_spak(tb_aicp_ptor_impl_t* ptor, tb_handle_t hloop, tb_aice_ref_t resp, tb_long_t timeout)
{
    // check
    tb_iocp_ptor_impl_t* impl = (tb_iocp_ptor_impl_t*)ptor;
    tb_assert_and_check_return_val(impl && impl->port && impl->timer && resp, -1);

    // the loop
    tb_iocp_loop_t* loop = (tb_iocp_loop_t*)hloop;
    tb_assert_and_check_return_val(loop, -1);

    // trace
    tb_trace_d("spak[%lu]: ..", loop->self);

    // exists GetQueuedCompletionStatusEx? using it
    if (impl->func.GetQueuedCompletionStatusEx)
    {
        // check
        tb_assert_and_check_return_val(loop->spak, -1);

        // exists olap? spak it first
        if (!tb_queue_null(loop->spak))
        {
            // the top entry
            tb_LPOVERLAPPED_ENTRY_t entry = (tb_LPOVERLAPPED_ENTRY_t)tb_queue_get(loop->spak);
            tb_assert_and_check_return_val(entry, -1);

            // init 
            tb_size_t           real = (tb_size_t)entry->dwNumberOfBytesTransferred;
            tb_iocp_aico_t*     aico = (tb_iocp_aico_t*)entry->lpCompletionKey;
            tb_iocp_olap_t*     olap = (tb_iocp_olap_t*)entry->lpOverlapped;
            tb_size_t           error = tb_ntstatus_to_winerror((tb_size_t)entry->Internal);
            tb_trace_d("spak[%lu]: aico: %p, ntstatus: %lx, winerror: %lu", loop->self, aico, (tb_size_t)entry->Internal, error);

            // pop the entry
            tb_queue_pop(loop->spak);
    
            // check
            tb_assert_and_check_return_val(olap && aico, -1);

            // save resp
            *resp = olap->aice;

            // spak resp
            return tb_iocp_spak_done(impl, resp, real, error);
        }
        else
        {
            // clear error first
            SetLastError(ERROR_SUCCESS);

            // wait
            DWORD       size = 0;
            BOOL        wait = impl->func.GetQueuedCompletionStatusEx(impl->port, loop->list, (DWORD)tb_arrayn(loop->list), &size, (DWORD)timeout, FALSE);

            // the last error
            tb_size_t   error = (tb_size_t)GetLastError();

            // trace
            tb_trace_d("spak[%lu]: wait: %d, size: %u, error: %lu", loop->self, wait, size, error);

            // timeout?
            if (!wait && error == WAIT_TIMEOUT) return 0;

            // error?
            tb_assert_and_check_return_val(wait, -1);

            // put entries to the spak queue
            tb_size_t i = 0;
            for (i = 0; i < size; i++) 
            {
                // the aico and olap
                tb_iocp_aico_t* aico = (tb_iocp_aico_t* )loop->list[i].lpCompletionKey;
                tb_iocp_olap_t* olap = (tb_iocp_olap_t*)loop->list[i].lpOverlapped;

                // aicp killed?
                tb_check_return_val(aico, -1);

                /* update aico
                 *
                 * the aico cannot be binded again if using DisconnectEx
                 */
                if (    impl->func.DisconnectEx
                    &&  olap
                    &&  olap->aice.aico
                    &&  ((tb_iocp_aico_t*)olap->aice.aico)->bDisconnectEx)
                {
                    aico = (tb_iocp_aico_t*)olap->aice.aico;
                    loop->list[i].lpCompletionKey = (ULONG_PTR)aico;
                }

                // remove task first
                tb_iocp_post_timeout_cancel(impl, aico);

                // full?
                if (!tb_queue_full(loop->spak))
                {
                    // put it
                    tb_queue_put(loop->spak, &loop->list[i]);
                }
                else 
                {
                    // full
                    tb_assert_and_check_return_val(0, -1);
                }
            }

            // continue 
            return 0;
        }
    }
    else
    {
        // clear error first
        SetLastError(ERROR_SUCCESS);

        // wait
        DWORD               real = 0;
        tb_iocp_aico_t*     aico = tb_null;
        tb_iocp_olap_t*     olap = tb_null;
        BOOL                wait = GetQueuedCompletionStatus(impl->port, (LPDWORD)&real, (PULONG_PTR)&aico, (LPOVERLAPPED*)&olap, (DWORD)(timeout < 0? INFINITE : timeout));

        // the last error
        tb_size_t           error = (tb_size_t)GetLastError();

        // trace
        tb_trace_d("spak[%lu]: aico: %p, wait: %d, real: %u, error: %lu", loop->self, aico, wait, real, error);

        // timeout?
        if (!wait && error == WAIT_TIMEOUT) return 0;

        // aicp killed?
        if (wait && !aico) return -1;

        /* update aico
         *
         * the aico cannot be binded again if using DisconnectEx
         */
        if (    impl->func.DisconnectEx
            &&  olap
            &&  olap->aice.aico
            &&  ((tb_iocp_aico_t*)olap->aice.aico)->bDisconnectEx)
        {
            aico = (tb_iocp_aico_t*)olap->aice.aico;
        }

        // exit the aico task
        if (aico)
        {
            // remove task
            if (aico->task) 
            {
                if (aico->bltimer) tb_ltimer_task_exit(impl->ltimer, (tb_ltimer_task_ref_t)aico->task);
                else tb_timer_task_exit(impl->timer, (tb_timer_task_ref_t)aico->task);
                aico->bltimer = 0;
            }
            aico->task = tb_null;
        }

        // check
        tb_assert_and_check_return_val(olap, -1);

        // check
        tb_assert(aico == (tb_iocp_aico_t*)olap->aice.aico);

        // save resp
        *resp = olap->aice;

        // spak resp
        return tb_iocp_spak_done(impl, resp, (tb_size_t)real, error);
    }

    // failed
    return -1;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
static tb_aicp_ptor_impl_t* tb_iocp_ptor_init(tb_aicp_impl_t* aicp)
{
    // check
    tb_assert_and_check_return_val(aicp && aicp->maxn, tb_null);

    // check iovec
    tb_assert_static(sizeof(tb_iovec_t) == sizeof(WSABUF));
    tb_assert_and_check_return_val(tb_memberof_eq(tb_iovec_t, data, WSABUF, buf), tb_null);
    tb_assert_and_check_return_val(tb_memberof_eq(tb_iovec_t, size, WSABUF, len), tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_iocp_ptor_impl_t*    impl = tb_null;
    do
    {
        // make ptor
        impl = tb_malloc0_type(tb_iocp_ptor_impl_t);
        tb_assert_and_check_break(impl);

        // init base
        impl->base.aicp         = aicp;
        impl->base.step         = sizeof(tb_iocp_aico_t);
        impl->base.kill         = tb_iocp_ptor_kill;
        impl->base.exit         = tb_iocp_ptor_exit;
        impl->base.addo         = tb_iocp_ptor_addo;
        impl->base.kilo         = tb_iocp_ptor_kilo;
        impl->base.post         = tb_iocp_ptor_post;
        impl->base.loop_init    = tb_iocp_ptor_loop_init;
        impl->base.loop_exit    = tb_iocp_ptor_loop_exit;
        impl->base.loop_spak    = tb_iocp_ptor_loop_spak;

        // init func
        impl->func.AcceptEx                         = tb_mswsock()->AcceptEx;
        impl->func.ConnectEx                        = tb_mswsock()->ConnectEx;
        impl->func.DisconnectEx                     = tb_mswsock()->DisconnectEx;
        impl->func.TransmitFile                     = tb_mswsock()->TransmitFile;
        impl->func.GetAcceptExSockaddrs             = tb_mswsock()->GetAcceptExSockaddrs;
        impl->func.GetQueuedCompletionStatusEx      = tb_kernel32()->GetQueuedCompletionStatusEx;
        impl->func.WSAGetLastError                  = tb_ws2_32()->WSAGetLastError;
        impl->func.WSASend                          = tb_ws2_32()->WSASend;
        impl->func.WSARecv                          = tb_ws2_32()->WSARecv;
        impl->func.WSASendTo                        = tb_ws2_32()->WSASendTo;
        impl->func.WSARecvFrom                      = tb_ws2_32()->WSARecvFrom;
        impl->func.bind                             = tb_ws2_32()->bind;
        tb_assert_and_check_break(impl->func.AcceptEx);
        tb_assert_and_check_break(impl->func.ConnectEx);
        tb_assert_and_check_break(impl->func.WSAGetLastError);
        tb_assert_and_check_break(impl->func.WSASend);
        tb_assert_and_check_break(impl->func.WSARecv);
        tb_assert_and_check_break(impl->func.WSASendTo);
        tb_assert_and_check_break(impl->func.WSARecvFrom);
        tb_assert_and_check_break(impl->func.bind);

        // init lock
        if (!tb_spinlock_init(&impl->lock)) break;

        // init port
        impl->port = CreateIoCompletionPort(INVALID_HANDLE_VALUE, tb_null, 0, 0);
        tb_assert_and_check_break(impl->port && impl->port != INVALID_HANDLE_VALUE);

        // init timer and using cache time
        impl->timer = tb_timer_init(aicp->maxn >> 8, tb_true);
        tb_assert_and_check_break(impl->timer);

        // init ltimer and using cache time
        impl->ltimer = tb_ltimer_init(aicp->maxn >> 8, TB_LTIMER_TICK_S, tb_true);
        tb_assert_and_check_break(impl->ltimer);

        // init wait
        impl->wait = tb_event_init();
        tb_assert_and_check_break(impl->wait);

        // init post
        impl->post[0] = tb_queue_init((aicp->maxn >> 4) + 16, tb_element_mem(sizeof(tb_aice_t), tb_null, tb_null));
        impl->post[1] = tb_queue_init((aicp->maxn >> 4) + 16, tb_element_mem(sizeof(tb_aice_t), tb_null, tb_null));
        tb_assert_and_check_break(impl->post[0] && impl->post[1]);

        // init kill
        impl->kill = tb_vector_init((aicp->maxn >> 6) + 16, tb_element_ptr(tb_null, tb_null));
        tb_assert_and_check_break(impl->kill);

        // register lock profiler
#ifdef TB_LOCK_PROFILER_ENABLE
        tb_lock_profiler_register(tb_lock_profiler(), (tb_pointer_t)&impl->lock, "aicp_iocp");
#endif

        // init the timer loop
        impl->loop = tb_thread_init(tb_null, tb_iocp_post_loop, impl, 0);
        tb_assert_and_check_break(impl->loop);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) tb_iocp_ptor_exit((tb_aicp_ptor_impl_t*)impl);
        return tb_null;
    }

    // ok?
    return (tb_aicp_ptor_impl_t*)impl;
}

