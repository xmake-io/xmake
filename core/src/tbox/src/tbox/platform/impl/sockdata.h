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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        sockdata.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_IMPL_SOCKDATA_H
#define TB_PLATFORM_IMPL_SOCKDATA_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "socket.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the socket data type
typedef struct __tb_sockdata_t
{
    // the socket data (sock => priv)
    tb_cpointer_t*          data;

    // the socket data maximum count
    tb_size_t               maxn;
    
}tb_sockdata_t, *tb_sockdata_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* get socket data instance in local thread
 *
 * @return sockdata the sockdata
 */
tb_sockdata_ref_t   tb_sockdata(tb_noarg_t);

/* init socket data
 *
 * @param sockdata  the sockdata
 */
tb_void_t           tb_sockdata_init(tb_sockdata_ref_t sockdata);

/* exit socket data 
 *
 * @param sockdata  the sockdata
 */
tb_void_t           tb_sockdata_exit(tb_sockdata_ref_t sockdata);

/* clear socket data 
 *
 * @param sockdata  the sockdata
 */
tb_void_t           tb_sockdata_clear(tb_sockdata_ref_t sockdata);

/* insert socket data 
 *
 * @param sockdata  the sockdata
 * @param sock      the socket
 * @param priv      the socket private data
 */
tb_void_t           tb_sockdata_insert(tb_sockdata_ref_t sockdata, tb_socket_ref_t sock, tb_cpointer_t priv);

/* remove socket data 
 *
 * @param sockdata  the sockdata
 * @param sock      the socket
 */
tb_void_t           tb_sockdata_remove(tb_sockdata_ref_t sockdata, tb_socket_ref_t sock);

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline implementation
 */
static __tb_inline__ tb_cpointer_t tb_sockdata_get(tb_sockdata_ref_t sockdata, tb_socket_ref_t sock)
{
    // check
    tb_long_t fd = tb_sock2fd(sock);
    tb_assert(sockdata && fd > 0 && fd < TB_MAXS32);

    // get the socket private data
    return (sockdata->data && fd < sockdata->maxn)? sockdata->data[fd] : tb_null;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
