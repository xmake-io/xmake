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
 * @file        ws2_32.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_INTERFACE_WS2_32_H
#define TB_PLATFORM_WINDOWS_INTERFACE_WS2_32_H

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

// the WSAStartup func type
typedef tb_int_t (WSAAPI* tb_ws2_32_WSAStartup_t)(WORD wVersionRequested, LPWSADATA lpWSAData);

// the WSACleanup func type
typedef tb_int_t (WSAAPI* tb_ws2_32_WSACleanup_t)(tb_void_t);

// the WSASocketA func type
typedef SOCKET (WSAAPI* tb_ws2_32_WSASocketA_t)(tb_int_t af, tb_int_t type, tb_int_t protocol, LPWSAPROTOCOL_INFO lpProtocolInfo, GROUP g, DWORD dwFlags);

// the WSAGetLastError func type
typedef tb_int_t (WSAAPI* tb_ws2_32_WSAGetLastError_t)(tb_void_t);

// the WSAIoctl func type
typedef tb_int_t (WSAAPI* tb_ws2_32_WSAIoctl_t)(SOCKET s, DWORD dwIoControlCode, LPVOID lpvInBuffer, DWORD cbInBuffer, LPVOID lpvOutBuffer, DWORD cbOutBuffer, LPDWORD lpcbBytesReturned, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

// the WSASend func type
typedef tb_int_t (WSAAPI* tb_ws2_32_WSASend_t)(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesSent, DWORD dwFlags, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

// the WSARecv func type
typedef tb_int_t (WSAAPI* tb_ws2_32_WSARecv_t)(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesRecvd, LPDWORD lpFlags, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

// the WSASendTo func type
typedef tb_int_t (WSAAPI* tb_ws2_32_WSASendTo_t)(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesSent, DWORD dwFlags, struct sockaddr const* lpTo, tb_int_t iToLen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

// the WSARecvFrom func type
typedef tb_int_t (WSAAPI* tb_ws2_32_WSARecvFrom_t)(SOCKET s, LPWSABUF lpBuffers, DWORD dwBufferCount, LPDWORD lpNumberOfBytesRecvd, LPDWORD lpFlags, struct sockaddr* lpFrom, LPINT lpFromlen, LPWSAOVERLAPPED lpOverlapped, LPWSAOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine);

// the send func type
typedef tb_int_t (WSAAPI* tb_ws2_32_send_t)(SOCKET s, tb_char_t const* buf, tb_int_t len, tb_int_t flags);

// the recv func type
typedef tb_int_t (WSAAPI* tb_ws2_32_recv_t)(SOCKET s, tb_char_t *buf, tb_int_t len, tb_int_t flags);

// the sendto func type
typedef tb_int_t (WSAAPI* tb_ws2_32_sendto_t)(SOCKET s, tb_char_t const* buf, tb_int_t len, tb_int_t flags, struct sockaddr const* to, tb_int_t tolen);

// the recvfrom func type
typedef tb_int_t (WSAAPI* tb_ws2_32_recvfrom_t)(SOCKET s, tb_char_t* buf, tb_int_t len, tb_int_t flags, struct sockaddr* from, tb_int_t* fromlen);

// the bind func type
typedef tb_int_t (WSAAPI* tb_ws2_32_bind_t)(SOCKET s, struct sockaddr const* name, tb_int_t namelen);

// the accept func type
typedef SOCKET (WSAAPI* tb_ws2_32_accept_t)(SOCKET s, struct sockaddr* addr, tb_int_t* addrlen);

// the listen func type
typedef tb_int_t (WSAAPI* tb_ws2_32_listen_t)(SOCKET s, tb_int_t backlog);

// the select func type
typedef tb_int_t (WSAAPI* tb_ws2_32_select_t)(tb_int_t nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval const* timeout);

// the connect func type
typedef tb_int_t (WSAAPI* tb_ws2_32_connect_t)(SOCKET s, struct sockaddr const* name, tb_int_t namelen);

// the shutdown func type
typedef tb_int_t (WSAAPI* tb_ws2_32_shutdown_t)(SOCKET s, tb_int_t how);

// the getsockname func type
typedef tb_int_t (WSAAPI* tb_ws2_32_getsockname_t)(SOCKET s, struct sockaddr* name, tb_int_t* namelen);

// the getsockopt func type
typedef tb_int_t (WSAAPI* tb_ws2_32_getsockopt_t)(SOCKET s, tb_int_t level, tb_int_t optname, tb_char_t* optval, tb_int_t* optlen);

// the setsockopt func type
typedef tb_int_t (WSAAPI* tb_ws2_32_setsockopt_t)(SOCKET s, tb_int_t level, tb_int_t optname, tb_char_t const* optval, tb_int_t optlen);

// the ioctlsocket func type
typedef tb_int_t (WSAAPI* tb_ws2_32_ioctlsocket_t)(SOCKET s, LONG cmd, u_long* argp);

// the closesocket func type
typedef tb_int_t (WSAAPI* tb_ws2_32_closesocket_t)(SOCKET s);

// the gethostname func type
typedef tb_int_t (WSAAPI* tb_ws2_32_gethostname_t)(tb_char_t* name, tb_int_t namelen);

// the __WSAFDIsSet func type
typedef tb_int_t (WSAAPI* tb_ws2_32___WSAFDIsSet_t)(SOCKET fd, fd_set* set);

// the ws2_32 interfaces type
typedef struct __tb_ws2_32_t
{
    // WSAStartup
    tb_ws2_32_WSAStartup_t          WSAStartup;
 
    // WSACleanup
    tb_ws2_32_WSACleanup_t          WSACleanup;
 
    // WSASocketA
    tb_ws2_32_WSASocketA_t          WSASocketA;

    // WSAIoctl
    tb_ws2_32_WSAIoctl_t            WSAIoctl;
 
    // WSAGetLastError
    tb_ws2_32_WSAGetLastError_t     WSAGetLastError;

    // WSASend
    tb_ws2_32_WSASend_t             WSASend;

    // WSARecv
    tb_ws2_32_WSARecv_t             WSARecv;

    // WSASendTo
    tb_ws2_32_WSASendTo_t           WSASendTo;

    // WSARecvFrom
    tb_ws2_32_WSARecvFrom_t         WSARecvFrom;

    // bind
    tb_ws2_32_bind_t                bind;

    // send
    tb_ws2_32_send_t                send;

    // recv
    tb_ws2_32_recv_t                recv;

    // sendto
    tb_ws2_32_sendto_t              sendto;

    // recvfrom
    tb_ws2_32_recvfrom_t            recvfrom;

    // accept
    tb_ws2_32_accept_t              accept;

    // listen
    tb_ws2_32_listen_t              listen;

    // select
    tb_ws2_32_select_t              select;

    // connect
    tb_ws2_32_connect_t             connect;

    // shutdown
    tb_ws2_32_shutdown_t            shutdown;

    // getsockname
    tb_ws2_32_getsockname_t         getsockname;

    // getsockopt
    tb_ws2_32_getsockopt_t          getsockopt;

    // setsockopt
    tb_ws2_32_setsockopt_t          setsockopt;

    // ioctlsocket
    tb_ws2_32_ioctlsocket_t         ioctlsocket;

    // closesocket
    tb_ws2_32_closesocket_t         closesocket;
    
    // gethostname
    tb_ws2_32_gethostname_t         gethostname;
 
    // __WSAFDIsSet
    tb_ws2_32___WSAFDIsSet_t        __WSAFDIsSet;

}tb_ws2_32_t, *tb_ws2_32_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* the ws2_32 interfaces
 *
 * @return          the ws2_32 interfaces pointer
 */
tb_ws2_32_ref_t    tb_ws2_32(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
