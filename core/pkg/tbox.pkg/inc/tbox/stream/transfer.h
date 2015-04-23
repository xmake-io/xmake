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
 * @file        transfer.h
 * @ingroup     stream
 *
 */
#ifndef TB_STREAM_TRANSFER_H
#define TB_STREAM_TRANSFER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "async_stream.h"
#include "async_transfer.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the basic transfer done func type
 *
 * @param state     the stream state 
 * @param offset    the istream offset
 * @param size      the istream size, no size: -1
 * @param save      the saved size
 * @param rate      the current rate, bytes/s
 * @param priv      the func private data
 *
 * @return          tb_true: ok and continue it if need, tb_false: break it
 */
typedef tb_bool_t   (*tb_transfer_done_func_t)(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_hize_t save, tb_size_t rate, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! done transfer from stream to stream
 *
 * @param istream   the istream
 * @param ostream   the ostream
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_done(tb_stream_ref_t istream, tb_stream_ref_t ostream, tb_size_t lrate, tb_transfer_done_func_t func, tb_cpointer_t priv);

/*! done transfer from stream to url
 *
 * @param istream   the istream
 * @param ourl      the output url
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_done_to_url(tb_stream_ref_t istream, tb_char_t const* ourl, tb_size_t lrate, tb_transfer_done_func_t func, tb_cpointer_t priv);

/*! done transfer from stream to data
 *
 * @param istream   the istream
 * @param odata     the output data
 * @param osize     the output size
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_done_to_data(tb_stream_ref_t istream, tb_byte_t* odata, tb_size_t osize, tb_size_t lrate, tb_transfer_done_func_t func, tb_cpointer_t priv);

/*! done transfer from url to url
 *
 * @param iurl      the input url
 * @param ourl      the output url
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_done_url(tb_char_t const* iurl, tb_char_t const* ourl, tb_size_t lrate, tb_transfer_done_func_t func, tb_cpointer_t priv);

/*! done transfer from url to stream
 *
 * @param iurl      the input url
 * @param ostream   the ostream
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_done_url_to_stream(tb_char_t const* iurl, tb_stream_ref_t ostream, tb_size_t lrate, tb_transfer_done_func_t func, tb_cpointer_t priv);

/*! done transfer from url to data
 *
 * @param iurl      the input url
 * @param odata     the output data
 * @param osize     the output size
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_done_url_to_data(tb_char_t const* iurl, tb_byte_t* odata, tb_size_t osize, tb_size_t lrate, tb_transfer_done_func_t func, tb_cpointer_t priv);

/*! done transfer from data to url
 *
 * @param idata     the input data
 * @param isize     the input size
 * @param ourl      the output url
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_done_data_to_url(tb_byte_t const* idata, tb_size_t isize, tb_char_t const* ourl, tb_size_t lrate, tb_transfer_done_func_t func, tb_cpointer_t priv);

/*! done transfer from data to stream
 *
 * @param idata     the input data
 * @param isize     the input size
 * @param ostream   the ostream
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_done_data_to_stream(tb_byte_t const* idata, tb_size_t isize, tb_stream_ref_t ostream, tb_size_t lrate, tb_transfer_done_func_t func, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
