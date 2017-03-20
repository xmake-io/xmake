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
 * @file        aioo.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_AIOO_H
#define TB_ASIO_AIOO_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the aioo handle
 *
 * @param aioo      the aioo
 *
 * @return          the socket
 */
__tb_deprecated__
tb_socket_ref_t     tb_aioo_sock(tb_aioo_ref_t aioo);

/*! wait the aioo
 *
 * blocking wait the single event aioo, so need not aiop 
 * return the event type if ok, otherwise return 0 for timeout
 *
 * @param sock      the sock 
 * @param code      the aioe code
 * @param timeout   the timeout, infinity: -1
 *
 * @return          > 0: the aioe code, 0: timeout, -1: failed
 */
__tb_deprecated__
tb_long_t           tb_aioo_wait(tb_socket_ref_t sock, tb_size_t code, tb_long_t timeout);


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
