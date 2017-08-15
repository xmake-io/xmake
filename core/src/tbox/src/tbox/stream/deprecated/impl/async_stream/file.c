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
 * @file        file.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "async_stream_file"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the file cache maxn
#define TB_ASYNC_STREAM_FILE_CACHE_MAXN             TB_FILE_DIRECT_CSIZE

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the file stream type
typedef struct __tb_async_stream_file_impl_t
{
    // the aico
    tb_aico_ref_t                       aico;

    // the file mode
    tb_size_t                           mode;

    // the file offset
    tb_atomic64_t                       offset;

    // is stream file?
    tb_bool_t                           bstream;

    // is closing
    tb_bool_t                           bclosing;

    // the func
    union
    {
        tb_async_stream_read_func_t     read;
        tb_async_stream_writ_func_t     writ;
        tb_async_stream_sync_func_t     sync;
        tb_async_stream_task_func_t     task;
        tb_async_stream_clos_func_t     clos;

    }                                   func;

    // the priv
    tb_cpointer_t                       priv;

}tb_async_stream_file_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_async_stream_file_impl_t* tb_async_stream_file_impl_cast(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_async_stream_type(stream) == TB_STREAM_TYPE_FILE, tb_null);

    // ok?
    return (tb_async_stream_file_impl_t*)stream;
}
static tb_void_t tb_async_stream_file_impl_clos_clear(tb_async_stream_file_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl);

    // clear the offset
    tb_atomic64_set0(&impl->offset);

    // clear base
    tb_async_stream_clear((tb_async_stream_ref_t)impl);
}
static tb_bool_t tb_async_stream_file_impl_clos_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_CLOS, tb_false);

    // the impl
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast((tb_async_stream_ref_t)aice->priv);
    tb_assert_and_check_return_val(impl && impl->func.clos, tb_false);

    // trace
    tb_trace_d("clos: notify: ..");

    // clear it
    tb_async_stream_file_impl_clos_clear(impl);

    /* done clos func
     *
     * note: cannot use this stream after closing, the stream may be exited in the closing func
     */
    impl->func.clos((tb_async_stream_ref_t)impl, TB_STATE_OK, impl->priv);

    // trace
    tb_trace_d("clos: notify: ok");

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_file_impl_clos_try(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // no aico or closed?
    if (!impl->aico || tb_aico_clos_try(impl->aico))
    {
        // clear it
        tb_async_stream_file_impl_clos_clear(impl);

        // ok
        return tb_true;
    }

    // failed
    return tb_false;
}
static tb_bool_t tb_async_stream_file_impl_open_try(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // the aicp
        tb_aicp_ref_t aicp = tb_async_stream_aicp(stream);
        tb_assert_and_check_break(aicp);

        // init aico
        if (!impl->aico) impl->aico = tb_aico_init(tb_async_stream_aicp(stream));
        tb_assert_and_check_break(impl->aico);

        // the url
        tb_char_t const* url = tb_url_cstr(tb_async_stream_url(stream));
        tb_assert_and_check_break(url);

        // open aico
        if (!tb_aico_open_file_from_path(impl->aico, url, impl->mode)) break;

        // killed?
        tb_check_break(!tb_async_stream_is_killed(stream));

        // init offset
        tb_atomic64_set0(&impl->offset);

        // open done
        tb_async_stream_open_done(stream);

        // ok
        ok = tb_true;

    } while (0);

    // failed? clear it
    if (!ok) tb_async_stream_file_impl_clos_clear(impl);

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_file_impl_open(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl && func, tb_false);

    // done
    tb_size_t state = TB_STATE_UNKNOWN_ERROR;
    do
    {
        // try opening it
        if (!tb_async_stream_file_impl_open_try(stream))
        {
            // killed?
            if (tb_async_stream_is_killed(stream))
            {
                // save state
                state = TB_STATE_KILLED;
                break;
            }

            // the url
            tb_char_t const* url = tb_url_cstr(tb_async_stream_url(stream));
            tb_assert_and_check_break(url);

            // trace
            tb_trace_e("open %s: failed", url);

            // save state
            state = tb_syserror_state();
            break;
        }

        // ok
        state = TB_STATE_OK;

    } while (0);

    // open done
    return tb_async_stream_open_func(stream, state, func, priv);
}
static tb_bool_t tb_async_stream_file_impl_clos(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv)
{   
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // trace
    tb_trace_d("clos: ..");

    // init clos
    impl->func.clos  = func;
    impl->priv       = priv;

    /* clos aico
     *
     * note: cannot use this stream after exiting, the stream may be exited after calling clos func
     */
    tb_aico_clos(impl->aico, tb_async_stream_file_impl_clos_func, impl);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_file_impl_read_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_READ, tb_false);

    // the stream
    tb_async_stream_file_impl_t* impl = (tb_async_stream_file_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.read, tb_false);

    // done state
    tb_size_t state = TB_STATE_UNKNOWN_ERROR;
    switch (aice->state)
    {
        // ok
    case TB_STATE_OK:
        tb_atomic64_fetch_and_add(&impl->offset, aice->u.read.real);
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
    default:
        tb_trace_d("read: unknown state: %s", tb_state_cstr(aice->state));
        break;
    }
 
    // done func
    if (impl->func.read((tb_async_stream_ref_t)impl, state, aice->u.read.data, aice->u.read.real, aice->u.read.size, impl->priv))
    {
        // continue?
        if (aice->state == TB_STATE_OK)
        {
            // continue to post read
            tb_aico_read(aice->aico, (tb_hize_t)tb_atomic64_get(&impl->offset), aice->u.read.data, aice->u.read.size, tb_async_stream_file_impl_read_func, (tb_async_stream_ref_t)impl);
        }
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_file_impl_read(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && data && size && func, tb_false);

    // save func and priv
    impl->priv       = priv;
    impl->func.read  = func;

    // post read
    return tb_aico_read_after(impl->aico, delay, (tb_hize_t)tb_atomic64_get(&impl->offset), data, size, tb_async_stream_file_impl_read_func, stream);
}
static tb_bool_t tb_async_stream_file_impl_writ_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_WRIT, tb_false);
 
    // the stream
    tb_async_stream_file_impl_t* impl = (tb_async_stream_file_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.writ, tb_false);

    // done state
    tb_size_t state = TB_STATE_UNKNOWN_ERROR;
    switch (aice->state)
    {
        // ok
    case TB_STATE_OK:
        tb_assert_and_check_break(aice->u.writ.data && aice->u.writ.real <= aice->u.writ.size);
        tb_atomic64_fetch_and_add(&impl->offset, aice->u.writ.real);
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
    default:
        tb_trace_d("writ: unknown state: %s", tb_state_cstr(aice->state));
        break;
    }

    // done func
    if (impl->func.writ((tb_async_stream_ref_t)impl, state, aice->u.writ.data, aice->u.writ.real, aice->u.writ.size, impl->priv))
    {
        // continue?
        if (aice->state == TB_STATE_OK && aice->u.writ.real < aice->u.writ.size)
        {
            // continue to post writ
            tb_aico_writ(aice->aico, (tb_hize_t)tb_atomic64_get(&impl->offset), aice->u.writ.data + aice->u.writ.real, aice->u.writ.size - aice->u.writ.real, tb_async_stream_file_impl_writ_func, (tb_async_stream_ref_t)impl);
        }
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_file_impl_writ(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && data && size && func, tb_false);

    // save func and priv
    impl->priv       = priv;
    impl->func.writ  = func;

    // post writ
    return tb_aico_writ_after(impl->aico, delay, (tb_hize_t)tb_atomic64_get(&impl->offset), data, size, tb_async_stream_file_impl_writ_func, stream);
}
static tb_bool_t tb_async_stream_file_impl_seek(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl && func, tb_false);

    // done
    tb_size_t state = TB_STATE_UNKNOWN_ERROR;
    do
    {
        // check
        tb_assert_and_check_break(impl->aico);

        // is stream file?
        tb_check_break_state(!impl->bstream, state, TB_STATE_NOT_SUPPORTED);

        // update offset
        tb_atomic64_set(&impl->offset, offset);

        // ok
        state = TB_STATE_OK;

    } while (0);

    // done func
    func(stream, state, offset, priv);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_file_impl_sync_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_FSYNC, tb_false);

    // the stream
    tb_async_stream_file_impl_t* impl = (tb_async_stream_file_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.sync, tb_false);

    // done func
    impl->func.sync((tb_async_stream_ref_t)impl, aice->state == TB_STATE_OK? TB_STATE_OK : TB_STATE_UNKNOWN_ERROR, impl->bclosing, impl->priv);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_file_impl_sync(tb_async_stream_ref_t stream, tb_bool_t bclosing, tb_async_stream_sync_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // save func and priv
    impl->priv       = priv;
    impl->func.sync  = func;
    impl->bclosing   = bclosing;

    // post sync
    return tb_aico_fsync(impl->aico, tb_async_stream_file_impl_sync_func, stream);
}
static tb_bool_t tb_async_stream_file_impl_task_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_RUNTASK, tb_false);

    // the stream
    tb_async_stream_file_impl_t* impl = (tb_async_stream_file_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.task, tb_false);

    // done func
    tb_bool_t ok = impl->func.task((tb_async_stream_ref_t)impl, aice->state, impl->priv);

    // ok and continue?
    if (ok && aice->state == TB_STATE_OK)
    {
        // post task
        tb_aico_task_run(aice->aico, aice->u.runtask.delay, tb_async_stream_file_impl_task_func, impl);
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_file_impl_task(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // save func and priv
    impl->priv       = priv;
    impl->func.task  = func;

    // post task
    return tb_aico_task_run(impl->aico, delay, tb_async_stream_file_impl_task_func, stream);
}
static tb_void_t tb_async_stream_file_impl_kill(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return(impl);

    // trace
    tb_trace_d("kill: %s: ..", tb_url_cstr(tb_async_stream_url(stream)));

    // kill it
    if (impl->aico) tb_aico_kill(impl->aico);
}
static tb_bool_t tb_async_stream_file_impl_exit(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // exit aico
    if (impl->aico) tb_aico_exit(impl->aico);
    impl->aico = tb_null;

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_file_impl_ctrl(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_STREAM_CTRL_GET_SIZE:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_opened(stream) && impl->aico, tb_false);

            // the file
            tb_file_ref_t file = tb_aico_file(impl->aico);
            tb_assert_and_check_return_val(file, tb_false);

            // the psize
            tb_hong_t* psize = (tb_hong_t*)tb_va_arg(args, tb_hong_t*);
            tb_assert_and_check_return_val(psize, tb_false);

            // get size
            if (!impl->bstream) *psize = tb_file_size(file);
            else *psize = -1;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_GET_OFFSET:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_opened(stream), tb_false);

            // the poffset
            tb_hize_t* poffset = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(poffset, tb_false);

            // get offset
            *poffset = (tb_hize_t)tb_atomic64_get(&impl->offset);

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FILE_SET_MODE:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);

            // set mode
            impl->mode = (tb_size_t)tb_va_arg(args, tb_size_t);
            return tb_true;
        }
    case TB_STREAM_CTRL_FILE_GET_MODE:
        {
            // the pmode
            tb_size_t* pmode = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pmode, tb_false);

            // get mode
            *pmode = impl->mode;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FILE_IS_STREAM:
        {
            // is stream
            impl->bstream = (tb_bool_t)tb_va_arg(args, tb_bool_t);

            // ok
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
tb_async_stream_ref_t tb_async_stream_init_file(tb_aicp_ref_t aicp)
{
    // init stream
    tb_async_stream_ref_t stream = tb_async_stream_init(    aicp
                                                        ,   TB_STREAM_TYPE_FILE
                                                        ,   sizeof(tb_async_stream_file_impl_t)
                                                        ,   TB_ASYNC_STREAM_FILE_CACHE_MAXN
                                                        ,   TB_ASYNC_STREAM_FILE_CACHE_MAXN
                                                        ,   tb_async_stream_file_impl_open_try
                                                        ,   tb_async_stream_file_impl_clos_try
                                                        ,   tb_async_stream_file_impl_open
                                                        ,   tb_async_stream_file_impl_clos
                                                        ,   tb_async_stream_file_impl_exit
                                                        ,   tb_async_stream_file_impl_kill
                                                        ,   tb_async_stream_file_impl_ctrl
                                                        ,   tb_async_stream_file_impl_read
                                                        ,   tb_async_stream_file_impl_writ
                                                        ,   tb_async_stream_file_impl_seek
                                                        ,   tb_async_stream_file_impl_sync
                                                        ,   tb_async_stream_file_impl_task);
    tb_assert_and_check_return_val(stream, tb_null);

    // init the stream impl
    tb_async_stream_file_impl_t* impl = tb_async_stream_file_impl_cast(stream);
    if (impl)
    {
        // init mode
        impl->mode      = TB_FILE_MODE_RO;
        impl->bstream   = tb_false;
    }

    // ok?
    return stream;
}
tb_async_stream_ref_t tb_async_stream_init_from_file(tb_aicp_ref_t aicp, tb_char_t const* path, tb_size_t mode)
{
    // check
    tb_assert_and_check_return_val(path, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   stream = tb_null;
    do
    {
        // init stream
        stream = tb_async_stream_init_file(aicp);
        tb_assert_and_check_break(stream);

        // set path
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_SET_URL, path)) break;
        
        // set mode
        if (stream) if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_FILE_SET_MODE, mode)) break;

        // check
        tb_assert_static(!(tb_offsetof(tb_async_stream_file_impl_t, offset) & (sizeof(tb_atomic64_t) - 1)));

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

    // ok
    return stream;
}
