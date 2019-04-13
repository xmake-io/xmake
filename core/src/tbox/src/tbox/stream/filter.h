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
 * @file        filter.h
 * @defgroup    stream
 *
 */
#ifndef TB_FILTER_H
#define TB_FILTER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the filter ctrl
#define TB_FILTER_CTRL(type, ctrl)               (((type) << 16) | (ctrl))

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the filter type enum
typedef enum __tb_filter_type_e
{
    TB_FILTER_TYPE_NONE      = 0
,   TB_FILTER_TYPE_ZIP       = 1
,   TB_FILTER_TYPE_CACHE     = 2
,   TB_FILTER_TYPE_CHARSET   = 3
,   TB_FILTER_TYPE_CHUNKED   = 4

}tb_filter_type_e;

/// the filter ctrl enum
typedef enum __tb_filter_ctrl_e
{
    TB_FILTER_CTRL_NONE                  = 0

,   TB_FILTER_CTRL_ZIP_GET_ALGO          = TB_FILTER_CTRL(TB_FILTER_TYPE_ZIP, 1)
,   TB_FILTER_CTRL_ZIP_GET_ACTION        = TB_FILTER_CTRL(TB_FILTER_TYPE_ZIP, 2)
,   TB_FILTER_CTRL_ZIP_SET_ALGO          = TB_FILTER_CTRL(TB_FILTER_TYPE_ZIP, 3)
,   TB_FILTER_CTRL_ZIP_SET_ACTION        = TB_FILTER_CTRL(TB_FILTER_TYPE_ZIP, 4)

,   TB_FILTER_CTRL_CHARSET_GET_FTYPE     = TB_FILTER_CTRL(TB_FILTER_TYPE_CHARSET, 1)
,   TB_FILTER_CTRL_CHARSET_GET_TTYPE     = TB_FILTER_CTRL(TB_FILTER_TYPE_CHARSET, 2)
,   TB_FILTER_CTRL_CHARSET_SET_FTYPE     = TB_FILTER_CTRL(TB_FILTER_TYPE_CHARSET, 3)
,   TB_FILTER_CTRL_CHARSET_SET_TTYPE     = TB_FILTER_CTRL(TB_FILTER_TYPE_CHARSET, 4)

}tb_filter_ctrl_e;

/// the filter ref type
typedef __tb_typeref__(filter);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init filter from zip
 *
 * @param algo          the zip algorithm
 * @param action        the zip action
 *
 * @return              the filter
 */
tb_filter_ref_t         tb_filter_init_from_zip(tb_size_t algo, tb_size_t action);

/*! init filter from charset
 *
 * @param fr            the from charset
 * @param to            the to charset
 *
 * @return              the filter
 */
tb_filter_ref_t         tb_filter_init_from_charset(tb_size_t fr, tb_size_t to);

/*! init filter from chunked
 *
 * @param dechunked decode the chunked data?
 *
 * @return              the filter
 */
tb_filter_ref_t         tb_filter_init_from_chunked(tb_bool_t dechunked);

/*! init filter from cache
 *
 * @param size          the initial cache size, using the default size if be zero
 *
 * @return              the filter
 */
tb_filter_ref_t         tb_filter_init_from_cache(tb_size_t size);

/*! exit filter
 *
 * @param filter        the filter
 */
tb_void_t               tb_filter_exit(tb_filter_ref_t filter);

/*! open filter
 *
 * @param filter        the filter
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_filter_open(tb_filter_ref_t filter);

/*! clos filter
 *
 * @param filter        the filter
 */
tb_void_t               tb_filter_clos(tb_filter_ref_t filter);

/*! ctrl filter
 *
 * @param filter        the filter
 * @param ctrl          the ctrl code
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_filter_ctrl(tb_filter_ref_t filter, tb_size_t ctrl, ...);

/*! is eof for the filter input data, but the output maybe exists the left data and need flush it
 *
 * @param filter        the filter
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_filter_beof(tb_filter_ref_t filter);

/*! limit the input size for filter
 *
 * @param filter        the filter
 * @param limit         the input limit size
 */
tb_void_t               tb_filter_limit(tb_filter_ref_t filter, tb_hong_t limit);

/*! push data to the filter input data
 *
 * @param filter        the filter
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_filter_push(tb_filter_ref_t filter, tb_byte_t const* data, tb_size_t size);

/*! spak filter
 *
 * @param filter        the filter
 * @param data          the input data, maybe null
 * @param size          the input size, maybe zero
 * @param pdata         the output data
 * @param need          the need output size, using the default size if zero
 * @param sync          sync? 1: sync, 0: no sync, -1: end
 *
 * @return              > 0: the output size, 0: continue, -1: end
 */
tb_long_t               tb_filter_spak(tb_filter_ref_t filter, tb_byte_t const* data, tb_size_t size, tb_byte_t const** pdata, tb_size_t need, tb_long_t sync);


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
