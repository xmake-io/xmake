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
#ifndef TB_STREAM_PREFIX_H
#define TB_STREAM_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../libc/libc.h"
#include "../network/url.h"
#include "../memory/memory.h"
#include "../platform/socket.h"

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
,   TB_STREAM_MODE_AIOO     = 1 ///!< for stream
,   TB_STREAM_MODE_AICO     = 2 ///!< for async_stream

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
    TB_STREAM_WAIT_NONE     = TB_SOCKET_EVENT_NONE
,   TB_STREAM_WAIT_READ     = TB_SOCKET_EVENT_RECV
,   TB_STREAM_WAIT_WRIT     = TB_SOCKET_EVENT_SEND
,   TB_STREAM_WAIT_EALL     = TB_SOCKET_EVENT_EALL

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
,   TB_STREAM_CTRL_FILE_IS_STREAM           = TB_STREAM_CTRL(TB_STREAM_TYPE_FILE, 3)

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
