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
 * @file        looker.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_DNS_LOOKER_H
#define TB_NETWORK_DNS_LOOKER_H

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

/// the dns looker type
typedef __tb_typeref__(dns_looker);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init for looking ipv4 from the host name, non-block
 *
 * @param name      the host name
 *
 * @return          the looker handle
 */
tb_dns_looker_ref_t tb_dns_looker_init(tb_char_t const* name);

/*! spak the looker
 *
 * @param looker    the looker 
 * @param addr      the address
 *
 * @return          1: ok, 0: continue: -1: failed
 */
tb_long_t           tb_dns_looker_spak(tb_dns_looker_ref_t looker, tb_ipaddr_ref_t addr);

/*! wait the looker
 *
 * @param looker    the looker 
 * @param timeout   the timeout
 *
 * @return          1: ok, 0: continue: -1: failed
 */
tb_long_t           tb_dns_looker_wait(tb_dns_looker_ref_t looker, tb_long_t timeout);

/*! exit the looker
 *
 * @param looker    the looker 
 */
tb_void_t           tb_dns_looker_exit(tb_dns_looker_ref_t looker);

/*! lookup address from the host name, block
 *
 * try to look it from cache first
 *
 * @param name      the host name
 * @param addr      the address
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_dns_looker_done(tb_char_t const* name, tb_ipaddr_ref_t addr);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
