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
 * @file        prefix.h
 *
 */
#ifndef TB_STREAM_PREFIX_H
#define TB_STREAM_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../libc/libc.h"
#include "../network/url.h"
#include "../asio/asio.h"
#include "../memory/memory.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the stream ctrl
#define TB_STREAM_CTRL(type, ctrl)                              (((type) << 16) | (ctrl))
#define TB_STREAM_CTRL_FLTR(type, ctrl)                         TB_STREAM_CTRL(TB_STREAM_TYPE_FLTR, (((type) << 8) | (ctrl)))

/// the stream default timeout, 10s
#define TB_STREAM_DEFAULT_TIMEOUT                               (10000)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the stream mode enum
typedef enum __tb_stream_mode_e
{
    TB_STREAM_MODE_NONE     = 0
,   TB_STREAM_MODE_AIOO     = 1 ///!< for bstream
,   TB_STREAM_MODE_AICO     = 2 ///!< for astream

}tb_stream_mode_e;

/// the stream type enum
typedef enum __tb_stream_type_e
{
    TB_STREAM_TYPE_NONE     = 0
,   TB_STREAM_TYPE_FILE     = 1
,   TB_STREAM_TYPE_SOCK     = 2
,   TB_STREAM_TYPE_HTTP     = 3
,   TB_STREAM_TYPE_DATA     = 4
,   TB_STREAM_TYPE_FLTR     = 5
,   TB_STREAM_TYPE_USER     = 6 ///!< for user defined stream type

}tb_stream_type_e;

/// the stream wait enum
typedef enum __tb_stream_wait_e
{
    TB_STREAM_WAIT_NONE     = TB_AIOE_CODE_NONE
,   TB_STREAM_WAIT_READ     = TB_AIOE_CODE_RECV
,   TB_STREAM_WAIT_WRIT     = TB_AIOE_CODE_SEND
,   TB_STREAM_WAIT_EALL     = TB_AIOE_CODE_EALL

}tb_stream_wait_e;

/// the stream ctrl enum
typedef enum __tb_stream_ctrl_e
{
    TB_STREAM_CTRL_NONE                     = 0

    // the stream
,   TB_STREAM_CTRL_GET_URL                  = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 1)
,   TB_STREAM_CTRL_GET_HOST                 = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 2)
,   TB_STREAM_CTRL_GET_PORT                 = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 3)
,   TB_STREAM_CTRL_GET_PATH                 = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 4)
,   TB_STREAM_CTRL_GET_SSL                  = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 5)
,   TB_STREAM_CTRL_GET_TIMEOUT              = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 6)
,   TB_STREAM_CTRL_GET_SIZE                 = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 7)
,   TB_STREAM_CTRL_GET_OFFSET               = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 8)

,   TB_STREAM_CTRL_SET_URL                  = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 11)
,   TB_STREAM_CTRL_SET_HOST                 = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 12)
,   TB_STREAM_CTRL_SET_PORT                 = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 13)
,   TB_STREAM_CTRL_SET_PATH                 = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 14)
,   TB_STREAM_CTRL_SET_SSL                  = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 15)
,   TB_STREAM_CTRL_SET_TIMEOUT              = TB_STREAM_CTRL(TB_STREAM_TYPE_NONE, 16)

    // the stream for data
,   TB_STREAM_CTRL_DATA_SET_DATA            = TB_STREAM_CTRL(TB_STREAM_TYPE_DATA, 1)

    // the stream for file
,   TB_STREAM_CTRL_FILE_GET_MODE            = TB_STREAM_CTRL(TB_STREAM_TYPE_FILE, 1)
,   TB_STREAM_CTRL_FILE_SET_MODE            = TB_STREAM_CTRL(TB_STREAM_TYPE_FILE, 2)

    // the stream for sock
,   TB_STREAM_CTRL_SOCK_GET_TYPE            = TB_STREAM_CTRL(TB_STREAM_TYPE_SOCK, 1)
,   TB_STREAM_CTRL_SOCK_SET_TYPE            = TB_STREAM_CTRL(TB_STREAM_TYPE_SOCK, 2)
,   TB_STREAM_CTRL_SOCK_KEEP_ALIVE          = TB_STREAM_CTRL(TB_STREAM_TYPE_SOCK, 3)

    // the stream for http
,   TB_STREAM_CTRL_HTTP_GET_HEAD            = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 1)
,   TB_STREAM_CTRL_HTTP_GET_RANGE           = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 2)
,   TB_STREAM_CTRL_HTTP_GET_METHOD          = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 3)
,   TB_STREAM_CTRL_HTTP_GET_VERSION         = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 4)
,   TB_STREAM_CTRL_HTTP_GET_COOKIES         = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 5)
,   TB_STREAM_CTRL_HTTP_GET_REDIRECT        = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 6) 
,   TB_STREAM_CTRL_HTTP_GET_HEAD_FUNC       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 7)
,   TB_STREAM_CTRL_HTTP_GET_HEAD_PRIV       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 8)
,   TB_STREAM_CTRL_HTTP_GET_AUTO_UNZIP      = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 9)
,   TB_STREAM_CTRL_HTTP_GET_POST_URL        = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 10)
,   TB_STREAM_CTRL_HTTP_GET_POST_DATA       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 11)
,   TB_STREAM_CTRL_HTTP_GET_POST_FUNC       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 12)
,   TB_STREAM_CTRL_HTTP_GET_POST_PRIV       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 13)
,   TB_STREAM_CTRL_HTTP_GET_POST_LRATE      = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 14)

,   TB_STREAM_CTRL_HTTP_SET_HEAD            = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 20)
,   TB_STREAM_CTRL_HTTP_SET_RANGE           = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 21)
,   TB_STREAM_CTRL_HTTP_SET_METHOD          = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 22)
,   TB_STREAM_CTRL_HTTP_SET_VERSION         = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 23)
,   TB_STREAM_CTRL_HTTP_SET_COOKIES         = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 24)
,   TB_STREAM_CTRL_HTTP_SET_REDIRECT        = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 25)
,   TB_STREAM_CTRL_HTTP_SET_HEAD_FUNC       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 26)
,   TB_STREAM_CTRL_HTTP_SET_HEAD_PRIV       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 27)
,   TB_STREAM_CTRL_HTTP_SET_AUTO_UNZIP      = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 28)
,   TB_STREAM_CTRL_HTTP_SET_POST_URL        = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 29)
,   TB_STREAM_CTRL_HTTP_SET_POST_DATA       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 30)
,   TB_STREAM_CTRL_HTTP_SET_POST_FUNC       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 31)
,   TB_STREAM_CTRL_HTTP_SET_POST_PRIV       = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 32)
,   TB_STREAM_CTRL_HTTP_SET_POST_LRATE      = TB_STREAM_CTRL(TB_STREAM_TYPE_HTTP, 33)

    // the stream for filter
,   TB_STREAM_CTRL_FLTR_GET_STREAM          = TB_STREAM_CTRL(TB_STREAM_TYPE_FLTR, 1)
,   TB_STREAM_CTRL_FLTR_GET_FILTER          = TB_STREAM_CTRL(TB_STREAM_TYPE_FLTR, 2)
,   TB_STREAM_CTRL_FLTR_SET_STREAM          = TB_STREAM_CTRL(TB_STREAM_TYPE_FLTR, 3)
,   TB_STREAM_CTRL_FLTR_SET_FILTER          = TB_STREAM_CTRL(TB_STREAM_TYPE_FLTR, 4)

}tb_stream_ctrl_e;

#endif
