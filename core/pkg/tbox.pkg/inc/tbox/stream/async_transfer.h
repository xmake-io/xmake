/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        async_transfer.h
 * @ingroup     stream
 *
 */
#ifndef TB_STREAM_ASYNC_TRANSFER_H
#define TB_STREAM_ASYNC_TRANSFER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "async_stream.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the async transfer open func type
 *
 * @param state         the stream state 
 * @param offset        the istream offset
 * @param size          the istream size, no size: -1
 * @param priv          the func private data
 *
 * @return              tb_true: ok, tb_false: break it
 */
typedef tb_bool_t       (*tb_async_transfer_open_func_t)(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_cpointer_t priv);

/*! the async transfer clos func type
 *
 * @param state         the stream state 
 * @param priv          the func private data
 */
typedef tb_void_t       (*tb_async_transfer_clos_func_t)(tb_size_t state, tb_cpointer_t priv);

/*! the async transfer ctrl func type
 *
 * @param istream       the istream
 * @param ostream       the ostream
 * @param priv          the func private data
 *
 * @return              tb_true: ok, tb_false: break it
 */
typedef tb_bool_t       (*tb_async_transfer_ctrl_func_t)(tb_async_stream_ref_t istream, tb_async_stream_ref_t ostream, tb_cpointer_t priv);

/*! the async transfer done func type
 *
 * @param state         the stream state 
 * @param offset        the istream offset
 * @param size          the istream size, no size: -1
 * @param save          the saved size
 * @param rate          the current rate, bytes/s
 * @param priv          the func private data
 *
 * @return              tb_true: ok and continue it if need, tb_false: break it
 */
typedef tb_bool_t       (*tb_async_transfer_done_func_t)(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_hize_t save, tb_size_t rate, tb_cpointer_t priv);

/// the async transfer ref type
typedef struct{}*       tb_async_transfer_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init async transfer
 *
 * @param aicp          the aicp, using the default aicp if be null
 * @param autoclosing   auto closing it after finishing transfer
 *
 * @return              the async transfer 
 */
tb_async_transfer_ref_t tb_async_transfer_init(tb_aicp_ref_t aicp, tb_bool_t autoclosing);

/*! init istream
 *
 * @param transfer      the async transfer
 * @param stream        the stream
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_init_istream(tb_async_transfer_ref_t transfer, tb_async_stream_ref_t stream);

/*! init istream from url
 *
 * @param transfer      the async transfer
 * @param url           the url
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_init_istream_from_url(tb_async_transfer_ref_t transfer, tb_char_t const* url);

/*! init istream from data
 *
 * @param transfer      the async transfer
 * @param data          the data
 * @param size          the size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_init_istream_from_data(tb_async_transfer_ref_t transfer, tb_byte_t const* data, tb_size_t size);

/*! init ostream
 *
 * @param transfer      the async transfer
 * @param stream        the stream
 *
 * @return              the async transfer 
 */
tb_bool_t               tb_async_transfer_init_ostream(tb_async_transfer_ref_t transfer, tb_async_stream_ref_t stream);

/*! init ostream from url
 *
 * @param transfer      the async transfer
 * @param url           the url
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_init_ostream_from_url(tb_async_transfer_ref_t transfer, tb_char_t const* url);

/*! init ostream from data
 *
 * @param transfer      the async transfer
 * @param data          the data
 * @param size          the size
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_init_ostream_from_data(tb_async_transfer_ref_t transfer, tb_byte_t* data, tb_size_t size);

/*! ctrl istream
 *
 * @note must call it before opening
 *
 * @param transfer      the async transfer
 * @param ctrl          the ctrl code, using the stream ctrl code
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_ctrl_istream(tb_async_transfer_ref_t transfer, tb_size_t ctrl, ...);

/*! ctrl ostream
 *
 * @note must call it before opening
 *
 * @param transfer      the async transfer
 * @param ctrl          the ctrl code, using the stream ctrl code
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_ctrl_ostream(tb_async_transfer_ref_t transfer, tb_size_t ctrl, ...);

/*! ctrl transfer
 *
 * @param transfer      the async transfer
 * @param offset        the start offset
 * @param func          the ctrl func 
 * @param priv          the func private data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_ctrl(tb_async_transfer_ref_t transfer, tb_async_transfer_ctrl_func_t func, tb_cpointer_t priv);

/*! open transfer
 *
 * @param transfer      the async transfer
 * @param offset        the start offset
 * @param func          the open func 
 * @param priv          the func private data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_open(tb_async_transfer_ref_t transfer, tb_hize_t offset, tb_async_transfer_open_func_t func, tb_cpointer_t priv);

/*! clos transfer
 *
 * @param transfer      the async transfer
 * @param func          the clos func 
 * @param priv          the func private data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_clos(tb_async_transfer_ref_t transfer, tb_async_transfer_clos_func_t func, tb_cpointer_t priv);

/*! try closing transfer
 *
 * @param transfer      the async transfer
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_clos_try(tb_async_transfer_ref_t transfer);

/*! done transfer and will close it automaticly
 *
 * @param transfer      the async transfer
 * @param func          the save func 
 * @param priv          the func private data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_done(tb_async_transfer_ref_t transfer, tb_async_transfer_done_func_t func, tb_cpointer_t priv);

/*! open and done transfer and will close it automaticly
 *
 * @code
 *
    static tb_bool_t tb_demo_transfer_done_func(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_hize_t save, tb_size_t rate, tb_cpointer_t priv)
    {
        // percent
        tb_size_t percent = 0;
        if (size > 0) percent = (offset * 100) / size;
        else if (state == TB_STATE_OK) percent = 100;

        // trace
        tb_trace_i("done: %llu bytes, rate: %lu bytes/s, percent: %lu%%, state: %s", save, rate, percent, tb_state_cstr(state));

        // ok
        return tb_true;
    }

    // init transfer
    tb_async_transfer_ref_t transfer = tb_async_transfer_init(tb_null);
    if (transfer)
    {
        // init stream
        tb_async_transfer_init_istream_from_url(transfer, url);
        tb_async_transfer_init_ostream_from_data(transfer, data, size);

        // ctrl stream
//      tb_async_transfer_ctrl_istream(transfer, TB_STREAM_CTRL_SET_TIMEOUT, 10000);

        // limit rate
//      tb_async_transfer_limitrate(transfer, 256000);

        // open and done transfer
        tb_async_transfer_open_done(transfer, 0, tb_demo_transfer_done_func, tb_null);

        // exit transfer
        tb_async_transfer_exit(transfer);
    }
 *
 * @endcode
 *
 * @param transfer      the async transfer
 * @param offset        the start offset
 * @param func          the save func 
 * @param priv          the func private data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_open_done(tb_async_transfer_ref_t transfer, tb_hize_t offset, tb_async_transfer_done_func_t func, tb_cpointer_t priv);

/*! kill transfer 
 *
 * @param transfer      the async transfer
 */
tb_void_t               tb_async_transfer_kill(tb_async_transfer_ref_t transfer);

/*! exit transfer 
 *
 * @note will wait transfer closed and cannot be called in the callback func
 *
 * @param transfer      the async transfer
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_exit(tb_async_transfer_ref_t transfer);

/*! pause transfer 
 *
 * the save func state will return TB_STATE_PAUSED 
 *
 * @param transfer      the async transfer
 */
tb_void_t               tb_async_transfer_pause(tb_async_transfer_ref_t transfer);

/*! resume transfer 
 *
 * @param transfer      the async transfer
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_async_transfer_resume(tb_async_transfer_ref_t transfer);

/*! limit transfer rate  
 *
 * @param transfer      the async transfer
 * @param rate          the trasfer rate and no limit if 0, bytes/s
 */
tb_void_t               tb_async_transfer_limitrate(tb_async_transfer_ref_t transfer, tb_size_t rate);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
