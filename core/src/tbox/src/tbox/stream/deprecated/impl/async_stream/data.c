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
 * @data        data.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "async_stream_data"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../../../../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the data read type
typedef struct __tb_async_stream_data_impl_read_t
{
    // the func
    tb_async_stream_read_func_t             func;

    // the size
    tb_size_t                               size;

    // the priv
    tb_cpointer_t                           priv;

}tb_async_stream_data_impl_read_t;

// the data writ type
typedef struct __tb_async_stream_data_impl_writ_t
{
    // the func
    tb_async_stream_writ_func_t             func;

    // the data
    tb_byte_t const*                        data;

    // the size
    tb_size_t                               size;

    // the priv
    tb_cpointer_t                           priv;

}tb_async_stream_data_impl_writ_t;

// the data task type
typedef struct __tb_async_stream_data_impl_task_t
{
    // the func
    tb_async_stream_task_func_t             func;

    // the priv
    tb_cpointer_t                           priv;

}tb_async_stream_data_impl_task_t;

// the data clos type
typedef struct __tb_async_stream_data_impl_clos_t
{
    // the func
    tb_async_stream_clos_func_t             func;

    // the priv
    tb_cpointer_t                           priv;

}tb_async_stream_data_impl_clos_t;

// the data stream type
typedef struct __tb_async_stream_data_impl_t
{
    // the aico for task
    tb_aico_ref_t                           aico;

    // the data
    tb_byte_t*                              data;

    // the head
    tb_byte_t*                              head;

    // the size
    tb_size_t                               size;

    // the data is referenced?
    tb_bool_t                               bref;

    // the offset
    tb_atomic64_t                           offset;

    // the func
    union
    {
        tb_async_stream_data_impl_read_t    read;
        tb_async_stream_data_impl_writ_t    writ;
        tb_async_stream_data_impl_task_t    task;
        tb_async_stream_data_impl_clos_t    clos;

    }                                       func;

}tb_async_stream_data_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_async_stream_data_impl_t* tb_async_stream_data_impl_cast(tb_async_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_async_stream_type(stream) == TB_STREAM_TYPE_DATA, tb_null);

    // ok?
    return (tb_async_stream_data_impl_t*)stream;
}
static tb_void_t tb_async_stream_data_impl_clos_clear(tb_async_stream_data_impl_t* impl)
{
    // check
    tb_assert_and_check_return(impl);

    // clear head
    impl->head = tb_null;

    // clear offset
    tb_atomic64_set0(&impl->offset);

    // clear base
    tb_async_stream_clear((tb_async_stream_ref_t)impl);
}
static tb_bool_t tb_async_stream_data_impl_clos_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->code == TB_AICE_CODE_CLOS, tb_false);

    // the impl
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast((tb_async_stream_ref_t)aice->priv);
    tb_assert_and_check_return_val(impl && impl->func.clos.func, tb_false);

    // trace
    tb_trace_d("clos: notify: ..");

    // clear it
    tb_async_stream_data_impl_clos_clear(impl);

    /* done clos func
     *
     * note: cannot use this stream after closing, the stream may be exited in the closing func
     */
    impl->func.clos.func((tb_async_stream_ref_t)impl, TB_STATE_OK, impl->func.clos.priv);

    // trace
    tb_trace_d("clos: notify: ok");

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_data_impl_clos_try(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // no aico or closed?
    if (!impl->aico || tb_aico_clos_try(impl->aico))
    {
        // clear it
        tb_async_stream_data_impl_clos_clear(impl);

        // ok
        return tb_true;
    }

    // failed
    return tb_false;
}
static tb_bool_t tb_async_stream_data_impl_clos(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv)
{   
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // trace
    tb_trace_d("clos: ..");

    // init func
    impl->func.clos.func = func;
    impl->func.clos.priv = priv;

    // clos it
    tb_aico_clos(impl->aico, tb_async_stream_data_impl_clos_func, impl);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_data_impl_open_try(tb_async_stream_ref_t stream)
{
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // check
        tb_assert_and_check_break(impl->data && impl->size);

        // the aicp
        tb_aicp_ref_t aicp = tb_async_stream_aicp(stream);
        tb_assert_and_check_break(aicp);

        // init aico
        if (!impl->aico) impl->aico = tb_aico_init(aicp);
        tb_assert_and_check_break(impl->aico);

        // open aico
        if (!tb_aico_open_task(impl->aico, tb_false)) break;

        // killed?
        tb_check_break(!tb_async_stream_is_killed(stream));

        // init head
        impl->head = impl->data;

        // init offset
        tb_atomic64_set0(&impl->offset);

        // open done
        tb_async_stream_open_done(stream);

        // ok
        ok = tb_true;

    } while (0);

    // failed? clear it
    if (!ok) tb_async_stream_data_impl_clos_clear(impl);

    // ok?
    return ok;
}
static tb_bool_t tb_async_stream_data_impl_open(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl && func, tb_false);

    // try opening it
    tb_size_t state = tb_async_stream_data_impl_open_try(stream)? TB_STATE_OK : TB_STATE_UNKNOWN_ERROR;

    // killed?
    if (state != TB_STATE_OK && tb_async_stream_is_killed(stream))
        state = TB_STATE_KILLED;

    // done func
    return tb_async_stream_open_func(stream, state, func, priv);
}
static tb_bool_t tb_async_stream_data_impl_read_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_RUNTASK, tb_false);

    // the stream
    tb_async_stream_data_impl_t* impl = (tb_async_stream_data_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.read.func, tb_false);

    // done state
    tb_size_t state = TB_STATE_UNKNOWN_ERROR;
    switch (aice->state)
    {
        // ok
    case TB_STATE_OK:
        {
            // check
            tb_assert_and_check_break(impl->data && impl->head);
            
            // the left
            tb_size_t left = impl->data + impl->size - impl->head;

            // the real
            tb_size_t real = impl->func.read.size;
            if (!real || real > left) real = left;

            // no data? closed
            if (!real) 
            {
                state = TB_STATE_CLOSED;
                break;
            }

            // save data
            tb_byte_t* data = impl->head;

            // save head
            impl->head += real;

            // save offset
            tb_atomic64_set(&impl->offset, impl->head - impl->data);

            // ok
            state = TB_STATE_OK;

            // done func
            if (impl->func.read.func((tb_async_stream_ref_t)impl, state, data, real, impl->func.read.size, impl->func.read.priv))
            {
                // continue to post read
                tb_aico_task_run(aice->aico, 0, tb_async_stream_data_impl_read_func, (tb_async_stream_ref_t)impl);
            }
        }
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
    if (state != TB_STATE_OK) impl->func.read.func((tb_async_stream_ref_t)impl, state, tb_null, 0, impl->func.read.size, impl->func.read.priv);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_data_impl_read(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // save func and priv
    impl->func.read.priv     = priv;
    impl->func.read.func     = func;
    impl->func.read.size     = size;

    // post read
    return tb_aico_task_run(impl->aico, delay, tb_async_stream_data_impl_read_func, stream);
}
static tb_bool_t tb_async_stream_data_impl_writ_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_RUNTASK, tb_false);

    // the stream
    tb_async_stream_data_impl_t* impl = (tb_async_stream_data_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.writ.func, tb_false);

    // done state
    tb_size_t state = TB_STATE_UNKNOWN_ERROR;
    switch (aice->state)
    {
        // ok
    case TB_STATE_OK:
        {
            // check
            tb_assert_and_check_break(impl->data && impl->head);
            tb_assert_and_check_break(impl->func.writ.data && impl->func.writ.size);
    
            // the left
            tb_size_t left = impl->data + impl->size - impl->head;

            // the real
            tb_size_t real = impl->func.writ.size;
            if (real > left) real = left;

            // no data? closed
            if (!real) 
            {
                state = TB_STATE_CLOSED;
                break;
            }

            // save data
            tb_memcpy(impl->head, impl->func.writ.data, real);

            // save head
            impl->head += real;

            // save offset
            tb_atomic64_set(&impl->offset, impl->head - impl->data);

            // ok
            state = TB_STATE_OK;

            // done func
            if (impl->func.writ.func((tb_async_stream_ref_t)impl, state, impl->func.writ.data, real, impl->func.writ.size, impl->func.writ.priv))
            {
                // not finished?
                if (real < impl->func.writ.size)
                {
                    // update data and size
                    impl->func.writ.data += real;
                    impl->func.writ.size -= real;

                    // continue to post writ
                    tb_aico_task_run(aice->aico, 0, tb_async_stream_data_impl_writ_func, (tb_async_stream_ref_t)impl);
                }
            }
        }
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
    if (state != TB_STATE_OK) impl->func.writ.func((tb_async_stream_ref_t)impl, state, impl->func.writ.data, 0, impl->func.writ.size, impl->func.writ.priv);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_data_impl_writ(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl && data && size && func, tb_false);

    // save func and priv
    impl->func.writ.priv     = priv;
    impl->func.writ.func     = func;
    impl->func.writ.data     = data;
    impl->func.writ.size     = size;

    // post writ
    return tb_aico_task_run(impl->aico, delay, tb_async_stream_data_impl_writ_func, stream);
}
static tb_bool_t tb_async_stream_data_impl_seek(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl && func, tb_false);

    // done
    tb_size_t state = TB_STATE_UNKNOWN_ERROR;
    do
    {
        // check
        tb_assert_and_check_break(impl->data && offset <= impl->size);

        // seek 
        impl->head = impl->data + offset;

        // save offset
        tb_atomic64_set(&impl->offset, offset);

        // ok
        state = TB_STATE_OK;

    } while (0);

    // done func
    func(stream, state, offset, priv);

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_data_impl_task_func(tb_aice_ref_t aice)
{
    // check
    tb_assert_and_check_return_val(aice && aice->aico && aice->code == TB_AICE_CODE_RUNTASK, tb_false);

    // the stream
    tb_async_stream_data_impl_t* impl = (tb_async_stream_data_impl_t*)aice->priv;
    tb_assert_and_check_return_val(impl && impl->func.task.func, tb_false);

    // done func
    tb_bool_t ok = impl->func.task.func((tb_async_stream_ref_t)impl, aice->state == TB_STATE_OK? TB_STATE_OK : TB_STATE_UNKNOWN_ERROR, impl->func.task.priv);

    // ok and continue?
    if (ok && aice->state == TB_STATE_OK)
    {
        // post task
        tb_aico_task_run(aice->aico, aice->u.runtask.delay, tb_async_stream_data_impl_task_func, impl);
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_data_impl_task(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv)
{
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl && impl->aico && func, tb_false);

    // save func and priv
    impl->func.task.priv     = priv;
    impl->func.task.func     = func;

    // post task
    return tb_aico_task_run(impl->aico, delay, tb_async_stream_data_impl_task_func, stream);
}
static tb_void_t tb_async_stream_data_impl_kill(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return(impl);

    // kill the task aico
    if (impl->aico) tb_aico_kill(impl->aico);
}
static tb_bool_t tb_async_stream_data_impl_exit(tb_async_stream_ref_t stream)
{   
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // exit the task aico
    if (impl->aico) tb_aico_exit(impl->aico);
    impl->aico = tb_null;

    // clear head
    impl->head = tb_null;

    // clear offset
    tb_atomic64_set0(&impl->offset);

    // exit data
    if (impl->data && !impl->bref) tb_free(impl->data);
    impl->data = tb_null;
    impl->size = 0;

    // ok
    return tb_true;
}
static tb_bool_t tb_async_stream_data_impl_ctrl(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{ 
    // check
    tb_async_stream_data_impl_t* impl = tb_async_stream_data_impl_cast(stream);
    tb_assert_and_check_return_val(impl, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_STREAM_CTRL_GET_SIZE:
        {
            // the psize
            tb_hong_t* psize = (tb_hong_t*)tb_va_arg(args, tb_hong_t*);
            tb_assert_and_check_return_val(psize, tb_false);

            // get size
            *psize = impl->size;
            return tb_true;
        }
    case TB_STREAM_CTRL_GET_OFFSET:
        {
            // check
            tb_assert_and_check_return_val(impl->data && impl->size, tb_false);
            tb_assert_and_check_return_val(tb_async_stream_is_opened(stream), tb_false);

            // the poffset
            tb_hize_t* poffset = (tb_hize_t*)tb_va_arg(args, tb_hize_t*);
            tb_assert_and_check_return_val(poffset, tb_false);

            // get offset
            *poffset = tb_atomic64_get(&impl->offset);
            return tb_true;
        }
    case TB_STREAM_CTRL_DATA_SET_DATA:
        {
            // exit data first if exists
            if (impl->data && !impl->bref) tb_free(impl->data);

            // save data
            impl->data = (tb_byte_t*)tb_va_arg(args, tb_byte_t*);
            impl->size = (tb_size_t)tb_va_arg(args, tb_size_t);
            impl->head = tb_null;
            impl->bref = tb_true;

            // clear offset
            tb_atomic64_set0(&impl->offset);

            // check
            tb_assert_and_check_return_val(impl->data && impl->size, tb_false);
            return tb_true;
        }
    case TB_STREAM_CTRL_SET_URL:
        {
            // check
            tb_assert_and_check_return_val(tb_async_stream_is_closed(stream), tb_false);

            // set url
            tb_char_t const* url = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(url, tb_false); 
            
            // the url size
            tb_size_t url_size = tb_strlen(url);
            tb_assert_and_check_return_val(url_size > 7, tb_false);

            // the base64 data and size
            tb_char_t const*    base64_data = url + 7;
            tb_size_t           base64_size = url_size - 7;

            // make data
            tb_size_t   maxn = base64_size;
            tb_byte_t*  data = tb_malloc_bytes(maxn); 
            tb_assert_and_check_return_val(data, tb_false);

            // decode base64 data
            tb_size_t   size = tb_base64_decode(base64_data, base64_size, data, maxn);
            tb_assert_and_check_return_val(size, tb_false);

            // exit data first if exists
            if (impl->data && !impl->bref) tb_free(impl->data);

            // save data
            impl->data = data;
            impl->size = size;
            impl->bref = tb_false;
            impl->head = tb_null;

            // clear offset
            tb_atomic64_set0(&impl->offset);

            // ok
            return tb_true;
        }
        break;
    default:
        break;
    }
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_async_stream_ref_t tb_async_stream_init_data(tb_aicp_ref_t aicp)
{
    return tb_async_stream_init(    aicp
                                ,   TB_STREAM_TYPE_DATA
                                ,   sizeof(tb_async_stream_data_impl_t)
                                ,   0
                                ,   0
                                ,   tb_async_stream_data_impl_open_try
                                ,   tb_async_stream_data_impl_clos_try
                                ,   tb_async_stream_data_impl_open
                                ,   tb_async_stream_data_impl_clos
                                ,   tb_async_stream_data_impl_exit
                                ,   tb_async_stream_data_impl_kill
                                ,   tb_async_stream_data_impl_ctrl
                                ,   tb_async_stream_data_impl_read
                                ,   tb_async_stream_data_impl_writ
                                ,   tb_async_stream_data_impl_seek
                                ,   tb_null
                                ,   tb_async_stream_data_impl_task);
}
tb_async_stream_ref_t tb_async_stream_init_from_data(tb_aicp_ref_t aicp, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(data && size, tb_null);

    // done
    tb_bool_t               ok = tb_false;
    tb_async_stream_ref_t   stream = tb_null;
    do
    {
        // init stream
        stream = tb_async_stream_init_data(aicp);
        tb_assert_and_check_break(stream);

        // set data
        if (!tb_async_stream_ctrl(stream, TB_STREAM_CTRL_DATA_SET_DATA, data, size)) break;

        // check
        tb_assert_static(!(tb_offsetof(tb_async_stream_data_impl_t, offset) & (sizeof(tb_atomic64_t) - 1)));

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
