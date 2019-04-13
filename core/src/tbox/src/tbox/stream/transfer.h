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

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the transfer func type
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
typedef tb_bool_t   (*tb_transfer_func_t)(tb_size_t state, tb_hize_t offset, tb_hong_t size, tb_hize_t save, tb_size_t rate, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! transfer stream to stream
 *
 * @param istream   the istream
 * @param ostream   the ostream
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer(tb_stream_ref_t istream, tb_stream_ref_t ostream, tb_size_t lrate, tb_transfer_func_t func, tb_cpointer_t priv);

/*! transfer stream to url
 *
 * @param istream   the istream
 * @param ourl      the output url
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_to_url(tb_stream_ref_t istream, tb_char_t const* ourl, tb_size_t lrate, tb_transfer_func_t func, tb_cpointer_t priv);

/*! transfer stream to data
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
tb_hong_t           tb_transfer_to_data(tb_stream_ref_t istream, tb_byte_t* odata, tb_size_t osize, tb_size_t lrate, tb_transfer_func_t func, tb_cpointer_t priv);

/*! transfer url to url
 *
 * @param iurl      the input url
 * @param ourl      the output url
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_url(tb_char_t const* iurl, tb_char_t const* ourl, tb_size_t lrate, tb_transfer_func_t func, tb_cpointer_t priv);

/*! transfer url to stream
 *
 * @param iurl      the input url
 * @param ostream   the ostream
 * @param lrate     the limit rate and no limit if 0, bytes/s
 * @param func      the save func and be optional
 * @param priv      the func private data
 *
 * @return          the saved size, failed: -1
 */
tb_hong_t           tb_transfer_url_to_stream(tb_char_t const* iurl, tb_stream_ref_t ostream, tb_size_t lrate, tb_transfer_func_t func, tb_cpointer_t priv);

/*! transfer url to data
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
tb_hong_t           tb_transfer_url_to_data(tb_char_t const* iurl, tb_byte_t* odata, tb_size_t osize, tb_size_t lrate, tb_transfer_func_t func, tb_cpointer_t priv);

/*! transfer data to url
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
tb_hong_t           tb_transfer_data_to_url(tb_byte_t const* idata, tb_size_t isize, tb_char_t const* ourl, tb_size_t lrate, tb_transfer_func_t func, tb_cpointer_t priv);

/*! transfer data to stream
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
tb_hong_t           tb_transfer_data_to_stream(tb_byte_t const* idata, tb_size_t isize, tb_stream_ref_t ostream, tb_size_t lrate, tb_transfer_func_t func, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
