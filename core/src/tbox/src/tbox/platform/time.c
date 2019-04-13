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
 * @file        time.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "time.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_OS_WINDOWS
#   include "windows/time.c"
#elif defined(TB_CONFIG_LIBC_HAVE_GETTIMEOFDAY)
#   include "posix/time.c"
#else
tb_void_t tb_usleep(tb_size_t us)
{
    tb_trace_noimpl();
}
tb_void_t tb_msleep(tb_size_t ms)
{
    tb_trace_noimpl();
}
tb_void_t tb_sleep(tb_size_t s)
{
    tb_trace_noimpl();
}
tb_hong_t tb_mclock()
{
    tb_trace_noimpl();
    return 0;
}
tb_hong_t tb_uclock()
{
    tb_trace_noimpl();
    return 0;
}
tb_bool_t tb_gettimeofday(tb_timeval_t* tv, tb_timezone_t* tz)
{
    tb_trace_noimpl();
    return tb_false;
}
#endif
