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
 * @file        date.h
 */
#ifndef TB_NETWORK_IMPL_HTTP_DATE_H
#define TB_NETWORK_IMPL_HTTP_DATE_H

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

/* get the http date from the given cstring
 *
 * <pre>
 * supports format:
 *    Sun, 06 Nov 1994 08:49:37 GMT  ; RFC 822, updated by RFC 1123
 *    Sunday, 06-Nov-94 08:49:37 GMT ; RFC 850, obsoleted by RFC 1036
 *    Sun Nov 6 08:49:37 1994        ; ANSI C's asctime() format
 *
 * for cookies(RFC 822, RFC 850, RFC 1036, and RFC 1123):
 *    Sun, 06-Nov-1994 08:49:37 GMT
 *
 * </pre>
 *
 * @param cstr          the cstring
 * @param size          the cstring length
 *
 * @return              the date
 */
tb_time_t               tb_http_date_from_cstr(tb_char_t const* cstr, tb_size_t size);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

