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
 * @file        prefix.h
 *
 */
#ifndef TB_PLATFORM_PREFIX_H
#define TB_PLATFORM_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// fd to file
#define tb_fd2file(fd)              ((fd) >= 0? (tb_file_ref_t)((tb_long_t)(fd) + 1) : tb_null)

// file to fd
#define tb_file2fd(file)            (tb_int_t)((file)? (((tb_long_t)(file)) - 1) : -1)

// fd to sock
#define tb_fd2sock(fd)              ((fd) >= 0? (tb_socket_ref_t)((tb_long_t)(fd) + 1) : tb_null)

// sock to fd
#define tb_sock2fd(sock)            (tb_int_t)((sock)? (((tb_long_t)(sock)) - 1) : -1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the iovec size type
 *
 * @note
 * we cannot use tb_size_t because sizeof(tb_size_t) != sizeof(u_long) for windows 64bits
 */
#ifdef TB_CONFIG_OS_WINDOWS
typedef  unsigned long      tb_iovec_size_t;
#else
typedef  tb_size_t          tb_iovec_size_t;
#endif

#ifdef TB_CONFIG_OS_WINDOWS
/// the iovec type for WSASend, WSARecv using WSABUF
typedef struct __tb_iovec_t
{
    /// the size
    tb_iovec_size_t         size;

    /// the data
    tb_byte_t*              data;

}tb_iovec_t;
#else
/// the iovec type for readv, preadv, writv, pwritv, recvv, sendv
typedef struct __tb_iovec_t
{
    /// the data
    tb_byte_t*              data;

    /// the size
    tb_iovec_size_t         size;

}tb_iovec_t;
#endif

#endif
