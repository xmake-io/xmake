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

