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
 * @file        charset.h
 * @defgroup    charset
 * @ingroup     charset
 *
 */
#ifndef TB_CHARSET_H
#define TB_CHARSET_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../stream/stream.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the endian for the charset type
#define TB_CHARSET_TYPE_LE                  (0x0100)
#define TB_CHARSET_TYPE_ME                  (0x0100)
#ifdef TB_WORDS_BIGENDIAN
#   define TB_CHARSET_TYPE_NE               (TB_CHARSET_TYPE_BE)
#else
#   define TB_CHARSET_TYPE_NE               (TB_CHARSET_TYPE_LE)
#endif

// type
#define TB_CHARSET_TYPE(type)               (((type) & ~TB_CHARSET_TYPE_ME))

// ok?
#define TB_CHARSET_TYPE_OK(type)            (TB_CHARSET_TYPE(type) != TB_CHARSET_TYPE_NONE)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the charset type enum
 * 
 * @note default: big endian
 */
typedef enum __tb_charset_type_e
{
    TB_CHARSET_TYPE_NONE        = 0x00
,   TB_CHARSET_TYPE_ASCII       = 0x01
,   TB_CHARSET_TYPE_GB2312      = 0x02
,   TB_CHARSET_TYPE_GBK         = 0x03
,   TB_CHARSET_TYPE_ISO8859     = 0x04
,   TB_CHARSET_TYPE_UCS2        = 0x05
,   TB_CHARSET_TYPE_UCS4        = 0x06
,   TB_CHARSET_TYPE_UTF16       = 0x07
,   TB_CHARSET_TYPE_UTF32       = 0x08
,   TB_CHARSET_TYPE_UTF8        = 0x09

}tb_charset_type_e;

/// the charset type
typedef struct __tb_charset_t
{
    /// the charset type
    tb_size_t           type;

    /// the charset name
    tb_char_t const*    name;

    /*! get ucs4 character
     *
     * return: -1, 0 or 1
     *
     * -1:  failed, break it
     * 0:   no character, skip and continue it
     * 1:   ok, continue it
     */
    tb_long_t           (*get)(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t* ch);

    /*! set ucs4 character
     *
     * return: -1, 0 or 1
     *
     * -1:  failed, break it
     * 0:   no character, skip and continue it
     * 1:   ok, continue it
     */
    tb_long_t           (*set)(tb_static_stream_ref_t sstream, tb_bool_t be, tb_uint32_t ch);

}tb_charset_t;

/// the charset ref type
typedef tb_charset_t*   tb_charset_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the charset name
 *
 * @param type      the charset type
 *
 * @return          the charset name
 */
tb_char_t const*    tb_charset_name(tb_size_t type);

/*! the charset type
 *
 * @param name      the charset name
 *
 * @return          the charset type
 */
tb_size_t           tb_charset_type(tb_char_t const* name);

/*! find the charset
 *
 * @param type      the charset type
 *
 * @return          the charset pointer
 */
tb_charset_ref_t    tb_charset_find(tb_size_t type);

/*! convert charset from static stream
 *
 * @param ftype     the from charset
 * @param ttype     the to charset
 * @param fst       the from stream
 * @param tst       the to stream
 *
 * @return          the converted bytes for output or -1
 */
tb_long_t           tb_charset_conv_bst(tb_size_t ftype, tb_size_t ttype, tb_static_stream_ref_t fst, tb_static_stream_ref_t tst);

/*! convert charset from cstr
 *
 * @param ftype     the from charset
 * @param ttype     the to charset
 * @param cstr      the cstr
 * @param data      the data
 * @param maxn      the size
 *
 * @return          the converted bytes for output or -1
 */
tb_long_t           tb_charset_conv_cstr(tb_size_t ftype, tb_size_t ttype, tb_char_t const* cstr, tb_byte_t* data, tb_size_t size);

/*! convert charset from data
 *
 * @param ftype     the from charset
 * @param ttype     the to charset
 * @param idata     the idata
 * @param isize     the isize
 * @param odata     the odata
 * @param osize     the osize
 *
 * @return          the converted bytes for output or -1
 */
tb_long_t           tb_charset_conv_data(tb_size_t ftype, tb_size_t ttype, tb_byte_t const* idata, tb_size_t isize, tb_byte_t* odata, tb_size_t osize);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

