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
 * @file        aiop.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "platform_aiop"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../../asio/deprecated/impl/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if defined(TB_CONFIG_OS_WINDOWS)
#   include "../deprecated/aiop_select.c"
    tb_aiop_rtor_impl_t* tb_aiop_rtor_impl_init(tb_aiop_impl_t* aiop)
    {
        return tb_aiop_rtor_select_init(aiop);
    }
#elif defined(TB_CONFIG_POSIX_HAVE_EPOLL_CREATE) \
    && defined(TB_CONFIG_POSIX_HAVE_EPOLL_WAIT)
#   include "../deprecated/aiop_epoll.c"
    tb_aiop_rtor_impl_t* tb_aiop_rtor_impl_init(tb_aiop_impl_t* aiop)
    {
        return tb_aiop_rtor_epoll_init(aiop);
    }
#elif defined(TB_CONFIG_OS_MACOSX)
#   include "../deprecated/aiop_kqueue.c"
    tb_aiop_rtor_impl_t* tb_aiop_rtor_impl_init(tb_aiop_impl_t* aiop)
    {
        return tb_aiop_rtor_kqueue_init(aiop);
    }
#elif defined(TB_CONFIG_POSIX_HAVE_POLL)
#   include "../deprecated/aiop_poll.c"
    tb_aiop_rtor_impl_t* tb_aiop_rtor_impl_init(tb_aiop_impl_t* aiop)
    {
        return tb_aiop_rtor_poll_init(aiop);
    }
#else
#   error have not available event mode
#endif

