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
 * @file        option.h
 * @ingroup     network
 *
 */
#ifndef TB_NETWORK_IMPL_HTTP_OPTION_H
#define TB_NETWORK_IMPL_HTTP_OPTION_H

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

/* init option
 *
 * @param option        the option
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_http_option_init(tb_http_option_t* option);

/* exit option
 *
 * @param option        the option
 */
tb_void_t               tb_http_option_exit(tb_http_option_t* option);

/* ctrl option
 *
 * @param option        the option
 * @param ctrl          the ctrl code
 * @param args          the ctrl args
 */
tb_bool_t               tb_http_option_ctrl(tb_http_option_t* option, tb_size_t code, tb_va_list_t args);

#ifdef __tb_debug__
/* dump option
 *
 * @param option        the option
 */
tb_void_t               tb_http_option_dump(tb_http_option_t* option);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

