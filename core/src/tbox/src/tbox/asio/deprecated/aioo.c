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
 * @file        aioo.c
 * @ingroup     asio
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aioo.h"
#include "aioe.h"
#include "impl/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */
tb_long_t tb_aioo_rtor_wait(tb_socket_ref_t sock, tb_size_t code, tb_long_t timeout);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_socket_ref_t tb_aioo_sock(tb_aioo_ref_t aioo)
{
    // check
    tb_aioo_impl_t const* impl = (tb_aioo_impl_t const*)aioo;
    tb_assert_and_check_return_val(impl, tb_null);

    // the sock
    return impl->sock;
}
tb_long_t tb_aioo_wait(tb_socket_ref_t sock, tb_size_t code, tb_long_t timeout)
{
    // check
    tb_assert_and_check_return_val(sock && code, 0);

    // wait aioo
    return tb_aioo_rtor_wait(sock, code, timeout);
}

