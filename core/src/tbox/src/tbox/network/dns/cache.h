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
 * @file        cache.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_DNS_CACHE_H
#define TB_NETWORK_DNS_CACHE_H

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

/*! init the cache list
 *
 * not using ctime default
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_dns_cache_init(tb_noarg_t);

/// exit the cache list
tb_void_t           tb_dns_cache_exit(tb_noarg_t);

/*! get addr from cache 
 *
 * @param name      the host name 
 * @param addr      the host addr
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_dns_cache_get(tb_char_t const* name, tb_ipaddr_ref_t addr);

/*! set addr to cache 
 *
 * @param name      the host name 
 * @param addr      the host addr
 */
tb_void_t           tb_dns_cache_set(tb_char_t const* name, tb_ipaddr_ref_t addr);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
