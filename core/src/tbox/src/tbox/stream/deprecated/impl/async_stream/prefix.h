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
 * @file        prefix.h
 *
 */
#ifndef TB_STREAM_IMPL_ASYNC_STREAM_PREFIX_H
#define TB_STREAM_IMPL_ASYNC_STREAM_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../../async_stream.h"
#include "../../../filter.h"
#include "../../../../asio/deprecated/asio.h"
#include "../../../../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the async stream impl
#define tb_async_stream_impl(stream)    ((stream)? &(((tb_async_stream_impl_t*)(stream))[-1]) : tb_null)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the stream open and read type
typedef struct __tb_async_stream_open_read_t
{
    // the func
    tb_async_stream_read_func_t         func;

    // the priv
    tb_cpointer_t                       priv;

    // the size
    tb_size_t                           size;

}tb_async_stream_open_read_t;

// the stream open and writ type
typedef struct __tb_async_stream_open_writ_t
{
    // the func
    tb_async_stream_writ_func_t         func;

    // the priv
    tb_cpointer_t                       priv;

    // the data
    tb_byte_t const*                    data;

    // the size
    tb_size_t                           size;

}tb_async_stream_open_writ_t;

// the stream open and seek type
typedef struct __tb_async_stream_open_seek_t
{
    // the func
    tb_async_stream_seek_func_t         func;

    // the priv
    tb_cpointer_t                       priv;

    // the offset
    tb_hize_t                           offset;

}tb_async_stream_open_seek_t;

// the stream close opening type
typedef struct __tb_async_stream_clos_opening_t
{
    // the func
    tb_async_stream_open_func_t         func;

    // the priv
    tb_cpointer_t                       priv;

    // the open state
    tb_size_t                           state;

}tb_async_stream_clos_opening_t;

// the stream cache and writ type
typedef struct __tb_async_stream_cache_writ_t
{
    // the func
    tb_async_stream_writ_func_t         func;

    // the data
    tb_byte_t const*                    data;

    // the size
    tb_size_t                           size;

}tb_async_stream_cache_writ_t;

// the stream cache and sync type
typedef struct __tb_async_stream_cache_sync_t
{
    // the func
    tb_async_stream_sync_func_t         func;

    // is closing
    tb_bool_t                           bclosing;

}tb_async_stream_cache_sync_t;

// the stream sync and read type
typedef struct __tb_async_stream_sync_read_t
{
    // the func
    tb_async_stream_read_func_t         func;

    // the priv
    tb_cpointer_t                       priv;

    // the size
    tb_size_t                           size;

}tb_async_stream_sync_read_t;

// the stream sync and seek type
typedef struct __tb_async_stream_sync_seek_t
{
    // the func
    tb_async_stream_seek_func_t         func;

    // the priv
    tb_cpointer_t                       priv;

    // the offset
    tb_hize_t                           offset;

}tb_async_stream_sync_seek_t;

// the asio stream type
typedef __tb_aligned__(8) struct __tb_async_stream_impl_t
{   
    // the stream type
    tb_uint8_t                          type;

    // the url
    tb_url_t                            url;

    /* internal state
     *
     * <pre>
     * TB_STATE_CLOSED
     * TB_STATE_OPENED
     * TB_STATE_KILLED
     * TB_STATE_OPENING
     * TB_STATE_KILLING
     * </pre>
     */
    tb_atomic_t                         istate;

    // the timeout
    tb_long_t                           timeout;

    // the aicp
    tb_aicp_ref_t                       aicp;

#ifdef __tb_debug__
    // the func
    tb_char_t const*                    func;

    // the file
    tb_char_t const*                    file;

    // the line
    tb_size_t                           line;
#endif

    // the open and read, writ, seek, ...
    union
    {
        tb_async_stream_open_read_t     read;
        tb_async_stream_open_writ_t     writ;
        tb_async_stream_open_seek_t     seek;

    }                                   open_and;

    // the sync and read, writ, seek, ...
    union
    {
        tb_async_stream_sync_read_t     read;
        tb_async_stream_sync_seek_t     seek;

    }                                   sync_and;

    // the wcache and writ, sync, ... 
    union
    {
        tb_async_stream_cache_writ_t    writ;
        tb_async_stream_cache_sync_t    sync;

    }                                   wcache_and;

    // the close opening
    tb_async_stream_clos_opening_t      clos_opening;

    // the read cache data
    tb_buffer_t                         rcache_data;

    // the read cache maxn
    tb_size_t                           rcache_maxn;

    // the writ cache data
    tb_buffer_t                         wcache_data;

    // the writ cache maxn
    tb_size_t                           wcache_maxn;

    /* try opening stream, optional
     * 
     * @param stream                    the stream
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*open_try)(tb_async_stream_ref_t stream);

    /* try closing stream, optional
     *
     * @param stream                    the stream
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*clos_try)(tb_async_stream_ref_t stream);

    /* open stream
     *
     * @param stream                    the stream
     * @param func                      the open func
     * @param priv                      the func private data
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*open)(tb_async_stream_ref_t stream, tb_async_stream_open_func_t func, tb_cpointer_t priv);

    /* clos stream
     *
     * @param stream                    the stream
     * @param func                      the open func
     * @param priv                      the func private data
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*clos)(tb_async_stream_ref_t stream, tb_async_stream_clos_func_t func, tb_cpointer_t priv);

    /* read stream
     *
     * @param stream                    the stream
     * @param delay                     read it after the delay time, ms
     * @param data                      the read data
     * @param size                      the read size
     * @param func                      the read func
     * @param priv                      the func private data
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*read)(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t* data, tb_size_t size, tb_async_stream_read_func_t func, tb_cpointer_t priv);

    /* writ stream
     *
     * @param stream                    the stream
     * @param delay                     writ it after the delay time, ms
     * @param data                      the writ data
     * @param size                      the writ size
     * @param func                      the writ func
     * @param priv                      the func private data
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*writ)(tb_async_stream_ref_t stream, tb_size_t delay, tb_byte_t const* data, tb_size_t size, tb_async_stream_writ_func_t func, tb_cpointer_t priv);

    /* seek stream, optional
     *
     * @param stream                    the stream
     * @param offset                    the seek offset
     * @param func                      the writ func
     * @param priv                      the func private data
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*seek)(tb_async_stream_ref_t stream, tb_hize_t offset, tb_async_stream_seek_func_t func, tb_cpointer_t priv);

    /* sync stream, optional
     *
     * @param stream                    the stream
     * @param bclosing                  the stream will be closed? 
     * @param func                      the writ func
     * @param priv                      the func private data
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*sync)(tb_async_stream_ref_t stream, tb_bool_t bclosing, tb_async_stream_sync_func_t func, tb_cpointer_t priv);

    /* post stream task
     *
     * @param stream                    the stream
     * @param delay                     done it after the delay time, ms
     * @param func                      the writ func
     * @param priv                      the func private data
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*task)(tb_async_stream_ref_t stream, tb_size_t delay, tb_async_stream_task_func_t func, tb_cpointer_t priv);

    /* ctrl stream
     *
     * @param stream                    the stream
     * @param ctrl                      the ctrl code
     * @param args                      the ctrl arguments
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*ctrl)(tb_async_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args);

    /* exit stream, optional
     *
     * @param stream                    the stream
     *
     * @return                          tb_true or tb_false
     */
    tb_bool_t                           (*exit)(tb_async_stream_ref_t stream);

    /* kill stream
     *
     * @param stream                    the stream
     *
     * @return                          tb_true or tb_false
     */
    tb_void_t                           (*kill)(tb_async_stream_ref_t stream);

}__tb_aligned__(8) tb_async_stream_impl_t;


/* //////////////////////////////////////////////////////////////////////////////////////
 * private interfaces
 */

/* clear the stream after closing stream
 *
 * @param stream        the stream
 */
tb_void_t               tb_async_stream_clear(tb_async_stream_ref_t stream);

/* done the opening stream
 *
 * @param stream        the stream
 */
tb_void_t               tb_async_stream_open_done(tb_async_stream_ref_t stream);

/* done the open func after opening stream
 *
 * @param stream        the stream
 * @param state         the state
 * @param func          the open func
 * @param priv          the func private data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_stream_open_func(tb_async_stream_ref_t stream, tb_size_t state, tb_async_stream_open_func_t func, tb_cpointer_t priv);


#endif
