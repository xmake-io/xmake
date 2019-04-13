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
 * @file        exception.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "platform.h"
#include "impl/exception.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if defined(TB_CONFIG_EXCEPTION_ENABLE) && defined(TB_CONFIG_OS_WINDOWS)
#   include "windows/exception.c"
#elif defined(TB_CONFIG_EXCEPTION_ENABLE) && defined(tb_signal)
#   include "libc/exception.c"
#else
tb_bool_t tb_exception_init_env()
{
    tb_trace_noimpl();
    return tb_true;
} 
tb_void_t tb_exception_exit_env()
{
    tb_trace_noimpl();
}
#endif

