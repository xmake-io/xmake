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
 * @file        method.c
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "http_method"
#define TB_TRACE_MODULE_DEBUG           (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "method.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
static tb_char_t const* g_http_methods[] = 
{
    "GET"
,   "POST"
,   "HEAD"
,   "PUT"
,   "OPTIONS"
,   "DELETE"
,   "TRACE"
,   "CONNECT"
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_char_t const* tb_http_method_cstr(tb_size_t method)
{
    // check
    tb_assert_and_check_return_val(method < tb_arrayn(g_http_methods), tb_null);

    // ok
    return g_http_methods[method];
}
