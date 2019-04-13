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
 * @file        url.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_URL_H
#define TB_UTILS_URL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! encode the url, not encode: -_. and ' ' => '+'
 *
 * @param ib        the input data
 * @param in        the input size
 * @param ob        the output data
 * @param on        the output size
 *
 * @return          the real size
 */
tb_size_t           tb_url_encode(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on);

/*! decode the url
 *
 * @param ib        the input data
 * @param in        the input size
 * @param ob        the output data
 * @param on        the output size
 *
 * @return          the real size
 */
tb_size_t           tb_url_decode(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on);

/*! encode the url, not encode: -_.!~*'();/?:@&=+$,#
 *
 * @param ib        the input data
 * @param in        the input size
 * @param ob        the output data
 * @param on        the output size
 *
 * @return          the real size
 */
tb_size_t           tb_url_encode2(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on);

/*! decode the url
 *
 * @param ib        the input data
 * @param in        the input size
 * @param ob        the output data
 * @param on        the output size
 *
 * @return          the real size
 */
tb_size_t           tb_url_decode2(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on);

/*! encode the url arguments, not encode: -_.!~*'() 
 *
 * @param ib        the input data
 * @param in        the input size
 * @param ob        the output data
 * @param on        the output size
 *
 * @return          the real size
 */
tb_size_t           tb_url_encode_args(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on);

/*! decode the url arguments
 *
 * @param ib        the input data
 * @param in        the input size
 * @param ob        the output data
 * @param on        the output size
 *
 * @return          the real size
 */
tb_size_t           tb_url_decode_args(tb_char_t const* ib, tb_size_t in, tb_char_t* ob, tb_size_t on);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

