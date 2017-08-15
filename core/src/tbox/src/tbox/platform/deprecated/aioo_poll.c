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
 * @file        aioo_poll.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <sys/poll.h>
#include <sys/socket.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_long_t tb_aioo_rtor_poll_wait(tb_socket_ref_t sock, tb_size_t code, tb_long_t timeout)
{
    // check
    tb_assert_and_check_return_val(sock, -1);

    // init
    struct pollfd pfd = {0};
    pfd.fd = tb_sock2fd(sock);
    if (code & TB_AIOE_CODE_RECV || code & TB_AIOE_CODE_ACPT) pfd.events |= POLLIN;
    if (code & TB_AIOE_CODE_SEND || code & TB_AIOE_CODE_CONN) pfd.events |= POLLOUT;

    // poll
    tb_long_t r = poll(&pfd, 1, timeout);
    tb_assert_and_check_return_val(r >= 0, -1);

    // timeout?
    tb_check_return_val(r, 0);

    // error?
    tb_int_t o = 0;
    socklen_t n = sizeof(socklen_t);
    getsockopt(pfd.fd, SOL_SOCKET, SO_ERROR, &o, &n);
    if (o) return -1;

    // ok
    tb_long_t e = 0;
    if (pfd.revents & POLLIN) 
    {
        e |= TB_AIOE_CODE_RECV;
        if (code & TB_AIOE_CODE_ACPT) e |= TB_AIOE_CODE_ACPT;
    }
    if (pfd.revents & POLLOUT) 
    {
        e |= TB_AIOE_CODE_SEND;
        if (code & TB_AIOE_CODE_CONN) e |= TB_AIOE_CODE_CONN;
    }
    if ((pfd.revents & POLLHUP) && !(e & (TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND))) 
        e |= TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND;
    return e;
}

