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
 * @file        status.h
 */
#ifndef TB_NETWORK_IMPL_HTTP_STATUS_H
#define TB_NETWORK_IMPL_HTTP_STATUS_H

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

/* init status
 *
 * @param status        the status
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_http_status_init(tb_http_status_t* status);

/* exit status
 *
 * @param status        the status
 */
tb_void_t               tb_http_status_exit(tb_http_status_t* status);

/* clear status
 *
 * @param status        the status
 * @param host_changed  the host is changed
 */
tb_void_t               tb_http_status_cler(tb_http_status_t* status, tb_bool_t host_changed);

#ifdef __tb_debug__
/* dump status
 *
 * @param status        the status
 */
tb_void_t               tb_http_status_dump(tb_http_status_t* status);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

