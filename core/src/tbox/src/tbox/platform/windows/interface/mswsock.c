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
 * @file        mswsock.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "mswsock.h"
#include "ws2_32.h"
#include "../../socket.h"
#include "../../../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// from mswsock.h
#define TB_MSWSOCK_WSAID_ACCEPTEX                   {0xb5367df1, 0xcbac, 0x11cf, {0x95, 0xca, 0x00, 0x80, 0x5f, 0x48, 0xa1, 0x92}}
#define TB_MSWSOCK_WSAID_TRANSMITFILE               {0xb5367df0, 0xcbac, 0x11cf, {0x95, 0xca, 0x00, 0x80, 0x5f, 0x48, 0xa1, 0x92}}
#define TB_MSWSOCK_WSAID_GETACCEPTEXSOCKADDRS       {0xb5367df2, 0xcbac, 0x11cf, {0x95, 0xca, 0x00, 0x80, 0x5f, 0x48, 0xa1, 0x92}}
#define TB_MSWSOCK_WSAID_CONNECTEX                  {0x25a207b9, 0xddf3, 0x4660, {0x8e, 0xe9, 0x76, 0xe5, 0x8c, 0x74, 0x06, 0x3e}}
#define TB_MSWSOCK_WSAID_DISCONNECTEX               {0x7fda2e11, 0x8630, 0x436f, {0xa0, 0x31, 0xf5, 0x36, 0xa6, 0xee, 0xc1, 0x57}}
#define TB_MSWSOCK_WSAID_GETACCEPTEXSOCKADDRS       {0xb5367df2, 0xcbac, 0x11cf, {0x95, 0xca, 0x00, 0x80, 0x5f, 0x48, 0xa1, 0x92}}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_mswsock_instance_init(tb_handle_t instance, tb_cpointer_t priv)
{
    // check
    tb_mswsock_ref_t mswsock = (tb_mswsock_ref_t)instance;
    tb_assert_and_check_return_val(mswsock, tb_false);

    // done
    tb_socket_ref_t sock = tb_null;
    do
    {
        // init sock
        sock = tb_socket_init(TB_SOCKET_TYPE_TCP, TB_IPADDR_FAMILY_IPV4);
        tb_assert_and_check_break(sock);

        // init AcceptEx
        DWORD   AcceptEx_real = 0;
        GUID    AcceptEx_guid = TB_MSWSOCK_WSAID_ACCEPTEX;
        tb_ws2_32()->WSAIoctl(  (SOCKET)sock - 1
                            ,   SIO_GET_EXTENSION_FUNCTION_POINTER
                            ,   &AcceptEx_guid
                            ,   sizeof(GUID)
                            ,   &mswsock->AcceptEx
                            ,   sizeof(tb_mswsock_AcceptEx_t)
                            ,   &AcceptEx_real
                            ,   tb_null
                            ,   tb_null);

        // init ConnectEx
        DWORD   ConnectEx_real = 0;
        GUID    ConnectEx_guid = TB_MSWSOCK_WSAID_CONNECTEX;
        tb_ws2_32()->WSAIoctl(  (SOCKET)sock - 1
                            ,   SIO_GET_EXTENSION_FUNCTION_POINTER
                            ,   &ConnectEx_guid
                            ,   sizeof(GUID)
                            ,   &mswsock->ConnectEx
                            ,   sizeof(tb_mswsock_ConnectEx_t)
                            ,   &ConnectEx_real
                            ,   tb_null
                            ,   tb_null);

        // init DisconnectEx
        DWORD   DisconnectEx_real = 0;
        GUID    DisconnectEx_guid = TB_MSWSOCK_WSAID_DISCONNECTEX;
        tb_ws2_32()->WSAIoctl(  (SOCKET)sock - 1
                            ,   SIO_GET_EXTENSION_FUNCTION_POINTER
                            ,   &DisconnectEx_guid
                            ,   sizeof(GUID)
                            ,   &mswsock->DisconnectEx
                            ,   sizeof(tb_mswsock_DisconnectEx_t)
                            ,   &DisconnectEx_real
                            ,   tb_null
                            ,   tb_null);

        // init TransmitFile
        DWORD   TransmitFile_real = 0;
        GUID    TransmitFile_guid = TB_MSWSOCK_WSAID_TRANSMITFILE;
        tb_ws2_32()->WSAIoctl(  (SOCKET)sock - 1
                            ,   SIO_GET_EXTENSION_FUNCTION_POINTER
                            ,   &TransmitFile_guid
                            ,   sizeof(GUID)
                            ,   &mswsock->TransmitFile
                            ,   sizeof(tb_mswsock_TransmitFile_t)
                            ,   &TransmitFile_real
                            ,   tb_null
                            ,   tb_null);

        // init GetAcceptExSockaddrs
        DWORD   GetAcceptExSockaddrs_real = 0;
        GUID    GetAcceptExSockaddrs_guid = TB_MSWSOCK_WSAID_GETACCEPTEXSOCKADDRS;
        tb_ws2_32()->WSAIoctl(  (SOCKET)sock - 1
                            ,   SIO_GET_EXTENSION_FUNCTION_POINTER
                            ,   &GetAcceptExSockaddrs_guid
                            ,   sizeof(GUID)
                            ,   &mswsock->GetAcceptExSockaddrs
                            ,   sizeof(tb_mswsock_GetAcceptExSockaddrs_t)
                            ,   &GetAcceptExSockaddrs_real
                            ,   tb_null
                            ,   tb_null);
    } while (0);

    // exit sock
    if (sock) tb_socket_exit(sock);

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_mswsock_ref_t tb_mswsock()
{
    // init
    static tb_atomic_t      s_binited = 0;
    static tb_mswsock_t     s_mswsock = {0};

    // init the static instance
    tb_bool_t ok = tb_singleton_static_init(&s_binited, &s_mswsock, tb_mswsock_instance_init, tb_null);
    tb_assert(ok); tb_used(ok);

    // ok
    return &s_mswsock;
}
