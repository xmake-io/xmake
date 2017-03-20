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
 * @file        dns.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_DNS_H
#define TB_ASIO_DNS_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "aicp.h"
#include "../../network/ipaddr.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the aicp dns ref type
typedef __tb_typeref__(aicp_dns);

/// the aicp dns done func type
typedef tb_void_t   (*tb_aicp_dns_done_func_t)(tb_aicp_dns_ref_t dns, tb_char_t const* host, tb_ipaddr_ref_t addr, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the dns 
 *
 * @param aicp      the aicp
 *
 * @return          the dns 
 */
__tb_deprecated__
tb_aicp_dns_ref_t   tb_aicp_dns_init(tb_aicp_ref_t aicp);

/*! kill the dns
 *
 * @param dns       the dns 
 */
__tb_deprecated__
tb_void_t           tb_aicp_dns_kill(tb_aicp_dns_ref_t dns);

/*! exit the dns
 *
 * @param dns       the dns 
 */
__tb_deprecated__
tb_void_t           tb_aicp_dns_exit(tb_aicp_dns_ref_t dns);

/*! done the dns
 *
 * @param dns       the dns 
 * @param host      the host
 * @param timeout   the timeout, ms
 * @param func      the done func
 * @param priv      the func private data
 *
 * @return          tb_true or tb_false
 */
__tb_deprecated__
tb_bool_t           tb_aicp_dns_done(tb_aicp_dns_ref_t dns, tb_char_t const* host, tb_long_t timeout, tb_aicp_dns_done_func_t func, tb_cpointer_t priv);

/*! the dns aicp
 *
 * @param handle    the dns handle
 *
 * @return          the aicp
 */
__tb_deprecated__
tb_aicp_ref_t       tb_aicp_dns_aicp(tb_aicp_dns_ref_t dns);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
