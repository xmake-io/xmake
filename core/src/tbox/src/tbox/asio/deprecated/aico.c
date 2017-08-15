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
 * @file        aico.c
 * @ingroup     asio
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "aico"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aico.h"
#include "aicp.h"
#include "impl/prefix.h"
#include "../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_aico_ref_t tb_aico_init(tb_aicp_ref_t aicp)
{
    // check
    tb_aicp_impl_t* aicp_impl = (tb_aicp_impl_t*)aicp;
    tb_assert_and_check_return_val(aicp_impl && aicp_impl->pool, tb_null);

    // enter 
    tb_spinlock_enter(&aicp_impl->lock);

    // make aico
    tb_aico_impl_t* aico = (tb_aico_impl_t*)tb_fixed_pool_malloc0(aicp_impl->pool);

    // init aico
    if (aico)
    {
        aico->aicp      = aicp;
        aico->type      = TB_AICO_TYPE_NONE;
        aico->handle    = tb_null;
        aico->state     = TB_STATE_CLOSED;

        // init timeout 
        tb_size_t i = 0;
        tb_size_t n = tb_arrayn(aico->timeout);
        for (i = 0; i < n; i++) aico->timeout[i] = -1;
    }

    // leave 
    tb_spinlock_leave(&aicp_impl->lock);
    
    // ok?
    return (tb_aico_ref_t)aico;
}
tb_bool_t tb_aico_open_sock(tb_aico_ref_t aico, tb_socket_ref_t sock)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_aicp_impl_t* aicp_impl = (tb_aicp_impl_t*)impl->aicp;
    tb_assert_and_check_return_val(impl && sock && aicp_impl && aicp_impl->ptor && aicp_impl->ptor->addo, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // closed?
        tb_assert_and_check_break(tb_atomic_get(&impl->state) == TB_STATE_CLOSED);
        tb_assert_and_check_break(!impl->type && !impl->handle);

        // bind type and handle
        impl->type     = TB_AICO_TYPE_SOCK;
        impl->handle   = (tb_handle_t)sock;

        // addo aico
        ok = aicp_impl->ptor->addo(aicp_impl->ptor, impl);
        tb_assert_and_check_break(ok);

        // opened
        tb_atomic_set(&impl->state, TB_STATE_OPENED);

    } while (0);

    // ok?
    return ok;
}
tb_bool_t tb_aico_open_sock_from_type(tb_aico_ref_t aico, tb_size_t type, tb_size_t family)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_aicp_impl_t* aicp_impl = (tb_aicp_impl_t*)impl->aicp;
    tb_assert_and_check_return_val(impl && aicp_impl && aicp_impl->ptor && aicp_impl->ptor->addo, tb_false);

    // done
    tb_bool_t       ok = tb_false;
    tb_socket_ref_t sock = tb_null;
    do
    {
        // closed?
        tb_assert_and_check_break(tb_atomic_get(&impl->state) == TB_STATE_CLOSED);
        tb_assert_and_check_break(!impl->type && !impl->handle);

        // init sock
        sock = tb_socket_init(type, family);
        tb_assert_and_check_break(sock);

        // bind type and handle
        impl->type     = TB_AICO_TYPE_SOCK;
        impl->handle   = (tb_handle_t)sock;

        // addo aico
        ok = aicp_impl->ptor->addo(aicp_impl->ptor, impl);
        tb_assert_and_check_break(ok);

        // opened
        tb_atomic_set(&impl->state, TB_STATE_OPENED);

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (sock) tb_socket_exit(sock);
        sock = tb_null;
    }

    // ok?
    return ok;
}
tb_bool_t tb_aico_open_file(tb_aico_ref_t aico, tb_file_ref_t file)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_aicp_impl_t* aicp_impl = (tb_aicp_impl_t*)impl->aicp;
    tb_assert_and_check_return_val(impl && file && aicp_impl && aicp_impl->ptor && aicp_impl->ptor->addo, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // closed?
        tb_assert_and_check_break(tb_atomic_get(&impl->state) == TB_STATE_CLOSED);
        tb_assert_and_check_break(!impl->type && !impl->handle);

        // bind type and handle
        impl->type     = TB_AICO_TYPE_FILE;
        impl->handle   = (tb_handle_t)file;

        // addo aico
        ok = aicp_impl->ptor->addo(aicp_impl->ptor, impl);
        tb_assert_and_check_break(ok);

        // opened
        tb_atomic_set(&impl->state, TB_STATE_OPENED);

    } while (0);

    // ok?
    return ok;
}
tb_bool_t tb_aico_open_file_from_path(tb_aico_ref_t aico, tb_char_t const* path, tb_size_t mode)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_aicp_impl_t* aicp_impl = (tb_aicp_impl_t*)impl->aicp;
    tb_assert_and_check_return_val(impl && path && aicp_impl && aicp_impl->ptor && aicp_impl->ptor->addo, tb_false);

    // done
    tb_bool_t       ok = tb_false;
    tb_file_ref_t   file = tb_null;
    do
    {
        // closed?
        tb_assert_and_check_break(tb_atomic_get(&impl->state) == TB_STATE_CLOSED);
        tb_assert_and_check_break(!impl->type && !impl->handle);

        // init file
        file = tb_file_init(path, mode | TB_FILE_MODE_ASIO);
        tb_assert_and_check_break(file);

        // bind type and handle
        impl->type     = TB_AICO_TYPE_FILE;
        impl->handle   = (tb_handle_t)file;

        // addo aico
        ok = aicp_impl->ptor->addo(aicp_impl->ptor, impl);
        tb_assert_and_check_break(ok);

        // opened
        tb_atomic_set(&impl->state, TB_STATE_OPENED);

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (file) tb_file_exit(file);
        file = tb_null;
    }

    // ok?
    return ok;
}
tb_bool_t tb_aico_open_task(tb_aico_ref_t aico, tb_bool_t ltimer)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_aicp_impl_t* aicp_impl = (tb_aicp_impl_t*)impl->aicp;
    tb_assert_and_check_return_val(impl && aicp_impl && aicp_impl->ptor && aicp_impl->ptor->addo, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // closed?
        tb_assert_and_check_break(tb_atomic_get(&impl->state) == TB_STATE_CLOSED);
        tb_assert_and_check_break(!impl->type);

        // bind type and handle
        // hack: handle != null? using higher precision timer for being compatible with sock/file task
        impl->type     = TB_AICO_TYPE_TASK;
        impl->handle   = (tb_handle_t)(tb_size_t)!ltimer;

        // addo aico
        ok = aicp_impl->ptor->addo(aicp_impl->ptor, impl);
        tb_assert_and_check_break(ok);

        // opened
        tb_atomic_set(&impl->state, TB_STATE_OPENED);

    } while (0);

    // ok?
    return ok;
}
tb_void_t tb_aico_exit(tb_aico_ref_t aico)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_aicp_impl_t* aicp_impl = (tb_aicp_impl_t*)impl->aicp;
    tb_assert_and_check_return(impl && aicp_impl && aicp_impl->pool);

    // wait closing?
    tb_size_t tryn = 15;
    while (tb_atomic_get(&impl->state) != TB_STATE_CLOSED && tryn--)
    {
        // trace
        tb_trace_d("exit[%p]: type: %lu, handle: %p, state: %s: wait: ..", aico, tb_aico_type(aico), impl->handle, tb_state_cstr(tb_atomic_get(&impl->state)));
    
        // wait some time
        tb_msleep(200);
    }

    // check
    tb_assert(tb_atomic_get(&impl->state) == TB_STATE_CLOSED);
    tb_check_return(tb_atomic_get(&impl->state) == TB_STATE_CLOSED);

    // enter 
    tb_spinlock_enter(&aicp_impl->lock);

    // trace
    tb_trace_d("exit[%p]: type: %lu, handle: %p, state: %s: ok", aico, tb_aico_type(aico), impl->handle, tb_state_cstr(tb_atomic_get(&impl->state)));
    
    // free it
    tb_fixed_pool_free(aicp_impl->pool, aico);

    // leave 
    tb_spinlock_leave(&aicp_impl->lock);
}
tb_void_t tb_aico_kill(tb_aico_ref_t aico)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_aicp_impl_t* aicp_impl = (tb_aicp_impl_t*)impl->aicp;
    tb_assert_and_check_return(impl && aicp_impl && aicp_impl->ptor && aicp_impl->ptor->kilo);

    // the impl is killed and not worked?
    tb_check_return(!tb_atomic_get(&aicp_impl->kill) || tb_atomic_get(&aicp_impl->work));

    // trace
    tb_trace_d("kill: aico[%p]: type: %lu, handle: %p: state: %s: ..", aico, tb_aico_type(aico), impl->handle, tb_state_cstr(tb_atomic_get(&((tb_aico_impl_t*)aico)->state)));

    // opened? killed
    if (TB_STATE_OPENED == tb_atomic_fetch_and_pset(&impl->state, TB_STATE_OPENED, TB_STATE_KILLED))
    { 
        // trace
        tb_trace_d("kill: aico[%p]: type: %lu, handle: %p: ok", aico, tb_aico_type(aico), impl->handle);
    }
    // pending? kill it
    else if (TB_STATE_PENDING == tb_atomic_fetch_and_pset(&impl->state, TB_STATE_PENDING, TB_STATE_KILLING)) 
    {
        // kill aico
        aicp_impl->ptor->kilo(aicp_impl->ptor, impl);

        // trace
        tb_trace_d("kill: aico[%p]: type: %lu, handle: %p: state: pending: ok", aico, tb_aico_type(aico), impl->handle);
    }
}
tb_aicp_ref_t tb_aico_aicp(tb_aico_ref_t aico)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl, tb_null);

    // the impl aicp
    return impl->aicp;
}
tb_size_t tb_aico_type(tb_aico_ref_t aico)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl, TB_AICO_TYPE_NONE);

    // the impl type
    return impl->type;
}
tb_socket_ref_t tb_aico_sock(tb_aico_ref_t aico)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->type == TB_AICO_TYPE_SOCK, tb_null);

    // the socket handle
    return (tb_socket_ref_t)impl->handle;
}
tb_file_ref_t tb_aico_file(tb_aico_ref_t aico)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->type == TB_AICO_TYPE_FILE, tb_null);

    // the file handle
    return (tb_file_ref_t)impl->handle;
}
tb_long_t tb_aico_timeout(tb_aico_ref_t aico, tb_size_t type)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && type < tb_arrayn(impl->timeout), -1);

    // the impl timeout
    return tb_atomic_get((tb_atomic_t*)(impl->timeout + type));
}
tb_void_t tb_aico_timeout_set(tb_aico_ref_t aico, tb_size_t type, tb_long_t timeout)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return(impl && type < tb_arrayn(impl->timeout));

    // set the impl timeout
    tb_atomic_set((tb_atomic_t*)(impl->timeout + type), timeout);
}
tb_bool_t tb_aico_clos_try(tb_aico_ref_t aico)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // closed?
    return (tb_atomic_get(&impl->state) == TB_STATE_CLOSED)? tb_true : tb_false;
}
tb_bool_t tb_aico_clos_(tb_aico_ref_t aico, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_CLOS;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;

    // closed?
    if (tb_aico_clos_try(aico))
    {
        // close ok
        aice.state = TB_STATE_OK;

        // done func directly
        func(&aice);

        // ok
        return tb_true;
    }

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_acpt_(tb_aico_ref_t aico, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_ACPT;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_conn_(tb_aico_ref_t aico, tb_ipaddr_ref_t addr, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && addr, tb_false);

    // check address
    tb_assert(!tb_ipaddr_is_empty(addr));

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_CONN;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    tb_ipaddr_copy(&aice.u.conn.addr, addr);

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_recv_(tb_aico_ref_t aico, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_RECV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.recv.data        = data;
    aice.u.recv.size        = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_send_(tb_aico_ref_t aico, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_SEND;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.send.data        = data;
    aice.u.send.size        = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_urecv_(tb_aico_ref_t aico, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_URECV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.urecv.data       = data;
    aice.u.urecv.size       = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_usend_(tb_aico_ref_t aico, tb_ipaddr_ref_t addr, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && addr && data && size, tb_false);

    // check address
    tb_assert(!tb_ipaddr_is_empty(addr));

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_USEND;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.usend.data       = data;
    aice.u.usend.size       = (tb_iovec_size_t)size;
    tb_ipaddr_copy(&aice.u.usend.addr, addr);

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_recvv_(tb_aico_ref_t aico, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_RECVV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.recvv.list       = list;
    aice.u.recvv.size       = size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_sendv_(tb_aico_ref_t aico, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_SENDV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.sendv.list       = list;
    aice.u.sendv.size       = size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_urecvv_(tb_aico_ref_t aico, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && addr && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_URECVV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.urecvv.list      = list;
    aice.u.urecvv.size      = size;
    tb_ipaddr_copy(&aice.u.urecvv.addr, addr);

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_usendv_(tb_aico_ref_t aico, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && addr && list && size, tb_false);

    // check address
    tb_assert(!tb_ipaddr_is_empty(addr));

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_USENDV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.usendv.list      = list;
    aice.u.usendv.size      = size;
    tb_ipaddr_copy(&aice.u.usendv.addr, addr);

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_sendf_(tb_aico_ref_t aico, tb_file_ref_t file, tb_hize_t seek, tb_hize_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && file, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_SENDF;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.sendf.file       = file;
    aice.u.sendf.seek       = seek;
    aice.u.sendf.size       = size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_read_(tb_aico_ref_t aico, tb_hize_t seek, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_READ;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.read.seek        = seek;
    aice.u.read.data        = data;
    aice.u.read.size        = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_writ_(tb_aico_ref_t aico, tb_hize_t seek, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_WRIT;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.writ.seek        = seek;
    aice.u.writ.data        = data;
    aice.u.writ.size        = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_readv_(tb_aico_ref_t aico, tb_hize_t seek, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_READV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.readv.seek       = seek;
    aice.u.readv.list       = list;
    aice.u.readv.size       = size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_writv_(tb_aico_ref_t aico, tb_hize_t seek, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_WRITV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.writv.seek       = seek;
    aice.u.writv.list       = list;
    aice.u.writv.size       = size;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_fsync_(tb_aico_ref_t aico, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_FSYNC;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_clos_after_(tb_aico_ref_t aico, tb_size_t delay, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_CLOS;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_acpt_after_(tb_aico_ref_t aico, tb_size_t delay, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_ACPT;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_conn_after_(tb_aico_ref_t aico, tb_size_t delay, tb_ipaddr_ref_t addr, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && addr, tb_false);

    // check address
    tb_assert(!tb_ipaddr_is_empty(addr));

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_CONN;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    tb_ipaddr_copy(&aice.u.conn.addr, addr);

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_recv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_RECV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.recv.data        = data;
    aice.u.recv.size        = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_send_after_(tb_aico_ref_t aico, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_SEND;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.send.data        = data;
    aice.u.send.size        = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_urecv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_URECV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.urecv.data       = data;
    aice.u.urecv.size       = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_usend_after_(tb_aico_ref_t aico, tb_size_t delay, tb_ipaddr_ref_t addr, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && addr && data && size, tb_false);

    // check address
    tb_assert(!tb_ipaddr_is_empty(addr));

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_USEND;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.usend.data       = data;
    aice.u.usend.size       = (tb_iovec_size_t)size;
    tb_ipaddr_copy(&aice.u.usend.addr, addr);

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_recvv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_RECVV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.recvv.list       = list;
    aice.u.recvv.size       = size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_sendv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_SENDV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.sendv.list       = list;
    aice.u.sendv.size       = size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_urecvv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && addr && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_URECVV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.urecvv.list      = list;
    aice.u.urecvv.size      = size;
    tb_ipaddr_copy(&aice.u.urecvv.addr, addr);

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_usendv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_ipaddr_ref_t addr, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && addr && list && size, tb_false);

    // check address
    tb_assert(!tb_ipaddr_is_empty(addr));

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_USENDV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.usendv.list      = list;
    aice.u.usendv.size      = size;
    tb_ipaddr_copy(&aice.u.usendv.addr, addr);

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_sendf_after_(tb_aico_ref_t aico, tb_size_t delay, tb_file_ref_t file, tb_hize_t seek, tb_hize_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && file, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_SENDF;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.sendf.file       = file;
    aice.u.sendf.seek       = seek;
    aice.u.sendf.size       = size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_read_after_(tb_aico_ref_t aico, tb_size_t delay, tb_hize_t seek, tb_byte_t* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_READ;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.read.seek        = seek;
    aice.u.read.data        = data;
    aice.u.read.size        = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_writ_after_(tb_aico_ref_t aico, tb_size_t delay, tb_hize_t seek, tb_byte_t const* data, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && data && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_WRIT;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.writ.seek        = seek;
    aice.u.writ.data        = data;
    aice.u.writ.size        = (tb_iovec_size_t)size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_readv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_hize_t seek, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_READV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.readv.seek       = seek;
    aice.u.readv.list       = list;
    aice.u.readv.size       = size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_writv_after_(tb_aico_ref_t aico, tb_size_t delay, tb_hize_t seek, tb_iovec_t const* list, tb_size_t size, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp && list && size, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_WRITV;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.writv.seek       = seek;
    aice.u.writv.list       = list;
    aice.u.writv.size       = size;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_fsync_after_(tb_aico_ref_t aico, tb_size_t delay, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_FSYNC;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;

    // post
    return tb_aicp_post_after_(impl->aicp, delay, &aice __tb_debug_args__);
}
tb_bool_t tb_aico_task_run_(tb_aico_ref_t aico, tb_size_t delay, tb_aico_func_t func, tb_cpointer_t priv __tb_debug_decl__)
{
    // check
    tb_aico_impl_t* impl = (tb_aico_impl_t*)aico;
    tb_assert_and_check_return_val(impl && impl->aicp, tb_false);

    // init
    tb_aice_t               aice = {0};
    aice.code               = TB_AICE_CODE_RUNTASK;
    aice.state              = TB_STATE_PENDING;
    aice.func               = func;
    aice.priv               = priv;
    aice.aico               = aico;
    aice.u.runtask.when     = tb_cache_time_mclock() + delay;
    aice.u.runtask.delay    = delay;

    // post
    return tb_aicp_post_(impl->aicp, &aice __tb_debug_args__);
}

