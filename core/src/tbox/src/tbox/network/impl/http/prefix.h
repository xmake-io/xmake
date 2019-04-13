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
 * @file        prefix.h
 *
 */
#ifndef TB_NETWORK_IMPL_HTTP_PREFIX_H
#define TB_NETWORK_IMPL_HTTP_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../../url.h"
#include "../../http.h"
#include "../../cookies.h"
#include "../../../libc/libc.h"
#include "../../../string/string.h"
#include "../../../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the http default timeout, 10s
#define TB_HTTP_DEFAULT_TIMEOUT                 (10000)

/// the http default redirect maxn
#define TB_HTTP_DEFAULT_REDIRECT                (10)

/// the http default port
#define TB_HTTP_DEFAULT_PORT                    (80)

/// the http default port for ssl
#define TB_HTTP_DEFAULT_PORT_SSL                (443)

#endif
